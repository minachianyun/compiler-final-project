%{
#include "y.tab.h"
%}
separator  \t|\n|\r
letter [a-z]
digit [0-9]
number 0|[1-9]{digit}*|-[1-9]{digit}*
ID {letter}({letter}|{digit}|-)*
symbol \+|\-|\*|\/|\>|\<|\=

%%
"print-num"	{return printNum;}
{number} {yylval.ival=atoi(yytext); return number;}
{symbol} {return yytext[0];}
"mod" {return mod;}


"print-bool" {return printBool;}
"#t"	{yylval.ival=1; return boolVal;}
"#f"	{yylval.ival=0; return boolVal;}
"and"	{return and;}
"or"	{return or;}
"not"	{return not;}

"if" 	{return ifs;}
"define" {return define;}
"fun"	{return (fun);}
{ID}	{strcpy(yylval.name,yytext);return id;}
"("|")"	{ return(yytext[0]); }

{separator} {/* do nothing */}
.	{  }
%%
