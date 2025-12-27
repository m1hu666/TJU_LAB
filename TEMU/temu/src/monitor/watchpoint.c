#include "watchpoint.h"
#include "expr.h"
#include "cpu/helper.h"
#define NR_WP 32

static WP wp_pool[NR_WP];
static WP *head, *free_;

void init_wp_pool() {
	int i;
	for(i = 0; i < NR_WP; i ++) {
		wp_pool[i].NO = i;
		wp_pool[i].next = &wp_pool[i + 1];
	}
	wp_pool[NR_WP - 1].next = NULL;

	head = NULL;
	free_ = wp_pool;
}

/* TODO: Implement the functionality of watchpoint */
WP *new_wp() {
 if(free_ == NULL)
  {
    printf("NO watchpoint can be uesd\n");
    assert(0);
  } 
  WP* tmp = free_;
  free_ = free_->next;
  tmp->next = head;
  head = tmp;
  return tmp;
}

void free_wp(WP *wp) {
	if(wp == NULL) assert(0);
	else if(wp == head){
		head = wp->next;
	}
	else{
		WP *ptr = head;
		while (ptr->next != wp&&ptr->next != NULL){
			ptr = ptr->next;
		}
		ptr->next = wp->next;
		wp->next = free_;
		free_ = wp;
	}	
	}

bool check_wp() {
	bool success = false;
	bool check = false;
	WP *temp = head;
	int v;
	while(temp != NULL){
		v = expr(temp->expr, &success);
		if (v != temp->val){
			check = true;
			printf ("Hint watchpoint %d at address 0x%08x\n", temp->NO, cpu.pc);
			printf ("Old value = %d\n",temp->val);
			printf ("New value = %d\n",v);
			temp->val = v;
			temp = temp->next;
			continue;
		}
		temp = temp->next;
	}
	return check;
}

void delete_wp(int n) {
	WP *temp = head;
	if(temp == NULL) assert(0);
	else{
		while(temp->NO != n){
			temp = temp->next;
					}
	 free_wp(temp);
		}
}


void print_wp() {
	WP *temp = head;
	if(temp == NULL) printf("No watchpoint\n");
	else{
		printf("\tNO\tAddress\t\t\tENABLE\n");
		while(temp!= NULL){
		printf("\t%d\t%s\t%d\n", temp->NO, temp->expr, temp->val);
		temp = temp->next;
	}
	}
}
	





