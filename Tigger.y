%{
#include<iostream>
#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include <map>
int yylex(void);
void yyerror(char*);
extern int yydebug;
using namespace std;
map<string,string> inst;
map<string,string> ex;
map<string,string> branch;
int STK;
%}

%union{
int iValue;
const char* sValue;
struct Enode* enode;
}

%token IF RETURN GOTO CALL PARAM END LOAD STORE LOADADDR MALLOC
%token<iValue> NUMBER
%token<sValue> VAR FUNC LABEL REG
%type<sValue> BinOP UnaryOP
%%


Program:
 GlobalVarDecl
|FunctionDef
|Program GlobalVarDecl
|Program FunctionDef
|Program END{return 0;}
;

GlobalVarDecl:
 VAR '=' NUMBER{
    printf("\t.global\t%s\n\
\t.section\t.sdata\n\
\t.align\t2\n\
\t.type\t%s, @object\n\
\t.size\t%s, 4\n\
%s:\n\
\t.word\t%d\n\n",$1,$1,$1,$1,$3);
 }

|VAR '=' MALLOC NUMBER{printf("\t.comm\t%s, %d, 4\n\n",$1,$4);}
;

FunctionDef:
 FUNC '[' NUMBER ']' '[' NUMBER ']'{
    STK=($6/4+1)*16;
    printf("\t.text\n\
\t.align\t2\n\
\t.global\t%s\n\
\t.type\t%s, @function\n\
%s:\n\
\taddi\tsp, sp, -%d\n\
\tsw\t\tra, %d(sp)\n",$1+2,$1+2,$1+2,STK,STK-4);
 }
 Expressions{}
 END FUNC{printf("\t.size\t%s, .-%s\n\n",$1+2,$1+2);}
;

Expressions:
 Expression
|Expressions Expression
;

Expression :
 REG '=' REG BinOP REG{
    string op=$4;
    if(op=="&&"){
        printf("\tsnez\t%s, %s\n",$1,$3);
        printf("\tsnez\ts0, %s\n",$5);
        printf("\tand \t%s, %s, s0\n",$1,$1);
    }
    else{
        printf("\t%s\t%s, %s, %s\n",inst[op].c_str(),$1,$3,$5);
        if(op.size()>1){
            printf("\t%s\t%s, %s\n",ex[op].c_str(),$1,$1);
        }
    }
 }
|REG '=' REG BinOP NUMBER{
    string op=$4;
    int num=$5;
    if((op=="+"||op=="<")&&num>=-2048&&num<2047){
        printf("\t%si\t%s, %s, %d\n",inst[op].c_str(),$1,$3,num);
    }
    else{
        printf("\tli\t\ts0, %d\n",num);
        printf("\t%s\t%s, %s, s0\n",inst[op].c_str(),$1,$3);
    }
}
|REG '=' UnaryOP REG{
    string op=$3;
    printf("\t%s\t%s, %s\n",ex[op].c_str(),$1,$4);
}
|REG '=' REG{
    printf("\tmv\t\t%s, %s\n",$1,$3);
}
|REG '=' NUMBER{
    printf("\tli\t\t%s, %d\n",$1,$3);
}
|REG '[' NUMBER ']' '=' REG{
    int num=$3;
    if(num>=-2048&&num<2047){
        printf("\tsw\t\t%s, %d(%s)\n",$6,$3,$1);
    }
    else{
        printf("\tli\t\ts0, %d\n",num);
        printf("\tadd \ts0, s0,%s\n",$1);
        printf("\tsw\t\t%s, 0(s0)\n",$6);
    }
}
|REG '=' REG '[' NUMBER ']'{
    int num=$5;
    if(num>=-2048&&num<2047){
        printf("\tlw\t\t%s, %d(%s)\n",$1,$5,$3);
    }
    else{
        printf("\tli\t\ts0, %d\n",num);
        printf("\tadd \ts0, s0,%s\n",$3);
        printf("\tlw\t\t%s, 0(s0)\n",$1);
    }
}
|IF REG BinOP REG GOTO LABEL{
    string op=$3;
    printf("\t%s\t%s, %s, .%s\n",branch[op].c_str(),$2,$4,$6);
}
|GOTO LABEL{
    printf("\tj\t\t.%s\n",$2);
}
|LABEL ':'{
    printf(".%s:\n",$1);
}
|CALL FUNC{
    printf("\tcall\t%s\n",$2+2);
}
|RETURN{
    printf("\tlw\t\tra, %d(sp)\n",STK-4);
    printf("\taddi\tsp, sp, %d\n",STK);
    printf("\tret\n");
}
|STORE REG NUMBER{
    int num=$3*4;
    if(num>=-2048&&num<2047){
        printf("\tsw\t\t%s, %d(sp)\n",$2,num);
    }
    else{
        printf("\tli\t\ts0, %d\n",num);
        printf("\tadd \ts0, s0, sp\n");
        printf("\tsw\t\t%s, 0(s0)\n",$2);
    }
}
|LOAD NUMBER REG{
    int num=$2*4;
    if(num>=-2048&&num<2047){
        printf("\tlw\t\t%s, %d(sp)\n",$3,num);
    }
    else{
        printf("\tli\t\ts0, %d\n",num);
        printf("\tadd \ts0, s0, sp\n");
        printf("\tlw\t\t%s, 0(s0)\n",$3);
    }
}
|LOAD VAR REG{
    printf("\tlui\t\t%s, %%hi(%s)\n",$3,$2);
    printf("\tlw\t\t%s, %%lo(%s)(%s)\n",$3,$2,$3);
}
|LOADADDR NUMBER REG{
    int num=$2*4;
    if(num>=-2048&&num<2047){
        printf("\taddi\t%s, sp, %d\n",$3,num);
    }
    else{
        printf("\tli\t\ts0, %d\n",num);
        printf("\tadd \t%s, s0, sp\n",$3);
    }
}
|LOADADDR VAR REG{
    printf("\tla\t\t%s, %s\n",$3, $2);
}
;

BinOP:
 '=' '='{$$="==";}
|'!' '='{$$="!=";}
|'='{$$="=";}
|'+'{$$="+";}
|'-'{$$="-";}
|'*'{$$="*";}
|'/'{$$="/";}
|'%'{$$="%";}
|'&' '&'{$$="&&";}
|'|' '|'{$$="||";}
|'>'{$$=">";}
|'<'{$$="<";}
|'>' '='{$$=">=";}
|'<' '='{$$="<=";}
;

UnaryOP:
 '!'{$$="!";}
|'-'{$$="-";}
;

%%

int main(int argc,char **argv)
{
        freopen(argv[2], "r", stdin);
        freopen(argv[4], "w", stdout);
        //yydebug=1;
        inst["+"]="add";
        inst["-"]="sub";
        inst["*"]="mul";
        inst["/"]="div";
        inst["%"]="rem";
        inst["<"]="slt";
        inst[">"]="sgt";
        inst["<="]="sgt";
        inst[">="]="slt";
        inst["||"]="or";
        inst["!="]="xor";
        inst["=="]="xor";

        ex["<="]="seqz";
        ex[">="]="seqz";
        ex["||"]="snez";
        ex["!="]="snez";
        ex["=="]="seqz";

        ex["-"]="neg";
        ex["!"]="seqz";

        branch["<"]="blt ";
        branch[">"]="bgt ";
        branch["<="]="ble ";
        branch[">="]="bge ";
        branch["!="]="bne ";
        branch["=="]="beq ";
        yyparse();
        printf("\n");
	return 0;
}
