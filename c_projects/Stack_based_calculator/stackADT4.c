#include <stdio.h>
#include <stdlib.h>
#ifdef IMP
#include "reference_stackADT.h"
#else
#include "stackADT.h"
#endif
#include "memtrace.h"

struct node{
    void* data;
    struct node *next;
};

struct stack_type {
    struct node *top;
};

static void terminate (const char *message){
    printf("%s\n", message);
    exit(EXIT_FAILURE);
};

Stack Stack_create(void){
    Stack s= malloc(sizeof(struct stack_type));
    if (s==NULL){
        terminate("Error in create; stack could not be created.");
    }
    s->top=NULL;
    return s;
}

void Stack_destroy(Stack s){
    Stack_make_empty(s);
    free(s);
}

void Stack_make_empty(Stack s){
    while (!Stack_is_empty(s)){
        void *p=Stack_pop(s);
        free(p);
    }
}

bool Stack_is_empty(Stack s){
    return s->top==NULL;
}

bool Stack_is_full(Stack s){
    return false;
}

void Stack_push(Stack s, void *i){
    struct node *new_node= malloc(sizeof(struct node));
    if (new_node==NULL){
        terminate("Error in push: stack is full.");
    }
    new_node->data= i;
    new_node->next=s->top;
    s->top=new_node;
}

void * Stack_pop(Stack s){
    struct node *old_top;
    void *i;
    
    if (Stack_is_empty(s)){
        terminate("Error in pop: stack is empty.");
    }

    old_top= s->top;
    i=old_top->data;
    s->top = old_top->next;
    free(old_top);
    return i;
}
