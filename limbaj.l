%{

#include <stdio.h>
#include <stdlib.h>
#include "y.tab.h"



%}
%option noyywrap
%%

"int"|"float"|"char"|"string"|"bool" {
    yylval.stringVal = malloc(yyleng + 1);
    strcpy(yylval.stringVal, yytext);
    return TIP_PRIMITIV;
}

"void" {
    return VOID;
}

">" {
    return NUM_MAI_MARE;
}
"<" {
    return NUM_MAI_MIC;
}
"==" {
    return NUM_EGALITATE;
}
"<=" {
    return NUM_MAI_MIC_SAU_EGAL;
}
">=" {
    return NUM_MAI_MARE_SAU_EGAL;
}

"strgt" {
    return STR_MAI_MARE;
}
"strlt" {
    return STR_MAI_MIC;
}
"streq" {
    return STR_EGALITATE;
}
"strle" {
    return STR_MAI_MIC_SAU_EGAL;
}
"strge" {
    return STR_MAI_MARE_SAU_EGAL;
}

"&&" {
    return SI;
}

"||" {
    return SAU;
}

"!" {
    return NEG;
}

"true" {
    return TRUE;
}

"false" {
    return FALSE;
}

"structX" {
    return STRUCT;
}

"funcX" {
    return FUNC;
}

"begin_program" {
    return BEGIN_PROG;
}

"end_program" {
    return END_PROG;
}

"while" {
    return WHILE;
}

"if" {
    return IF;
}

"else" {
    return ELSE;
}

"for" {
    return FOR;
}

"in" {
    return IN;
}

"const" {
    return CONST;
}

"concat" {
    return CONCAT;
}

"new" {
    return NEW;
}

"eval" {
    return EVAL;
}

"return" {
    return RETURN;
}

[0-9]|[1-9][0-9]* {
    yylval.nr = atoi(yytext);
    return NUMAR;
}

[0-9]|[1-9][0-9]*\.[0-9]+ {
    return NUMARFLOAT;
}

\"[^\"]*\" {
    return VALOARE_STRING;
}

[a-zA-Z_][a-zA-Z0-9_]* {
    yylval.stringVal = malloc(yyleng + 1);
    strcpy(yylval.stringVal, yytext);
    return IDENTIFICATOR;
}

[ \t] ;

[\n] { ++yylineno; }

. {
  return yytext[0];
}
