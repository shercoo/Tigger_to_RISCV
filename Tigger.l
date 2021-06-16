%{
#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include"Tigger.tab.hpp"

int line=1;
%}


digit       [0-9]
number      -?{digit}+
label       l{number}
letter      [a-zA-Z_]
identifier  {letter}({letter}|{digit})*
variable    v{number}
function    f_{identifier}
whitespace  [ \t\n]+
reg         (x0)|(s([0-9]|(10)|(11)))|(t[0-6])|(a[0-7])


%%

\n {yylineno++;}
[ \t]+ {}
"/*"(([^\*]*(\*[^\/])?)*)"*/" {}
\/\/.* {}


[-+*/\(\)\[\]{}%,.:;!<>=&|] {return yytext[0];}

if	    {return IF;}
return      {return RETURN;}
goto	      {return GOTO;}
call        {return CALL;}
end	      {return END;}
malloc    {return MALLOC;}
store     {return STORE;}
load      {return LOAD;}
loadaddr  {return LOADADDR;}
{label}       {yylval.sValue=strdup(yytext); return LABEL; }
{number}      {yylval.iValue=atoi(yytext);return NUMBER;}
{variable}    {yylval.sValue=strdup(yytext); return VAR;}
{function}    {yylval.sValue=strdup(yytext); return FUNC; }
{reg}         {yylval.sValue=strdup(yytext); return REG; }


<<EOF>> {return END;}


%%

int yywrap()
{
	return 1;
}

void yyerror(char *message)
{
    printf("%d %s\n",yylineno,message);
    exit(0);
}

