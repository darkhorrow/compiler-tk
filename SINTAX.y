%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>

	extern FILE *yyin;
	extern FILE *yyout;
	extern int lineno;
	extern int yylex();
	void yyerror();

%}

/* YYSTYPE union */
%union {

  char char_val;
	int int_val;
	double double_val;
	char* str_val;
	int bool_val;
	char byte_val;
	float float_val;
}

/* token definition */

%token <int_val> CHARPAL INTPAL FLOATPAL DOUBLEPAL BOOLPAL IF ELSE WHILE FOR CONTINUE BREAK VOID RETURNPAL
%token <int_val> MAS MULTIPLICACION DIVISION MODULO MASIGUAL MENOSIGUAL MULTIGUAL DIVIGUAL INCR DECR OR AND NOT IGUALA DISTINTO MAYOR MENOR MAYORIGUAL MENORIGUAL
%token <int_val> ABREPARENTESIS CIERRAPARENTESIS ABRECORCHETE CIERRACORCHETE ABRELLAVE CIERRALLAVE PUNTOCOMA PUNTO COMA IGUAL REFERENCE
%token <symtab_item>   IDENTIF
%token <int_val>       INTEGER
%token <float_val>     FLOAT
%token <double_val>    DOUBLE
%token <char_val>      CHARACTER
%token <str_val>       STRING
%token <bool_val>			 BOOL
%token <byte_val>			 BYTE
%token  MENOS ELEVADO DESPLAZAMIENTOIZQ DESPLAZAMIENTODERECHA XOR DEF IN
%token PRINT PRINTLN SPLICE SIZE MAIN BYTEPAL NULO FREE_MEM
%token PASS

/* precedencies and associativities */


%start program

/* expression rules */
%right IGUAL
%left ABRECORCHETE CIERRACORCHETE
%left ABREPARENTESIS CIERRAPARENTESIS
%left ELEVADO
%left MULTIPLICACION DIVISION MODULO OR AND NOT XOR
%left MAS MENOS
%left DESPLAZAMIENTOIZQ DESPLAZAMIENTODERECHA
%nonassoc IGUALA DISTINTO MAYOR MENOR MAYORIGUAL MENORIGUAL
%nonassoc INCR DECR
%left COMA

%%

program: global_var main_def |
				 functions main_def |
				 global_var functions main_def ;

functions: functions function_def | function_def;

global_var: declaration global_var |
            declaration_array global_var |
            assigment global_var |
            declaration |
            declaration_array |
            assigment ;

type: INTPAL | DOUBLEPAL | FLOATPAL | CHARPAL | BYTEPAL | BOOLPAL | VOID;

array: ABRECORCHETE CIERRACORCHETE array | ABRECORCHETE CIERRACORCHETE;

declaration_array: type array IDENTIF;
declaration: type IDENTIF ;

array_acceso: ABRECORCHETE expression CIERRACORCHETE array_acceso | ABRECORCHETE expression CIERRACORCHETE;

variable: IDENTIF |
					IDENTIF array_acceso;

sign: MAS | MENOS | ;
constant: sign INTEGER | sign FLOAT | sign DOUBLE | CHARACTER | BYTE | STRING | BOOL | NULO;

stats: assigment stats  |
			 declaration stats |
			 function_call stats |
			 if_stat stats |
			 for_stat stats |
			 forin_stat stats |
			 while_stat stats |
			 RETURNPAL expression stats |
			 print_call stats |
			 println_call stats |
			 PASS stats |
			 assigment |
			 declaration |
			 function_call |
			 if_stat |
			 for_stat |
			 forin_stat |
			 while_stat |
			 print_call |
			 println_call |
			 RETURNPAL expression |
			 PASS
			 ;

expression:
  expression MAS expression |
  expression MENOS expression |
  expression MULTIPLICACION expression |
  expression DIVISION expression |
	expression MODULO expression |
	expression AND expression |
	expression OR expression |
	expression XOR expression |
	NOT expression |
	expression IGUALA expression |
	expression MAYOR expression |
	expression MENOR expression |
	expression MAYORIGUAL expression |
	expression MENORIGUAL expression |
	expression DISTINTO expression |
	expression ELEVADO expression |
	expression DESPLAZAMIENTOIZQ expression |
	expression DESPLAZAMIENTODERECHA expression |
	ABREPARENTESIS expression CIERRAPARENTESIS |
  constant |
	size_call |
	splice_call |
	function_call |
  variable;

loop_stats: assigment loop_stats  |
						declaration loop_stats |
					 	function_call loop_stats |
					 	if_stat loop_stats |
					 	for_stat loop_stats |
					 	forin_stat loop_stats |
					 	while_stat loop_stats |
						print_call loop_stats |
					 	println_call loop_stats |
					 	BREAK loop_stats |
					 	CONTINUE loop_stats |
					 	RETURNPAL expression loop_stats |
						PASS loop_stats |
					 	assigment |
					 	declaration |
					 	function_call |
					 	if_stat |
					 	for_stat |
					 	forin_stat |
					 	while_stat |
					 	print_call |
					 	println_call |
					 	CONTINUE |
					 	BREAK |
					 	RETURNPAL expression |
					 	PASS
					 	;

body_loop: ABRELLAVE loop_stats CIERRALLAVE;

print_call: PRINT  ABREPARENTESIS expression CIERRAPARENTESIS;

println_call: PRINTLN ABREPARENTESIS expression CIERRAPARENTESIS;

size_call: SIZE ABREPARENTESIS IDENTIF CIERRAPARENTESIS;

splice_call: SPLICE ABREPARENTESIS IDENTIF COMA expression COMA expression CIERRAPARENTESIS;

while_stat: WHILE ABREPARENTESIS expression CIERRAPARENTESIS body_loop;

forin_stat: FOR IDENTIF IN variable body_loop;

for_stat: FOR ABREPARENTESIS assigment PUNTOCOMA expression PUNTOCOMA asignacion CIERRAPARENTESIS body_loop;

else_if_st: else_if_st ELSE IF ABREPARENTESIS expression CIERRAPARENTESIS body |
						ELSE IF ABREPARENTESIS expression CIERRAPARENTESIS body;

else_st: ELSE body | ;

if_stat: IF ABREPARENTESIS expression CIERRAPARENTESIS body else_if_st else_st |
				 IF ABREPARENTESIS expression CIERRAPARENTESIS body else_st	;

parametro: parametro COMA expression | expression ;

parametros: parametro | ;

function_call: IDENTIF ABREPARENTESIS parametros CIERRAPARENTESIS ;

parametro_def: parametro_def COMA declaration |
							 parametro_def COMA declaration_array |
							 declaration_array |
 							 declaration ;

parametros_def: parametro_def | ;

body: ABRELLAVE stats CIERRALLAVE;

main_def: DEF INTPAL MAIN ABREPARENTESIS CIERRAPARENTESIS body;

function_def: DEF type IDENTIF ABREPARENTESIS parametros_def CIERRAPARENTESIS body |
							DEF type array IDENTIF ABREPARENTESIS parametros_def CIERRAPARENTESIS body;

array_size: ABRECORCHETE expression CIERRACORCHETE |
            ABRECORCHETE expression CIERRACORCHETE array_size;

array_values: array_values COMA expression | expression;

array_mat: ABRECORCHETE array_values CIERRACORCHETE COMA array_mat |
           ABRECORCHETE array_values CIERRACORCHETE |
           array_values;

array_init: ABRECORCHETE array_mat CIERRACORCHETE ;

assigment: declaration IGUAL expression |
					 declaration_array IGUAL expression |
           declaration_array IGUAL type array_size |
           declaration_array IGUAL array_init |
					 asignacion;

asignacion:IDENTIF IGUAL expression |
					 IDENTIF MASIGUAL expression |
					 IDENTIF MENOSIGUAL expression |
					 IDENTIF MULTIGUAL expression |
					 IDENTIF DIVIGUAL expression |
					 IDENTIF array_acceso IGUAL expression |
					 IDENTIF INCR |
					 INCR IDENTIF |
					 IDENTIF DECR |
					 DECR IDENTIF ;

%%

void yyerror ()
{
  fprintf(stderr, "Syntax error at line %d\n", lineno);
  exit(1);
}

int main (int argc, char *argv[]){

	// initialize symbol table

	// parsing
	int flag;
	yyin = fopen(argv[1], "r");
	flag = yyparse();
	fclose(yyin);

	return flag;
}
