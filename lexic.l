%option noyywrap

%{
#include "symbol_table.h"
#include "SINTAX.tab.h"


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
{digit}+ { yylval.tipo_dato = INT_TYPE;
           Value v;
           v.int_val = atoi(yytext);
           yylval.val = v;
           return INTEGER; }
{digit}+"."{digit}+f { yylval.tipo_dato = FLOAT_TYPE;
                       Value v;
                       char* pend;
                       v.float_val = strtof(yytext, &pend);
                       yylval.val = v;
                       return FLOAT; }
{digit}+"."{digit}+ { yylval.tipo_dato = DOUBLE_TYPE;
                      Value v;
                      v.double_val = atof(yytext);
                      yylval.val = v;
                      return DOUBLE; }
\".*\" {
        // Quitar comillas
        int str_size = strlen(yytext) - 2;
        char* str = malloc(str_size*sizeof(char));
        for(int i = 1; i < strlen(yytext)-1; i++) str[i-1] = yytext[i];
        Value v;
        v.str_val = str;
        yylval.val = v;
        return STRING;
       }
"'"."'" { yylval.tipo_dato = CHAR_TYPE;
          Value v;
          v.char_val = yytext[1];
          yylval.val = v;
          return CHARACTER; }
"'"\\[nt0r]"'" { yylval.tipo_dato = CHAR_TYPE;
                 Value v;
                 if(yytext[2] == 'n') {
                    v.char_val = '\n';
                 } else
                 if(yytext[2] == 't') {
                    v.char_val = '\t';
                 } else
                 if(yytext[2] == '0') {
                    v.char_val = '\0';
                 } else
                 if(yytext[2] == 'r') {
                    v.char_val = '\r';
                 }
                 yylval.val = v;
                 return CHARACTER;}
(true|false) { yylval.tipo_dato = BOOL_TYPE;
               Value v;
               if(strcmp(yytext, "true") == 0) v.bool_val = 1;
               else if(strcmp(yytext, "false") == 0) v.bool_val = 0;
               yylval.val = v;
               return BOOL; }
("+"|-)?{digit}+b { yylval.tipo_dato = BYTE_TYPE;
                    Value v;
                    int tam = strlen(yytext)-1;
                    char *mybyte = malloc(tam*sizeof(char));
                    for(int i = 0; i < tam; i++) mybyte[i] = yytext[i];

                    v.byte_val = atoi(mybyte);
                    yylval.val = v;
                    return BYTE; }
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
int { yylval.tipo_dato = INT_TYPE; return INTPAL; }
double { yylval.tipo_dato = DOUBLE_TYPE; return DOUBLEPAL; }
float { yylval.tipo_dato = FLOAT_TYPE; return FLOATPAL; }
char { yylval.tipo_dato = CHAR_TYPE; return CHARPAL; }
bool { yylval.tipo_dato = BOOL_TYPE; return BOOLPAL; }
return {return RETURNPAL;}
print {return PRINT;} // Palabra reservada print
";" {return PUNTOCOMA;} // Para el for
println {return PRINTLN; }
splice {return SPLICE; }
size {return SIZE;}
main {
  yylval.id = yytext;
  return MAIN;}
"." {return PUNTO;}
byte {yylval.tipo_dato = BYTE_TYPE; return BYTEPAL;}
null {
  yylval.tipo_dato = NULL_TYPE;
  Value v;
  yylval.val = v;
  return NULO;
}
free { return FREE_MEM; }
void {yylval.tipo_dato = VOID_TYPE; return VOID; }
continue {return CONTINUE;}
break {return BREAK;}
"&" {return REFERENCE;}

{letter}{letdig}* {//insert(yytext, strlen(yytext), NO_CAT, lineno);
  yylval.id = malloc(strlen(yytext)*sizeof(char));
  for(int i = 0; i < strlen(yytext); i++) yylval.id[i] = yytext[i];
  return IDENTIF;} /* Identificador de una variable (NOTA: no añadir palabras reservadas debajo, o no las contempla) */

"/*" { BEGIN COMMENT; }
<COMMENT>. ;
<COMMENT>\n {lineno++;}
<COMMENT>"*/" {BEGIN INITIAL;}

\n {lineno++; }

[ \t] {} /*Ignora tabuladores y espacios*/
"/""/".*\n {lineno++;} /* Ignora comentario de línea y continúa */

. { error("Expression not recognized."); }
<<EOF>> { return 0; }
%%
