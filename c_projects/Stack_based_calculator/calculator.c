#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <assert.h>
#include <errno.h>
#include <stdio.h>
#ifdef IMP
#include "reference_stackADT.h"
#else
#include "stackADT.h"
#endif

#include "memtrace.h"

// maximum size of a single command 
#define MAX_INPUT_SIZE 4096
// maximum size of a operation
#define MAX_OP_SIZE 64


void print_command_help();
int process(char *input, Stack dataStack, Stack opStack);
bool is_int(char *);
int runOperation(char *op, Stack dataStack);
int runCloseParen(Stack dataStack, Stack opStack);
bool higherPriority(char *op1, char *op2);

static int num1=0;
void error_msg_extraData(char *cmd) {
  printf("ERROR: %s: found data left over!\n", cmd);
}

void error_msg_badCommand(char *cmd) {
  printf("ERROR: bad command!\n");
}

void error_msg_opStackNotEmpty(char *cmd) {
  printf("ERROR: %s: not able to process all operations\n", cmd);
}

void error_msg_missingResult(char *cmd) {
  printf("ERROR: %s: no result!\n", cmd);
}

void error_msg_opMissingArgs(char *op) {
  printf("ERROR: op %s: empty stack need two arguments: found none.\n", op);
}

void error_msg_divByZero(void) {
  printf("Error: Division by zero!\n");
}

void error_msg_badOp(char *op) {
  printf("Error: Unrecognized operator: %s!\n", op);
}

int main(int argc, char *argv[]) 
{
  Stack dataStack;
  Stack opStack;
  char *command = NULL;
  int max_input = MAX_INPUT_SIZE;
  int result;
  int *presult;
  int num=0;
  char *calc;
  int check=0;

  // PART B: See writup for details.
  // Your job is to implment the calculator taking care of all the dynamic
  // memory management using the stack module you implmented in Part A

  //creating opStack and dataStack
  dataStack=Stack_create();
  opStack=Stack_create();

  //initializing pointers which I will use them to hold pop values
  int runope=0;
  int *resu = ((void *)0);
  char *top1= ((void *)0);


  while (1){
    command = (char *)malloc(sizeof(char) * max_input);
    char *str = fgets(command, max_input, stdin);
    printf("%s", str);
    if (!str || *str == '\n'){
      break;
    }
    if(check !=0 ){ //if opStack and dataStack have already created, then we can skip this part
      dataStack=Stack_create(); 
      opStack=Stack_create(); 
    }
    check++; //to check have I created opStack and dataStack 
    int proc= process(command,dataStack,opStack); 
    if(proc==0){
      while(!Stack_is_empty(opStack)){
        top1 = Stack_pop(opStack); 
        runope=runOperation(top1,dataStack);  
        if (runope!=0){
          if(runope==-1 && num1 ==0 && proc !=0){
            error_msg_badCommand(command); 
          }
          num1=0;  
          break;
        }
      }
      if (runope==0) {
        if (!Stack_is_empty(opStack)){
          error_msg_opStackNotEmpty(command);
        }
        else if (Stack_is_empty(dataStack)){
          error_msg_missingResult(command);
        }
        else{
          resu= Stack_pop(dataStack);
          if (!Stack_is_empty(opStack)){
            error_msg_extraData(command);
          }
          else {
            num++;
            printf("= %d\n", *resu);
            free(resu);  //we are done with resu pointer 
            }
          }
        }
      }
    free(command); // we are done with command
    //destroying the two stacks to get ready to other commands
    Stack_destroy(dataStack); 
    Stack_destroy(opStack);
    
    }
    
    free(command);
    //if two of the stacks have already destroyed we can skip this part
    //checking whether Stacks are empty prevenets the possible double-free errors
    Stack_int_print(dataStack); //you can ignore this, helper funciton...
    if (!Stack_is_empty(dataStack)){
      Stack_destroy(dataStack);
    }
    
    if (!Stack_is_empty(opStack)){
      Stack_destroy(opStack);
    }
    
    
    
  return 0;
}

/***********************************************************************
 This is the main skeleton for processing a command string:
   You main task is to get it working by adding the necressary memory
   allocations and deallocations.  The rest of the logic is taken care
   of for you.  See writeup for and explanation of what this function 
   does.
***********************************************************************/
int process(char *command, Stack dataStack, Stack opStack){
  char delim[] = " ";
  int *data = ((void *)0);
  char *operation = ((void *)0);
  int rc = 0;
  int max_op_size=MAX_OP_SIZE;

  char *pops= ((void *)0);
  


  char* token = strtok(command, delim);
  while (token != ((void *)0)) {
  operation = (char *)malloc(sizeof(char)*max_op_size); 
  data = (int *)malloc(sizeof(int));
    int ssc=sscanf(token, "%d", data);
    if (ssc == 1){ //if the token is data
      Stack_push(dataStack, data); 
      
      free(operation);
       
    }
    else { //if the token is operation including ( and ).
      int ss=sscanf(token, "%c", operation); 
      free(data);
      if (*operation == ')' && ssc==0){ 
        int paren= runCloseParen(dataStack, opStack); 
        if (paren !=0){
          return -1; 
        }
      }
      else {
        if (*operation== '('){
          Stack_push(opStack, operation);
        }
        else{ 
          while(1) { 
          
          if (Stack_is_empty(opStack)){
            break;
          }
          
          pops =Stack_pop(opStack);
          Stack_push(opStack,pops); //pushing again to nt lose the node
          if (higherPriority((char*) pops, operation)){ 
            Stack_pop(opStack);  
            int runope= runOperation(pops, dataStack); 
            if (runope !=0){
              error_msg_badCommand(command);
              
              return -1;
            }
            num1++;
          }
          else {
            break;
          }
          
          }
          Stack_push(opStack, operation); 
        } 
        
        
      }
    }
    token = strtok(((void *)0), delim);
  }
  
  
  
  return rc;
}


int runCloseParen(Stack dataStack, Stack opStack) { 
  int rc = 0;
  char *op = ((void *)0);
  while (1){
    if (Stack_is_empty(opStack)){
      goto error; 
    }
    void *top1= Stack_pop(opStack);
    char top2= *(char *) top1;
     
    if (top2=='('){ // if the top of the opStack is (
      break;
    }
    else {
      int runoper=runOperation((char *)top1, dataStack); 
      if (runoper !=0){
        
        goto error; 
      }
    }
  }
  return rc;

  error:
    return -1;
}

int
getPriority(char* op)
{
  if(!strcmp(op,"*") || !strcmp(op, "/")) return 2;
  if(!strcmp(op,"+") || !strcmp(op, "-")) return 1;
  return 0;
}

_Bool
higherPriority(char *oldOp, char *newOp)
{
  return getPriority(oldOp) >= getPriority(newOp);
}

// This function executes the specified operation 
//  It's arguments are the first two values on the data stack
//  You must carefully analyize it and add the necessary code
//  to allocate and deallocte the necessary memory items 
int
runOperation(char *op, Stack dataStack)
{
  int data1;
  int data2;
  int result;

  int *pdata1=((void *)0);
  char *pdata2=((void *)0);
  int *presult=((void *)0);

  // to check if the dataStack is empty. this prevents segmentation fault
  if (Stack_is_empty(dataStack)){
    error_msg_opMissingArgs(op);
    return -1;
  }

  pdata1= Stack_pop(dataStack); 
  data1= *(int *)pdata1; 
   
  // to check if the dataStack is empty. this prevents segmentation fault
  if (Stack_is_empty(dataStack)){
    error_msg_opMissingArgs(op); 
    Stack_push(dataStack,  pdata1); // data1 is pushed again since we have nothing to do with this and there is no
    //other data in the dataStack
    
    return -1;
  }
  free(pdata1); 
  pdata2= Stack_pop(dataStack); 
  data2= *(int *)pdata2; 
  free(pdata2);
  
  if (*op == '+'){
    result = data1+data2;
  }
  else if (*op == '*'){
    result = data1*data2;
  }
  else if (*op == '/'){
    if(data1==0){
      error_msg_divByZero();
      return -2;
    }
    result=data2/data1;
  }
  else if(*op == '-'){
    result = data2- data1;
  }
  else {
    error_msg_badOp(op);
    return -1;
  }
  presult= (int *) malloc(sizeof(int));
  //this lines of code assign result to preresult.
  char strr[12];
  sprintf(strr, "%d", result);
  sscanf(strr, "%d", presult);
  Stack_push(dataStack, presult); 
  

  return 0;
}
