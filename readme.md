compile bison:
bison -d -o y.tab.c dd.y
gcc -c -g -I.. y.tab.c

compile flex:
flex -o lex.yy.c d.l
gcc -c -g -I.. lex.yy.c

compile and link bison and flex:
gcc -o dd y.tab.o lex.yy.o -ll

run and test the testcase:
bash test.sh
