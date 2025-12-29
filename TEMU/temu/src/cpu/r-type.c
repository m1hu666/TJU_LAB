#include "helper.h"
#include "monitor.h"
#include "reg.h"

extern uint32_t instr;
extern char assembly[80];

/* decode R-type instrucion */
static void decode_r_type(uint32_t instr) {

	op_src1->type = OP_TYPE_REG;
	op_src1->reg = (instr & RS_MASK) >> (RT_SIZE + IMM_SIZE);
	op_src1->val = reg_w(op_src1->reg);
	
	op_src2->type = OP_TYPE_REG;
	op_src2->imm = (instr & RT_MASK) >> (RD_SIZE + SHAMT_SIZE + FUNC_SIZE);
	op_src2->val = reg_w(op_src2->reg);

	op_dest->type = OP_TYPE_REG;
	op_dest->reg = (instr & RD_MASK) >> (SHAMT_SIZE + FUNC_SIZE);
}

make_helper(and) {

	decode_r_type(instr);
	reg_w(op_dest->reg) = (op_src1->val & op_src2->val);
	sprintf(assembly, "and   %s,   %s,   %s", REG_NAME(op_dest->reg), REG_NAME(op_src1->reg), REG_NAME(op_src2->reg));
}

make_helper(addu) {

	decode_r_type(instr);
	reg_w(op_dest->reg) = op_src1->val + op_src2->val;
	sprintf(assembly, "addu   %s,   %s,   %s", REG_NAME(op_dest->reg), REG_NAME(op_src1->reg), REG_NAME(op_src2->reg));
}

make_helper(or) {

	decode_r_type(instr);
	reg_w(op_dest->reg) = (op_src1->val | op_src2->val);
	sprintf(assembly, "or    %s,   %s,   %s", REG_NAME(op_dest->reg), REG_NAME(op_src1->reg), REG_NAME(op_src2->reg));
}

make_helper(xor) {

	decode_r_type(instr);
	reg_w(op_dest->reg) = (op_src1->val ^ op_src2->val);
	sprintf(assembly, "xor   %s,   %s,   %s", REG_NAME(op_dest->reg), REG_NAME(op_src1->reg), REG_NAME(op_src2->reg));
}

make_helper(sll) {

    decode_r_type(instr);
    uint32_t sa = (instr & 0x000007C0) >> 6;
    reg_w(op_dest->reg) = op_src2->val << sa;
    sprintf(assembly, "sll   %s,   %s,   %d", REG_NAME(op_dest->reg), REG_NAME(op_src2->reg), sa);
}

make_helper(add) {

    decode_r_type(instr);
    uint32_t a = op_src1->val;
    uint32_t b = op_src2->val;
    uint32_t res = a + b;
	Assert(!(((a ^ res) & (b ^ res)) & 0x80000000), "add Overflow\n");
    reg_w(op_dest->reg) = res;
    sprintf(assembly, "add   %s,   %s,   %s", REG_NAME(op_dest->reg), REG_NAME(op_src1->reg), REG_NAME(op_src2->reg));
}

make_helper(srav) {

    decode_r_type(instr);
    uint32_t shf = op_src1->val & 0x1F; 
    int32_t s_src = (int32_t)op_src2->val; 
    // 规范：算术右移，符号位填充
    int32_t res = s_src >> shf;
    reg_w(op_dest->reg) = (uint32_t)res;
    sprintf(assembly, "srav   %s,   %s,   %s", REG_NAME(op_dest->reg), REG_NAME(op_src2->reg), REG_NAME(op_src1->reg));
}