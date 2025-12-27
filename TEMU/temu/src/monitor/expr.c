#include "temu.h"

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <sys/types.h>
#include <regex.h>

enum {
	/* TODO: Add more token types */
	NOTYPE = 256, 
	EQ = 255,
	NUM = 254,
	HEX = 253,
	REG = 252,
	NOTEQ = 251,
	NEG = 250,
	JIE = 249
};

static struct rule {
	char *regex;
	int token_type;
} rules[] = {

	/* TODO: Add more rules.
	 * Pay attention to the precedence level of different rules.
	 */
	{" +",	NOTYPE},				// spaces
	{"\\+", '+'},					// plus
	{"-",'-'},						// minus/neg	
	{"\\*",'*'},					//multiply/jie
	{"/",'/'},					//divide
	{"\\(",'('},					//(
	{"\\)",')'},					//)
	{"0x[0-9a-fA-F]+",HEX},		//h number
	{"0X[0-9a-fA-F]+",HEX},		//h number
	{"[0-9]+",NUM},					//d number
	{"\\$[a-z]+",REG},				//register
	{"==", EQ},						// equal
	{"!=",NOTEQ},					// not equal
	{"\\|\\|",'|'},						// or
	{"&&",'&'},						// and	
	{"!",'!'},						// not	
};

#define NR_REGEX (sizeof(rules) / sizeof(rules[0]) )

static regex_t re[NR_REGEX];

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
	int i;
	char error_msg[128];
	int ret;

	for(i = 0; i < NR_REGEX; i ++) {
		ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
		if(ret != 0) {
			regerror(ret, &re[i], error_msg, 128);
			Assert(ret == 0, "regex compilation failed: %s\n%s", error_msg, rules[i].regex);
		}
	}
}

typedef struct token {
	int type;
	char str[32];
} Token;

Token tokens[32];
int nr_token;

static bool make_token(char *e) {
	int position = 0;
	int i;
	regmatch_t pmatch;
	
	nr_token = 0;

	while(e[position] != '\0') {
		/* Try all rules one by one. */
		for(i = 0; i < NR_REGEX; i ++) {
			if(regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
				char *substr_start = e + position;
				int substr_len = pmatch.rm_eo;

				Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s", i, rules[i].regex, position, substr_len, substr_len, substr_start);
				position += substr_len;

				/* TODO: Now a new token is recognized with rules[i]. Add codes
				 * to record the token in the array `tokens'. For certain types
				 * of tokens, some extra actions should be performed.
				 */

				switch(rules[i].token_type) {
					case NOTYPE: 
					break;

					case '+':
					tokens[nr_token].type = rules[i].token_type;
					nr_token ++;
					break;

					case '-':
					if((tokens[nr_token-1].type == ')'||tokens[nr_token-1].type == NUM || tokens[nr_token-1].type == HEX || tokens[nr_token-1].type == REG)	||(tokens[i].type == '-' && i == 0)){
						tokens[nr_token].type = '-';
						nr_token ++;
						break;
					}
					else{			
						tokens[nr_token].type = NEG;
						nr_token ++;
						break;
					}

					case '*':
					if((tokens[nr_token-1].type == ')'||tokens[nr_token-1].type == NUM || tokens[nr_token-1].type == HEX || tokens[nr_token-1].type == REG)	||(tokens[i].type == '-' && i == 0)){
						tokens[nr_token].type = '*';
						nr_token ++;
						break;
					}
					else{			
						tokens[nr_token].type = JIE;
						nr_token ++;
						break;
					}

					case '/':
					case '(':
					case ')':
					case EQ:
					case NOTEQ:
					case '&':
					case '|':
					case '!':					
					tokens[nr_token].type = rules[i].token_type;
					nr_token ++;
					break;

					case NUM:
					case HEX:
					case REG:
					tokens[nr_token].type = rules[i].token_type;
					strncpy(tokens[nr_token].str, substr_start , substr_len);
					tokens[nr_token].str[substr_len] = '\0';
					nr_token ++;
					break;

					default: panic("please implement me");
				}

				break;
			}
		}

		if(i == NR_REGEX) {
			printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
			return false;
		}
	}

	return true; 
}

bool check_parenteses(int p,int q) {
		int cnt = 0;
		if(tokens[p].type != '('|| tokens[q].type != ')') {
			     return false;
		}
		else{
			int i;
			for(i = p+1; i <= q-1; i++) {
				if(tokens[i].type == '(') 	cnt++;
				else if(tokens[i].type == ')')  cnt--;
				if(cnt < 0) {
					return false;
				}
				}
			if(cnt == 0) return true;
			else return false;
		}
}

static int check_par(int p,int q){
	 int cnt = 0;
	 int i;
	 int num1=0,num2=0;
	 for(i = p; i <= q; i++){
		 if(tokens[i].type == '(') {cnt++;num1++;}
		 else if(tokens[i].type == ')') {cnt--;num2++;}
		 if(cnt < 0) assert(0);
		 else if(cnt >= 2) return 1;
		 	 }
	if(num1==1&&num2==1&&(tokens[p].type == '(')) return 1;
	return 0;
} 

static int get_dp(int p,int q){
 			int i=0;
			int flag = -1;
			int ret=0;
			bool check = false;
			for(i = p;i <= q;i++){	

				if(i == p||check){
				if(tokens[i].type == '('){
					while(tokens[i].type != ')'){
						if(tokens[i].type == '('&& i != p){
							flag=-1;
							check = true;
						}
						i++;
					}
				}
				}
				if(tokens[i].type =='('){
					while(tokens[i].type != ')'){
						i++;
					}
				}
			if(tokens[i].type == '|'){
				if(flag<=5){
					ret = i;
					flag=5;
				}
			}
			if(tokens[i].type == '&'){
				if(flag<=4){
					ret = i;
					flag=4;
				}
			}
			if(tokens[i].type == EQ||tokens[i].type == NOTEQ){
				if(flag<=3){
					ret = i;
					flag=3;
				}
			}
			if(tokens[i].type == '+'||tokens[i].type == '-'){
				if(flag<=2){
					ret = i;
					flag=2;
				}
			}
			if(tokens[i].type == '*'||tokens[i].type == '/'){
				if(flag<=1){
					ret = i;
					flag=1;
				}
			}
			if(tokens[i].type == '!'||tokens[i].type == NEG||tokens[i].type == JIE){
				if(flag<=0){
					ret = i;
					flag=0;
				}
				if(check_par(p,q) && i == p){
					ret = i;
					break;
				}
			}
			}
			return ret;	
}


static int get_reg(const char *reg) {
	if (!strcmp(reg, "$zero")) return cpu.zero;
	if (!strcmp(reg, "$at")) return cpu.at;
	if (!strcmp(reg, "$v0")) return cpu.v0;
	if (!strcmp(reg, "$v1")) return cpu.v1;
	if (!strcmp(reg, "$a0")) return cpu.a0;
	if (!strcmp(reg, "$a1")) return cpu.a1;
	if (!strcmp(reg, "$a2")) return cpu.a2;
	if (!strcmp(reg, "$a3")) return cpu.a3;
	if (!strcmp(reg, "$t0")) return cpu.t0;
	if (!strcmp(reg, "$t1")) return cpu.t1;
	if (!strcmp(reg, "$t2")) return cpu.t2;
	if (!strcmp(reg, "$t3")) return cpu.t3;
	if (!strcmp(reg, "$t4")) return cpu.t4;
	if (!strcmp(reg, "$t5")) return cpu.t5;
	if (!strcmp(reg, "$t6")) return cpu.t6;
	if (!strcmp(reg, "$t7")) return cpu.t7;
	if (!strcmp(reg, "$s0")) return cpu.s0;
	if (!strcmp(reg, "$s1")) return cpu.s1;
	if (!strcmp(reg, "$s2")) return cpu.s2;
	if (!strcmp(reg, "$s3")) return cpu.s3;
	if (!strcmp(reg, "$s4")) return cpu.s4;
	if (!strcmp(reg, "$s5")) return cpu.s5;
	if (!strcmp(reg, "$s6")) return cpu.s6;
	if (!strcmp(reg, "$s7")) return cpu.s7;
	if (!strcmp(reg, "$t8")) return cpu.t8;
	if (!strcmp(reg, "$t9")) return cpu.t9;
	if (!strcmp(reg, "$k1")) return cpu.k1;
	if (!strcmp(reg, "$k2")) return cpu.k2;
	if (!strcmp(reg, "$gp")) return cpu.gp;
	if (!strcmp(reg, "$sp")) return cpu.sp;
	if (!strcmp(reg, "$fp")) return cpu.fp;
	if (!strcmp(reg, "$ra")) return cpu.ra;
	if (!strcmp(reg, "$pc")) return cpu.pc;
	if (!strcmp(reg, "$hi")) return cpu.hi;
	if (!strcmp(reg, "$lo")) return cpu.lo;
    else return 0;
}

uint32_t eval(int p, int q) {
	  	bool check = true;
		if(p > q)	{
		assert(0);
		}
		if(p == q) {
			int res = 0;
			if(tokens[p].type == NUM){
				sscanf(tokens[p].str, "%d", &res);
			}
			if(tokens[p].type == HEX){
				sscanf(tokens[p].str, "%x", &res);
			}
			if(tokens[p].type == REG){
				res = get_reg(tokens[p].str);
			}
				return res;
			}
			if(p+1 == q){
				if(tokens[p].type == NEG){
					return -eval(p+1,q);
				}
				if(tokens[p].type == JIE){
					return mem_read(eval(p+1,q),4);
				}				
				if(tokens[p].type == '!'){
					return !eval(p+1,q);
				}
			}
		else if(check_parenteses(p,q) == true){
			return eval(p+1,q-1);
		}
		else {
				int op = get_dp(p,q);
				if(op == 0&&(tokens[p].type == NEG||tokens[p].type == '!'||tokens[p].type == JIE)) check = false;
				if(op == p) check = false;
				uint32_t val2 = eval(op+1,q);
				uint32_t val1 = 0;
				if(check){
					val1 = eval(p,op-1);	
				}
				switch(tokens[op].type){
					case '+': return val1 + val2;
					case '-': return val1 - val2;
					case '*': return val1 * val2;
					case '/': 
					if(val2 == 0) { 
						printf("It is wrong to divide by zero\n");
						return 0;
						}
					else return val1 / val2;
					case '!': return (!val2);
					case '&': return (val1 && val2);
					case '|': return (val1 || val2);
					case EQ: return (val1 == val2)? 1 : 0;
					case NOTEQ: return (val1 != val2)? 1 : 0;
					case NEG: return -val2;
					case JIE: return mem_read(val2,4);
				 }
		}
		return 0;
}

uint32_t expr(char *e, bool *success) {
	if(!make_token(e)) {
		*success = false;
		return 0;
	}

	/* TODO: Insert codes to evaluate the expression. */
	return eval(0, nr_token-1);
	panic("please implement me");
	return 0;
}

