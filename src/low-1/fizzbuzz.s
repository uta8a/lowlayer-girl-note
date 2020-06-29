.intel_syntax noprefix
.global main

main:
  mov rdx, 0x8
  lea rsi, [fizzbuzz]
  mov rdi, 0x1
  mov rax, 0x1
  syscall
  mov rax, 0x3c
  syscall

fizzbuzz:
  .ascii "fizzbuzz"
fizz:
  .ascii "fizz"
buzz:
  .ascii "buzz"
