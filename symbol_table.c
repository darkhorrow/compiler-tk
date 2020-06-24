#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symbol_table.h"

int cur_scope = 0;
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

  unsigned int hashindex = hash(name);
  node *l = hash_table[hashindex];

  while((l!=NULL) && (strcmp(name, l->name) != 0)) l = l->next;

  if(l == NULL) {
    l = (node*) malloc(sizeof(node));
    char *n = malloc(sizeof(char)*len);
		strncpy(n, name, len);
    l->name = n;

    l->size = len;
		l->type = type;
    l->datatype = NOT_DECLARED_TYPE;
		l->scope = cur_scope;
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
  unsigned int hashindex = hash(name);
  node *l = hash_table[hashindex];
  while ((l != NULL) && (strcmp(name,l->name) != 0)) l = l->next;
	return l;
}

node *lookup_scope(char *name, int scope) {
  int hashval = hash(name);
	node *l = hash_table[hashval];
	while ((l != NULL) && (strcmp(name,l->name) != 0) && (scope != l->scope)) l = l->next;
	return l;
}

void remove_hash(char *name) {

}

void writetable() {
  int i;
  printf("------------ -------------- ------------ ------ ------------ ----------- \n");
  printf("Name         Type           Category     Scope  Line Numbers  Address    \n");
  printf("------------ -------------- ------------ ------ ------------ ----------- \n");
  for (i=0; i < TAM; ++i){
    node *l = hash_table[i];
    if(l!=NULL) {
      printf("%s", l->name);

      // Tipo de dato
      printf("\t\t");
      switch (l->datatype) {
        case INT_TYPE:
          printf("INT");
          break;
        case DOUBLE_TYPE:
          printf("DOUBLE");
          break;
        case FLOAT_TYPE:
          printf("FLOAT");
          break;
        case CHAR_TYPE:
          printf("CHAR");
          break;
        case BYTE_TYPE:
          printf("BYTE");
          break;
        case BOOL_TYPE:
          printf("BOOL");
          break;
        case VOID_TYPE:
          printf("VOID");
          break;
        case STR_TYPE:
          printf("STR");
          break;
        case NULL_TYPE:
          printf("NULL");
          break;
        default:
          printf("no datatype ");
      }

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

      printf("\t  %d\t", l->scope);
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
        printf(" 0x%x ", l->address);
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
