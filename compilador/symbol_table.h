
// Tipos de datos
#define NOT_DECLARED_TYPE 0
#define INT_TYPE 1
#define DOUBLE_TYPE 2
#define FLOAT_TYPE 3
#define CHAR_TYPE 4
#define BYTE_TYPE 5
#define BOOL_TYPE 6
#define STR_TYPE 7
#define VOID_TYPE 8
#define NULL_TYPE 9

// Categoria
#define ARRAY 20
#define NO_CAT 21
#define VARIABLE_CAT 22
#define FUNCTION_CAT 23
#define FUNCTION_CALL_CAT 24

// Operacion
#define SUMA_OP 25
#define RESTA_OP 26
#define MULT_OP 27
#define DIV_OP 28
#define INCR_OP 29
#define DECR_OP 30

// Statement
#define RETURN_STAT 31
#define IF_STAT 32
#define FOR_STAT 33
#define WHILE_STAT 34
#define SPLICE_STAT 36
#define PASS_STAT 37
#define ASIG_STAT 38
#define DECL_STAT 39
#define CONTINUE_STAT 40
#define BREAK_STAT 41

typedef union Value {
  char char_val;
	int int_val;
	double double_val;
	char* str_val;
	int bool_val;
	int byte_val;
	float float_val;
} Value;
typedef struct ValueType {
  int datatype;
  Value val;
} ValueType;

typedef struct Param {
  char* name;
  int type;
  int category;
  Value val;

  //Value val;
  struct Param *next;
} Param;


typedef struct List {
  int lineno;
  struct List *next;
} List;

typedef struct node {
  char *name; // nombre
  int size; // tamaño name
  int scope;
  int scope_func;

  int address; // direccion almacenamiento de variables
  int function_tag; // numero de etiqueta a la que saltar cuando se hace una llamada a funcion

  List *lines; // lineas en la que esta el nodo

  Value val; // Valor del nodo

  int type; // categoria de variable

  // arrays y variables - tipo de dato
  // funciones - return type
  int datatype;

  // arrays
  Value *vals;
  int array_size;

  // funciones
  Param* params;
  int type_return; // ARRAY para funciones que devuelven arrays

  struct node *next;

}node;

typedef struct Operacion {
  node* var;
  int op;
} Operacion;

typedef struct Statement {
  int *tags;

  int type;
  int isArray;

  int category;

  int scope;
  struct Statement *next;

} Statement;


#define TAM 50
static node **hash_table;

static int stack_idx;
static int *stack;

static int stack_idx_continue;
static int *stack_continue;

void init_table();
unsigned int hash(char *key);
void insert(char *name, int len, int type, int lineno);
void insert_sinlen(char *name, int type, int lineno);
node *lookup(char *name);
node *lookup_scope(char *name, int scope, int scope_fun);
void remove_hash(char *name);

void hide_scope();
void incr_scope();
void incr_scope_func();
int get_scope();
int get_scope_func();
void set_scope_func(int f);

char* datatypeToString(int type);
void writetable();

// PILA break
void init_stack_break();
void push_break(int et);
int pop_break();
int top_break();

// PILA continue
void init_stack_continue();
void push_continue(int et);
int pop_continue();
int top_continue();
