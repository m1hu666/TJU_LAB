
build/test:     file format elf32-tradlittlemips
build/test


Disassembly of section .text:

80000000 <main>:
80000000:	3c08abcd 	lui	t0,0xabcd
80000004:	35101234 	ori	s0,t0,0x1234
80000008:	3c111234 	lui	s1,0x1234
8000000c:	3c098000 	lui	t1,0x8000
80000010:	3c0a8000 	lui	t2,0x8000
80000014:	012a9021 	addu	s2,t1,t2
80000018:	3c0b1111 	lui	t3,0x1111
8000001c:	356b1111 	ori	t3,t3,0x1111
80000020:	3c0c2222 	lui	t4,0x2222
80000024:	358c2222 	ori	t4,t4,0x2222
80000028:	156c0004 	bne	t3,t4,8000003c <bne_success>
8000002c:	00000000 	nop

80000030 <bne_failure>:
bne_failure():
80000030:	2413ffff 	li	s3,-1
80000034:	08000010 	j	80000040 <andi_test>
80000038:	00000000 	nop

8000003c <bne_success>:
bne_success():
8000003c:	24130000 	li	s3,0

80000040 <andi_test>:
andi_test():
80000040:	3c0dabcd 	lui	t5,0xabcd
80000044:	35ad1234 	ori	t5,t5,0x1234
80000048:	31b4ff00 	andi	s4,t5,0xff00
8000004c:	3c0effff 	lui	t6,0xffff
80000050:	3c0f00ff 	lui	t7,0xff
80000054:	35efff00 	ori	t7,t7,0xff00
80000058:	01cfa825 	or	s5,t6,t7
8000005c:	01cfb026 	xor	s6,t6,t7
80000060:	2417fe0c 	li	s7,-500
80000064:	3c083333 	lui	t0,0x3333
80000068:	35083333 	ori	t0,t0,0x3333
8000006c:	3c093333 	lui	t1,0x3333
80000070:	35293333 	ori	t1,t1,0x3333
80000074:	11090004 	beq	t0,t1,80000088 <beq_success>
80000078:	00000000 	nop

8000007c <beq_failure>:
beq_failure():
8000007c:	240affff 	li	t2,-1
80000080:	08000023 	j	8000008c <lb_test>
80000084:	00000000 	nop

80000088 <beq_success>:
beq_success():
80000088:	240a0000 	li	t2,0

8000008c <lb_test>:
lb_test():
8000008c:	3c0b8001 	lui	t3,0x8001
80000090:	256b0004 	addiu	t3,t3,4
80000094:	816c0000 	lb	t4,0(t3)
80000098:	816d0001 	lb	t5,1(t3)
8000009c:	3c0e1234 	lui	t6,0x1234
800000a0:	35ce5678 	ori	t6,t6,0x5678
800000a4:	3c0f8001 	lui	t7,0x8001
800000a8:	25ef0009 	addiu	t7,t7,9
800000ac:	a1ee0000 	sb	t6,0(t7)
800000b0:	24080001 	li	t0,1
800000b4:	00084940 	sll	t1,t0,0x5
800000b8:	340affff 	li	t2,0xffff
800000bc:	240b0001 	li	t3,1
800000c0:	014b6020 	add	t4,t2,t3
800000c4:	3c0d8000 	lui	t5,0x8000
800000c8:	240e0002 	li	t6,2
800000cc:	01cd7807 	srav	t7,t5,t6
800000d0:	2408fff6 	li	t0,-10
800000d4:	19000004 	blez	t0,800000e8 <blez_success>
800000d8:	00000000 	nop

800000dc <blez_failure>:
blez_failure():
800000dc:	2409ffff 	li	t1,-1
800000e0:	0800003b 	j	800000ec <lw_test>
800000e4:	00000000 	nop

800000e8 <blez_success>:
blez_success():
800000e8:	24090000 	li	t1,0

800000ec <lw_test>:
lw_test():
800000ec:	3c0a8001 	lui	t2,0x8001
800000f0:	254a0000 	addiu	t2,t2,0
800000f4:	8d4b0000 	lw	t3,0(t2)
800000f8:	3c0caaaa 	lui	t4,0xaaaa
800000fc:	358caaaa 	ori	t4,t4,0xaaaa
80000100:	3c0d8001 	lui	t5,0x8001
80000104:	25ad0005 	addiu	t5,t5,5
80000108:	adac0000 	sw	t4,0(t5)

8000010c <end_loop>:
end_loop():
8000010c:	08000043 	j	8000010c <end_loop>
80000110:	00000000 	nop
80000114:	00000000 	nop

Disassembly of section .data:

80010000 <test_word>:
test_word():
80010000:	5a5a5a5a 	0x5a5a5a5a

80010004 <test_byte>:
test_byte():
80010004:	0000007f 	0x7f

80010005 <empty_word>:
empty_word():
80010005:	0000      	addiu	s0,sp,0
	...

80010009 <empty_byte>:
empty_byte():
80010009:	0000      	addiu	s0,sp,0
	...

Disassembly of section .reginfo:

00000000 <.reginfo>:
   0:	00ffff00 	0xffff00
	...
