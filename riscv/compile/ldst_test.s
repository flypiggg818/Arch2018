.org 0x0
 	.global _start
_start:
	addi	x1,x0,0x08F # lets $(x1) <- 0xF0F. Stall four cycles. 
	addi	x0,x0,0x000
	addi	x0,x0,0x000
	addi	x0,x0,0x000
  addi	x0,x0,0x000
	sw		x1,0(x0)		# save $(x1) into 0 address in ram 
  addi	x0,x0,0x000
  addi	x0,x0,0x000
	addi	x0,x0,0x000
	addi	x0,x0,0x000
	addi	x0,x0,0x000
	lw		x2,0(x0)		# fetch the stored $(x1) from ram into x2
	lw		x2,0(x0)		
	lw		x2,0(x0)	
	lw		x2,0(x0)
	lw		x2,0(x0)
	lw		x2,0(x0)
	lw		x2,0(x0)
	lw		x2,0(x0)
	lw		x2,0(x0)		
