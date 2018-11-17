.org 0x0
 	.global _start
_start:
	addi x1,x0,0x0FF # lets $(x1) <- 0x101. Stall four cycles. 
	addi x0,x0,0x000
	addi x0,x0,0x000
	addi x0,x0,0x000
  addi x0,x0,0x000
