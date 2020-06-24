%{
	#include "symbol_table.h"
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>

	FILE * maquina;

	int funtag = 1;

	int sm = 0x12000;
	int stat = 0;

	int inner_fin = -1; // el break solo afecta a for internos
	int inner_ini = -1; // el continue solo afecta a for internos

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
%token  MENOS ELEVADO DESPLAZAMIENTOIZQ DESPLAZAMIENTODERECHA XOR DEF IN
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
%type<params> function_call
%type<item> declaration_array
%type<item> param_decl
%type<params> splice_call
%type<params> stats
%type<params> body
%type<tag> if_stat
%type<tag> if_head
%type<tag> if_init
%type<multitag> while_head
%type<tag> while_tk
%type<tag> for_assig
%type<tag> for_exp
%type<operacion> for_asig


%%

global_amb: global_var {fprintf(maquina, "\tGT(1); // salta a main \n");} |
											 {fprintf(maquina, "\tGT(1); // salta a main \n");} ;

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
	node *f = lookup_scope(yylval.id, get_scope());
	f->datatype = $1;
	$$ = f;
};
declaration: type IDENTIF
{
				node *check = lookup_scope(yylval.id, get_scope());
				if(check != NULL) taberror("redeclared variable");
				insert(yylval.id, strlen(yylval.id), VARIABLE_CAT, lineno);
				node *f = (node *) lookup_scope(yylval.id, get_scope());
				f->datatype = $1;

				if($1 == DOUBLE_TYPE) {
					fprintf(maquina, "\tR7=R7-8; // reserva espacio para variable %s\n", f->name);
					sm -= 8;
				} else {
					fprintf(maquina, "\tR7=R7-4; // reserva espacio para variable %s\n", f->name);
					sm -= 4;
				}
				f->address = sm;

				$$ = f;
};

array_acceso: ABRECORCHETE expression CIERRACORCHETE array_acceso
							| ABRECORCHETE expression CIERRACORCHETE;

variable: IDENTIF {
						char* name = yylval.id;
						node *f = lookup_scope(name, get_scope());
						if(f == NULL) {
							char error[100];
							strcat(error,  "no declared name ");
							strcat(error,  f->name);
							taberror(error);
						}
						$$ = f;
					} | IDENTIF array_acceso
					{
						node *f = lookup_scope(yylval.id, get_scope());
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

stats: assigment stats { $$ = $2; } |
			 declaration stats { $$ = $2; } |
			 declaration_array stats { $$ = $2; } |
			 function_call stats { $$ = $2; } |
			 if_stat stats { $$ = $2; } |
			 for_stat stats { $$ = $2; } |
			 forin_stat stats { $$ = $2; } |
			 while_stat stats { $$ = $2; } |
			 CONTINUE stats { $$ = $2; } |
			 BREAK stats { $$ = $2; } |
			 print_call stats { $$ = $2; } |
			 println_call stats { $$ = $2; } |
			 PASS stats { $$ = $2; } |
			 assigment { $$ = (Param*)NULL; } |
			 declaration { $$ = (Param*)NULL; } |
			 declaration_array { $$ = (Param*)NULL; } |
			 function_call { $$ = (Param*)NULL; } |
			 if_stat { $$ = (Param*)NULL;; } |
			 for_stat { $$ = (Param*)NULL; } |
			 forin_stat { $$ = (Param*)NULL; } |
			 while_stat { $$ = (Param*)NULL; } |
			 print_call { $$ = (Param*)NULL; } |
			 println_call { $$ = (Param*)NULL; } |
			 CONTINUE {
			 	 fprintf(maquina, "\tGT(%d); // continue\n", inner_ini);
				 $$ = (Param*)NULL;
			 } |
			 BREAK {
			 	 fprintf(maquina, "\tGT(%d);// break\n", inner_fin);
				 $$ = (Param*)NULL;
			 }|
			 RETURNPAL expression {
			 		$$ = $2;
					fprintf(maquina, "// al evaluar expresion se agrego resultado a pila\n");
					fprintf(maquina, "\tGT(R6); // vuelve a direccion de llamada\n");
			 } |
			 PASS { $$ = (Param*)NULL; fprintf(maquina, "// body vacio\n");}
			 ;

expression:
  expression MAS expression {
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		$$ = $1;
		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0+R1; // suma expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tI(R7)=R0; // guarda suma en pila\n");
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tRR0=F(R7+8);\n");
			fprintf(maquina, "\tRR1=F(R7);\n");
			fprintf(maquina, "\tRR0=RR0+RR1; // suma expresion\n");
			fprintf(maquina, "\tR7=R7+8;\n");
			sm+=8;
			fprintf(maquina, "\tF(R7)= RR0; // guarda suma en pila\n");
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tRR0=D(R7+8);\n");
			fprintf(maquina, "\tRR1=D(R7);\n");
			fprintf(maquina, "\tRR0=RR0+RR1; // suma expresion\n");
			fprintf(maquina, "\tR7=R7+8;\n");
			sm+=8;
			fprintf(maquina, "\tD(R7)= RR0; // guarda suma en pila\n");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0+R1; // suma expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)=R0; // guarda suma en pila\n");
		}
	} |
  expression MENOS expression {
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		$$ = $1;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0-R1; // resta expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tI(R7)=R0; // guarda respetar en pila\n");
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tRR0=F(R7+8);\n");
			fprintf(maquina, "\tRR1=F(R7);\n");
			fprintf(maquina, "\tRR0=RR0-RR1; // resta expresion\n");
			fprintf(maquina, "\tR7=R7+8;\n");
			sm+=8;
			fprintf(maquina, "\tF(R7)= RR0; // guarda resta en pila\n");
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tRR0=D(R7+8);\n");
			fprintf(maquina, "\tRR1=D(R7);\n");
			fprintf(maquina, "\tRR0=RR0-RR1; // resta expresion\n");
			fprintf(maquina, "\tR7=R7+8;\n");
			sm+=8;
			fprintf(maquina, "\tD(R7)= RR0; // guarda resta en pila\n");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0-R1; // resta expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)=R0; // guarda resta en pila\n");
		}
	} |
  expression MULTIPLICACION expression {
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		$$ = $1;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0*R1; // multiplicacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tI(R7)=R0; // guarda multiplicacion en pila\n");
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tRR0=F(R7+8);\n");
			fprintf(maquina, "\tRR1=F(R7);\n");
			fprintf(maquina, "\tRR0=RR0*RR1; // multiplicacion expresion\n");
			fprintf(maquina, "\tR7=R7+8;\n");
			sm+=8;
			fprintf(maquina, "\tF(R7)= RR0; // guarda multiplicacion en pila\n");
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tRR0=D(R7+8);\n");
			fprintf(maquina, "\tRR1=D(R7);\n");
			fprintf(maquina, "\tRR0=RR0*RR1; // multiplicacion expresion\n");
			fprintf(maquina, "\tR7=R7+8;\n");
			sm+=8;
			fprintf(maquina, "\tD(R7)= RR0; // guarda multiplicacion en pila\n");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0*R1; // multiplicacion expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)=R0; // guarda multiplicacion en pila\n");
		}
	} |
  expression DIVISION expression {
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

			sm+=4;
			fprintf(maquina, "\tI(R7)=R0; // guarda division en pila\n");
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tRR0=F(R7+8);\n");
			fprintf(maquina, "\tRR1=F(R7);\n");
			fprintf(maquina, "\tIF(!RR1) GT(-13); // ERROR: division por cero\n");
			fprintf(maquina, "\tRR0=RR0/RR1; // division expresion\n");
			fprintf(maquina, "\tR7=R7+8;\n");
			sm+=8;
			fprintf(maquina, "\tF(R7)= RR0; // guarda division en pila\n");
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tRR0=D(R7+8);\n");
			fprintf(maquina, "\tRR1=D(R7);\n");
			fprintf(maquina, "\tIF(!RR1) GT(-13); // ERROR: division por cero\n");
			fprintf(maquina, "\tRR0=RR0/RR1; // division expresion\n");
			fprintf(maquina, "\tR7=R7+8;\n");
			sm+=8;
			fprintf(maquina, "\tD(R7)= RR0; // guarda division en pila\n");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tIF(!R1) GT(-13); // ERROR: division por cero\n");
			fprintf(maquina, "\tR0=R0/R1; // division expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)=R0; // guarda division en pila\n");
		}

	} |
	expression MODULO expression {
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		$$ = $1;
	} |
	expression AND expression {
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		$$ = $1;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0 & R1; // and expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			sm+=4;
			fprintf(maquina, "\tI(R7)=R0; // guarda and en pila\n");
		}

		if(tipo == BOOL_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0 & R1; // and expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			sm+=4;
			fprintf(maquina, "\tU(R7)=R0; // guarda and en pila\n");
		}

	} |
	expression OR expression {
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		$$ = $1;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0 | R1; // or expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			sm+=4;
			fprintf(maquina, "\tI(R7)=R0; // guarda or en pila\n");
		}

		if(tipo == BOOL_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0 | R1; // or expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			sm+=4;
			fprintf(maquina, "\tU(R7)=R0; // guarda or en pila\n");
		}

	} |
	expression XOR expression {
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = BOOL_TYPE;
		$$ = param;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0 ^ R1; // xor expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			sm+=4;
			fprintf(maquina, "\tI(R7)=R0; // guarda xor en pila\n");
		}

		if(tipo == BOOL_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0 ^ R1; // xor expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			sm+=4;
			fprintf(maquina, "\tU(R7)=R0; // guarda xor en pila\n");
		}
	} |
	NOT expression {
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
	}|
	expression IGUALA expression {
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = BOOL_TYPE;
		$$ = param;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0==R1; // igual expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			sm+=4;
			fprintf(maquina, "\tU(R7)=R0; // guarda boolean en pila\n");
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tRR0=F(R7+8);\n");
			fprintf(maquina, "\tRR1=F(R7);\n");
			fprintf(maquina, "\tR0=RR0==RR1; // igual expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)= R0; // guarda igual en pila\n");
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tRR0=D(R7+8);\n");
			fprintf(maquina, "\tRR1=D(R7);\n");
			fprintf(maquina, "\tR0=RR0==RR1; // igual expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)= R0; // guarda igual en pila\n");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0==R1; // igual expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)=R0; // guarda igual en pila\n");
		}
	} |
	expression MAYOR expression {
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = BOOL_TYPE;
		$$ = param;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0>R1; // igual expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			sm+=4;
			fprintf(maquina, "\tU(R7)=R0; // guarda boolean en pila\n");
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tRR0=F(R7+8);\n");
			fprintf(maquina, "\tRR1=F(R7);\n");
			fprintf(maquina, "\tR0=RR0>RR1; // igual expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)= R0; // guarda igual en pila\n");
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tRR0=D(R7+8);\n");
			fprintf(maquina, "\tRR1=D(R7);\n");
			fprintf(maquina, "\tR0=RR0>RR1; // igual expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)= R0; // guarda igual en pila\n");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0>R1; // igual expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)=R0; // guarda igual en pila\n");
		}
	} |
	expression MENOR expression {
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = BOOL_TYPE;
		$$ = param;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0<R1; // igual expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			sm+=4;
			fprintf(maquina, "\tU(R7)=R0; // guarda boolean en pila\n");
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tRR0=F(R7+8);\n");
			fprintf(maquina, "\tRR1=F(R7);\n");
			fprintf(maquina, "\tR0=RR0<RR1; // igual expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)= R0; // guarda igual en pila\n");
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tRR0=D(R7+8);\n");
			fprintf(maquina, "\tRR1=D(R7);\n");
			fprintf(maquina, "\tR0=RR0<RR1; // igual expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)= R0; // guarda igual en pila\n");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0<R1; // igual expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)=R0; // guarda igual en pila\n");
		}
	} |
	expression MAYORIGUAL expression {
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = BOOL_TYPE;
		$$ = param;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0>=R1; // comp expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			sm+=4;
			fprintf(maquina, "\tU(R7)=R0; // guarda boolean en pila\n");
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tRR0=F(R7+8);\n");
			fprintf(maquina, "\tRR1=F(R7);\n");
			fprintf(maquina, "\tR0=RR0>=RR1; // comp expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)= R0; // guarda bool en pila\n");
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tRR0=D(R7+8);\n");
			fprintf(maquina, "\tRR1=D(R7);\n");
			fprintf(maquina, "\tR0=RR0>=RR1; // comp expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)= R0; // guarda comp en pila\n");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0>=R1; // comp expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)=R0; // guarda comp en pila\n");
		}
	} |
	expression MENORIGUAL expression {
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = BOOL_TYPE;
		$$ = param;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0<=R1; // comp expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			sm+=4;
			fprintf(maquina, "\tU(R7)=R0; // guarda boolean en pila\n");
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tRR0=F(R7+8);\n");
			fprintf(maquina, "\tRR1=F(R7);\n");
			fprintf(maquina, "\tR0=RR0<=RR1; // comp expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)= R0; // guarda bool en pila\n");
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tRR0=D(R7+8);\n");
			fprintf(maquina, "\tRR1=D(R7);\n");
			fprintf(maquina, "\tR0=RR0<=RR1; // comp expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)= R0; // guarda comp en pila\n");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0<=R1; // comp expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)=R0; // guarda comp en pila\n");
		}
	} |
	expression DISTINTO expression {
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = BOOL_TYPE;
		$$ = param;

		int tipo = $1->type;

		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR0=I(R7+4);\n");
			fprintf(maquina, "\tR1=I(R7);\n");
			fprintf(maquina, "\tR0=R0!=R1; // comp expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");

			sm+=4;
			fprintf(maquina, "\tU(R7)=R0; // guarda boolean en pila\n");
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tRR0=F(R7+8);\n");
			fprintf(maquina, "\tRR1=F(R7);\n");
			fprintf(maquina, "\tR0=RR0!=RR1; // comp expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)= R0; // guarda bool en pila\n");
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tRR0=D(R7+8);\n");
			fprintf(maquina, "\tRR1=D(R7);\n");
			fprintf(maquina, "\tR0=RR0!=RR1; // comp expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)= R0; // guarda comp en pila\n");
		}
		if(tipo == BYTE_TYPE) {
			fprintf(maquina, "\tR0=U(R7+4);\n");
			fprintf(maquina, "\tR1=U(R7);\n");
			fprintf(maquina, "\tR0=R0!=R1; // comp expresion\n");
			fprintf(maquina, "\tR7=R7+4;\n");
			sm+=4;
			fprintf(maquina, "\tU(R7)=R0; // guarda comp en pila\n");
		}
	} |
	expression ELEVADO expression {
		/* Toma valor primera expresion */
		if($1->type != $3->type) taberror("types in the expression do not match");
		$$ = $1;
	} |
	expression DESPLAZAMIENTOIZQ expression {
		/* Toma valor primera expresion */
		if($1->type != BYTE_TYPE || $3->type != INT_TYPE) taberror("types in the expression do not match");
		$$ = $1;
	} |
	expression DESPLAZAMIENTODERECHA expression {
		/* Toma valor primera expresion */
		if($1->type != BYTE_TYPE || $3->type != INT_TYPE) taberror("types in the expression do not match");
		$$ = $1;
	} |
	ABREPARENTESIS expression CIERRAPARENTESIS
	{
		$$ = $2;
	} |
  constant {
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = $1.datatype;
		param->category = VARIABLE_CAT;
		param->val = $1.val;
		$$ = param;


		if($1.datatype == INT_TYPE) {
			fprintf(maquina, "\tR7=R7-4;\n");
			sm-=4;
			fprintf(maquina, "\tI(R7)=%d;", $1.val.int_val);
		}
		if($1.datatype == FLOAT_TYPE) {
			fprintf(maquina, "\tR7=R7-8;\n");
			sm-=8;
			fprintf(maquina, "\tF(R7)=%0.4f;", $1.val.float_val);
		}
		if($1.datatype == DOUBLE_TYPE) {
			fprintf(maquina, "\tR7=R7-8;\n");
			sm-=8;
			fprintf(maquina, "\tD(R7)=%0.4f;", $1.val.double_val);
		}
		if($1.datatype == CHAR_TYPE) {
			fprintf(maquina, "\tR7=R7-4;\n");
			sm-=4;
			fprintf(maquina, "\tU(R7)=\'%c\';", $1.val.char_val);
		}
		if($1.datatype == BYTE_TYPE) {
			fprintf(maquina, "\tR7=R7-4;\n");
			sm-=4;
			fprintf(maquina, "\tU(R7)=%d;", $1.val.byte_val);
		}
		if($1.datatype == BOOL_TYPE) {
			fprintf(maquina, "\tR7=R7-4;\n");
			sm-=4;
			fprintf(maquina, "\tU(R7)=%d;", $1.val.bool_val);
		}
		if($1.datatype == STR_TYPE) {
			char *s = $1.val.str_val;
			int len = strlen(s) + 1;

			int buf = 4 * (int)(len/2);
			buf = len % 2 == 0 ? buf : buf + 4;

			sm -= buf;

			fprintf(maquina, "STAT(%d)\n", stat);
			fprintf(maquina, "\tSTR(0x%x, \"%s\"); // Guarda string %s\n", sm, s, s);
			fprintf(maquina, "CODE(%d)\n", stat);
			fprintf(maquina, "\tR7=R7-%d;\n", buf);

			stat++;
		}

		fprintf(maquina, " // asigna constante a pila \n");
	}|
	size_call {
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = INT_TYPE;
		param->category = VARIABLE_CAT;
		$$ = param;
	}|
	splice_call {
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = $1->type;
		param->category = ARRAY;
		$$ = param;
	} |
	function_call {
		Param* param = (Param*) $1;
		$$ = param;
	} |
  variable {

		node *n = $1;
		Param* param = (Param*) malloc(sizeof(Param));
		param->type = n->datatype;
		param->category = n->type;

		$$ = param;

		int tipo = n->datatype;
		int addr = n->address;
		fprintf(maquina, "\tR1=0x%x;\n", addr);


		if(tipo == INT_TYPE) {
			fprintf(maquina, "\tR7=R7-4;\n");
			fprintf(maquina, "\tR2=I(R1);\n");
			fprintf(maquina, "\tI(R7)=R2;");
			sm-=4;
		}
		if(tipo == FLOAT_TYPE) {
			fprintf(maquina, "\tR7=R7-8;\n");
			fprintf(maquina, "\tRR0=F(R1);\n");
			fprintf(maquina, "\tF(R7)=RR0;");
			sm-=8;
		}
		if(tipo == DOUBLE_TYPE) {
			fprintf(maquina, "\tR7=R7-8;\n");
			fprintf(maquina, "\tRR0=D(R1);\n");
			fprintf(maquina, "\tD(R7)=RR0;");
			sm-=8;
		}
		if(tipo == CHAR_TYPE) {
			fprintf(maquina, "\tR7=R7-4;\n");
			fprintf(maquina, "\tR2=U(R1);\n");
			fprintf(maquina, "\tU(R7)=R2;");
			sm-=4;
		}
		if(tipo == BOOL_TYPE) {
			fprintf(maquina, "\tR7=R7-4;\n");
			fprintf(maquina, "\tR2=U(R1);\n");
			fprintf(maquina, "\tU(R7)=R2;");
			sm-=4;
		}

		fprintf(maquina, " // asignacion constante a pila \n");
	};

print_call: PRINT ABREPARENTESIS expression CIERRAPARENTESIS {

	if($3->type == INT_TYPE)
	{
		sm-=6;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(0x%x, \"%%d\"); // espacio para digito\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=0x%x;\n", sm);
		fprintf(maquina, "\tR2=I(R7);\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tR7=R7+4;\n");
		fprintf(maquina, "\tGT(putf_);\n");
		fprintf(maquina, "L %d:\n", funtag);
		sm+=4;
		sm+=6;

		stat++;
	}

	if($3->type == FLOAT_TYPE)
	{
		sm-=12;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(0x%x, \"%%0.8f\"); // espacio para digito\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=0x%x;\n", sm);
		fprintf(maquina, "\tRR2=F(R7);\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tR7=R7+8;\n");
		fprintf(maquina, "\tGT(putd_);\n");
		fprintf(maquina, "L %d: \n", funtag);
		sm+=8;
		sm+=12;

		stat++;
	}

	if($3->type == DOUBLE_TYPE)
	{
		sm-=12;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(0x%x, \"%%0.8f\"); // espacio para digito\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=0x%x;\n", sm);
		fprintf(maquina, "\tRR2=D(R7);\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tR7=R7+8;\n");
		fprintf(maquina, "\tGT(putd_);\n");
		fprintf(maquina, "L %d:\n", funtag);
		sm+=8;
		sm+=12;

		stat++;
	}

	if($3->type == STR_TYPE)
	{
		fprintf(maquina, "\tR1=0x%x;\n", sm);

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(-12);\n");
		fprintf(maquina, "L %d: \n", funtag);
	}

	if($3->type == BOOL_TYPE)
	{
		sm-=6;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(0x%x, \"%%d\"); // espacio para bool\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=0x%x;\n", sm);
		fprintf(maquina, "\tR2=I(R7);\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tR7=R7+4;\n");
		fprintf(maquina, "\tGT(putf_);\n");
		fprintf(maquina, "L %d:\n", funtag);
		sm+=4;
		sm+=6;

		stat++;
	}

	if($3->type == CHAR_TYPE)
	{
		sm-=6;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(0x%x, \"%%c\"); // espacio para char\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=0x%x;\n", sm);
		fprintf(maquina, "\tR2=U(R7);\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tR7=R7+4;\n");
		fprintf(maquina, "\tGT(putf_);\n");
		fprintf(maquina, "L %d:\n", funtag);
		sm+=4;
		sm+=6;

		stat++;
	}

	if($3->type == BYTE_TYPE)
	{
		sm-=6;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(0x%x, \"%%d\"); // espacio para bool\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=0x%x;\n", sm);
		fprintf(maquina, "\tR2=U(R7);\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putf_);\n");
		fprintf(maquina, "L %d:\n", funtag);
		sm+=6;

		stat++;
	}

};

println_call: PRINTLN ABREPARENTESIS expression CIERRAPARENTESIS {

	if($3->type == INT_TYPE)
	{
		sm-=8;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(0x%x, \"%%d\\n\"); // espacio para digito\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=0x%x;\n", sm);
		fprintf(maquina, "\tR2=I(R7);\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putf_);\n");
		fprintf(maquina, "L %d:\n", funtag);
		sm+=8;

		stat++;
	}

	if($3->type == FLOAT_TYPE)
	{
		sm-=14;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(0x%x, \"%%0.8f\\n\"); // espacio para digito\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=0x%x;\n", sm);
		fprintf(maquina, "\tRR2=F(R7);\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putd_);\n");
		fprintf(maquina, "L %d:\n", funtag);
		sm+=14;
	}

	if($3->type == DOUBLE_TYPE)
	{
		sm-=14;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(0x%x, \"%%0.8f\n\"); // espacio para digito\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=0x%x;\n", sm);
		fprintf(maquina, "\tRR2=D(R7);\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putd_);\n");
		fprintf(maquina, "L %d: \n", funtag);
		sm+=14;

		stat++;
	}

	if($3->type == STR_TYPE)
	{
		fprintf(maquina, "\tR1=0x%x;\n", sm);

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(-12);\n");
		fprintf(maquina, "L %d: \n", funtag);

		// imprime salto linea
		sm-=2;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(0x%x, \"\\n\"); // salto linea\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);

		fprintf(maquina, "\tR7=R7-2;\n");
		fprintf(maquina, "\tR1=R7;\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(-12);\n");
		fprintf(maquina, "L %d: R7=R7+2;\n", funtag);
		sm +=2;

		stat++;
	}

	if($3->type == BOOL_TYPE)
	{
		sm-=8;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(0x%x, \"%%d\\n\"); // espacio para bool\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=0x%x;\n", sm);
		fprintf(maquina, "\tR2=I(R7);\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putf_);\n");
		fprintf(maquina, "L %d:\n", funtag);
		sm+=8;

		stat++;
	}

	if($3->type == CHAR_TYPE)
	{
		sm-=8;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(0x%x, \"%%c\\n\"); // espacio para char\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=0x%x;\n", sm);
		fprintf(maquina, "\tR2=U(R7);\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putf_);\n");
		fprintf(maquina, "L %d:\n", funtag);
		sm+=8;

		stat++;
	}

	if($3->type == BYTE_TYPE)
	{
		sm-=8;
		fprintf(maquina, "STAT(%d)\n", stat);
		fprintf(maquina, "\tSTR(0x%x, \"%%d\\n\"); // espacio para bool\n", sm); // establece espacio para imprimir\n");
		fprintf(maquina, "CODE(%d)\n", stat);
		fprintf(maquina, "\tR1=0x%x;\n", sm);
		fprintf(maquina, "\tR2=U(R7);\n");

		funtag++;
		fprintf(maquina, "\tR0=%d; // direccion retorno\n", funtag);
		fprintf(maquina, "\tGT(putf_);\n");
		fprintf(maquina, "L %d:\n", funtag);
		sm+=8;

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

											Param * param = (Param*) malloc(sizeof(Param));
											node *n = $3;
											param->type = n->datatype;
											param->category = n->type;
											$$ = param;
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
							multitag[0] = $1;

							funtag++;
							fprintf(maquina, "\tIF(!R0) GT(%d); // ignora while\n", funtag);
							multitag[1] = funtag;


							$$ = multitag;
						};

while_stat: while_head
						body
						{
							fprintf(maquina, "GT(%d); // itera \n", $1[0]);
							fprintf(maquina, "L %d: // while fin\n", $1[1]);
						};

forin_stat: FOR IDENTIF IN variable { node* n = $4;
																			if(n->datatype != ARRAY)
																			{taberror("forin only accept array");} } body;


for_assig: FOR ABREPARENTESIS assigment
					{
						funtag++;
						fprintf(maquina, "\tL %d:\n", funtag);
						$$ = funtag;
						inner_ini = funtag;
					};

for_exp: PUNTOCOMA expression
{
	if($2->type != BOOL_TYPE) taberror("for expression can only be boolean");

	fprintf(maquina, "\tR0=U(R7);\n");
	funtag++;
	fprintf(maquina, "\tIF(!R0) GT(%d); // for expresion\n", funtag);
	$$ = funtag;
	inner_fin = funtag;
};

for_asig: id_assig MASIGUAL expression {
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
					} |
					id_assig DECR {
						$$ = (Operacion*) NULL;
					} ;

for_stat: for_assig
					for_exp
					PUNTOCOMA for_asig CIERRAPARENTESIS
					body {
						if($4->op == INCR_OP && $4->var->datatype == INT_TYPE) {

							fprintf(maquina, "\tR0 = I(0x%x); // Incremento for\n", $4->var->address);
							fprintf(maquina, "\tR0 = R0 + 1;\n");
							fprintf(maquina, "\tI(0x%x) = R0;\n", $4->var->address);
						}

						fprintf(maquina, "\tGT(%d); // itera for\n", $1);
						fprintf(maquina, "\tL %d: // fin for\n", $2);
						inner_fin = $2; // resetea
						inner_ini = $1;
					};


if_head: IF ABREPARENTESIS expression CIERRAPARENTESIS {
						if($3->type != BOOL_TYPE) taberror("if only accept bool type");

						fprintf(maquina, "\tR0=U(R7); // valor expresion en if\n");
						funtag++;
						fprintf(maquina, "\tIF(!R0) GT(%d);\n", funtag);

						$$ = funtag;
				 };

else_if_st: else_if_st ELSE IF ABREPARENTESIS expression CIERRAPARENTESIS  body |
						ELSE IF ABREPARENTESIS expression CIERRAPARENTESIS {

						} body {

						};

else_st: ELSE body | ;

else_body : else_if_st
						else_st |
	 				 	else_st;

if_init: if_head
				 body {
				 		funtag++;
				  	fprintf(maquina, "\tGT(%d); // salta a finsi\n", funtag);

				 		fprintf(maquina, "L %d: // else \n", $1);
						$$ = funtag;
					};

if_stat: if_init
				 else_body {
				 		fprintf(maquina, "L %d: // fin si \n", $1);

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
	$$ = lookup(name);
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
			strcat(error,  " param type error");
			taberror(error);
		}

		call_param = call_param->next;
		expected = expected->next;
	}
	fprintf(maquina, "\t// asigna parametros\n");

	if(call_param != NULL || expected != NULL) taberror("number parameters error");

	Param* p = (Param*) malloc(sizeof(Param));
	p->type = n->datatype;
	p->category = n->type;
	$$ = p;

	// compilador

	funtag++;
	fprintf(maquina, "\tR0=R7; // Puntero a posicion valores de parametros\n");
	fprintf(maquina, "\tR6=%d; // guarda retorno de funcion\n", funtag);
	fprintf(maquina, "\tGT(%d); // llama a funcion %s\n", n->function_tag, n->name);
	fprintf(maquina, "\tL %d: // vuelve funcion\n", funtag);
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
									decl->scope += 1;
									prev->next = temp;
									temp->next = NULL;

									$$ = $1;

							 } |
 							 param_decl {

							 		Param *p = (Param*) malloc(sizeof(Param));
									node* decl = (node *)$1;

									decl->scope += 1;

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

body: ABRELLAVE {incr_scope();} stats CIERRALLAVE {hide_scope(); $$ = $3; };

main_def: DEF INTPAL MAIN {fprintf(maquina, "L 1: // definicion de funcion main\n");} ABREPARENTESIS CIERRAPARENTESIS {
						char * name = "main";
						insert(name, strlen(name), FUNCTION_CAT, lineno);
						node* n = lookup_scope("main", get_scope());
						n->datatype = INT_TYPE;
						n->type = FUNCTION_CAT;
						n->params = (Param*) NULL;

						n->function_tag = 1;
					} body;


function_identif: IDENTIF {
										insert(yylval.id, strlen(yylval.id), FUNCTION_CAT, lineno);
										$$ = lookup_scope(yylval.id, get_scope());
									};

function_def: DEF type function_identif {
									node *n = $3;
									funtag++;
									fprintf(maquina, "L %d: // definicion de funcion %s\n", funtag, n->name);
								} ABREPARENTESIS parametros_def CIERRAPARENTESIS {
								node *n = $3;
								n->datatype = $2;
								n->type = FUNCTION_CAT;
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
									vars[i] = lookup(parametros->name);
									parametros = parametros->next;
								}

								// asigna valores a parametros en orden inverso
								fprintf(maquina, "// en R0 está la direccion donde se almacenan los valores de parametros\n");
								for(int i = 0; i < num_params; i++) {
									int addr = vars[i]->address;

									if(vars[i]->datatype == INT_TYPE) {
										//printf("0x%x\n", addr);
										fprintf(maquina, "\tR1=I(R0);\n");
										fprintf(maquina, "\tI(0x%x)=R1;\n", addr);
										fprintf(maquina, "\tR0=R0+4;\n");
									}

									if(vars[i]->datatype == FLOAT_TYPE) {
										//printf("0x%x\n", addr);
										fprintf(maquina, "\tRR1=F(R0);\n");
										fprintf(maquina, "\tF(0x%x)=RR1;\n", addr);
										fprintf(maquina, "\tR0=R0+8;\n");
									}

									if(vars[i]->datatype == DOUBLE_TYPE) {
										//printf("0x%x\n", addr);
										fprintf(maquina, "\tRR1=D(R0);\n");
										fprintf(maquina, "\tD(0x%x)=RR1;\n", addr);
										fprintf(maquina, "\tR0=R0+8;\n");
									}

									if(vars[i]->datatype == BOOL_TYPE) {
										//printf("0x%x\n", addr);
										fprintf(maquina, "\tR1=U(R0);\n");
										fprintf(maquina, "\tU(0x%x)=R1;\n", addr);
										fprintf(maquina, "\tR0=R0+4;\n");
									}

									if(vars[i]->datatype == BYTE_TYPE) {
										//printf("0x%x\n", addr);
										fprintf(maquina, "\tR1=U(R0);\n");
										fprintf(maquina, "\tU(0x%x)=R1;\n", addr);
										fprintf(maquina, "\tR0=R0+4;\n");
									}

									if(vars[i]->datatype == CHAR_TYPE) {
										//printf("0x%x\n", addr);
										fprintf(maquina, "\tR1=U(R0);\n");
										fprintf(maquina, "\tU(0x%x)=R1;\n", addr);
										fprintf(maquina, "\tR0=R0+4;\n");
									}
								}

							} body {
								fprintf(maquina, "\tGT(R6); // retorna sin usar return funcion\n");
							} |
							DEF type array function_identif { funtag++; fprintf(maquina, "L %d:\n", funtag); } ABREPARENTESIS parametros_def CIERRAPARENTESIS {
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
								strcat(error, "Expression cannot be assigned to ");
								strcat(error, n->name);
								taberror(error);
							}


							int addr = n->address;
							fprintf(maquina, "\tR1=0x%x;\n", addr);


							if(tipo == INT_TYPE) {
								fprintf(maquina, "\tR2=I(R7);\n");
								fprintf(maquina, "\tI(R1)=R2;\n");
							}
							if(tipo == FLOAT_TYPE) {
								fprintf(maquina, "\tRR0=F(R7);\n");
								fprintf(maquina, "\tF(R1)=RR0;\n");
							}
							if(tipo == DOUBLE_TYPE) {
								fprintf(maquina, "\tRR0=D(R7);\n");
								fprintf(maquina, "\tD(R1)=RR0;\n");
							}
							if(tipo == CHAR_TYPE) {
								fprintf(maquina, "\tR2=U(R7);\n");
								fprintf(maquina, "\tU(R1)=R2;\n");
							}
							if(tipo == BYTE_TYPE) {
								fprintf(maquina, "\tR2=I(R7);\n");
								fprintf(maquina, "\tI(R1)=R2;\n");
							}
							if(tipo == BOOL_TYPE) {
								fprintf(maquina, "\tR2=U(R7);\n");
								fprintf(maquina, "\tU(R1)=R2;\n");
							}
							sm+=4;
							fprintf(maquina, "\tR7=R7+4;");
							fprintf(maquina, " // asignacion variable %s \n", n->name);
					 } |
					 declaration_array IGUAL expression |
           declaration_array IGUAL type array_size |
           declaration_array IGUAL array_init |
					 asignacion;

id_assig: IDENTIF {
	node *n = lookup_scope(yylval.id, get_scope());
	if(n == NULL) taberror("not declared variable");
	$$ = n;
};

asignacion:id_assig IGUAL expression {
					 		int tipo_id  = $1->datatype;
							int tipo_exp = $3->type;
							if(tipo_id != tipo_exp) {
								taberror("types do not match");
							}

							int addr = $1->address;
							fprintf(maquina, "\tR1=0x%x;\n", addr);


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
							sm+=4;
							fprintf(maquina, "\tR7=R7+4;");
							fprintf(maquina, " // asignacion variable %s \n", $1->name);

					 }|
					 id_assig MASIGUAL expression {
					  	int tipo_id  = $1->datatype;
					  	int tipo_exp = $3->type;
					  	if(tipo_id != tipo_exp) {
						  	taberror("types do not match");
					  	}
							int addr = $1->address;
							fprintf(maquina, "\tR1=0x%x;\n", addr);

							if(tipo_id == INT_TYPE) {
								fprintf(maquina, "\tR2=I(R7);\n");
								fprintf(maquina, "\tR3=I(R1);\n");
								fprintf(maquina, "\tR3=R3+R2;\n");
								fprintf(maquina, "\tI(R1)=R3;\n");
							}
					 }|
					 id_assig MENOSIGUAL expression {
					  	int tipo_id  = $1->datatype;
					  	int tipo_exp = $3->type;
					  	if(tipo_id != tipo_exp) {
						  	taberror("types do not match");
					  	}

							int addr = $1->address;
							fprintf(maquina, "\tR1=0x%x;\n", addr);

							if(tipo_id == INT_TYPE) {
								fprintf(maquina, "\tR2=I(R7);\n");
								fprintf(maquina, "\tR3=I(R1);\n");
								fprintf(maquina, "\tR3=R3-R2;\n");
								fprintf(maquina, "\tI(R1)=R3;\n");
							}
					 }|
					 id_assig MULTIGUAL expression {
					  	int tipo_id  = $1->datatype;
					  	int tipo_exp = $3->type;
					  	if(tipo_id != tipo_exp) {
						  	taberror("types do not match");
					  	}

							int addr = $1->address;
							fprintf(maquina, "\tR1=0x%x;\n", addr);

							if(tipo_id == INT_TYPE) {
								fprintf(maquina, "\tR2=I(R7);\n");
								fprintf(maquina, "\tR3=I(R1);\n");
								fprintf(maquina, "\tR3=R3*R2;\n");
								fprintf(maquina, "\tI(R1)=R3;\n");
							}
					 }|
					 id_assig DIVIGUAL expression {
					  	int tipo_id  = $1->datatype;
					  	int tipo_exp = $3->type;
					  	if(tipo_id != tipo_exp) {
						  	taberror("types do not match");
					  	}

							int addr = $1->address;
							fprintf(maquina, "\tR1=0x%x;\n", addr);

							if(tipo_id == INT_TYPE) {
								fprintf(maquina, "\tR2=I(R7);\n");
								fprintf(maquina, "\tR3=I(R1);\n");
								fprintf(maquina, "\tR3=R3/R2;\n");
								fprintf(maquina, "\tI(R1)=R3;\n");
							}
					 }|
					 id_assig array_acceso IGUAL expression |
					 id_assig INCR {
					 	 int tipo_id  = $1->datatype;
						 int addr = $1->address;
						 fprintf(maquina, "\tR1=0x%x;\n", addr);

						 if(tipo_id == INT_TYPE) {
							 fprintf(maquina, "\tR2=I(R1);\n");
							 fprintf(maquina, "\tR2=R2+1;\n");
							 fprintf(maquina, "\tI(R1)=R2;\n");
						 }
					 } |
					 INCR id_assig {
					 	 int tipo_id  = $2->datatype;
						 int addr = $2->address;
						 fprintf(maquina, "\tR1=0x%x;\n", addr);

						 if(tipo_id == INT_TYPE) {
							 fprintf(maquina, "\tR2=I(R1);\n");
							 fprintf(maquina, "\tR2=R2+1;\n");
							 fprintf(maquina, "\tI(R1)=R2;\n");
						 }
					 } |
					 id_assig DECR {
					 	 int tipo_id  = $1->datatype;
						 int addr = $1->address;
						 fprintf(maquina, "\tR1=0x%x;\n", addr);

						 if(tipo_id == INT_TYPE) {
							 fprintf(maquina, "\tR2=I(R1);\n");
							 fprintf(maquina, "\tR2=R2-1;\n");
							 fprintf(maquina, "\tI(R1)=R2;\n");
						 }
					 } |
					 DECR id_assig {
					 	 int tipo_id  = $2->datatype;
						 int addr = $2->address;
						 fprintf(maquina, "\tR1=0x%x;\n", addr);

						 if(tipo_id == INT_TYPE) {
							 fprintf(maquina, "\tR2=I(R1);\n");
							 fprintf(maquina, "\tR2=R2-1;\n");
							 fprintf(maquina, "\tI(R1)=R2;\n");
						 }
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
exit(1);
}

int main (int argc, char *argv[]){
	char *file;
	char *op;
	char *maq = "maquina.q.c";

	maquina = fopen(maq, "w");

	switch(argc) {
		case 2:
			file = argv[1];
			break;
		case 3:
			op = argv[1];
			file = argv[2];
			break;
		default:
			fprintf(stderr, "incompatible compiler params:\n");
			fprintf(stderr, "\t ./tkc [-g] file.tk");
			fprintf(stderr, "\n");
			return 1;
	}

	// initialize symbol table
	init_table();

	// parsing
	int flag;
	yyin = fopen(file, "r");

	fprintf(maquina, "#include \"Q.h\"\n");
	fprintf(maquina, "BEGIN\n");
	fprintf(maquina, "L 0: \tR7=0x%x;\n", sm);
	flag = yyparse();
	fprintf(maquina, "\tGT(-2);\n");
	fprintf(maquina, "END\n");

	fclose(maquina);
	fclose(yyin);

	if(strcmp(op, "-g") == 0) {
		writetable();
	}

	return flag;
}
