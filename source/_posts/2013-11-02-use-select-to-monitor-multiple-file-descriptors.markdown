---
layout: post
title: "Use Select to Monitor Multiple File Descriptors"
date: 2013-11-02 21:44
comments: true
categories:  ["network"]
tags: ["select", "fd_set"]
---

In the [P2P network project][project], we were asked to simultaneously monitor user input
and also potential in-coming messages, yet we're not supposed to use multiple
threads or processes. That leaves us no choice but the [`select`][select] function.

<!-- more -->

In short, `select` allows you to monitor multiple file descriptors at the same
time, and tells you when some of them are available to read or write. 

### `fd_set` Operations

`fd_set` is fixed-size buffer that can host a few (up to `FD_SETSIZE`) file
descriptors. `sys/select.h` provide a few macros to manipulate the `fd_set`.

```c
void FD_CLR(int fd, fd_set *set);
int  FD_ISSET(int fd, fd_set *set);
void FD_SET(int fd, fd_set *set);
void FD_ZERO(fd_set *set);
```
Basically 

 - `FD_CLR` will remove a `fd` from the `fd_set`
 - `FD_ISSET` will test if a certain `fd` in the `fd_set` or not. 
 - `FD_SET` will add a `fd` to the `fd_set`
 - `FD_ZERO` will clear the `fd_set`

### Improved `fd_set` Wrappers

In practice, you'll often need to maintain a `fd_set` together with the maximun
fd in that set (more on this later). So I use a few wrappers to update the
`fd_set` and the `max_fd` at the same time.

```c
#include <sys/select.h>
#include <assert.h>

/* add a fd to fd_set, and update max_fd */
int
safe_fd_set(int fd, fd_set* fds, int* max_fd) {
    assert(max_fd != NULL);

    FD_SET(fd, fds);
    if (fd > *max_fd) {
        *max_fd = fd;
    }
    return 0;
}

/* clear fd from fds, update max fd if needed */
int
safe_fd_clr(int fd, fd_set* fds, int* max_fd) {
    assert(max_fd != NULL);

    FD_CLR(fd, fds);
    if (fd == *max_fd) {
        (*max_fd)--;
    }
    return 0;
}
```


### The `select` Function

The prototype of the function looks like this:

```c
int select(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds, struct timeval *timeout);
```

In our case, we only want to monitor a set of fds that are available to read, so
we don't really care about the `writefds` or `exceptfds`, just leave them as
`NULL`.

A key point here is that, console is also a file, with fd is `STDIN_FILENO`,
just as other files (socket, normal file, etc.). So to monitor user input as
well as socket, we only need to add their fds to the `readfds`.

Another trick is that, `nfds` is the highest-numbered file descriptor in
`readfds`, *plus 1*. So you'll want to set `nfds` as `max_fd+1`.

Also, note that `select` will modify the `readfds` you passed in, so you'll
definitely back up your `readfds` before calling `select`.

In this project, if nothing happens (no user input and no incoming message), we
just wait, so `timeout` parameter is not used here.


### Connect the Dots

We usually call `select` inside a `while` loop to keep monitoring possible
inputs. Here is the code snippets that demonstrate the typical usage of
`select`.

```
fd_set master;

/* add stdin and the sock fd to master fd_set */
FD_ZERO(&master);
safe_fd_set(STDIN_FILENO, &master, &max_fd);
safe_fd_set(server_sock, &master, &max_fd);

char prompt[512];
sprintf(prompt, "[%s@%s] $ ", is_server?"server":"client", hostname);

while (1) {
    printf("\r%s", prompt);
    fflush(stdout);

    /* back up master */
    fd_set dup = master;

    /* note the max_fd+1 */
    if (select(max_fd+1, &dup, NULL, NULL, NULL) < 0) {
        perror("select");
        return -1;
    }

    /* check which fd is avaialbe for read */
    for (int fd = 0; fd <= max_fd; fd++) {
        if (FD_ISSET(fd, &dup)) {
            if (fd == STDIN_FILENO) {
                handle_command();
            }
            else if (fd == server_sock) {
                printf("\n");
                handle_new_connection();
            }
            else {
                handle_message(fd);
            }
        }
    }
}
```

[project]: https://github.com/jhshi/course.network.p2p
[select]: http://man7.org/linux/man-pages/man2/pselect.2.html
