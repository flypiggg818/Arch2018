指令 li $t1,40 是一条伪指令，在汇编器中会转换成 addi $t1,$zero,40. 

Passed test: 
1. _out_abc.c: lui, jal, sb, addi, 
2. _funct.c: lw, andi, beqz, srli, bne, jalr, sw, 

I think that is my way of reading input is incorrect. 