flex lexic.l
bison -d SINTAX.y
gcc -o tkc SINTAX.tab.c lex.yy.c symbol_table.c
