/* t3.y */

%{
#include <stdio.h>
#include <stdlib.h>
#include "lbn.h"

struct decl* parser_result = NULL;
void yyerror(const char *s, ...);
int yylex();
%}

%glr-parser

/* definicoes de tokens */

%token <num> NUM
%token ARRAYT
%token BOOLEANT
%token <num> FALSET
%token <num> TRUET
%token IFT
%token ELSET
%token WHILET
%token FUNCTIONT
%token INTEGERT
%token VOIDT
%token PRINTT
%token RETURNT
%token <str> ID
%token EQT
%token GTET
%token LTET
%token NEQT

%token COMMA
%token COLON
%token SEMICOLON
%token EQUALS
%token GT
%token LT
%token NOT
%token LBRACKET
%token RBRACKET
%token LPAREN
%token RPAREN
%token LBRACE
%token RBRACE

%token PLUS
%token MINUS
%token TIMES
%token DIV

%token ERROR

%union {
    int num;
    char* str;
    struct expr* expr;
    struct stmt* stmt;
    struct param_list* params;
    struct type* type;
    struct decl* decl;
    }

%type <decl> program var_decl var_list func_decl func_list
%type <type> var_type func_type param_type array_type
%type <params> param_list param
%type <expr> term expr arg_list expr_list var_assignment array_assignment arr_elem arr_list
%type <stmt> stmt stmt_list block body cond_block

%nonassoc EQT GTET LTET NEQT GT LT
%nonassoc IFT
%nonassoc ELSET

%left PLUS MINUS
%left TIMES DIV
%right NOT UMINUS

%start program

%%
program
: var_list func_list
{
    if ($1) {   // declaração opcional de variáveis
        $$ = insert_decl($1, $2);
    } else {
        $$ = $2;
    }
    parser_result = $$;
}
;

// DECLARAÇÕES DE VARIÁVEIS --------------------------------
var_list
: var_decl var_list {$$ = insert_decl($1,$2);}
| {$$ = NULL;}
;

var_decl
: ID COLON var_type var_assignment SEMICOLON
{
    $$ = var_decl_create($1, $3, $4);
}
;

var_type
: INTEGERT {$$ = type_create(TYPE_INTEGER,NULL,NULL,NULL);}
| BOOLEANT {$$ = type_create(TYPE_BOOLEAN,NULL,NULL,NULL);}
| ARRAYT LBRACKET NUM RBRACKET array_type array_assignment {$$ = array_type_create($3,$5);}
;

var_assignment
: EQUALS expr {$$ = $2;}
| {$$ = NULL;}
;

array_type
: INTEGERT
{
    $$ = type_create(TYPE_INTEGER,NULL,NULL,NULL);
}
| BOOLEANT
{
    $$ = type_create(TYPE_BOOLEAN,NULL,NULL,NULL);
}
;

array_assignment
: EQUALS LBRACE arr_list RBRACE {$$ = $3;}
| {$$ = NULL;}
;

arr_list
: arr_elem COMMA arr_list {$$ = expr_create_arg($1, $3);}
| arr_elem {$$ = expr_create_arg($1, NULL);}
;

arr_elem
: NUM {$$ = expr_create_integer($1);}
| TRUET {$$ = expr_create_boolean($1);}
| FALSET {$$ = expr_create_boolean($1);}
;

// DECLARAÇÕES DE FUNÇÕES --------------------------------
func_list
: func_list func_decl {$$ = insert_decl($1,$2);}
| func_decl {$$ = $1;}
;

func_decl
: ID COLON FUNCTIONT func_type LPAREN param_list RPAREN EQUALS block
{
    struct type* fn_type = func_type_create($6, $4);
    $$ = func_decl_create($1, fn_type, $9);
}
| ID COLON FUNCTIONT func_type LPAREN RPAREN EQUALS block
{
    struct type* fn_type = func_type_create(NULL, $4);
    $$ = func_decl_create($1, fn_type, $8);
}
;

func_type
: INTEGERT
{
    $$ = type_create(TYPE_INTEGER,NULL,NULL,NULL);
}
| BOOLEANT
{
    $$ = type_create(TYPE_BOOLEAN,NULL,NULL,NULL);
}
| VOIDT
{
    $$ = type_create(TYPE_VOID,NULL,NULL,NULL);
}
;

param_list
: param COMMA param_list {$$ = insert_param($1,$3);}
| param {$$ = $1;}
;

param
: ID COLON param_type {$$ = param_create($1, $3);}
;

param_type
: INTEGERT
{
    $$ = type_create(TYPE_INTEGER,NULL,NULL,NULL);
}
| BOOLEANT
{
    $$ = type_create(TYPE_BOOLEAN,NULL,NULL,NULL);
}
| ARRAYT LBRACKET RBRACKET array_type
{
    $$ = type_create(TYPE_ARRAY,NULL,$4,NULL);
}
;

// BLOCO DE CÓDIGO --------------------------------
block
: LBRACE var_list stmt_list RBRACE {$$ = block_stmt_create($2, $3);}
;

stmt_list
: stmt stmt_list {$$ = insert_stmt($1,$2);} 
| stmt {$$ = $1;}
;

stmt
: ID EQUALS expr SEMICOLON {
    struct expr* id = expr_create_var($1);
    $$ = assign_stmt_create(id, $3);}
| ID LBRACKET expr RBRACKET EQUALS expr SEMICOLON {
    struct expr* arr = expr_create_var_array($1, $3);
    $$ = assign_stmt_create(arr, $6);
}
| RETURNT expr SEMICOLON {$$ = return_stmt_create($2);}
| RETURNT SEMICOLON {$$ = return_stmt_create(NULL);}
| PRINTT LPAREN expr_list RPAREN SEMICOLON {$$ = print_stmt_create($3);}
| ID LPAREN arg_list RPAREN SEMICOLON {$$ = func_stmt_create(expr_create_call($1, $3));}
| ID LPAREN RPAREN SEMICOLON {$$ = func_stmt_create(expr_create_call($1, NULL));}
| IFT LPAREN expr RPAREN body %prec IFT {$$ = if_stmt_create($3, $5);}
| IFT LPAREN expr RPAREN body ELSET body {$$ = if_else_stmt_create($3, $5, $7);}
| WHILET LPAREN expr RPAREN block {$$ = while_stmt_create($3, $5);}
;

body
: cond_block 
| stmt 
;

cond_block
: LBRACE stmt_list RBRACE {$$ = block_stmt_create(NULL, $2);}
;

expr_list
: expr COMMA expr_list { $$ = expr_create_arg($3, $1); }
| expr { $$ = expr_create_arg(NULL, $1); }
;

arg_list
: expr COMMA arg_list { $$ = expr_create_arg($3, $1); }
| expr { $$ = expr_create_arg(NULL, $1); }
;

// EXPRESSÕES E TERMOS --------------------------------
expr
: ID LPAREN RPAREN {$$ = expr_create_call($1, NULL);}
| ID LPAREN arg_list RPAREN {$$ = expr_create_call($1, $3);}
| expr PLUS  expr {$$ = expr_create(EXPR_ADD, $1, $3);}
| expr MINUS expr {$$ = expr_create(EXPR_SUB, $1, $3);}
| expr TIMES expr {$$ = expr_create(EXPR_MUL, $1, $3);}
| expr DIV   expr {$$ = expr_create(EXPR_DIV, $1, $3);}
| expr EQT   expr {$$ = expr_create(EXPR_EQ, $1, $3);}
| expr NEQT  expr {$$ = expr_create(EXPR_NEQ, $1, $3);}
| expr GT    expr {$$ = expr_create(EXPR_GT, $1, $3);}
| expr LT    expr {$$ = expr_create(EXPR_LT, $1, $3);}
| expr GTET  expr {$$ = expr_create(EXPR_GTEQ, $1, $3);}
| expr LTET  expr {$$ = expr_create(EXPR_LTEQ, $1, $3);}
| NOT   expr {
    struct expr* not = $2;
    if (not->integer_value == 0) {
        not->integer_value = 1;
    } else {
        not->integer_value = 0;
    }
    $$ = not;
}
| MINUS expr  %prec UMINUS {
    struct expr* minus = $2;
    if (minus->integer_value != 0) {
        minus->integer_value = -minus->integer_value;
    }
    $$ = minus;
}
| LPAREN expr RPAREN {$$ = $2;}
| term
;

term
: NUM {$$ = expr_create_integer($1);}
| TRUET {$$ = expr_create_boolean($1);}
| FALSET {$$ = expr_create_boolean($1);}
| ID LBRACKET expr RBRACKET {$$ = expr_create_var_array($1, $3);}
| ID {$$ = expr_create_var($1);}
;

%%

// conserta erro de "undefined reference to `yyerror'"
void yyerror(const char *s, ...) {
    fprintf(stderr, "%s\n", s);
}