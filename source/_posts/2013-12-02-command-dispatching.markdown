---
layout: post
title: "Command Dispatching"
date: 2013-12-02 12:52
comments: true
categories: ["network"]
tags: ["C", "dispatch", "readline"]
---

In a few network projects, we're asked to write an interactive shell, to receive
command from user input. Here is the general pattern I used. The example I used
here is from the [P2P network project][hub], and you can find my earlier post
about [use select to monitor user input and socket at the same time][post].

<!--more-->

### Command Handing Functions

Since each command may have various number of arguments or options, it's
straightforward to use the standard `argc` and `argv` interface. So for each
command, we define there handling functions as follows.

```c
int cmd_help(int argc, char* argv[]);
int cmd_myip(int argc, char* argv[]);
int cmd_myport(int argc, char* argv[]);
int cmd_register(int argc, char* argv[]);
int cmd_connect(int argc, char* argv[]);
int cmd_list(int argc, char* argv[]);
int cmd_terminate(int argc, char* argv[]);
int cmd_exit(int argc, char* argv[]);
int cmd_download(int argc, char* argv[]);
int cmd_creator(int argc, char* argv[]);
int cmd_packet(int argc, char* argv[]);
```

### Command Table

It'll be tedious to manually decide which handling function to call. Instead,
we'll use an data structure called _Command Table_ to gracefully handle the
cases for all commands.

```c
struct {
    char* name;
    int (*handler)(int argc, char* argv[]);
    char* help_msg;
} cmd_table[] = {
    {"HELP", cmd_help, ": Show available user interface options."},
    {"MYIP", cmd_myip, ": Show IP address of this process."},
    {"MYPORT", cmd_myport, ": Show port on which this process is listening."},
    {"REGISTER", cmd_register, " <server_IP> <port_no>: Client register to server."},
    {"CONNECT", cmd_connect, " <destination> <port_no>: Connect to a peer client."},
    {"LIST", cmd_list, ": Show list of connected hosts."},
    {"TERMINATE", cmd_terminate, " <connection_id>: Terminate a certain connection"},
    {"EXIT", cmd_exit, ": Close all connections and terminate this process." },
    {"DOWNLOAD", cmd_download, " <file_name> <file_chunk_size_in_bytes>: Download a file in parallel."},
    {"CREATOR", cmd_creator, ": Show author's info."},
    {"PACKET", cmd_packet, " <packet_size_in_bytes>: Set packet size."},
    {NULL, NULL, NULL},
};
```
Here we define, for each command, which handler to use and also the help
message. More specifically, our `cmd_help` and be written as simple as follows.

```c
int
cmd_help(int argc, char* argv[]) {
    printf("Available commands are:\n");
    for (int i = 0; cmd_table[i].name != NULL; i++) {
        printf("%s%s\n", cmd_table[i].name, cmd_table[i].help_msg);
    }
    return 0;
}
```

### Command Dispatching

Now suppose you already found `STDIN_FILENO` is available to read using
`select`, which means user has entered some input and hit the {% key Enter %} key.
Then we need to read the input and dispatch the command.

```c
int
handle_command(void) {
    char* command = NULL;
    size_t len;
    /* let getline allocate memory for us */
    if (getline(&command, &len, stdin) < 0) {
        perror("getline");
        return -1;
    }
    if (cmd_dispatch(command) < 0) {
        return -1;
    }
    free(command);

    return 0;
}
```

Here we use the `getline` function to read the input from `stdin`. `getline`
will allocate the buffer for us, so we need not worry about the input size. But
we do need to free the buffer afterwards.

```c
int
cmd_dispatch(char* cmd) {
    char *argv[512];
    int argc=0;

    for (char* word = strtok(cmd, " \t\n");
            word != NULL;
            word = strtok(NULL, " \t\n")) {

        if (argc >= 512) {
            printf("[ERROR]: too many arguments\n");
            return -1;
        }

        argv[argc++] = word;
    }

    if (argc == 0) {
        return 0;
    }

    for (int i = 0; cmd_table[i].name != NULL; i++) {
        if (!strcmp(argv[0], cmd_table[i].name)) {
            return cmd_table[i].handler(argc, argv);
        }
    }

    printf("[ERROR]: command not found.\n");
    return -1;
}
```

In `cmd_dispatch`, we first split the inputs into an array of strings, then we
traverse the command table to find a match.

[hub]: https://github.com/jhshi/course.network.p2p
[post]: /2013/11/02/use-select-to-monitor-multiple-file-descriptors/
