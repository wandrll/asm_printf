# Printf written on assembler
It is an educational project for the second term of MIPT 
## Requirments:
1. My printf uses SystemV call convention, so x86-64 unix-system only
1. Nasm (The Netwide Assembler)
1. googletest if you want run my examples
## How to compile your programm with my printf
1. Declare my printf function in your programm
```c++
    extern "C" long long myprintf(FILE* file, const char* line, ...); // return count of printed symbols
```
2. Compile printf.nas and descriptor.cpp
```sh
    nasm -f elf64 printf.nas
    g++ -c descriptor.cpp
```
3. Link descriptor.o and printf.o with your programm

## Supported formats
1. %d - 32-bit decimal signed integer numbers
2. %c - char
3. %s - string
4. %b - 32-bit binary number
5. %o - 32-bit octal number
6. %x - 32-bit hexadecimal number
