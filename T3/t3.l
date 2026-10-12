/* t3.l */

%option noyywrap yylineno
%{

// noyywrap    - no need to deal with multiple input files
// yylineno    - variable to track line numbers 
//               that copies otherwise unmatched input to yyout.

#include "token.h"
#include "lbn.h"

%}

%%
([0-9]+\.[0-9]+|[0-9]+) {yylval.num = atoi(yytext); return NUM;}
"array" {return ARRAYT;}
"boolean" {return BOOLEANT;}
"false" {yylval.num = 0; return FALSET;}
"true" {yylval.num = 1; return TRUET;}
"if" {return IFT;}
"else" {return ELSET;}
"while" {return WHILET;}
"function" {return FUNCTIONT;}
"integer" {return INTEGERT;}
"void" {return VOIDT;}
"print" {return PRINTT;}
"return" {return RETURNT;}

[a-zA-Z][a-zA-Z0-9_]* {yylval.str = strdup(yytext); return ID;}

"==" {return EQT;}
">=" {return GTET;}
"<=" {return LTET;}
"!=" {return NEQT;}

"+" { return PLUS; }
"-" { return MINUS; }
"*" { return TIMES; }
"/" { return DIV; }

"," {return COMMA;}
":" {return COLON;}
";" {return SEMICOLON;}
"=" {return EQUALS;}
">" {return GT;}
"<" {return LT;}
"!" {return NOT;}
"[" {return LBRACKET;}
"]" {return RBRACKET;}
"(" {return LPAREN;}
")" {return RPAREN;}
"{" {return LBRACE;}
"}" {return RBRACE;}

[ \t\n\r]+|"//"[^\n]* ;
. {return ERROR;}

%%
