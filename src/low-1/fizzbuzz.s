.intel_syntax noprefix
.global main

main:
  mov rcx, 0x1
loop:
  # fizzbuzz
  # 答え->rax 余り-> rdx
  # 割られる数 rdx,rax (rdxが上位に来て128bit)
  # div <reg>
  mov rdx, 0
  mov rax, rcx
  mov r15, 15
  div r15
  # rdx is zero?i
  cmp rdx, 0
  jne fizznext

  # call write
  mov rdx, 0x8
  lea rsi, [fizzbuzz]
  mov rdi, 0x1
  mov rax, 0x1
  push rcx
  syscall
  pop rcx
  jmp next

fizznext:
  # fizz
  # 答え->rax 余り-> rdx
  # 割られる数 rdx,rax (rdxが上位に来て128bit)
  # div <reg>
  mov rdx, 0
  mov rax, rcx
  mov r15, 3
  div r15
  # rdx is zero?i
  cmp rdx, 0
  jne buzznext

  # call write
  mov rdx, 0x4
  lea rsi, [fizz]
  mov rdi, 0x1
  mov rax, 0x1
  push rcx
  syscall
  pop rcx
  jmp next

buzznext:
  # buzz
  # 答え->rax 余り-> rdx
  # 割られる数 rdx,rax (rdxが上位に来て128bit)
  # div <reg>
  mov rdx, 0
  mov rax, rcx
  mov r15, 5
  div r15
  # rdx is zero?i
  cmp rdx, 0
  jne next

  # call write
  mov rdx, 0x4
  lea rsi, [buzz]
  mov rdi, 0x1
  mov rax, 0x1
  push rcx
  syscall
  pop rcx
  jmp next

next:
  inc rcx
  # print "\n"
  mov rdx, 0x1
  lea rsi, [newline]
  mov rdi, 0x1
  mov rax, 0x1
  push rcx
  syscall
  pop rcx

  cmp rcx,0x10
  jz exit
  jmp loop
exit:
  mov rax, 0x3c
  syscall

fizzbuzz:
  .ascii "fizzbuzz"
fizz:
  .ascii "fizz"
buzz:
  .ascii "buzz"
newline:
  .ascii "\n"
