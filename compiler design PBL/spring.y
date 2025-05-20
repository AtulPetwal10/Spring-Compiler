%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_VARS 100

void yyerror(const char *s);
int yylex(void);

typedef struct {
    char name[100];
    float value;
} Variable;

Variable symtab[MAX_VARS];
int symcount = 0;

void setVarValue(char *name, float val) {
    for (int i = 0; i < symcount; i++) {
        if (strcmp(symtab[i].name, name) == 0) {
            symtab[i].value = val;
            return;
        }
    }
    strcpy(symtab[symcount].name, name);
    symtab[symcount].value = val;
    symcount++;
}

float getVarValue(char *name) {
    for (int i = 0; i < symcount; i++) {
        if (strcmp(symtab[i].name, name) == 0) {
            return symtab[i].value;
        }
    }
    return 0.0;
}
%}

%union {
    char *sval;
    int ival;
    float fval;
    float fexpr;
}

%token <sval> ID STRING
%token <ival> NUMBER
%token <fval> FLOAT

%token SHOW ARROW ASSIGN SEMICOLON
%token EQ NEQ LE GE LT GT
%token AND OR NOT


%type <fexpr> expr statement

%left '+' '-'
%left '*' '/' '%'
%right UMINUS

%left OR
%left AND
%left EQ NEQ
%left LT LE GT GE
%right NOT


%%

program:
    statements
    ;

statements:
    statements statement
    |
    statement
    ;

statement:
      SHOW ARROW STRING SEMICOLON {
          char *str = strdup($3);
          str[strlen(str) - 1] = '\0';  // Remove last quote
          printf("%s\n", str + 1);      // Skip first quote
          free(str);
      }
    | 
    SHOW ARROW ID SEMICOLON {
          printf("%g\n", getVarValue($3));
      }
    | 
    SHOW ARROW expr SEMICOLON {
          printf("%g\n", $3);
      }
    | 
    ID ASSIGN expr SEMICOLON {
          setVarValue($1, $3);
      }
    ;

expr:
      NUMBER            { $$ = $1; }
    | 
    FLOAT             { $$ = $1; }
    | 
    ID                { $$ = getVarValue($1); }
    | 
    expr '+' expr     { $$ = $1 + $3; }
    | 
    expr '-' expr     { $$ = $1 - $3; }
    | 
    expr '*' expr     { $$ = $1 * $3; }
    | 
    expr '/' expr     { $$ = $3 == 0 ? (yyerror("Division by zero"), 0) : $1 / $3; }
    | 
    expr '%' expr     { $$ = (int)$3 == 0 ? (yyerror("Modulo by zero"), 0) : (int)$1 % (int)$3; }
    | 
    '-' expr %prec UMINUS { $$ = -$2; }
    | 
    '(' expr ')'      { $$ = $2; }
    | 
    expr EQ expr      { $$ = ($1 == $3); }
    | 
    expr NEQ expr     { $$ = ($1 != $3); }
    | 
    expr LT expr      { $$ = ($1 < $3); }
    | 
    expr LE expr      { $$ = ($1 <= $3); }
    | 
    expr GT expr      { $$ = ($1 > $3); }
    | 
    expr GE expr      { $$ = ($1 >= $3); }
    | 
    expr AND expr     { $$ = ($1 && $3); }
    | 
    expr OR expr      { $$ = ($1 || $3); }
    | 
    NOT expr          { $$ = !$2; }
    ;


%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}
