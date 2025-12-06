# ARM Assembly Calculator

A command-line calculator built in ARM64 assembly for macOS that performs basic arithmetic operations (+, -, *, /) on single-digit numbers (0-9).

```bash
./calculator 5 + 3    # Prints: 8
./calculator 9 - 4    # Prints: 5
./calculator 2 '*' 3  # Prints: 6
./calculator 8 / 2    # Prints: 4
```

**Note:** Use quotes around `*` because it's a shell wildcard!

---

## Quick Start

### Build
```bash
# Assemble
as -o calculator.o calculator.s

# Link
ld -o calculator calculator.o -lSystem \
   -syslibroot `xcrun -sdk macosx --show-sdk-path` \
   -e _start -arch arm64
```

### Run
```bash
./calculator 1 + 2
```

---

## How It Works (High Level)

1. **Read arguments** from command line (e.g., "5", "+", "3")
2. **Convert from ASCII** strings to numbers (e.g., '5' → 5)
3. **Perform calculation** based on operator
4. **Convert back to ASCII** (e.g., 8 → '8')
5. **Print result** to terminal

All done in pure ARM64 assembly - no libraries except system calls!

---

## Core Concepts

### Registers We Use

Think of registers as super-fast temporary storage built into the CPU:

**For Arguments:**
- **x0**: How many arguments (argc)
- **x1**: Pointer to array of argument strings (argv)

**For Working Data:**
- **x9-x11**: Pointers to our argument strings
- **w12**: First number (after converting from ASCII)
- **w13**: Operator character
- **w14**: Second number
- **w15**: Result

**For System Calls:**
- **x16**: Which system call to make (macOS convention)

**Why x vs w?**
- **x** = 64-bit register (for addresses/pointers)
- **w** = 32-bit register (for smaller values like our 0-9 numbers)

---

### ASCII Conversion

When you type `./calculator 5 + 3`, the shell stores "5" and "3" as **text characters**, not numbers!

**ASCII Table (relevant part):**
```
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
```

**String to Number:** Subtract 48
```assembly
sub w12, w12, #48   # '5' (53) → 5
```

**Number to String:** Add 48
```assembly
add w15, w15, #48   # 8 → '8' (56)
```

**Why convert?**
If we did math on ASCII values:
- '4' (52) + '5' (53) = 105 = ASCII 'i' ❌
  
Instead:
- 4 + 5 = 9 → convert to '9' (57) ✓

---

## Step-by-Step Code Walkthrough

### 1. Get Command-Line Arguments

On macOS with `-lSystem`, arguments arrive in registers:
- x0 = argc (4 in our case: program name + 3 args)
- x1 = pointer to argv array

```assembly
cmp x0, #4       # Check argc == 4
bne error        # If not, exit with error
```

### 2. Load Argument Pointers

The argv array contains **pointers** to strings, not the strings themselves:

```
x1 → [ptr to "calculator", ptr to "5", ptr to "+", ptr to "3"]
      ^                     ^            ^           ^
      argv[0]              argv[1]      argv[2]    argv[3]
```

Each pointer is 8 bytes, so we skip 8 to get argv[1]:

```assembly
ldr x9, [x1, #8]    # x9 = pointer to "5"
ldr x10, [x1, #16]  # x10 = pointer to "+"
ldr x11, [x1, #24]  # x11 = pointer to "3"
```

### 3. Dereference Pointers (Get Actual Characters)

Now follow those pointers to get the characters:

```assembly
ldrb w12, [x9]     # w12 = '5' (ASCII 53)
ldrb w13, [x10]    # w13 = '+'
ldrb w14, [x11]    # w14 = '3' (ASCII 51)
```

`ldrb` = Load Register Byte (just 1 byte, not all 8)

### 4. Convert ASCII to Numbers

```assembly
sub w12, w12, #48  # w12 = 5
sub w14, w14, #48  # w14 = 3
```

### 5. Check Operator and Branch

Compare the operator and jump to appropriate code:

```assembly
cmp w13, #43       # Is it '+' (ASCII 43)?
beq add_op         # Yes, go to add
cmp w13, #45       # Is it '-' (ASCII 45)?
beq sub_op         # Yes, go to subtract
# ... etc
```

**How `cmp` works:**
- Internally does subtraction: w13 - 43
- Sets CPU flags (Z=zero, N=negative, etc.)
- `beq` checks if Z flag is set (result was zero = equal)

### 6. Perform Calculation

```assembly
add_op:
    add w15, w12, w14   # w15 = 5 + 3 = 8
    b print_positive

sub_op:
    sub w15, w12, w14   # w15 = w12 - w14
    cmp w15, #0
    bmi print_negative  # If negative, handle differently
    b print_positive
```

### 7. Handle Negative Numbers

**The Problem:**
```
1 - 5 = -4
-4 + 48 = 44 (ASCII ',') ❌
```

**The Solution:**
```assembly
print_negative:
    neg w15, w15           # Flip sign: -4 → 4
    add w15, w15, #48      # Convert to ASCII: '4'
    
    # Store "-4\n" in output buffer
    mov w16, #45           # '-' character
    strb w16, [x1]         # Store '-'
    strb w15, [x1, #1]     # Store '4'
    mov w16, #10           # '\n' newline
    strb w16, [x1, #2]     # Store newline
```

`neg` does: 0 - w15 (flips the sign using two's complement)

### 8. Print Result

Use macOS write syscall:

```assembly
mov x0, #1      # File descriptor: 1 = stdout
mov x2, #2      # Bytes to write (or 3 for negatives)
mov x16, #4     # Syscall number: 4 = write
svc #0x80       # Invoke syscall
```

### 9. Exit

```assembly
mov x0, #0      # Exit code: 0 = success
mov x16, #1     # Syscall number: 1 = exit
svc #0x80       # Invoke syscall
```

---

## Deep Dive: Technical Details

### Memory Sections

Your program is divided into sections in RAM:

```
┌─────────────────┐
│ .text (code)    │ ← Your instructions execute here
├─────────────────┤
│ .data (globals) │ ← output: "0\n" lives here
├─────────────────┤
│ .bss (uninit)   │ ← Uninitialized variables
├─────────────────┤
│ Heap            │ ← Dynamic allocation (not used here)
│   ↓ grows       │
├─────────────────┤
│   ↑ grows       │
│ Stack           │ ← Function calls, local variables
└─────────────────┘
```

### Accessing .data Variables (macOS)

To get the address of the `output` buffer, we need **two instructions** because:
- ARM instructions are 32-bit
- Addresses are 64-bit
- Can't fit a full address in one instruction!

```assembly
adrp x1, output@PAGE        # Get 4KB page address
add x1, x1, output@PAGEOFF  # Add offset within page
strb w15, [x1]              # Now can store at output
```

**Why pages?**
- The OS divides ALL memory into 4KB chunks (pages)
- For memory management, virtual memory, and protection
- `@PAGE` = which 4KB page contains the variable
- `@PAGEOFF` = byte offset within that page
- Like finding: "Page 10, line 40" in a book

This `@PAGE/@PAGEOFF` syntax is macOS/Mach-O specific.

---

## Program Structure Directives

These lines tell the assembler/linker how to organize your code:

### `.global _start`
Makes `_start` visible to the linker so it knows where the program begins.

**What's a linker?**
When building, two tools work together:
1. **Assembler (`as`)**: Converts `.s` → `.o` (machine code)
2. **Linker (`ld`)**: Combines `.o` files + libraries → final executable

Think: Assembler makes LEGO pieces, linker connects them together.

### `.data`
Everything after this goes in the DATA section (initialized variables).

```assembly
.data
output: .ascii "0\n"    # Creates a 2-byte buffer
```

### `.text`
Everything after this goes in the TEXT section (executable code).

### `.align 2`
Ensures instructions align to 4-byte boundaries (2² = 4).
- ARM instructions are 4 bytes each
- Must start at addresses divisible by 4
- Good defensive practice to prevent alignment errors

---

## System Calls (macOS)

### Write (Print to Terminal)
```assembly
mov x0, #1      # stdout (file descriptor 1)
mov x1, buffer  # Pointer to data
mov x2, #2      # Number of bytes
mov x16, #4     # write syscall
svc #0x80       # Invoke
```

### Exit
```assembly
mov x0, #0      # Exit code
mov x16, #1     # exit syscall
svc #0x80       # Invoke
```

**macOS Convention:** Syscall number in x16 (Linux uses x8)

---

## Complete Memory Flow Example

Let's trace `./calculator 5 + 3`:

### At Program Start
```
x0 = 4 (argc)
x1 = address of argv array

Memory at [x1]:
  [x1]      → "calculator"
  [x1, #8]  → "5"
  [x1, #16] → "+"
  [x1, #24] → "3"
```

### After Loading Pointers
```
x9  = address where "5" is stored
x10 = address where "+" is stored
x11 = address where "3" is stored
```

### After Dereferencing
```
w12 = '5' (ASCII 53)
w13 = '+' (ASCII 43)
w14 = '3' (ASCII 51)
```

### After ASCII Conversion
```
w12 = 5
w14 = 3
```

### After Calculation
```
w15 = 8
```

### After Converting Back
```
w15 = '8' (ASCII 56)
```

### In Output Buffer
```
output: "8\n"
```

### Write to Terminal
```
Prints: 8
```

---

## Limitations

- Only handles single-digit inputs (0-9)
- Division rounds down (integer division)
- Limited error handling
- No floating point support

---

