
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


#define TAM 50
static node **hash_table;

void init_table();
unsigned int hash(char *key);
void insert(char *name, int len, int type, int lineno);
void insert_sinlen(char *name, int type, int lineno);
node *lookup(char *name);
node *lookup_scope(char *name, int scope);
void remove_hash(char *name);

void hide_scope();
void incr_scope();
int get_scope();

void writetable();
