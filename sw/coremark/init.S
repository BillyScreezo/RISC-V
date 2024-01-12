.section .text, "ax"

.global _start
_start:
	.option push
	.option norelax
	la gp, __global_pointer$
	.option pop
	la sp, __stack_top

	la t0, __bss_start
	la t1, _end
bss_clear:
	beq t0, t1, bss_done
	sw zero, 0(t0)
	addi t0, t0, 4
	j bss_clear

bss_done:
	la t0, _vtrap
	csrw mtvec, t0
	li t1, 1
	csrw mie, t1

	call main

exit:
	j exit


.global _rdcycle
_rdcycle:
again:
	rdcycleh a1
	rdcycle a0
	rdcycleh a2
	bne a1, a2, again
	ret

_vtrap:
	li t0, 0x10000000
	csrr t1, mcause
	sw t1, 0(t0)
break:
	j break

	mret
