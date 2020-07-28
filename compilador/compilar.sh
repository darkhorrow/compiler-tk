bison -d SINTAX.y
flex lexic.l
gcc -o tkc SINTAX.tab.c lex.yy.c symbol_table.c
