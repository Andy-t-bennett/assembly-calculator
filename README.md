# assembly-calculator
Assembly program written for ARM on Macos that is a basic calculator

ARM64 means 64 bit architecture (8 bytes)
meaning memory addresses are always 64 bits

will be command line arguments
./calculator 5 + 3

os will read this and handle allocating space for this in stack
it will also place argument count in x0 (argc) and sp will point to argc 

Lower memory addresses (top of stack)
    ↓
    +------------------+  ← sp points here initially
    | argc             |  (8 bytes) - number of arguments
    +------------------+  
    | argv[0] pointer  |  (8 bytes) - pointer to program name string
    +------------------+
    | argv[1] pointer  |  (8 bytes) - pointer to first argument string
    +------------------+
    | argv[2] pointer  |  (8 bytes) - pointer to second argument
    +------------------+
    | argv[3] pointer  |  (8 bytes) - pointer to third argument
    +------------------+
    | NULL (0)         |  (8 bytes) - marks end of argv
    +------------------+
    | environment vars |  (we won't worry about these)
    ↓
Higher memory addresses

typically load argc sp into x0


ldr x0, [sp]
load register (load from data into register)
[] or dereference: go to address and get value
ldr x0, [sp]: essentially go to stack pointer address, get value and load into register x0
different from
mov x9, sp: move ADDRESS of sp into x9

