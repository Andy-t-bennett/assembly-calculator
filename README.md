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
ldr x0, [sp]: go to stack pointer address, get value and load into x0
different from
mov x9, sp: copy sp's value (which is an address) into x9

sp contains an address (it IS a pointer)
[sp] is the value stored at that address, which could be another pointer

EXAMPLE
sp = 0x7ff8b2c01000  (sp always contains an address)

Memory at 0x7ff8b2c01000: [4]  ← This is argc

mov x9, sp       // x9 = 0x7ff8b2c01000 (copy the address)
                 // Just register copy, no memory access

ldr x9, [sp]     // Go to address 0x7ff8b2c01000
                 // Read what's there: 4
                 // x9 = 4
                 // This reads from memory!



LDRB
load register 1 byte, used with w registers (32 bits/4 bytes) 


Because arguemnts from the terminal are stored as strings, the numbers are stored and represented as ascii values
'0' = 48
'1' = 49
'2' = 50
'3' = 51
'4' = 52
'5' = 53
'6' = 54
'7' = 55
'8' = 56
'9' = 57

in order to capture the value, it needs to be offset so to get 0 we subtract 48 (the common denominator)

general operators though we keep ascii value
'+' = 43
'-' = 45
'*' = 42
'/' = 47

comparing
cmp does a subtraction but doesnt store the value, 
cpu has flag rgisters (conditional flags) with 4 important bits stored in PSTATE
N = Negative flag
Z = Zero flag
C = Carry flag
V = Overflow flag

branching
beq reads z flag from PSTATE and expects 1
bne reads z flag from PSTATE and expets 0
assembly code is read top to bottom, branching allows the ability to move to other sections of code (branch to a label)

operators
add destination, value1, value2

Running the code
as -o calculator.o calculator.s
ld -o calculator calculator.o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -e _start -arch arm64
./calculator value1 operator value 2




.global _start
- makes _start visible to the linker
- without this _start would only be private to this function, linker needs to find _Start to know where program begins (like public)

.data
- tells assembler that everything after this goes into the DATA section of the program
- this is used for initialised data - variables with starting values
- in this instance variable "output" has an ascii value of "0\n"
- we use 0 because we will overwrite it with an actual value later
- these values live for the lifetime of the program, memory is allocated by os and deallocated when program is done (allocated in RAM)

.text
- directive that says everything after this foes int he Text section
- Executable code

.align 2
- ensures each instruction is aligned to a 4 byte boundary (2^2 = 4)
- Arm instructions are 4 bytes each, they must stat at an address divisble by 4

arguments
- x0 stores the argc (total count of arguments)
- x1 stores the address of the location of the argv's

Updating value of output variable
- Idea is find the page (4kb of allocated chunked storage) that output is on
- Then find the offset of where output actually resides on that page
- Add the 2 together to get a full 64 bit address
- This is a macos convetion, but must be done in 2 parts because arm assembly only allos 32 bit instructions, and an address is always 64 bits
adrp x1, output@PAGE
add x1, x1, output@PAGEOFF
strb w15, [x1]
