#include "helper.h"
#include "monitor.h"
#include "reg.h"

extern uint32_t instr;
extern char assembly[80];

/* decode I-type instrucion with unsigned immediate */
static void decode_imm_type(uint32_t instr) {

	op_src1->type = OP_TYPE_REG;
	op_src1->reg = (instr & RS_MASK) >> (RT_SIZE + IMM_SIZE);
	op_src1->val = reg_w(op_src1->reg);
	
	op_src2->type = OP_TYPE_IMM;
	op_src2->imm = instr & IMM_MASK;
	op_src2->val = op_src2->imm;

	op_dest->type = OP_TYPE_REG;
	op_dest->reg = (instr & RT_MASK) >> (IMM_SIZE);
}

static void decode_simm_type(uint32_t instr) {

	op_src1->type = OP_TYPE_REG;
	op_src1->reg = (instr & RS_MASK) >> (RT_SIZE + IMM_SIZE);
	op_src1->val = reg_w(op_src1->reg);
	
	op_src2->type = OP_TYPE_IMM;
	op_src2->simm = (int16_t)(instr & IMM_MASK);
	op_src2->val = op_src2->simm;

	op_dest->type = OP_TYPE_REG;
	op_dest->reg = (instr & RT_MASK) >> (IMM_SIZE);
}

static void decode_imm_zero_extend(uint32_t instr) {
    op_src1->type = OP_TYPE_REG;
    op_src1->reg = (instr & RS_MASK) >> (RT_SIZE + IMM_SIZE);
    op_src1->val = reg_w(op_src1->reg);
    
    op_src2->type = OP_TYPE_IMM;
    op_src2->imm = instr & IMM_MASK;
    op_src2->val = (uint32_t)op_src2->imm; // 规范：0扩展至32位
    op_dest->type = OP_TYPE_REG;
    op_dest->reg = (instr & RT_MASK) >> IMM_SIZE;
}

make_helper(lui) {

	decode_imm_type(instr);
	reg_w(op_dest->reg) = (op_src2->val << 16);
	sprintf(assembly, "lui   %s,   0x%04x", REG_NAME(op_dest->reg), op_src2->imm);
}

make_helper(ori) {

    decode_imm_zero_extend(instr); // 使用0扩展解码
    reg_w(op_dest->reg) = op_src1->val | op_src2->val;
	sprintf(assembly, "ori   %s,   %s,   0x%04x", REG_NAME(op_dest->reg), REG_NAME(op_src1->reg), op_src2->imm);
}

make_helper(bne) {

	decode_simm_type(instr);
	if (reg_w(op_dest->reg) != op_src1->val) {
		cpu.pc += (op_src2->simm << 2);
	}
	sprintf(assembly, "bne   %s,   %s,   %d", REG_NAME(op_src1->reg), REG_NAME(op_dest->reg), op_src2->simm);
}

make_helper(lw) {

	decode_simm_type(instr);
	uint32_t vaddr = op_src1->val + op_src2 -> simm;
	Assert(vaddr % 4 == 0, "lw addr error\n");
	uint32_t paddr = vaddr & 0x7fffffff;
	reg_w(op_dest->reg) = mem_read(paddr, 4);
	sprintf(assembly, "lw    %s,   %d(%s)", REG_NAME(op_dest->reg), op_src2->simm, REG_NAME(op_src1->reg));
}

make_helper(sw) {

	decode_simm_type(instr);
	uint32_t vaddr = op_src1->val + op_src2 -> simm;
	Assert(vaddr % 4 == 0, "sw addr error\n");
	uint32_t paddr = vaddr & 0x7fffffff;
	mem_write(paddr, 4, reg_w(op_dest->reg));
	sprintf(assembly, "sw    %s,   %d(%s)", REG_NAME(op_dest->reg), op_src2->simm, REG_NAME(op_src1->reg));
}

make_helper(andi) {

    decode_imm_zero_extend(instr); 
    uint32_t res = op_src1->val & op_src2->val;
    reg_w(op_dest->reg) = res;
	sprintf(assembly, "andi  %s,   %s,   0x%04x", REG_NAME(op_dest->reg), REG_NAME(op_src1->reg), op_src2->imm);
}

make_helper(addiu) {

	decode_simm_type(instr);
	reg_w(op_dest->reg) = op_src1->val + op_src2->simm;
	sprintf(assembly, "addiu %s,   %s,   %d", REG_NAME(op_dest->reg), REG_NAME(op_src1->reg), op_src2->simm);
}

make_helper(beq) {

	decode_simm_type(instr);
	if(op_src1->val == reg_w(op_dest->reg)) {
		cpu.pc += (op_src2->simm << 2);
	}
	sprintf(assembly, "beq   %s,   %s,   %d", REG_NAME(op_src1->reg), REG_NAME(op_dest->reg), op_src2->simm);
}

make_helper(lb) {

	decode_simm_type(instr);
	uint32_t vaddr = op_src1->val + op_src2 -> simm;
	uint32_t paddr = vaddr & 0x7fffffff;
    int8_t byte_data = mem_read(paddr, 1);
    int32_t sign_extended = (int32_t)byte_data;
    reg_w(op_dest->reg) = sign_extended;
	sprintf(assembly, "lb    %s,   %d(%s)", REG_NAME(op_dest->reg), op_src2->simm, REG_NAME(op_src1->reg));
}

make_helper(sb) {

	decode_simm_type(instr);
	uint32_t vaddr = op_src1->val + op_src2 -> simm;
	uint32_t paddr = vaddr & 0x7fffffff;
    uint8_t data = reg_w(op_dest->reg) & 0xFF;
    mem_write(paddr, 1, data);
	sprintf(assembly, "sb    %s,   %d(%s)", REG_NAME(op_dest->reg), op_src2->simm, REG_NAME(op_src1->reg));
}

make_helper(blez) {

    decode_simm_type(instr);
    int32_t v = (int32_t)op_src1->val;   // 按有符号数理解寄存器
    if (v <= 0) {
        cpu.pc += (op_src2->simm << 2);
    }
    sprintf(assembly, "blez   %s,   %d", REG_NAME(op_src1->reg), op_src2->simm);
}
