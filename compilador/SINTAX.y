%{
	#include "symbol_table.h"
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>

	#include <ctype.h>
	#include <unistd.h>

	FILE * maquina;
	char* maqfile;

	int funtag = 1;

	int sm = 0x12000;
	int fm = 0;

	int global_dir = 0x12000;

	int stat = 0;


	extern FILE *yyin;
	extern FILE *yyout;
	extern int lineno;
	extern int yylex();
	void yyerror();
	void taberror(char* error);
%}

/* YYSTYPE union */
%union {
	node* item;

	Value val;
	ValueType value_type;

	char* id;
	int tipo_dato;

	Param* params;

	int tag;

	int* multitag;

	Operacion* operacion;

	Statement* statement;
}

/* token definition */
%token <tipo_dato> CHARPAL INTPAL FLOATPAL DOUBLEPAL BOOLPAL VOID BYTEPAL
%token IF ELSE WHILE FOR CONTINUE BREAK RETURNPAL
%token MAS MULTIPLICACION DIVISION MODULO MASIGUAL MENOSIGUAL MULTIGUAL DIVIGUAL INCR DECR OR AND NOT IGUALA DISTINTO MAYOR MENOR MAYORIGUAL MENORIGUAL
%token ABREPARENTESIS CIERRAPARENTESIS ABRECORCHETE CIERRACORCHETE ABRELLAVE CIERRALLAVE PUNTOCOMA PUNTO COMA IGUAL REFERENCE
%token <id>   IDENTIF
%token <val>  INTEGER
%token <val>  FLOAT
%token <val>  DOUBLE
%token <val>  CHARACTER
%token <val>  STRING
%token <val>  BOOL
%token <val>  BYTE
%token <val> 	NULO
%token MENOS ELEVADO DESPLAZAMIENTOIZQ DESPLAZAMIENTODERECHA XOR DEF IN
%token PRINT PRINTLN SPLICE SIZE MAIN FREE_MEM
%token PASS

/* precedencies and associativities */


%start program

/* expression rules */
%nonassoc IGUALA DISTINTO MAYOR MENOR MAYORIGUAL MENORIGUAL
%right IGUAL
%left ABRECORCHETE CIERRACORCHETE
%left ABREPARENTESIS CIERRAPARENTESIS

%left MAS MENOS
%left MULTIPLICACION DIVISION MODULO OR AND NOT XOR
%left ELEVADO

%left DESPLAZAMIENTOIZQ DESPLAZAMIENTODERECHA
%nonassoc INCR DECR
%left COMA

%type<item> function_identif
%type<item> function_call_id
%type<tipo_dato> type
%type<item> variable
%type<params> expression
%type<item> declaration
%type<item> id_assig

%type<val> sign
%type<value_type> constant

%type<params> parametro_def
%type<params> parametros_def
%type<params> parametro
%type<params> parametros

%type<item> declaration_array
%type<item> param_decl

%type<statement> stats
%type<statement> body

%type<statement> for_stat
%type<statement> splice_call
%type<statement> function_call
%type<statement> if_stat
%type<tag> if_head
%type<statement> if_init
%type<statement> while_head
%type<statement> while_stat
%type<statement> else_st
%type<statement> else_body

%type<statement> asignacion
%type<statement> assigment

%type<tag> while_tk
%type<tag> for_assig
%type<tag> for_exp

%type<operacion> for_op


%%

global_amb: global_var {
							fprintf(maquina, "\tR7=R7-4;\n");
							fprintf(maquina, "\tP(R7)=R6;\n");
							fprintf(maquina, "\tR7=R7-4;\n");
							fprintf(maquina, "\tP(R7)=-2;\n");

							fprintf(maquina, "\tR0=R7; // Puntero a posicion valores de parametros\n");

							fprintf(maquina, "\tGT(1); // salta a main \n");
						} |
						{
							fprintf(maquina, "\tR7=R7-4;\n");
							fprintf(maquina, "\tP(R7)=R6;\n");
							fprintf(maquina, "\tR7=R7-4;\n");
							fprintf(maquina, "\tP(R7)=-2;\n");

							fprintf(maquina, "\tR0=R7; // Puntero a posicion valores de parametros\n");

							fprintf(maquina, "\tGT(1); // salta a main \n");
						};

program: global_amb main_def |
				 global_amb functions main_def;

functions: functions function_def | function_def;

global_var: declaration global_var |
            declaration_array global_var |
            assigment global_var |
            declaration |
            declaration_array |
            assigment ;

type: INTPAL { $$ = INT_TYPE; } |
			DOUBLEPAL { $$ = DOUBLE_TYPE; } |
			FLOATPAL { $$ = FLOAT_TYPE; } |
			CHARPAL { $$ = CHAR_TYPE; } |
			BYTEPAL { $$ = BYTE_TYPE; } |
			BOOLPAL { $$ = BOOL_TYPE; } |
			VOID { $$ = VOID_TYPE; };

array: ABRECORCHETE CIERRACORCHETE array | ABRECORCHETE CIERRACORCHETE;

declaration_array: type array IDENTIF {
	insert(yylval.id, strlen(yylval.id), ARRAY, lineno);
	node *f = lookup_scope(yylval.id, get_scope(), get_scope_func());
	f->datatype = $1;
	$$ = f;
};
declaration: type IDENTIF
{
				node *check = lookup_scope(yylval.id, get_scope(), get_scope_func());

				if(check != NULL) {
					taberror("redeclared variable");
				}
				int n_val = get_scope() - 1;
				while(check == NULL && n_val >= 0) {
					check = lookup_scope(yylval.id, n_val, get_scope_func());

					n_val--;
				}
				if(check != NULL) {
					taberror("redeclared variable");
				}
				check = lookup_scope(yylval.id, 0, 0);
				if(check != NULL) {
					taberror("redeclared variable");
				}


				insert(yylval.id, strlen(yylval.id), VARIABLE_CAT, lineno);

				node *f = (node *) lookup_scope(yylval.id, get_scope(), get_scope_func());


				f->datatype = $1;

				int scope_var = f->scope;
				if(scope_var == 0) {
					if($1 == DOUBLE_TYPE || $1 == FLOAT_TYPE) {
						fprintf(maquina, "\tR7=R7-8; // reserva espacio para variable %s\n", f->name);

						sm -= 8;
					} else {
						fprintf(maquina, "\tR7=R7-4; // reserva espacio para variable %s\n", f->name);

						sm -= 4;
					}
					f->address = sm;

				} else {
					if($1 == DOUBLE_TYPE || $1 == FLOAT_TYPE) {
						fprintf(maquina, "\tR7=R7-8; // reserva espacio para variable %s\n", f->name);

						fm -= 8;
					} else {
						fprintf(maquina, "\tR7=R7-4; // reserva espacio para variable %s\n", f->name);

						fm -= 4;
					}
					f->address = fm;
				}
				$$ = f;
};

array_acceso: ABRECORCHETE expression CIERRACORCHETE array_acceso
							| ABRECORCHETE expression CIERRACORCHETE;

variable: IDENTIF {

						char* name = $1;

						int scope_f = get_scope();
						node *f = lookup_scope(name, scope_f, get_scope_func());
						while(f == NULL && scope_f != 0) {
							scope_f--;
							f = lookup_scope(name, scope_f, get_scope_func());
						}
						if(f == NULL) {
							f = lookup_scope(name, 0, 0);
						}

						if(f == NULL) {
							char error[100];
							strcat(error,  "no declared name ");
							strcat(error,  name);
							taberror(error);
						}
						$$ = f;
					} | IDENTIF array_acceso
					{
						node *f = lookup_scope(yylval.id, get_scope(), get_scope_func());
						if(f == NULL) {
							char error[100];
							strcat(error,  "no declared name ");
							strcat(error,  f->name);
							taberror(error);
						}
						$$ = f;
					}
					;

sign: MAS { Value v; v.int_val = 1; $$ = v; } | MENOS { Value v; v.int_val = -1; $$ = v; } |  {Value v; v.int_val = 1; $$ = v;};
constant: sign INTEGER {
						ValueType vt;
						vt.datatype = INT_TYPE;

						Value signo = $1;
						Value valor = yylval.val;
						valor.int_val = signo.int_val * valor.int_val;

						vt.val = valor;
						$$ = vt;
					} |
					sign FLOAT {
						ValueType vt;
						vt.datatype = FLOAT_TYPE;

						Value signo = $1;
						Value valor = yylval.val;
						valor.float_val = signo.int_val * valor.float_val;

						vt.val = valor;
						$$ = vt;
					} |
					sign DOUBLE {
						ValueType vt;
						vt.datatype = DOUBLE_TYPE;

						Value signo = $1;
						Value valor = yylval.val;
						valor.double_val = signo.int_val * valor.double_val;

						vt.val = valor;
						$$ = vt;
					} |
					CHARACTER {
						ValueType vt;
						vt.datatype = CHAR_TYPE;
						vt.val = yylval.val;
						$$ = vt;
					} |
					BYTE {
						ValueType vt;
						vt.datatype = BYTE_TYPE;
						vt.val = yylval.val;
						$$ = vt;
					} |
					STRING {
						ValueType vt;
						vt.datatype = STR_TYPE;
						vt.val = yylval.val;

						$$ = vt;
					} |
					BOOL {
						ValueType vt;
						vt.datatype = BOOL_TYPE;
						vt.val = yylval.val;
						$$ = vt;
					} |
					NULO {
						ValueType vt;
						vt.datatype = NULL_TYPE;
						vt.val = yylval.val;
						$$ = vt;
					};

stats: assigment stats
			 {
					Statement* st = $2;
					Statement* a = (Statement*) malloc(sizeof(Statement));
					a->scope = get_scope();
					a->category = ASIG_STAT;
					a->next = st;
					$$ = a;
			 } |
			 declaration stats {
			 	  Statement* st = $2;
			 	  Statement* a = (Statement*) malloc(sizeof(Statement));
				  a->next = st;
					a->category = DECL_STAT;
					a->type = $1->datatype;
					a->scope = get_scope();
			 		$$ = a;
			 } |
			 declaration_array stats {
					Statement* st = $2;
					Statement* a = (Statement*) malloc(sizeof(Statement));
					a->next = st;
			 		$$ = $2;
			 } |
			 function_call stats {
				  Statement* st = $2;
				  $1->next = st;
			 		$$ = $1;
			 } |
			 if_stat stats {

				  Statement* st = $2;
				  $1->next = st;
			 		$$ = $1;
			 } |
			 for_stat stats {
				  Statement* st = $2;
				  $1->next = st;
			 		$$ = $1;
			 } |
			 forin_stat stats {
				  Statement* st = $2;
				  Statement* a = (Statement*) malloc(sizeof(Statement));
				  a->next = st;
			 		$$ = $2;
			 } |
			 while_stat stats {
				  Statement* st = $2;
				  $1->next = $2;
			 		$$ = $1;
			 } |
			 CONTINUE {fprintf(maquina, "\tGT(%d); // continue\n", top_continue());} stats {
				  Statement* st = $3;
				  Statement* a = (Statement*) malloc(sizeof(Statement));
					st->category = CONTINUE_STAT;
 				 	st->scope = get_scope();
				  a->next = st;
			 		$$ = a;
			 } |
			 BREAK {fprintf(maquina, "\tGT(%d); // break A\n", top_break());} stats {
				  Statement* st = $3;
				  Statement* a = (Statement*) malloc(sizeof(Statement));
					st->category = BREAK_STAT;
 				 	st->scope = get_scope();
				  a->next = st;
			 		$$ = a;
			 } |
			 print_call stats {
				  Statement* st = $2;
				  Statement* a = (Statement*) malloc(sizeof(Statement));
				  a->next = st;
					a->type = VOID_TYPE;
 			   	a->scope = get_scope();
			 		$$ = a;
			 } |
			 println_call stats {
				  Statement* st = $2;
				  Statement* a = (Statement*) malloc(sizeof(Statement));
				  a->next = st;
					a->type = VOID_TYPE;
 			   	a->scope = get_scope();
			 		$$ = a;
			 } |
			 PASS stats {
				  Statement* st = $2;
				  Statement* a = (Statement*) malloc(sizeof(Statement));
					a->category = PASS_STAT;
					a->scope = get_scope();
				  a->next = st;

			 		$$ = a;
			 } |
			 assigment {
			 		Statement* st = (Statement*) malloc(sizeof(Statement));
			 		st->category=ASIG_STAT;
					st->scope = get_scope();
					st->next = (Statement*) NULL;
					$$ = st;
			 } |
			 declaration {
			 	Statement* st = (Statement*) malloc(sizeof(Statement));
				st->type = $1->datatype;
				st->category = DECL_STAT;
				st->scope = get_scope();
				st->next = (Statement*) NULL;
			 	$$ = st;
			 } |
			 declaration_array { $$ = (Statement*)NULL;  } |
			 function_call { $$ = $1; } |
			 if_stat {  $$ = $1; } |
			 for_stat { $$ = $1; } |
			 forin_stat { $$ = (Statement*)NULL; } |
			 while_stat { $$ = $1; } |
			 print_call {

			 	 Statement* st = (Statement*) malloc(sizeof(Statement));
			 	 st->category = FUNCTION_CALL_CAT;
			   st->type = VOID_TYPE;
			   st->scope = get_scope();
			   st->next = (Statement*) NULL;
			   $$ = st;
			 } |
			 println_call {
				 Statement* st = (Statement*) malloc(sizeof(Statement));
				 st->category = FUNCTION_CALL_CAT;
				 st->type = VOID_TYPE;
				 st->scope = get_scope();
				 st->next = (Statement*) NULL;
				 $$ = st;
			 } |
			 CONTINUE {
				 Statement* st = (Statement*) malloc(sizeof(Statement));
				 st->category = CONTINUE_STAT;
				 st->scope = get_scope();
				 st->next = (Statement*) NULL;

				 fprintf(maquina, "\tGT(%d); // continue\n", top_continue());
				 $$ = st;
			 } |
			 BREAK {
				 Statement* st = (Statement*) malloc(sizeof(Statement));
				 st->category = BREAK_STAT;
				 st->scope = get_scope();
				 st->next = (Statement*) NULL;

				 fprintf(maquina, "\tGT(%d); // break\n", top_break());

				 $$ = st;
			 }|
			 RETURNPAL expression {
			 		Statement* st = (Statement*) malloc(sizeof(Statement));
					st->type = $2->type;
					st->category = RETURN_STAT;
					st->scope = get_scope();
					st->next = (Statement*) NULL;

			 		$$ = st;
					fprintf(maquina, "// al evaluar expresion se agregó resultado a pila\n");

					switch($2->type) {
						case INT_TYPE:
							fprintf(maquina, "\tR0=I(R7); // saca resultado del return de la pila\n");
							fprintf(maquina, "\tR7=R7+4; // libera espacio en la pila\n");
							break;
						case FLOAT_TYPE:
							fprintf(maquina, "\tRR0=F(R7); // saca resultado del return de la pila\n");
							fprintf(maquina, "\tR7=R7+8; // libera espacio en la pila\n");
							break;
						case DOUBLE_TYPE:
							fprintf(maquina, "\tRR0=D(R7); // saca resultado del return de la pila\n");
							fprintf(maquina, "\tR7=R7+8; // libera espacio en la pila\n");
							break;
						case CHAR_TYPE:
							fprintf(maquina, "\tR0=U(R7); // saca resultado del return de la pila\n");
							fprintf(maquina, "\tR7=R7+4; // libera espacio en la pila\n");
							break;
						case BOOL_TYPE:
							fprintf(maquina, "\tR0=U(R7); // saca resultado del return de la pila\n");
							fprintf(maquina, "\tR7=R7+4; // libera espacio en la pila\n");
							break;
						case BYTE_TYPE:
							fprintf(maquina, "\tR0=U(R7); // saca resultado del return de la pila\n");
							fprintf(maquina, "\tR7=R7+4; // libera espacio en la pila\n");
							break;
						default:
							taberror("return type not accepted\n");
					}
					fprintf(maquina, "// saca resultado y lo introduce en pila\n");

					fprintf(maquina, "\tR5=P(R6-8); // saca etiqueta de retorno \n");
					fprintf(maquina, "\tR7=R7+4; // libera espacio en la pila\n");

					fprintf(maquina, "\tR1=P(R6-4); // saca el R6 de la funcion anterior\n");
					fprintf(maquina, "\tR7=R7+4; // libera espacio en la pila\n");

					fprintf(maquina, "\tR7=R6; // recupera puntero de la pila\n");
					fprintf(maquina, "\tR6=R1; // recupera frame pointer de la funcion previa\n");

					fprintf(maquina, "\tGT(R5); // retorna a la funcion previa (return R0/RR0)\n");
			 } |
			 PASS {
			 	Statement* st = (Statement*) malloc(sizeof(Statement));
				st->category = PASS_STAT;
				st->scope = get_scope();
				st->next = (Statement*) NULL;
				$$ = st;
			 	fprintf(maquina, "// pass\n");
			 }
			 ;

expression:
  expression MAS expression
	{
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		$$ = $1;
		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0+R1; // suma expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tI(R7)=R0; // guarda suma en pila\n");
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tRR0=F(R7+8);\n");
			fprintf(maquina, "\tRR1=F(R7);\n");
			fprintf(maquina, "\tRR0=RR0+RR1; // suma expresion\n");
			fprintf(maquina, "\tR7=R7+8;\n");
			fprintf(maquina, "\tF(R7)= RR0; // guarda suma en pila\n");
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tRR0=D(R7+8);\n");
			fprintf(maquina, "\tRR1=D(R7);\n");
			fprintf(maquina, "\tRR0=RR0+RR1; // suma expresion\n");
			fprintf(maquina, "\tR7=R7+8;\n");
			fprintf(maquina, "\tD(R7)= RR0; // guarda suma en pila\n");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0+R1; // suma expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)=R0; // guarda suma en pila\n");
		}
	} |
  expression MENOS expression
	{
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		$$ = $1;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0-R1; // resta expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tI(R7)=R0; // guarda resta en pila\n");
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tRR0=F(R7+8);\n");
			fprintf(maquina, "\tRR1=F(R7);\n");
			fprintf(maquina, "\tRR0=RR0-RR1; // resta expresion\n");
			fprintf(maquina, "\tR7=R7+8;\n");
			fprintf(maquina, "\tF(R7)= RR0; // guarda resta en pila\n");
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tRR0=D(R7+8);\n");
			fprintf(maquina, "\tRR1=D(R7);\n");
			fprintf(maquina, "\tRR0=RR0-RR1; // resta expresion\n");
			fprintf(maquina, "\tR7=R7+8;\n");
			fprintf(maquina, "\tD(R7)= RR0; // guarda resta en pila\n");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0-R1; // resta expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)=R0; // guarda resta en pila\n");
		}
	} |
  expression MULTIPLICACION expression
	{
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		$$ = $1;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0*R1; // multiplicacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tI(R7)=R0; // guarda multiplicacion en pila\n");
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tRR0=F(R7+8);\n");
			fprintf(maquina, "\tRR1=F(R7);\n");
			fprintf(maquina, "\tRR0=RR0*RR1; // multiplicacion expresion\n");
			fprintf(maquina, "\tR7=R7+8;\n");
			fprintf(maquina, "\tF(R7)= RR0; // guarda multiplicacion en pila\n");
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tRR0=D(R7+8);\n");
			fprintf(maquina, "\tRR1=D(R7);\n");
			fprintf(maquina, "\tRR0=RR0*RR1; // multiplicacion expresion\n");
			fprintf(maquina, "\tR7=R7+8;\n");
			fprintf(maquina, "\tD(R7)= RR0; // guarda multiplicacion en pila\n");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0*R1; // multiplicacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)=R0; // guarda multiplicacion en pila\n");
		}
	} |
  expression DIVISION expression
	{
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		$$ = $1;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tIF(!R1) GT(-13); // ERROR: division por cero\n");
			fprintf(maquina, "\tR0=R0/R1; // division expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			fprintf(maquina, "\tI(R7)=R0; // guarda division en pila\n");
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tRR0=F(R7+8);\n");
			fprintf(maquina, "\tRR1=F(R7);\n");
			fprintf(maquina, "\tIF(!RR1) GT(-13); // ERROR: division por cero\n");
			fprintf(maquina, "\tRR0=RR0/RR1; // division expresion\n");
			fprintf(maquina, "\tR7=R7+8;\n");
			fprintf(maquina, "\tF(R7)= RR0; // guarda division en pila\n");
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tRR0=D(R7+8);\n");
			fprintf(maquina, "\tRR1=D(R7);\n");
			fprintf(maquina, "\tIF(!RR1) GT(-13); // ERROR: division por cero\n");
			fprintf(maquina, "\tRR0=RR0/RR1; // division expresion\n");
			fprintf(maquina, "\tR7=R7+8;\n");
			fprintf(maquina, "\tD(R7)= RR0; // guarda division en pila\n");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tIF(!R1) GT(-13); // ERROR: division por cero\n");
			fprintf(maquina, "\tR0=R0/R1; // division expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)=R0; // guarda division en pila\n");
		}
	} |
	expression MODULO expression
	{
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		$$ = $1;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0 % R1; // and expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			fprintf(maquina, "\tI(R7)=R0; // guarda and en pila\n");
		}

		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0 % R1; // and expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			fprintf(maquina, "\tU(R7)=R0; // guarda and en pila\n");
		}
	} |
	expression AND expression
	{
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		$$ = $1;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0 & R1; // and expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			fprintf(maquina, "\tI(R7)=R0; // guarda and en pila\n");
		}

		if(tipo == BOOL_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0 & R1; // and expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			fprintf(maquina, "\tU(R7)=R0; // guarda and en pila\n");
		}

		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0 & R1; // and expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			fprintf(maquina, "\tU(R7)=R0; // guarda and en pila\n");
		}
	} |
	expression OR expression
	{
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		$$ = $1;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0 | R1; // or expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			fprintf(maquina, "\tI(R7)=R0; // guarda or en pila\n");
		}

		if(tipo == BOOL_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0 | R1; // or expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			fprintf(maquina, "\tU(R7)=R0; // guarda or en pila\n");
		}

		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0 | R1; // or expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			fprintf(maquina, "\tU(R7)=R0; // guarda or en pila\n");
		}
	} |
	expression XOR expression
	{
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = BYTE_TYPE;
		$$ = param;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0 ^ R1; // xor expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			fprintf(maquina, "\tI(R7)=R0; // guarda xor en pila\n");
		}

		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0 ^ R1; // xor expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			fprintf(maquina, "\tU(R7)=R0; // guarda xor en pila\n");
		}

		if(tipo == BOOL_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0 ^ R1; // xor expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			fprintf(maquina, "\tU(R7)=R0; // guarda xor en pila\n");
		}
	} |
	NOT expression
	{
		$$ = $2;

		int tipo = $2->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7);\n");
			fprintf(maquina, "\tR0=!R0; // not expresion\n");
			fprintf(maquina, "\tI(R7)=R0; // guarda not en pila\n");
		}
		if(tipo == BOOL_TYPE) {
			fprintf(maquina, "\tR0=U(R7);\n");
			fprintf(maquina, "\tR0=!R0; // not expresion\n");
			fprintf(maquina, "\tU(R7)=R0; // guarda not en pila\n");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7);\n");
			fprintf(maquina, "\tR0=!R0; // not expresion\n");
			fprintf(maquina, "\tU(R7)=R0; // guarda not en pila\n");
		}
	}|
	expression IGUALA expression
	{
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = BOOL_TYPE;
		$$ = param;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0==R1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			fprintf(maquina, "\tU(R7)=R0; // guarda boolean en pila\n");
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tRR0=F(R7+8);\n");
			fprintf(maquina, "\tRR1=F(R7);\n");
			fprintf(maquina, "\tR0=RR0==RR1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)= R0; // guarda igual en pila\n");
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tRR0=D(R7+8);\n");
			fprintf(maquina, "\tRR1=D(R7);\n");
			fprintf(maquina, "\tR0=RR0==RR1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)= R0; // guarda igual en pila\n");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0==R1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)=R0; // guarda igual en pila\n");
		}
	} |
	expression MAYOR expression
	{
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = BOOL_TYPE;
		$$ = param;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0>R1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			fprintf(maquina, "\tU(R7)=R0; // guarda boolean en pila\n");
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tRR0=F(R7+8);\n");
			fprintf(maquina, "\tRR1=F(R7);\n");
			fprintf(maquina, "\tR0=RR0>RR1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)= R0; // guarda igual en pila\n");
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tRR0=D(R7+8);\n");
			fprintf(maquina, "\tRR1=D(R7);\n");
			fprintf(maquina, "\tR0=RR0>RR1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)= R0; // guarda igual en pila\n");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0>R1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)=R0; // guarda igual en pila\n");
		}
	} |
	expression MENOR expression
	{
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = BOOL_TYPE;
		$$ = param;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0<R1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			fprintf(maquina, "\tU(R7)=R0; // guarda boolean en pila\n");
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tRR0=F(R7+8);\n");
			fprintf(maquina, "\tRR1=F(R7);\n");
			fprintf(maquina, "\tR0=RR0<RR1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)= R0; // guarda igual en pila\n");
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tRR0=D(R7+8);\n");
			fprintf(maquina, "\tRR1=D(R7);\n");
			fprintf(maquina, "\tR0=RR0<RR1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)= R0; // guarda igual en pila\n");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0<R1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)=R0; // guarda igual en pila\n");
		}
	} |
	expression MAYORIGUAL expression
	{
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = BOOL_TYPE;
		$$ = param;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0>=R1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			fprintf(maquina, "\tU(R7)=R0; // guarda boolean en pila\n");
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tRR0=F(R7+8);\n");
			fprintf(maquina, "\tRR1=F(R7);\n");
			fprintf(maquina, "\tR0=RR0>=RR1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)= R0; // guarda comparacion en pila\n");
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tRR0=D(R7+8);\n");
			fprintf(maquina, "\tRR1=D(R7);\n");
			fprintf(maquina, "\tR0=RR0>=RR1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)= R0; // guarda boolean en pila\n");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0>=R1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)=R0; // guarda boolean en pila\n");
		}
	} |
	expression MENORIGUAL expression
	{
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = BOOL_TYPE;
		$$ = param;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0<=R1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)=R0; // guarda boolean en pila\n");
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tRR0=F(R7+8);\n");
			fprintf(maquina, "\tRR1=F(R7);\n");
			fprintf(maquina, "\tR0=RR0<=RR1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			fprintf(maquina, "\tU(R7)= R0; // guarda boolean en pila\n");
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tRR0=D(R7+8);\n");
			fprintf(maquina, "\tRR1=D(R7);\n");
			fprintf(maquina, "\tR0=RR0<=RR1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)= R0; // guarda boolean en pila\n");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0<=R1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)=R0; // guarda boolean en pila\n");
		}
	} |
	expression DISTINTO expression
	{
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = BOOL_TYPE;
		$$ = param;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0!=R1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			fprintf(maquina, "\tU(R7)=R0; // guarda boolean en pila\n");
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tRR0=F(R7+8);\n");
			fprintf(maquina, "\tRR1=F(R7);\n");
			fprintf(maquina, "\tR0=RR0!=RR1; // comp expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)= R0; // guarda bool en pila\n");
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tRR0=D(R7+8);\n");
			fprintf(maquina, "\tRR1=D(R7);\n");
			fprintf(maquina, "\tR0=RR0!=RR1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)= R0; // guarda boolean en pila\n");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0!=R1; // comparacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			fprintf(maquina, "\tU(R7)=R0; // guarda boolean en pila\n");
		}
	} |
	expression ELEVADO expression
	{
		/* Toma valor primera expresion */
		if($1->type != $3->type ) taberror("types in the expression do not match");

		int tipo = $1->type;

		if(tipo == INT_TYPE) {

			fprintf(maquina, "\t// calcula exponente : n^e\n");
			fprintf(maquina, "\tR0=I(R7+4); // base : R0=n\n");
			fprintf(maquina, "\tR1=I(R7); // exponente : R1=e\n");
			fprintf(maquina, "\tR7=R7+4; // R0\n");
			fprintf(maquina, "\tR7=R7+4; // R1\n");


			funtag++;
			int L1 = funtag;
			funtag++;
			int L2 = funtag;
			funtag++;
			int L3 = funtag;
			funtag++;
			int L4 = funtag;
			funtag++;
			int L5 = funtag;
			funtag++;
			int L6 = funtag;
			funtag++;
			int L7 = funtag;

			fprintf(maquina, "\tR3 = R1 > 0;\n");
			fprintf(maquina, "\tIF(!R3) GT(%d); // if(e > 0) {\n", L1);
			fprintf(maquina, "\t\tR2 = 1;\n");
			fprintf(maquina, "\t\tL %d: // while\n", L4);
			fprintf(maquina, "\t\tR3 = R1 > 0;\n");
			fprintf(maquina, "\t\tIF(!R3) GT(%d); // while(e > 0) {\n", L5);
			fprintf(maquina, "\t\t\tR2 = R2 * R0;\n");
			fprintf(maquina, "\t\t\tR1 = R1 - 1;\n");
			fprintf(maquina, "\t\t\tGT(%d);\n", L4);
			fprintf(maquina, "\t\tL %d: // } // finwhile\n", L5);
			fprintf(maquina, "\t\tRR0=R2; // resultado : n^e\n");
			fprintf(maquina, "\tGT(%d);\n", L2);
			fprintf(maquina, "\tL %d: // } else {\n", L1);
			fprintf(maquina, "\t\tR2 = R0;\n");
			fprintf(maquina, "\t\tR1 = R1 + 1;\n");
			fprintf(maquina, "\t\tL %d: // while\n", L6);
			fprintf(maquina, "\t\tR3 = R1 < 0;\n");
			fprintf(maquina, "\t\tIF(!R3) GT(%d);\n", L7);
			fprintf(maquina, "\t\t\tR2 = R2 * R0;\n");
			fprintf(maquina, "\t\t\tR1 = R1 + 1;\n");
			fprintf(maquina, "\t\t\tGT(%d);\n", L6);
			fprintf(maquina, "\t\tL %d: // } // finwhile\n", L7);
			fprintf(maquina, "\t\tRR0 = 1.0 / R2; // resultado : n^e\n", L7);
			fprintf(maquina, "\tL %d: // } // finsi\n", L2);

			fprintf(maquina, "\tR7 = R7 - 8;\n");
			fprintf(maquina, "\tD(R7) = RR0; // introduce resultado en memoria\n");
		}

		$1->type = DOUBLE_TYPE;
		$$ = $1;
	} |
	expression DESPLAZAMIENTOIZQ expression
	{
		/* Toma valor primera expresion */
		if($1->type != BYTE_TYPE || $3->type != INT_TYPE) taberror("types in the expression do not match");

		fprintf(maquina, "\tR0=U(R7+4);\n");
		fprintf(maquina, "\tR1=I(R7);\n");
		fprintf(maquina, "\tR0=R0<<R1; // desplazamiento izquierda expresion\n");
		fprintf(maquina, "\tR7=R7+4;\n");
		fprintf(maquina, "\tU(R7)=R0; // guarda byte en pila\n");

		$$ = $1;
	} |
	expression DESPLAZAMIENTODERECHA expression
	{
		/* Toma valor primera expresion */
		if($1->type != BYTE_TYPE || $3->type != INT_TYPE) taberror("types in the expression do not match");

		fprintf(maquina, "\tR0=U(R7+4);\n");
		fprintf(maquina, "\tR1=I(R7);\n");
		fprintf(maquina, "\tR0=R0>>R1; // desplazamiento izquierda expresion\n");
		fprintf(maquina, "\tR7=R7+4;\n");
		fprintf(maquina, "\tU(R7)=R0; // guarda byte en pila\n");

		$$ = $1;
	} |
	ABREPARENTESIS expression CIERRAPARENTESIS
	{
		$$ = $2;
	} |
  constant
	{
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = $1.datatype;
		param->category = VARIABLE_CAT;
		param->val = $1.val;
		$$ = param;


		if($1.datatype == INT_TYPE) {
			fprintf(maquina, "\tR7=R7-4;\n");
			fprintf(maquina, "\tI(R7)=%d;", $1.val.int_val);
		}
		if($1.datatype == FLOAT_TYPE) {
			fprintf(maquina, "\tR7=R7-8;\n");
			fprintf(maquina, "\tF(R7)=%0.4f;", $1.val.float_val);
		}
		if($1.datatype == DOUBLE_TYPE) {
			fprintf(maquina, "\tR7=R7-8;\n");
			fprintf(maquina, "\tD(R7)=%0.4f;", $1.val.double_val);
		}
		if($1.datatype == CHAR_TYPE) {
			fprintf(maquina, "\tR7=R7-4;\n");
			fprintf(maquina, "\tU(R7)=\'%c\';", $1.val.char_val);
		}
		if($1.datatype == BYTE_TYPE) {
			fprintf(maquina, "\tR7=R7-4;\n");
			fprintf(maquina, "\tU(R7)=%d;", $1.val.byte_val);
		}
		if($1.datatype == BOOL_TYPE) {
			fprintf(maquina, "\tR7=R7-4;\n");
			fprintf(maquina, "\tU(R7)=%d;", $1.val.bool_val);
		}
		if($1.datatype == STR_TYPE) {
			char *s = $1.val.str_val;
			int len = strlen(s) + 1;

			int buf = 4 * (int)(len/2);
			buf = len % 2 == 0 ? buf : buf + 4;

			sm -= buf;


			fprintf(maquina, "STAT(%d)\n", stat);
			fprintf(maquina, "\tSTR(%#x, \"%s\"); // Guarda string %s\n", sm, s, s);
			fprintf(maquina, "CODE(%d)\n", stat);
			//fprintf(maquina, "\tR7=R7-%d;\n", buf);

			stat++;
		}

		fprintf(maquina, " // asigna constante a pila \n");
	}|
	size_call
	{
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = INT_TYPE;
		param->category = VARIABLE_CAT;
		$$ = param;
	}|
	splice_call
	{
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = $1->type;
		param->category = ARRAY;
		$$ = param;
	} |
	function_call
	{
		Param* param = (Param*) $1;
		param->category = VARIABLE_CAT;
		$$ = param;
	} |
  variable
	{

		node *n = $1;
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = n->datatype;
		param->category = n->type;

		$$ = param;

		int tipo = n->datatype;
		int addr = n->address;

		if(n->scope == 0) {
			fprintf(maquina, "\tR1=%#x; // direccion de variable\n", addr);
		} else {
			fprintf(maquina, "\tR1=R6%d; // direccion de variable\n", addr);
		}

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR7=R7-4;\n");
			fprintf(maquina, "\tR2=I(R1);\n");
			fprintf(maquina, "\tI(R7)=R2;");
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tR7=R7-8;\n");
			fprintf(maquina, "\tRR0=F(R1);\n");
			fprintf(maquina, "\tF(R7)=RR0;");
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tR7=R7-8;\n");
			fprintf(maquina, "\tRR0=D(R1);\n");
			fprintf(maquina, "\tD(R7)=RR0;");
		}
		if(tipo == CHAR_TYPE) {
			fprintf(maquina, "\tR7=R7-4;\n");
			fprintf(maquina, "\tR2=U(R1);\n");
			fprintf(maquina, "\tU(R7)=R2;");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR7=R7-4;\n");
			fprintf(maquina, "\tR2=U(R1);\n");
			fprintf(maquina, "\tU(R7)=R2;");
		}
		if(tipo == BOOL_TYPE) {
			fprintf(maquina, "\tR7=R7-4;\n");
			fprintf(maquina, "\tR2=U(R1);\n");
			fprintf(maquina, "\tU(R7)=R2;");
		}

		fprintf(maquina, " // asignacion de valor de variable a pila \n");
	};

print_call: PRINT ABREPARENTESIS expression CIERRAPARENTESIS {

	if($3->type == INT_TYPE)
	{
		sm-=6;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(%#x, \"%%d\"); // espacio para digito\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=%#x; // string de formato\n", sm);
		fprintf(maquina, "\tR2=I(R7); // valor a imprimir\n");
		fprintf(maquina, "\tR7=R7+4;\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putf_);\n");
		fprintf(maquina, "L %d:\n", funtag);

		stat++;
	}

	if($3->type == FLOAT_TYPE)
	{
		sm-=12;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(%#x, \"%%0.8f\"); // espacio para digito\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=%#x; // string de formato\n", sm);
		fprintf(maquina, "\tRR2=F(R7); // valor a imprimir\n");
		fprintf(maquina, "\tR7=R7+8;\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putd_);\n");
		fprintf(maquina, "L %d: \n", funtag);

		stat++;
	}

	if($3->type == DOUBLE_TYPE)
	{
		sm-=12;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(%#x, \"%%0.8f\"); // espacio para digito\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=%#x; // string de formato\n", sm);
		fprintf(maquina, "\tRR2=D(R7); // valor a imprimir\n");
		fprintf(maquina, "\tR7=R7+8;\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putd_);\n");
		fprintf(maquina, "L %d:\n", funtag);

		stat++;
	}

	if($3->type == STR_TYPE)
	{
		fprintf(maquina, "\tR1=%#x;\n", sm);

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putf_);\n");
		fprintf(maquina, "L %d: \n", funtag);
	}

	if($3->type == BOOL_TYPE)
	{
		sm-=6;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(%#x, \"%%d\"); // espacio para bool\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=%#x; // string de formato\n", sm);
		fprintf(maquina, "\tR2=U(R7); // valor a imprimir\n");
		fprintf(maquina, "\tR7=R7+4;\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putf_);\n");
		fprintf(maquina, "L %d:\n", funtag);

		stat++;
	}

	if($3->type == CHAR_TYPE)
	{
		sm-=6;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(%#x, \"%%c\"); // espacio para char\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=%#x; // string de formato\n", sm);
		fprintf(maquina, "\tR2=U(R7); // valor a imprimir\n");
		fprintf(maquina, "\tR7=R7+4;\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putf_);\n");
		fprintf(maquina, "L %d:\n", funtag);

		stat++;
	}

	if($3->type == BYTE_TYPE)
	{
		sm-=6;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(%#x, \"%%d\"); // espacio para bool\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=%#x; // string de formato\n", sm);
		fprintf(maquina, "\tR2=U(R7); // valor a imprimir\n");
		fprintf(maquina, "\tR7=R7+4;\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putf_);\n");
		fprintf(maquina, "L %d:\n", funtag);

		stat++;
	}

};

println_call: PRINTLN ABREPARENTESIS expression CIERRAPARENTESIS {

	if($3->type == INT_TYPE)
	{
		sm-=8;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(%#x, \"%%d\\n\"); // espacio para digito\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=%#x; // string de formato\n", sm);
		fprintf(maquina, "\tR2=I(R7); // valor a imprimir\n");
		fprintf(maquina, "\tR7=R7+4;\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putf_);\n");
		fprintf(maquina, "L %d:\n", funtag);

		stat++;
	}

	if($3->type == FLOAT_TYPE)
	{
		sm-=14;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(%#x, \"%%0.8f\\n\"); // espacio para digito\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=%#x; // string de formato\n", sm);
		fprintf(maquina, "\tRR2=F(R7); // valor a imprimir\n");
		fprintf(maquina, "\tR7=R7+8;\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putd_);\n");
		fprintf(maquina, "L %d:\n", funtag);

		stat++;
	}

	if($3->type == DOUBLE_TYPE)
	{
		sm-=14;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(%#x, \"%%0.8f\\n\"); // espacio para digito\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=%#x; // string de formato\n", sm);
		fprintf(maquina, "\tRR2=D(R7); // valor a imprimir\n");
		fprintf(maquina, "\tR7=R7+8;\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putd_);\n");
		fprintf(maquina, "L %d: \n", funtag);

		stat++;
	}

	if($3->type == STR_TYPE)
	{
		fprintf(maquina, "\tR1=%#x; // direccion de string\n", sm);

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putf_);\n");
		fprintf(maquina, "L %d: \n", funtag);

		// imprime salto linea
		sm-=4;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(%#x, \"\\n\"); // salto linea\n", sm); // establece espacio para imprimir
		fprintf(maquina, "CODE(%d)\n", stat);

		funtag++;
		fprintf(maquina, "\tR1=%#x; // direccion de \\n\n", sm);
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putf_);\n");
		fprintf(maquina, "L %d: \n", funtag);

		stat++;
	}

	if($3->type == BOOL_TYPE)
	{
		sm-=8;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(%#x, \"%%d\\n\"); // espacio para bool\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=%#x; // string de formato\n", sm);
		fprintf(maquina, "\tR2=U(R7); // valor a imprimir\n");
		fprintf(maquina, "\tR7=R7+4;\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putf_);\n");
		fprintf(maquina, "L %d:\n", funtag);

		stat++;
	}

	if($3->type == CHAR_TYPE)
	{
		sm-=8;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(%#x, \"%%c\\n\"); // espacio para char\n", sm); // establece espacio para imprimir
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=%#x; // string de formato\n", sm);
		fprintf(maquina, "\tR2=U(R7); // valor a imprimir\n");
		fprintf(maquina, "\tR7=R7+4;\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putf_);\n");
		fprintf(maquina, "L %d:\n", funtag);

		stat++;
	}

	if($3->type == BYTE_TYPE)
	{
		sm-=8;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(%#x, \"%%d\\n\"); // espacio para bool\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=%#x; // string de formato\n", sm);
		fprintf(maquina, "\tR2=U(R7); // valor a imprimir\n");
		fprintf(maquina, "\tR7=R7+4;\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putf_);\n");
		fprintf(maquina, "L %d:\n", funtag);

		stat++;
	}
};

size_call: SIZE ABREPARENTESIS variable {node *n = $3; int type = n->datatype; if(type != ARRAY) taberror("size expected an array"); } CIERRAPARENTESIS;

splice_call: SPLICE ABREPARENTESIS variable {node *n = $3;
																						 int type = n->datatype; if(type != ARRAY) taberror("slice expected an array");
																						}
 																		COMA expression {if(((Param*)$6)->type != INT_TYPE) taberror("slice a indice must be integer");}
																		COMA expression {if(((Param*)$9)->type != INT_TYPE) taberror("slice b indice must be integer");}
										CIERRAPARENTESIS {

											Statement * st = (Statement*) malloc(sizeof(Param));
											node *n = $3;
											st->type = n->datatype;
											st->category = SPLICE_STAT;
											st->isArray = n->type;

											st->scope = get_scope();
											st->next = (Statement*) NULL;
											$$ = st;
										};

while_tk: WHILE {
							funtag++;
							fprintf(maquina, "L %d: // while\n", funtag);
							$$ = funtag;
						};

while_head: while_tk ABREPARENTESIS expression CIERRAPARENTESIS
						{ if($3->type != BOOL_TYPE) taberror("while only accept bool type");
							int* multitag = malloc(sizeof(int)*2);

							fprintf(maquina, "\tR0=U(R7);\n");
							fprintf(maquina, "\tR7=R7+4; // baja puntero \n");
							multitag[0] = $1;

							funtag++;

							fprintf(maquina, "\tIF(!R0) GT(%d); // ignora while\n", funtag);
							multitag[1] = funtag;

							push_break(funtag);

							Statement* st = (Statement*) malloc(sizeof(Statement));
							st->category = WHILE_STAT;
							st->tags = multitag;
							st->scope = get_scope();
							st->next = (Statement*) NULL;
							$$ = st;

							incr_scope();
						};

while_stat: while_head
						body
						{
							fprintf(maquina, "GT(%d); // itera \n", $1->tags[0]);
							fprintf(maquina, "L %d: // while fin\n", $1->tags[1]);

							// introduce stat
							Statement* st = $2;
							while(st->next != NULL) {
								st = st->next;
							}
							st->next = (Statement*) malloc(sizeof(Statement));
							st->next->category = WHILE_STAT;

							st->next->scope = get_scope();
							st->next->next = (Statement*) NULL;

							pop_break();

							$$ = $2;
						};

forin_stat: FOR IDENTIF IN variable { node* n = $4;
																			if(n->datatype != ARRAY)
																			{
																				taberror("forin only accept array");
																			}
																			incr_scope();
																		} body;


for_assig: FOR ABREPARENTESIS assigment
					{
						funtag++;
						fprintf(maquina, "L %d:\n", funtag);
						$$ = funtag;
					};

for_exp: PUNTOCOMA expression
{
	if($2->type != BOOL_TYPE) taberror("for expression can only be boolean");

	fprintf(maquina, "\tR0=U(R7);\n");
	funtag++;
	fprintf(maquina, "\tR7=R7+4;\n");
	fprintf(maquina, "\tIF(!R0) GT(%d); // for expresion\n", funtag);

	push_break(funtag);

	$$ = funtag;
};

for_op: id_assig MASIGUAL expression {
						$$ = (Operacion*) NULL;
					} |
					id_assig MENOSIGUAL expression {
						$$ = (Operacion*) NULL;
					} |
					id_assig INCR {
						Operacion* op = malloc(sizeof(Operacion));
						op->var = $1;
						op->op = INCR_OP;
						$$ = op;

						funtag++;
						push_continue(funtag);
					} |
					id_assig DECR {
						Operacion* op = malloc(sizeof(Operacion));
						op->var = $1;
						op->op = DECR_OP;
						$$ = op;

						funtag++;
						push_continue(funtag);
					} ;

for_stat: for_assig
					for_exp
					PUNTOCOMA for_op CIERRAPARENTESIS {
						incr_scope();
					}
					body {
						fprintf(maquina, "L %d:\n", top_continue());
						if($4->op == INCR_OP && $4->var->datatype == INT_TYPE) {
							fprintf(maquina, "\tR0 = I(R6%d); // Incremento for\n", $4->var->address);
							fprintf(maquina, "\tR0 = R0 + 1;\n");
							fprintf(maquina, "\tI(R6%d) = R0;\n", $4->var->address);
						}
						if($4->op == DECR_OP && $4->var->datatype == INT_TYPE) {
							fprintf(maquina, "\tR0 = I(R6%d); // Incremento for\n", $4->var->address);
							fprintf(maquina, "\tR0 = R0 - 1;\n");
							fprintf(maquina, "\tI(R6%d) = R0;\n", $4->var->address);
						}

						fprintf(maquina, "\tGT(%d); // itera for\n", $1);
						fprintf(maquina, "\tL %d: // fin for\n", $2);

						pop_break();
						pop_continue();

						// Statement
						Statement* st = $7;
						while(st->next != NULL) {
							st = st->next;
						}
						st->next = (Statement*) malloc(sizeof(Statement));
						st->next->scope = get_scope();
						st->next->category = FOR_STAT;
						st->next->next = (Statement*) NULL;
						$$ = $7;
					};


if_head: IF ABREPARENTESIS expression CIERRAPARENTESIS {

						if($3->type != BOOL_TYPE) taberror("if only accept bool type");

						fprintf(maquina, "\tR0=U(R7); // valor expresion en if\n");
						fprintf(maquina, "\tR7=R7+4; // baja puntero \n");
						funtag++;
						fprintf(maquina, "\tIF(!R0) GT(%d);\n", funtag);

						$$ = funtag;
						incr_scope();
				 };

else_if_st: else_if_st ELSE IF ABREPARENTESIS expression CIERRAPARENTESIS {
							incr_scope();
						} body |
						ELSE IF ABREPARENTESIS expression CIERRAPARENTESIS {
							incr_scope();
						} body {
						};

else_st: ELSE {incr_scope();} body {$$ = $3;} | {$$ = (Statement*) NULL;};

else_body: else_if_st
						else_st {$$ = $2;}|
	 				 	else_st {$$ = $1;};

if_init: if_head
				 body {
				 		funtag++;
				  	fprintf(maquina, "\tGT(%d); // salta a finsi\n", funtag);

				 		fprintf(maquina, "L %d: // else \n", $1);

						Statement* st = (Statement*) malloc(sizeof(Statement));
						int* tags = (int*) malloc(sizeof(int));
						tags[0] = funtag;
						st->tags = tags;
						st->scope = get_scope();

						Statement* b = $2;
						while(b->next != NULL) b = b->next;
						b->next = st;

						$$ = $2;
					};

if_stat: if_init
				 else_body {
				 		Statement* ifst = $1;
						while(ifst->next != NULL) ifst = ifst->next;

				 		fprintf(maquina, "L %d: // fin si \n", ifst->tags[0]);

						// stats


						Statement* st = $1;
						while(st->next != NULL) {
							st = st->next;
						}
						st->next = $2;

						$$ = $1;
				 };

parametro: parametro COMA expression {
							Param *p = (Param*) $1;
							Param *prev = NULL;

							while(p != NULL) {
								prev = p;
								p = p->next;
							}

							Param* temp = (Param *) malloc(sizeof(sizeof(Param)));
							temp->type = $3->type;
							temp->category = $3->category;
							temp->next = (Param *)malloc(sizeof(Param));
							prev->next = temp;
							temp->next = NULL;

							$$ = $1;
					 }
					 | expression {
						 Param *p = (Param*) malloc(sizeof(Param));

						 p->type = $1->type;
						 p->category = $1->category;
						 p->next = NULL;
						 $$ = p;

					 } ;

parametros: parametro {

								$$ = $1;
						} | {
								$$ = (Param*) NULL;
						};

function_call_id: IDENTIF {
	char * name = yylval.id;
	int temp = get_scope_func();

	set_scope_func(0);
	$$ = lookup_scope(name, 0, 0);
	set_scope_func(temp);

} ;

function_call: function_call_id ABREPARENTESIS parametros CIERRAPARENTESIS {

	Param* call_param = $3;

	node* n = $1;
	if(n == NULL) taberror("Not defined function");
	Param* expected = n->params;



	while(call_param != NULL && expected != NULL) {


		int type_call = call_param->type;
		int type_expe = expected->type;

		int cat_call  = call_param->category;
		int cat_expe	= expected->category;

		if(type_call != type_expe || cat_call != cat_expe) {
			char error[100];
			strcat(error,  n->name);
			strcat(error,  " param type error ");

			taberror(error);
		}

		call_param = call_param->next;
		expected = expected->next;
	}
	fprintf(maquina, "\t// asigna parametros\n");

	if(call_param != NULL || expected != NULL) taberror("number parameters error");

	Statement* p = (Statement*) malloc(sizeof(Statement));
	p->type = n->datatype;
	p->category = n->type;
	p->scope = get_scope();
	p->next = (Statement*) NULL;
	$$ = p;

	// compilador

	funtag++;
	fprintf(maquina, "\tR7=R7-4;\n");
	fprintf(maquina, "\tP(R7)=R6;\n");

	fprintf(maquina, "\tR7=R7-4;\n");
	fprintf(maquina, "\tP(R7)=%d;\n", funtag);

	fprintf(maquina, "\tR0=R7; // Puntero a posicion valores de parametros\n");

	fprintf(maquina, "\tGT(%d); // llama a funcion %s\n", n->function_tag, n->name);
	fprintf(maquina, "L %d: // vuelve funcion\n", funtag);

	call_param = $3;
	fprintf(maquina, "// borra parametros\n");
	fprintf(maquina, "\tR7=R7+4; // elimina dir R6 de pila\n");
	fprintf(maquina, "\tR7=R7+4; // elimina etiqueta de pila\n");
	while(call_param != NULL) {
		if(call_param->type == FLOAT_TYPE || call_param->type == DOUBLE_TYPE) {
			fprintf(maquina, "\tR7=R7+8; // elimina parametro de pila\n");
		} else {
			fprintf(maquina, "\tR7=R7+4; // elimina parametro de pila\n");
		}
		call_param = call_param->next;
	}

	switch(n->datatype) {
		case INT_TYPE:
			fprintf(maquina, "\tR7=R7-4;\n");
			fprintf(maquina, "\tI(R7)=R0;\n");
			break;
		case FLOAT_TYPE:
			fprintf(maquina, "\tR7=R7-8;\n");
			fprintf(maquina, "\tF(R7)=RR0;\n");
			break;
		case DOUBLE_TYPE:
			fprintf(maquina, "\tR7=R7-8;\n");
			fprintf(maquina, "\tD(R7)=RR0;\n");
			break;
			break;
		case CHAR_TYPE:
			fprintf(maquina, "\tR7=R7-4;\n");
			fprintf(maquina, "\tU(R7)=R0;\n");
			break;
		case BOOL_TYPE:
			fprintf(maquina, "\tR7=R7-4;\n");
			fprintf(maquina, "\tU(R7)=R0;\n");
			break;
		case BYTE_TYPE:
			fprintf(maquina, "\tR7=R7-4;\n");
			fprintf(maquina, "\tU(R7)=R0;\n");
			break;
		default:
			break;
	}

};

param_decl: declaration { $$ = $1;} | declaration_array { $$ = $1;};

parametro_def: parametro_def COMA param_decl {

							 		Param *p = (Param*) $1;
									Param *prev = NULL;

									while(p != NULL)
									{
										prev = p;
										p = p->next;
									}

									Param* temp = (Param *) malloc(sizeof(Param));
									node* decl = (node*)$3;
									temp->type = decl->datatype;
									temp->name = decl->name;
									temp->category = decl->type;
									temp->next = (Param *)malloc(sizeof(Param));
									//decl->scope += 1;
									prev->next = temp;
									temp->next = NULL;

									$$ = $1;

							 } |
 							 param_decl {

							 		Param *p = (Param*) malloc(sizeof(Param));
									node* decl = (node *)$1;

									//decl->scope += 1;

									p->name = decl->name;
									p->category = decl->type;
									p->type = decl->datatype;

									p->next = NULL;

									$$ = p;

							 };

parametros_def: parametro_def {
									$$ = $1;
								} | /* No params */
								{
									$$ = (Param*)NULL;
								};

body: ABRELLAVE stats CIERRALLAVE {hide_scope(); $$ = $2; };

main_def: DEF INTPAL MAIN {


						fm = 0;

						fprintf(maquina, "L 1: R6=R7;// definicion de funcion main\n");

						fprintf(maquina, "\tR7=R7-4; // reserva espacio para R6\n");
						fprintf(maquina, "\tR1=P(R0+4); // toma R6 de memoria\n");
						fprintf(maquina, "\tP(R6-4)=R1; // almacena R6 en pila (R6-4)\n");
						fprintf(maquina, "\tR7=R7-4; // reserva espacio para la etiqueta de retorno\n");
						fprintf(maquina, "\tR1=P(R0); // toma R6 de memoria\n");
						fprintf(maquina, "\tP(R6-8)=R1; // almacena R6 en pila (R6-8)\n");
						fprintf(maquina, "\tR0=R0+8; // desplaza R0 hasta la direccion donde estan los parametros\n");
						fm-=8; // mover framepointer despues de R6 y etiqueta



					} ABREPARENTESIS CIERRAPARENTESIS {
						char * name = "main";
						insert(name, strlen(name), FUNCTION_CAT, lineno);
						node* n = lookup_scope("main", get_scope(), get_scope_func());
						n->datatype = INT_TYPE;
						n->type = FUNCTION_CAT;
						n->params = (Param*) NULL;

						n->function_tag = 1;

						incr_scope();
						incr_scope_func();
					} body {
						Statement* st = $8;
						while(st != NULL) {
							if(st->type != INT_TYPE && st->category == RETURN_STAT) {
								char error[100];
								strcat(error, "main function cannot return ");
								strcat(error, datatypeToString(st->type));
								strcat(error, " value");
								taberror(error);
							}
							st = st->next;
						}
					};


function_identif: IDENTIF {
										int temp = get_scope_func();

										set_scope_func(0);
										insert(yylval.id, strlen(yylval.id), FUNCTION_CAT, lineno);
										set_scope_func(temp);


										$$ = lookup_scope(yylval.id, 0, 0);
									};

function_def: DEF type function_identif
							{
									node *n = $3;
									funtag++;
									fprintf(maquina, "L %d: R6=R7; // definicion de funcion %s\n", funtag, n->name);

									fprintf(maquina, "\tR7=R7-4; // reserva espacio para R6\n");
									fprintf(maquina, "\tR1=P(R0+4); // toma R6 de memoria\n");
									fprintf(maquina, "\tP(R6-4)=R1; // almacena R6 en pila (R6-4)\n");
									fprintf(maquina, "\tR7=R7-4; // reserva espacio para la etiqueta de retorno\n");
									fprintf(maquina, "\tR1=P(R0); // toma R6 de memoria\n");
									fprintf(maquina, "\tP(R6-8)=R1; // almacena R6 en pila (R6-8)\n");
									fprintf(maquina, "\tR0=R0+8; // desplaza R0 hasta la direccion donde estan los parametros\n");

									incr_scope();
									incr_scope_func();
									fm = -8;

							} ABREPARENTESIS parametros_def CIERRAPARENTESIS {

									node *n = $3;
									n->datatype = $2;
									n->type = FUNCTION_CAT;
									n->scope_func = 0;
									n->params = $6;
									n->type_return = $2;



									n->function_tag = funtag;

									// compilador
									// cuenta numero parametros
									Param* params = $6;
									int num_params= 0;
									while(params != NULL) {
										num_params++;
										params = params->next;
									}



									Param* parametros = $6;



									// invierte parametros
									node** vars = malloc(sizeof(node) * num_params);
									for(int i = num_params-1; i >=0 && parametros != NULL; i--) {
										vars[i] = lookup_scope(parametros->name, get_scope(), get_scope_func());

										parametros = parametros->next;
									}



									// asigna valores a parametros en orden inverso
									fprintf(maquina, "// ahora en R0 está la direccion donde se almacenan los valores de parametros\n");
									for(int i = 0; i < num_params; i++) {


										int addr = vars[i]->address;

										if(vars[i]->datatype == INT_TYPE) {

											fprintf(maquina, "\tR1=I(R0);\n");
											fprintf(maquina, "\tI(R6%d)=R1;\n", addr);
											fprintf(maquina, "\tR0=R0+4;\n");
										}

										if(vars[i]->datatype == FLOAT_TYPE) {
											fprintf(maquina, "\tRR1=F(R0);\n");
											fprintf(maquina, "\tF(R6%d)=RR1;\n", addr);
											fprintf(maquina, "\tR0=R0+8;\n");
										}

										if(vars[i]->datatype == DOUBLE_TYPE) {
											fprintf(maquina, "\tRR1=D(R0);\n");
											fprintf(maquina, "\tD(R6%d)=RR1;\n", addr);
											fprintf(maquina, "\tR0=R0+8;\n");
										}

										if(vars[i]->datatype == BOOL_TYPE) {
											fprintf(maquina, "\tR1=U(R0);\n");
											fprintf(maquina, "\tU(R6%d)=R1;\n", addr);
											fprintf(maquina, "\tR0=R0+4;\n");
										}

										if(vars[i]->datatype == BYTE_TYPE) {
											fprintf(maquina, "\tR1=U(R0);\n");
											fprintf(maquina, "\tU(R6%d)=R1;\n", addr);
											fprintf(maquina, "\tR0=R0+4;\n");
										}

										if(vars[i]->datatype == CHAR_TYPE) {
											fprintf(maquina, "\tR1=U(R0);\n");
											fprintf(maquina, "\tU(R6%d)=R1;\n", addr);
											fprintf(maquina, "\tR0=R0+4;\n");
										}
									}
							} body {

								Statement* st = $9;
								while(st != NULL) {
									if($2 == VOID_TYPE && st->category == RETURN_STAT) {
										char error[100];
										strcat(error, $3->name);
										strcat(error, " void function not accept return statement");
										taberror(error);


									} else if(st->type != $2 && st->category == RETURN_STAT) {
										char error[100];
										strcat(error, $3->name);
										strcat(error, " function cannot return ");
										strcat(error, datatypeToString(st->type));
										strcat(error, " value");
										taberror(error);


									}
									st = st->next;
								}

								fprintf(maquina, "\tR5=P(R6-8); // saca etiqueta\n");
								fprintf(maquina, "\tR7=R7+4;\n");

								fprintf(maquina, "\tR1=P(R6-4); // sacamos R6 de donde se almacenó al llamar a la funcion\n");
								fprintf(maquina, "\tR7=R7+4;\n");

								fprintf(maquina, "\tR7=R6;\n");
								fprintf(maquina, "\tR6=R1;\n");


								fprintf(maquina, "\tGT(R5); // retorna sin usar return funcion\n");

							} |
							DEF type array function_identif {
								funtag++;
								fprintf(maquina, "L %d:\n", funtag);

								incr_scope();
							} ABREPARENTESIS parametros_def CIERRAPARENTESIS {
								node *n = $4;

								n->datatype = $2;

								n->type = FUNCTION_CAT;
								n->params = (Param *) $7;
								n->type_return = ARRAY;
							} body;

array_size: ABRECORCHETE expression CIERRACORCHETE |
            ABRECORCHETE expression CIERRACORCHETE array_size;

array_values: array_values COMA expression | expression;

array_mat: ABRECORCHETE array_values CIERRACORCHETE COMA array_mat |
           ABRECORCHETE array_values CIERRACORCHETE |
           array_values;

array_init: ABRECORCHETE array_mat CIERRACORCHETE ;

assigment: declaration IGUAL expression {

					 		node *n = $1;
							int tipo = $3->type;
							if(n->datatype != tipo) {
								char error[100];
								strcat(error, "types do not match: ");
								strcat(error, datatypeToString(tipo));
								strcat(error,  " can not be assigned to ");
								strcat(error, datatypeToString(n->datatype));
								taberror(error);
							}

							int addr = n->address;
							if(n->scope == 0) {
								fprintf(maquina, "\tR1=%#x;\n", addr);
							} else {
								fprintf(maquina, "\tR1=R6%d;\n", addr);
							}

							if(tipo == INT_TYPE) {
								fprintf(maquina, "\tR2=I(R7);\n");
								fprintf(maquina, "\tI(R1)=R2;\n");
								fprintf(maquina, "\tR7=R7+4;");
							}
							if(tipo == FLOAT_TYPE) {
								fprintf(maquina, "\tRR0=F(R7);\n");
								fprintf(maquina, "\tF(R1)=RR0;\n");
								fprintf(maquina, "\tR7=R7+8;");
							}
							if(tipo == DOUBLE_TYPE) {
								fprintf(maquina, "\tRR0=D(R7);\n");
								fprintf(maquina, "\tD(R1)=RR0;\n");
								fprintf(maquina, "\tR7=R7+8;");
							}
							if(tipo == CHAR_TYPE) {
								fprintf(maquina, "\tR2=U(R7);\n");
								fprintf(maquina, "\tU(R1)=R2;\n");
								fprintf(maquina, "\tR7=R7+4;");
							}
							if(tipo == BYTE_TYPE) {
								fprintf(maquina, "\tR2=I(R7);\n");
								fprintf(maquina, "\tI(R1)=R2;\n");
								fprintf(maquina, "\tR7=R7+4;");
							}
							if(tipo == BOOL_TYPE) {
								fprintf(maquina, "\tR2=U(R7);\n");
								fprintf(maquina, "\tU(R1)=R2;\n");
								fprintf(maquina, "\tR7=R7+4;");
							}

							fprintf(maquina, " // asignacion variable %s \n", n->name);

							Statement* st = (Statement*) malloc(sizeof(Statement));
							st->type = tipo;
							st->category = ASIG_STAT;
							st->scope = get_scope();
							st->next = (Statement*)NULL;
							$$ = st;
					 } |
					 declaration_array IGUAL expression { $$ = (Statement*) NULL; } |
           declaration_array IGUAL type array_size { $$ = (Statement*) NULL; } |
           declaration_array IGUAL array_init { $$ = (Statement*) NULL; } |
					 asignacion { $$ = $1; } ;

id_assig: IDENTIF {

	int scope_f = get_scope();
	node *f = lookup_scope(yylval.id, scope_f, get_scope_func());
	while(f == NULL && scope_f != 0) {
		scope_f--;
		f = lookup_scope(yylval.id, scope_f, get_scope_func());
	}
	if(f == NULL) {
		f = lookup_scope(yylval.id, 0, 0);
	}

	if(f == NULL) taberror("not declared variable");
	$$ = f;
};

asignacion:id_assig IGUAL expression {
					 		int tipo_id  = $1->datatype;
							int tipo_exp = $3->type;
							if(tipo_id != tipo_exp) {
								char error[100];
								strcat(error, "types do not match: ");
								strcat(error, datatypeToString(tipo_exp));
								strcat(error,  " can not be assigned to ");
								strcat(error, datatypeToString(tipo_id));
								taberror(error);
							}

							int addr = $1->address;
							if($1->scope != 0) {
								fprintf(maquina, "\tR1=R6%d;\n", addr);
							} else {
								fprintf(maquina, "\tR1=%#x;\n", addr);
							}

							if(tipo_id == INT_TYPE) {
								fprintf(maquina, "\tR2=I(R7);\n");
								fprintf(maquina, "\tI(R1)=R2;\n");
							}
							if(tipo_id == FLOAT_TYPE) {
								fprintf(maquina, "\tRR0=F(R7);\n");
								fprintf(maquina, "\tF(R1)=RR0;\n");
							}
							if(tipo_id == DOUBLE_TYPE) {
								fprintf(maquina, "\tRR0=D(R7);\n");
								fprintf(maquina, "\tD(R1)=RR0;\n");
							}
							if(tipo_id == CHAR_TYPE) {
								fprintf(maquina, "\tR2=U(R7);\n");
								fprintf(maquina, "\tU(R1)=R2;\n");
							}
							if(tipo_id == BYTE_TYPE) {
								fprintf(maquina, "\tR2=I(R7);\n");
								fprintf(maquina, "\tU(R1)=R2;\n");
							}
							if(tipo_id == BOOL_TYPE) {
								fprintf(maquina, "\tR2=U(R7);\n");
								fprintf(maquina, "\tU(R1)=R2;\n");
							}
							fprintf(maquina, "\tR7=R7+4;");
							fprintf(maquina, " // asignacion variable %s \n", $1->name);

							Statement* st = (Statement*) malloc(sizeof(Statement));
							st->type = tipo_id;
							st->category = ASIG_STAT;
							st->next = (Statement*) NULL;

							$$ = st;
					 }|
					 id_assig MASIGUAL expression {
					  	int tipo_id  = $1->datatype;
					  	int tipo_exp = $3->type;
					  	if(tipo_id != tipo_exp) {
								char error[100];
								strcat(error, "types do not match: ");
								strcat(error, datatypeToString(tipo_exp));
								strcat(error,  " can not be assigned to ");
								strcat(error, datatypeToString(tipo_id));
								taberror(error);
					  	}
							int addr = $1->address;
							if($1->scope != 0) {
								fprintf(maquina, "\tR1=R6%d;\n", addr);
							} else {
								fprintf(maquina, "\tR1=%#x;\n", addr);
							}

							if(tipo_id == INT_TYPE) {
								fprintf(maquina, "\tR2=I(R7);\n");
								fprintf(maquina, "\tR3=I(R1);\n");
								fprintf(maquina, "\tR3=R3+R2;\n");
								fprintf(maquina, "\tI(R1)=R3;\n");
							}

							Statement* st = (Statement*) malloc(sizeof(Statement));
							st->type = tipo_id;
							st->category = ASIG_STAT;
							st->next = (Statement*) NULL;

							$$ = st;
					 }|
					 id_assig MENOSIGUAL expression {
					  	int tipo_id  = $1->datatype;
					  	int tipo_exp = $3->type;
					  	if(tipo_id != tipo_exp) {
								char error[100];
								strcat(error, "types do not match: ");
								strcat(error, datatypeToString(tipo_exp));
								strcat(error,  " can not be assigned to ");
								strcat(error, datatypeToString(tipo_id));
								taberror(error);
					  	}

							int addr = $1->address;
							if($1->scope != 0) {
								fprintf(maquina, "\tR1=R6%d;\n", addr);
							} else {
								fprintf(maquina, "\tR1=%#x;\n", addr);
							}

							if(tipo_id == INT_TYPE) {
								fprintf(maquina, "\tR2=I(R7);\n");
								fprintf(maquina, "\tR3=I(R1);\n");
								fprintf(maquina, "\tR3=R3-R2;\n");
								fprintf(maquina, "\tI(R1)=R3;\n");
							}

							Statement* st = (Statement*) malloc(sizeof(Statement));
							st->type = tipo_id;
							st->category = ASIG_STAT;
							st->next = (Statement*) NULL;

							$$ = st;
					 }|
					 id_assig MULTIGUAL expression {
					  	int tipo_id  = $1->datatype;
					  	int tipo_exp = $3->type;
					  	if(tipo_id != tipo_exp) {
								char error[100];
								strcat(error, "types do not match: ");
								strcat(error, datatypeToString(tipo_exp));
								strcat(error,  " can not be assigned to ");
								strcat(error, datatypeToString(tipo_id));
								taberror(error);
					  	}

							int addr = $1->address;
							if($1->scope != 0) {
								fprintf(maquina, "\tR1=R6%d;\n", addr);
							} else {
								fprintf(maquina, "\tR1=%#x;\n", addr);
							}

							if(tipo_id == INT_TYPE) {
								fprintf(maquina, "\tR2=I(R7);\n");
								fprintf(maquina, "\tR3=I(R1);\n");
								fprintf(maquina, "\tR3=R3*R2;\n");
								fprintf(maquina, "\tI(R1)=R3;\n");
							}

							Statement* st = (Statement*) malloc(sizeof(Statement));
							st->type = tipo_id;
							st->category = ASIG_STAT;
							st->next = (Statement*) NULL;

							$$ = st;
					 }|
					 id_assig DIVIGUAL expression {
					  	int tipo_id  = $1->datatype;
					  	int tipo_exp = $3->type;
					  	if(tipo_id != tipo_exp) {
								char error[100];
								strcat(error, "types do not match: ");
								strcat(error, datatypeToString(tipo_exp));
								strcat(error,  " can not be assigned to ");
								strcat(error, datatypeToString(tipo_id));
								taberror(error);
					  	}

							int addr = $1->address;
							if($1->scope != 0) {
								fprintf(maquina, "\tR1=R6%d;\n", addr);
							} else {
								fprintf(maquina, "\tR1=%#x;\n", addr);
							}

							if(tipo_id == INT_TYPE) {
								fprintf(maquina, "\tR2=I(R7);\n");
								fprintf(maquina, "\tR3=I(R1);\n");
								fprintf(maquina, "\tR3=R3/R2;\n");
								fprintf(maquina, "\tI(R1)=R3;\n");
							}

							Statement* st = (Statement*) malloc(sizeof(Statement));
							st->type = tipo_id;
							st->category = ASIG_STAT;
							st->next = (Statement*) NULL;

							$$ = st;
					 }|
					 id_assig array_acceso IGUAL expression {$$ = (Statement*) NULL;} |
					 id_assig INCR {
					 	 int tipo_id  = $1->datatype;
						 int addr = $1->address;
						 if($1->scope != 0) {
							 fprintf(maquina, "\tR1=R6%d;\n", addr);
						 } else {
							 fprintf(maquina, "\tR1=%#x;\n", addr);
						 }

						 if(tipo_id == INT_TYPE) {
							 fprintf(maquina, "\tR2=I(R1);\n");
							 fprintf(maquina, "\tR2=R2+1;\n");
							 fprintf(maquina, "\tI(R1)=R2;\n");
						 } else {
						 	taberror("type must be integer");
						 }

						 Statement* st = (Statement*) malloc(sizeof(Statement));
						 st->type = tipo_id;
						 st->category = ASIG_STAT;
						 st->next = (Statement*) NULL;

						 $$ = st;
					 } |
					 INCR id_assig {
					 	 int tipo_id  = $2->datatype;
						 int addr = $2->address;
						 if($2->scope != 0) {
							 fprintf(maquina, "\tR1=R6%d;\n", addr);
						 } else {
							 fprintf(maquina, "\tR1=%#x;\n", addr);
						 }

						 if(tipo_id == INT_TYPE) {
							 fprintf(maquina, "\tR2=I(R1);\n");
							 fprintf(maquina, "\tR2=R2+1;\n");
							 fprintf(maquina, "\tI(R1)=R2;\n");
						 } else {
						 	taberror("type must be integer");
						 }

						 Statement* st = (Statement*) malloc(sizeof(Statement));
						 st->type = tipo_id;
						 st->category = ASIG_STAT;
						 st->next = (Statement*) NULL;

						 $$ = st;
					 } |
					 id_assig DECR {
					 	 int tipo_id  = $1->datatype;
						 int addr = $1->address;
						 if($1->scope != 0) {
							 fprintf(maquina, "\tR1=R6%d;\n", addr);
						 } else {
							 fprintf(maquina, "\tR1=%#x;\n", addr);
						 }

						 if(tipo_id == INT_TYPE) {
							 fprintf(maquina, "\tR2=I(R1);\n");
							 fprintf(maquina, "\tR2=R2-1;\n");
							 fprintf(maquina, "\tI(R1)=R2;\n");
						 } else {
						 	taberror("type must be integer");
						 }

						 Statement* st = (Statement*) malloc(sizeof(Statement));
						 st->type = tipo_id;
						 st->category = ASIG_STAT;
						 st->next = (Statement*) NULL;

						 $$ = st;
					 } |
					 DECR id_assig {
					 	 int tipo_id  = $2->datatype;
						 int addr = $2->address;
						 if($2->scope != 0) {
							 fprintf(maquina, "\tR1=R6%d;\n", addr);
						 } else {
							 fprintf(maquina, "\tR1=%#x;\n", addr);
						 }

						 if(tipo_id == INT_TYPE) {
							 fprintf(maquina, "\tR2=I(R1);\n");
							 fprintf(maquina, "\tR2=R2-1;\n");
							 fprintf(maquina, "\tI(R1)=R2;\n");
						 } else {
						 	taberror("type must be integer");
						 }

						 Statement* st = (Statement*) malloc(sizeof(Statement));
						 st->type = tipo_id;
						 st->category = ASIG_STAT;
						 st->next = (Statement*) NULL;

						 $$ = st;
					 } ;

%%

void yyerror ()
{
  fprintf(stderr, "Syntax error at line %d\n", lineno);
  exit(1);
}

void taberror (char *error)
{
	fprintf(stderr, error);
	fprintf(stderr, " in line %d\n", lineno);

	fclose(maquina);
	remove(maqfile);

	exit(1);
}

int main (int argc, char *argv[]){
	char *file = NULL; // fichero entrada
	maqfile = "maquina.q.c"; // fichero salida

	int debug_flag = 0;

	opterr = 0;

	int c;
	while((c = getopt(argc, argv, "go:i:")) != -1) {

		switch(c) {
			case 'g':
				debug_flag = 1;
				break;
			case 'o':
				maqfile = optarg;
				break;
			case 'i':
				file = optarg;
				break;
			case '?':
				if(optopt == 'o') {
					fprintf(stderr, "Option -%c requires an argument.\n", optopt);
					fprintf(stderr, "\t ./tkc [-g] [-o maquina.q.c] -i file.tk \n");
				} else if(optopt == 'i') {
						fprintf(stderr, "Option -%c requires an argument.\n", optopt);
						fprintf(stderr, "\t ./tkc [-g] [-o maquina.q.c] -i file.tk \n");
				} else if(isprint(optopt)) {
					fprintf(stderr, "Unknown option -%c.\n", optopt);
					fprintf(stderr, "\t ./tkc [-g] [-o maquina.q.c] -i file.tk \n");
				} else {
					fprintf(stderr, "Unknown option character -%c.\n", optopt);
					fprintf(stderr, "\t ./tkc [-g] [-o maquina.q.c] -i file.tk \n");
				}
				break;
			default:
				fprintf(stderr, "incompatible compiler params:\n");
				fprintf(stderr, "\t ./tkc [-g] [-o maquina.q.c] -i file.tk \n");
				abort();
		}
	}

	if(file == NULL) {
		fprintf(stderr, "please specify an input file\n");
		fprintf(stderr, "\t ./tkc [-g] [-o maquina.q.c] -i file.tk\n");
		return -1;
	}


	maquina = fopen(maqfile, "w");


	// initialize symbol table
	init_table();
	init_stack_break();
	init_stack_continue();

	// parsing
	int flag;
	yyin = fopen(file, "r");

	sm = 0x12000;

	fprintf(maquina, "#include \"Q.h\"\n");
	fprintf(maquina, "BEGIN\n");
	fprintf(maquina, "L 0: R6 = R7;\n");
	flag = yyparse();
	fprintf(maquina, "\tGT(-2);\n");
	fprintf(maquina, "END\n");


	fclose(maquina);

	fclose(yyin);

	if(debug_flag == 1) {
		writetable();
	}

	return flag;
}
