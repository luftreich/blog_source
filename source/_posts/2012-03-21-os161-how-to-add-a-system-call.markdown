---
comments: true
date: 2012-03-21 14:15:41
layout: post
title: "OS161: How to Add a System Call"
categories: [os161]
tags: [syscall]
---

Let's use the `fork` system call as an example. For convinience, let's assume
`$OS161_SRC` is your os161 source root directory.


<!-- more -->

### How is a system call defined?

Take a look at `$OS161_SRC/user/lib/libc/arch/mips/syscalls-mips.S`. We can see
that a macro called `SYSCALL(sym, num)` is defined. Basically, this macro does
a very simple thing: fill `$v0` with `SYS_##sym` and jump to the common code at
`__syscall`. Two points to note here:

- `SYS_##sym` is a little compiler trick. `##sym` will be replaced by the
actual name of `sym`. In our case (`SYSCALL(fork, SYS_fork)`), here `sym` is
actually `fork`, so `SYS_##sym` will be replaced by `SYS_fork`. See [this gcc
document][gcc_concat] if you want know more details about it.

- The second argument of the macro, `num`, is unused here.

Then in `__syscall`, the first instruction is the [MIPS syscall instruction][mips_instr]. 
We'll discuss the details of this instruction later.
After this, we check `$a3` value to see if the syscall is successful and store
the error number (`$v0`) to `errno` if not.

`$OS161_SRC/build/user/libc/syscall.S` is generated according to
`$OS161_SRC/user/lib/libc/arch/mips/syscall-mips.S` during compiling, and this
file is the actual file that be compiled and linked to user library. We can
see that besides the `SYSCALL` macro and the `__syscall` code, declarations of
all the syscalls are added here. So when we call `fork` in user program, we
actually called the assembly functions defined in this file.

[gcc_concat]: http://gcc.gnu.org/onlinedocs/cpp/Concatenation.html#Concatenation
[mips_instr]: http://www.mrc.uidaho.edu/mrc/people/jff/digital/MIPSir.html

### How a system call get called?

The MIPS `syscall` instruction will cause a software interruption. (See
[MIPS syscall function][mips_syscall]). After this instruction, the hardware
will automatically turn off interrupts, then jump to the code located at
`0x80000080`. From `$OS161_SRC/kern/arch/mips/locore/exception-mips1.S`, we can
see that `mips_general_handler` is the code that defined at `0x80000080`.

The assembly code here do a lot of stuff that we don't need to care. All we
need to know that they will save a trapframe on current thread's kernel stack
and call `mips_trap` in `$OS161_SRC/kern/arch/mips/locore/trap.c`. Then if this
trap (or interruption) is caused by `syscall` instruction, `mips_trap` will
call `syscall` in `$OS161_SRC/kern/arch/mips/syscall/syscall.c` to handle. Then
we go to our familiar `syscall` function, we dispatch the syscall according to
the call number, then collect the results and return. If every thing is OK, we
go back to `mips_trap`, then to the assembly code `common_exception` and then
go back to user mode.

[mips_syscall]: http://courses.missouristate.edu/KenVollmar/MARS/Help/SyscallHelp.html

### How to add a system call

To add a system call, a typical flow would be:

- Add a case branch in the syscall function:
``` c
 case SYS_fork: 
     err = sys_fork(&retval, tf); 
     break;
```

- Add a new header file in `$OS161_SRC/kern/include/kern`, declare your
`sys_fork`

- Include your header file in `$OS161_SRC/kern/include/syscall.h` so that the
compiler can find the definition of `sys_fork`

- Add a new c file in `$OS161_SRC/kern/syscall`, implement your `sys_fork`
function

- Add your c file's full path to `$OS161_SRC/kern/conf/conf.kern` so that
your c file will be compiled. See `loadelf.c` and `runprogram.c` entries in that
file for examples.

- Then in `$OS161_SRC/kern/conf`, **reconfigure the kernel**:
``` bash
$ ./config ASST3
```

