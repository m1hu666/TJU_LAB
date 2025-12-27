#include "monitor.h"
#include "expr.h"
#include "watchpoint.h"
#include "temu.h"

#include <stdlib.h>
#include <readline/readline.h>
#include <readline/history.h>

void cpu_exec(uint32_t);

void display_reg();

/* We use the `readline' library to provide more flexibility to read from stdin. */
char* rl_gets() {
	static char *line_read = NULL;

	if (line_read) {
		free(line_read);
		line_read = NULL;
	}

	line_read = readline("(temu) ");

	if (line_read && *line_read) {
		add_history(line_read);
	}

	return line_read;
}

static int cmd_c(char *args) {
	cpu_exec(-1);
	return 0;
}

static int cmd_q(char *args) {
	return -1;
}

static int cmd_si(char *args){
	int time = 0;
	if(args!= NULL) {
		sscanf(args, "%d", &time);
	}
	else cpu_exec(1);
	cpu_exec(time);
	return 0;
}

void print_wp();
static int cmd_info(char *args){
	if(*args == 'r'){
		display_reg();
	}

	if(*args == 'w'){
		print_wp();
	}
	return 0;
}

static int cmd_x(char *args){
	char* arg1 = strtok(NULL, " ");
	char* arg2 = strtok(NULL, " ");
	uint32_t address; int range =0;
	sscanf(arg1,"%d", &range); 	
	sscanf(arg2,"%x",&address);
	int i=0; int data;
	// uint8_t buf[4];
	for (i=0;i<range;i++){
		printf("0x%08x: ",address+i*4);
		data=mem_read(address+i*4, 4);
		int j=0; 
		for(j=0;j<4;j++){
			printf("0x%02x ", data&0xff);
			//  buf[3-j]=data&0xff;
			data=data>>8; 
		}
		// for(j=0;j<4;j++){
		// 	printf("0x%02x ", buf[j]);
		// }
		printf("\n");
	}
	return 0;
}

static int cmd_p(char *args){
	bool success = false;
	int res=expr(args, &success);
	printf("0x%08x(%d)\n", res,res);
	return 0;
}

WP* new_wp();
static int cmd_w(char *args){
	    WP *wp = new_wp();
		bool success = false;
	    strcpy(wp->expr, args);
		wp->val=expr(wp->expr, &success);
		printf("Set watchpoint \n");
		return 0;
}

void delete_wp(int n);
static int cmd_d(char *args){
   int NO;
   sscanf(args, "%d", &NO);
   delete_wp(NO);
   return 0;
}

static int cmd_help(char *args);

static struct {
	char *name;
	char *description;
	int (*handler) (char *);
} cmd_table [] = {
	{ "help", "Display informations about all supported commands", cmd_help },
	{ "c", "Continue the execution of the program", cmd_c },
	{ "q", "Exit TEMU", cmd_q },

	/* TODO: Add more commands */
	{ "si", "Execute specified times you want", cmd_si },
	{ "info", "Print registers's value", cmd_info },
	{ "x", "Scan memory", cmd_x },
	{ "p", "Expression evaluation",cmd_p},
	{ "w","Watchpoint setting",cmd_w},
	{ "d","Delete watchpoint",cmd_d}
};

#define NR_CMD (sizeof(cmd_table) / sizeof(cmd_table[0]))

static int cmd_help(char *args) {
	/* extract the first argument */
	char *arg = strtok(NULL, " ");
	int i;

	if(arg == NULL) {
		/* no argument given */
		for(i = 0; i < NR_CMD; i ++) {
			printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
		}
	}
	else {
		for(i = 0; i < NR_CMD; i ++) {
			if(strcmp(arg, cmd_table[i].name) == 0) {
				printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
				return 0;
			}
		}
		printf("Unknown command '%s'\n", arg);
	}
	return 0;
}

void ui_mainloop() {
	while(1) {
		char *str = rl_gets();
		char *str_end = str + strlen(str);

		/* extract the first token as the command */
		char *cmd = strtok(str, " ");
		if(cmd == NULL) { continue; }

		/* treat the remaining string as the arguments,
		 * which may need further parsing
		 */
		char *args = cmd + strlen(cmd) + 1;
		if(args >= str_end) {
			args = NULL;
		}

		int i;
		for(i = 0; i < NR_CMD; i ++) {
			if(strcmp(cmd, cmd_table[i].name) == 0) {
				if(cmd_table[i].handler(args) < 0) { return; }
				break;
			}
		}

		if(i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
	}
}
