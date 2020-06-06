%option noyywrap

%{
#include "SINTAX.tab.h"

/*
#define INTEGER 1
#define FLOAT 2
#define DOUBLE 3
#define CHARACTER 4
#define BOOL 5
#define BYTE 6
#define ABRELLAVE 7
#define CIERRALLAVE 8
#define ABREPARENTESIS 9
#define CIERRAPARENTESIS 10
#define ABRECORCHETE 11
#define CIERRACORCHETE 12
#define MAYOR 13
#define MENOR 14
#define IGUALA 15
#define DISTINTO 16
#define MAYORIGUAL 17
#define MENORIGUAL 18
#define MAS 19
#define MENOS 20
#define DIVISION 21
#define MULTIPLICACION 22
#define ELEVADO 23
#define IGUAL 24
#define DESPLAZAMIENTOIZQ 25
#define DESPLAZAMIENTODERECHA 26
#define AND 27
#define OR 28
#define XOR 29
#define NOT 30
#define IF 31
#define ELSE 32
#define FOR 33
#define WHILE 34
#define LOCAL 35
#define IN 36
#define COMA 37
#define INTPAL 38
#define DOUBLEPAL 39
#define FLOATPAL 40
#define CHARPAL 41
#define BOOLPAL 42
#define RETURNPAL 43
#define IDENTIF 44
#define PRINT 45
#define PUNTOCOMA 46
#define IMPORT 47
#define PRINTLN 48
#define SPLICE 49
#define SIZE 50
#define PUNTO 51
#define MAIN 52
#define BYTEPAL 53
#define NULO 54
#define FREE_MEM 55
#define VOID 56
*/

int lineno = 1;
int comment = 0;
void error(char*);
%}

%x COMMENT
letter [a-zA-Z]
digit [0-9]
letdig {letter}|{digit}
diglet {digit}|{letter}

%%
{digit}+ { return INTEGER; }
{digit}+"."{digit}+f { return FLOAT; }
{digit}+"."{digit}+ { return DOUBLE; }
\".*\" { return STRING; }
"'"."'" { return CHARACTER; }
"'"\\[nt0r]"'" {return CHARACTER;}
(true|false) { return BOOL; }
("+"|-)?{digit}+b { return BYTE; }
"{" { return ABRELLAVE; }
"}" { return CIERRALLAVE; }
"(" { return ABREPARENTESIS; }
")" { return CIERRAPARENTESIS; }
"[" { return ABRECORCHETE; }
"]" { return CIERRACORCHETE; }
">" { return MAYOR; }
"<" { return MENOR; }
"+=" { return MASIGUAL; }
"-=" { return MENOSIGUAL; }
"*=" { return MULTIGUAL; }
"/=" { return DIVIGUAL; }
"==" { return IGUALA; }
"=" { return IGUAL; }
"!=" { return DISTINTO; }
">=" { return MAYORIGUAL; }
"<=" { return MENORIGUAL; }
"+" { return MAS; }
"%" { return MODULO; }
"++" {return INCR;}
"-" { return MENOS; }
"--" {return DECR;}
"/"[^/*] { return DIVISION; }
"*" { return MULTIPLICACION; }
"^" { return ELEVADO; }
"<<" { return DESPLAZAMIENTOIZQ; }
">>" { return DESPLAZAMIENTODERECHA; }
"&&" { return AND; }
"||" { return OR; }
"^^" { return XOR; }
"!" { return NOT; }
if { return IF; }
else { return ELSE; }
for { return FOR; }
while { return WHILE; }
def { return DEF; }
pass { return PASS; }
in { return IN; }
"," { return COMA; }
int { return INTPAL; }
double { return DOUBLEPAL; }
float { return FLOATPAL; }
char { return CHARPAL; }
bool { return BOOLPAL; }
return {return RETURNPAL;}
print {return PRINT;} // Palabra reservada print
";" {return PUNTOCOMA;} // Para el for
println {return PRINTLN; }
splice {return SPLICE; }
size {return SIZE;}
main {return MAIN;}
"." {return PUNTO;}
byte {return BYTEPAL;}
null {return NULO; }
free { return FREE_MEM; }
void {return VOID; }
continue {return CONTINUE;}
break {return BREAK;}
"&" {return REFERENCE;}

{letter}{letdig}* {return IDENTIF;} /* Identificador de una variable (NOTA: no añadir palabras reservadas debajo, o no las contempla) */

"/*" { BEGIN COMMENT; }
<COMMENT>. ;
<COMMENT>\n {lineno++;}
<COMMENT>"*/" {BEGIN INITIAL;}

\n {lineno++;}

[ \t] {} /*Ignora tabuladores y espacios*/
"/""/".*\n {lineno++;} /* Ignora comentario de línea y continúa */
. { error("Expression not recognized."); }
<<EOF>> { return 0; }
%%

/*

int main(int argc, char** argv) {
	int s;
	if(argc > 1) yyin = fopen(argv[1], "r");
	do {
		s = yylex();
		printf("Detected a %i token in lineno %i\n", s, lineno);
	} while(s != 0);
	return 0;
}

void error(char* msg) {
	printf("Lexical error in lineno %i: %s\n", lineno, msg);
}
*/
