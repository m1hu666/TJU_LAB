
build/my_test:     file format elf32-tradlittlemips
build/my_test


Disassembly of section .text:

80000000 <__start>:
80000000:	3c1d8001 	lui	sp,0x8001
80000004:	37bd3ff0 	ori	sp,sp,0x3ff0
80000008:	3c11bfd0 	lui	s1,0xbfd0
8000000c:	3c14bfd1 	lui	s4,0xbfd1
80000010:	3c108001 	lui	s0,0x8001
80000014:	26100000 	addiu	s0,s0,0

80000018 <print_loop_start>:
print_loop_start():
80000018:	82040000 	lb	a0,0(s0)
8000001c:	10800009 	beqz	a0,80000044 <init_data_phase>
80000020:	00000000 	nop

80000024 <wait_tx_start>:
wait_tx_start():
80000024:	822803fc 	lb	t0,1020(s1)
80000028:	31080001 	andi	t0,t0,0x1
8000002c:	1100fffd 	beqz	t0,80000024 <wait_tx_start>
80000030:	00000000 	nop
80000034:	a22403f8 	sb	a0,1016(s1)
80000038:	26100001 	addiu	s0,s0,1
8000003c:	1000fff6 	b	80000018 <print_loop_start>
80000040:	00000000 	nop

80000044 <init_data_phase>:
init_data_phase():
80000044:	3c128001 	lui	s2,0x8001
80000048:	36521000 	ori	s2,s2,0x1000
8000004c:	3c138001 	lui	s3,0x8001
80000050:	36731100 	ori	s3,s3,0x1100
80000054:	34080010 	li	t0,0x10
80000058:	34090000 	li	t1,0x0

8000005c <init_loop>:
init_loop():
8000005c:	1100000a 	beqz	t0,80000088 <calc_phase>
80000060:	00000000 	nop
80000064:	25290001 	addiu	t1,t1,1
80000068:	ae490000 	sw	t1,0(s2)
8000006c:	ae690000 	sw	t1,0(s3)
80000070:	ae890000 	sw	t1,0(s4)
80000074:	26520004 	addiu	s2,s2,4
80000078:	26730004 	addiu	s3,s3,4
8000007c:	2508ffff 	addiu	t0,t0,-1
80000080:	1000fff6 	b	8000005c <init_loop>
80000084:	00000000 	nop

80000088 <calc_phase>:
calc_phase():
80000088:	3c128001 	lui	s2,0x8001
8000008c:	36521000 	ori	s2,s2,0x1000
80000090:	3c138001 	lui	s3,0x8001
80000094:	36731100 	ori	s3,s3,0x1100
80000098:	34080010 	li	t0,0x10
8000009c:	340d0000 	li	t5,0x0

800000a0 <calc_loop>:
calc_loop():
800000a0:	1100000a 	beqz	t0,800000cc <verify_phase>
800000a4:	00000000 	nop
800000a8:	8e490000 	lw	t1,0(s2)
800000ac:	8e6a0000 	lw	t2,0(s3)
800000b0:	012a5821 	addu	t3,t1,t2
800000b4:	01ab6826 	xor	t5,t5,t3
800000b8:	26520004 	addiu	s2,s2,4
800000bc:	26730004 	addiu	s3,s3,4
800000c0:	2508ffff 	addiu	t0,t0,-1
800000c4:	1000fff6 	b	800000a0 <calc_loop>
800000c8:	00000000 	nop

800000cc <verify_phase>:
verify_phase():
800000cc:	340e0020 	li	t6,0x20
800000d0:	3c0fffff 	lui	t7,0xffff
800000d4:	35efffff 	ori	t7,t7,0xffff
800000d8:	01af7826 	xor	t7,t5,t7
800000dc:	ae8f0000 	sw	t7,0(s4)
800000e0:	15ae0005 	bne	t5,t6,800000f8 <error_loop>
800000e4:	00000000 	nop
800000e8:	3c108001 	lui	s0,0x8001
800000ec:	26100008 	addiu	s0,s0,8
800000f0:	10000003 	b	80000100 <print_loop_final>
800000f4:	00000000 	nop

800000f8 <error_loop>:
error_loop():
800000f8:	3c108001 	lui	s0,0x8001
800000fc:	26100013 	addiu	s0,s0,19

80000100 <print_loop_final>:
print_loop_final():
80000100:	82040000 	lb	a0,0(s0)
80000104:	10800009 	beqz	a0,8000012c <finish_blink>
80000108:	00000000 	nop

8000010c <wait_tx_final>:
wait_tx_final():
8000010c:	822803fc 	lb	t0,1020(s1)
80000110:	31080001 	andi	t0,t0,0x1
80000114:	1100fffd 	beqz	t0,8000010c <wait_tx_final>
80000118:	00000000 	nop
8000011c:	a22403f8 	sb	a0,1016(s1)
80000120:	26100001 	addiu	s0,s0,1
80000124:	1000fff6 	b	80000100 <print_loop_final>
80000128:	00000000 	nop

8000012c <finish_blink>:
finish_blink():
8000012c:	3c0a0010 	lui	t2,0x10

80000130 <blink_loop>:
blink_loop():
80000130:	8e890000 	lw	t1,0(s4)
80000134:	3c0bffff 	lui	t3,0xffff
80000138:	356bffff 	ori	t3,t3,0xffff
8000013c:	012b4826 	xor	t1,t1,t3
80000140:	ae890000 	sw	t1,0(s4)
80000144:	35480000 	ori	t0,t2,0x0

80000148 <delay_inner>:
delay_inner():
80000148:	2508ffff 	addiu	t0,t0,-1
8000014c:	1500fffe 	bnez	t0,80000148 <delay_inner>
80000150:	00000000 	nop
80000154:	1000fff6 	b	80000130 <blink_loop>
80000158:	00000000 	nop

Disassembly of section .data:

80010000 <msg_start>:
msg_start():
80010000:	74530a0d 	jalx	814c2834 <msg_fail+0x14b2821>
80010004:	00747261 	0x747261

80010008 <msg_pass>:
msg_pass():
80010008:	502e2e2e 	0x502e2e2e
8001000c:	21535341 	addi	s3,t2,21313
80010010:	2e000a0d 	sltiu	zero,s0,2573

80010013 <msg_fail>:
msg_fail():
80010013:	2e2e      	bnez	a2,80010071 <msg_fail+0x5e>
80010015:	462e      	addiu	s1,a2,-2
80010017:	4941      	addiu	s1,65
80010019:	214c      	beqz	s1,800100b3 <msg_fail+0xa0>
8001001b:	0a0d      	la	v0,8001004c <msg_fail+0x39>
	...

Disassembly of section .reginfo:

00000000 <.reginfo>:
   0:	201fef10 	addi	ra,zero,-4336
	...
