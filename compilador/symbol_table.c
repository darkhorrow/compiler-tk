#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symbol_table.h"

int cur_scope = 0;
int cur_scope_func = 0;
int declare = 0;

void init_table() {
  hash_table = malloc(TAM * sizeof(node*));
  int i;
  for(i = 0; i < TAM; i++) hash_table[i] = NULL;
}

unsigned int hash(char *key) {
	int hash = 401;
	int c;
	while (*key != '\0') {
		hash = ((hash << 4) + (int)(*key)) % TAM;
		key++;
	}
	return hash % TAM;
}


void insert(char *name, int len, int type, int lineno) {


  int temp_scope = cur_scope_func;
  /*
  if(type == FUNCTION_CAT) {
    temp_scope = 0;
  }
  */

  int scLen = snprintf(NULL, 0, "%d", cur_scope);
  int scfLen = snprintf(NULL, 0, "%d", temp_scope);

  char* strScope = (char*) malloc(sizeof(char)*(scLen + scfLen + 1));

  snprintf(strScope, scLen + scfLen + 1, "%d%d", cur_scope, temp_scope);

  char* newId = (char*) malloc(sizeof(char)*(scLen + scfLen + strlen(name) + 1));
  strcpy(newId, name);
  strcat(newId, strScope);

  unsigned int hashindex = hash(newId);

  node *l = hash_table[hashindex];



  while(l!=NULL) {
    if((strcmp(name,l->name) == 0) && (cur_scope == l->scope) && (temp_scope == l->scope_func)) {
      break;
    }
    l = l->next;
   }



  if(l == NULL) {
    l = (node*) malloc(sizeof(node));
    char *n = malloc(sizeof(char)*len);
		strncpy(n, name, len);

    l->name = n;

    l->size = len;
		l->type = type;
    l->datatype = NOT_DECLARED_TYPE;
		l->scope = cur_scope;
    l->scope_func = temp_scope;
		l->lines = (List*) malloc(sizeof(List));
		l->lines->lineno = lineno;
		l->lines->next = NULL;



		l->next = hash_table[hashindex];
		hash_table[hashindex] = l;


  } else {
    List* n = l->lines;
    List* nprev = NULL;

    while(n != NULL) {
      nprev = n;
      n = n->next;
    }
    List* temp = (List*) malloc(sizeof(List));
    temp->lineno = lineno;
    nprev->next = temp;
  }

  
}

void insert_sinlen(char *name, int type, int lineno) {

}

node *lookup(char *name) {
  int scLen = snprintf(NULL, 0, "%d", cur_scope);
  int scfLen = snprintf(NULL, 0, "%d", cur_scope_func);

  char* strScope = (char*) malloc(sizeof(char)*(scLen + scfLen + 1));

  snprintf(strScope, scLen + 1, "%d", cur_scope);
  snprintf(strScope, scfLen + 1, "%d", cur_scope_func);

  char* newId = (char*) malloc(sizeof(char)*(scLen + scfLen + strlen(name) + 1));
  strcpy(newId, name);
  strcat(newId, strScope);

  unsigned int hashindex = hash(newId);

  node *l = hash_table[hashindex];
  while ((l != NULL) && (strcmp(name,l->name) != 0)) l = l->next;
	return l;
}

node *lookup_scope(char *name, int scope, int scope_fun) {

  int scLen = snprintf(NULL, 0, "%d", scope);
  int scfLen = snprintf(NULL, 0, "%d", scope_fun);

  char* strScope = (char*) malloc(sizeof(char)*(scLen + scfLen + 1));

  snprintf(strScope, scLen + scfLen + 1, "%d%d", scope, scope_fun);

  char* newId = (char*) malloc(sizeof(char)*(scLen + scfLen + strlen(name) + 1));
  strcpy(newId, name);
  strcat(newId, strScope);

  unsigned int hashindex = hash(newId);



	node *l = hash_table[hashindex];

	while ((l != NULL) ) {
    if((strcmp(name,l->name) == 0) && (scope == l->scope) && (scope_fun == l->scope_func)) {
      break;
    }
    l = l->next;
  }

	return l;
}

void remove_hash(char *name) {
  int hashval = hash(name);
  hash_table[hashval] = NULL;
}

char* datatypeToString(int type) {
  switch (type) {
    case INT_TYPE:
      return "INT";
      break;
    case DOUBLE_TYPE:
       return "DOUBLE";
      break;
    case FLOAT_TYPE:
      return "FLOAT";
      break;
    case CHAR_TYPE:
      return "CHAR";
      break;
    case BYTE_TYPE:
      return "BYTE";
      break;
    case BOOL_TYPE:
      return "BOOL";
      break;
    case VOID_TYPE:
      return "VOID";
      break;
    case STR_TYPE:
      return "STR";
      break;
    case NULL_TYPE:
      return "NULL";
      break;
    default:
      return "";
  }
}

void writetable() {
  int i;
  printf("\n------------ -------------- ------------ ------ ------------ ----------- \n");
  printf("Name         Type           Category     Scope  Line Numbers  Address    \n");
  printf("------------ -------------- ------------ ------ ------------ ----------- \n");
  for (i=0; i < TAM; ++i){
    node *l = hash_table[i];
    if(l!=NULL) {
      printf("%s", l->name);

      // Tipo de dato
      printf("\t\t");
      printf("%s", datatypeToString(l->datatype));

      // Categoria
      switch (l->type) {
        case VARIABLE_CAT:
          printf("\t    VARIABLE  ");
          break;
        case FUNCTION_CAT:
          if(l->type_return == ARRAY) {
            printf(" ARRAY");
          }
          printf("\t    FUNCTION  ");
          break;
        case FUNCTION_CALL_CAT:
          printf("\t    CALL_FUN  ");
          break;
        case ARRAY:
          printf("\t    ARRAY");
          break;
        default:
          printf("\t    NO_CAT (%d)",l->type);
          break;
      }

      printf("\t  %d f=%d\t", l->scope, l->scope_func);
      List *num = l->lines;
      while(num != NULL) {
        printf(" %d, ", num->lineno);
        num = num->next;
      }

      if(l->type == FUNCTION_CAT) {
        Param* param = (Param*) l->params;

        printf(" params : ");
        while(param != NULL) {
          printf(" %s, ", param->name);
          param = (Param*) param->next;
        }

        printf("tag : %d", l->function_tag);
      }
      if(l->type == VARIABLE_CAT) {
        printf(" %d ", l->address);
      }

      printf("\n");
    }
  }
}

void hide_scope() {
  if(cur_scope > 0) cur_scope--;
}

void incr_scope() {
  cur_scope++;
}

int get_scope() {
  return cur_scope;
}

void incr_scope_func() {
  cur_scope_func++;
}

int get_scope_func() {
  return cur_scope_func;
}

void set_scope_func(int f) {
  cur_scope_func = f;
}

// PILA BREAK

void init_stack_break() {
  stack = (int*) malloc(sizeof(int)*15);
  stack_idx = -1;
}
void push_break(int et) {
  if(stack_idx < 14) {
    stack_idx++;
    stack[stack_idx] = et;
  }
}
int pop_break() {
  if(stack_idx >= 0) {
    stack_idx--;
    return stack[stack_idx+1];
  }
  return -1;
}
int top_break() {
  return stack[stack_idx];
}

// PILA CONTINUE

void init_stack_continue() {
  stack_continue = (int*) malloc(sizeof(int)*15);
  stack_idx_continue = -1;
}
void push_continue(int et) {
  if(stack_idx_continue < 14) {
    stack_idx_continue++;
    stack_continue[stack_idx_continue] = et;
  }
}
int pop_continue() {
  if(stack_idx_continue >= 0) {
    stack_idx_continue--;
    return stack_continue[stack_idx_continue+1];
  }
  return -1;
}
int top_continue() {
  return stack_continue[stack_idx_continue];
}
