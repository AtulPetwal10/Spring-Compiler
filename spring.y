%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

//maxvars is a size for symbol table
#define MAX_VARS 100
#define MAX_INPUT_LINE 256

//for variable value type
typedef enum {
    VAR_UNDEFINED = 0,
    VAR_NUMBER_VAL,
    VAR_STRING_VAL
} VarType;

void yyerror(const char *s);
int yylex(void);

//structure of every element specially variable
typedef struct {
    char name[100];
    VarType type;
    union {
        float fval;
        char *sval;
    } val;
} Variable;

//size of symbol table
Variable symtab[MAX_VARS];

//number of entries in symbol table
int symcount = 0;

int execute_block = 1;

//looking into symbol table
int lookupVar(char *name) {
    for (int i = 0; i < symcount; i++) {
        if (strcmp(symtab[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

//if variable is present in symbol table it will ignore otherwise push it into symbol table
void setVarValue(char *name, VarType type, void *value_ptr) {
    if (!execute_block) return;

    int idx = lookupVar(name);
    if (idx == -1) {
        if (symcount >= MAX_VARS) {
            fprintf(stderr, "Error: Symbol table full. Cannot declare '%s'.\n", name);
            return;
        }
        idx = symcount++;
        strcpy(symtab[idx].name, name);
        symtab[idx].type = VAR_UNDEFINED;
        symtab[idx].val.fval = 0.0;
        symtab[idx].val.sval = NULL;
    }
    if (symtab[idx].type == VAR_STRING_VAL && symtab[idx].val.sval != NULL) {
        free(symtab[idx].val.sval);
        symtab[idx].val.sval = NULL;
    }
    symtab[idx].type = type;

    if (type == VAR_NUMBER_VAL) {
        symtab[idx].val.fval = *(float *)value_ptr;
    } else if (type == VAR_STRING_VAL) {
        symtab[idx].val.sval = strdup((char *)value_ptr);
        if (symtab[idx].val.sval == NULL) {
            yyerror("Memory allocation failed for string variable.");
        }
    }
}

float getVarNumericValue(char *name) {
    int idx = lookupVar(name);
    if (idx != -1) {
        if (symtab[idx].type == VAR_NUMBER_VAL) {
            return symtab[idx].val.fval;
        } else if (symtab[idx].type == VAR_STRING_VAL) {
            yyerror("Cannot use a string variable in a numeric expression.");
            return 0.0;
        }
    }
    yyerror("Undefined variable used in expression.");
    return 0.0;
}

char *getVarStringValue(char *name) {
    int idx = lookupVar(name);
    if (idx != -1) {
        if (symtab[idx].type == VAR_STRING_VAL) {
            return symtab[idx].val.sval;
        } else {
            yyerror("Cannot use a numeric variable as a string.");
            return ""; 
        }
    }
    yyerror("Undefined variable used as a string.");
    return ""; 
}

void cleanup_symtab() {
    for (int i = 0; i < symcount; i++) {
        if (symtab[i].type == VAR_STRING_VAL && symtab[i].val.sval != NULL) {
            free(symtab[i].val.sval);
            symtab[i].val.sval = NULL;
        }
    }
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
%token TAKE IF ELSE

%type <fexpr> expr
%type <fexpr> statement

%left '+' '-'
%left '*' '/' '%'
%right UMINUS
%left OR
%left AND
%left EQ NEQ
%left LT LE GT GE
%right NOT

%%

//rest is grammer

program:
    statements
    ;

statements:
      statements statement
    | statement
    ;

statement:
      SHOW ARROW STRING SEMICOLON {
            if (!execute_block) break;
            char *str = strdup($3);
            str[strlen(str) - 1] = '\0';
            printf("%s\n", str + 1);
            free(str);
      }
    | SHOW ARROW ID SEMICOLON {
            if (!execute_block) break;
            int idx = lookupVar($3);
            if (idx != -1) {
                if (symtab[idx].type == VAR_NUMBER_VAL) {
                    printf("%g\n", symtab[idx].val.fval);
                } else if (symtab[idx].type == VAR_STRING_VAL) {
                    printf("%s\n", symtab[idx].val.sval);
                } else {
                    fprintf(stderr, "Warning: Variable '%s' is undefined.\n", $3);
                }
            } else {
                yyerror("Attempt to show undeclared variable.");
            }
      }
    | SHOW ARROW expr SEMICOLON {
            if (!execute_block) break;
            printf("%g\n", $3);
      }
    | ID ASSIGN expr SEMICOLON {
            if (!execute_block) break;
            float val_to_assign = $3;
            setVarValue($1, VAR_NUMBER_VAL, &val_to_assign);
      }
    | ID ASSIGN TAKE SEMICOLON {
            if (!execute_block) break;
            char input_buffer[MAX_INPUT_LINE];
            float num_val;
            int scan_result;

            printf("Enter value for '%s': ", $1);
            if (fgets(input_buffer, sizeof(input_buffer), stdin) != NULL) {
                input_buffer[strcspn(input_buffer, "\n")] = 0;
                scan_result = sscanf(input_buffer, "%f", &num_val);
                if (scan_result == 1 && (input_buffer[strspn(input_buffer, "-+0123456789.")] == '\0' || input_buffer[strspn(input_buffer, "-+0123456789.")] == '\n')) {
                    setVarValue($1, VAR_NUMBER_VAL, &num_val);
                } else {
                    setVarValue($1, VAR_STRING_VAL, input_buffer);
                }
            } else {
                yyerror("Failed to read input for 'take'.");
            }
      }
    | IF '(' expr ')' '{' {
            $<ival>$ = execute_block;
            $<fexpr>0 = $3;

            if (execute_block && $3) {
                execute_block = 1;
            } else {
                execute_block = 0;
            }
        } statements '}' ELSE '{' {
            int parent_block_state = $<ival>5;
            float condition_result = $<fexpr>0;

            if (parent_block_state && !condition_result) {
                execute_block = 1;
            } else {
                execute_block = 0;
            }
        } statements '}' {
            execute_block = $<ival>5;
        }
    ;

expr:
      NUMBER            { $$ = $1; }
    | FLOAT             { $$ = $1; }
    | ID                { $$ = getVarNumericValue($1); }
    | expr '+' expr     { $$ = $1 + $3; }
    | expr '-' expr     { $$ = $1 - $3; }
    | expr '*' expr     { $$ = $1 * $3; }
    | expr '/' expr     { $$ = $3 == 0 ? (yyerror("Division by zero"), 0) : $1 / $3; }
    | expr '%' expr     { $$ = (int)$3 == 0 ? (yyerror("Modulo by zero"), 0) : (float)((int)$1 % (int)$3); }
    | '-' expr %prec UMINUS { $$ = -$2; }
    | '(' expr ')'      { $$ = $2; }
    | expr EQ expr      { $$ = ($1 == $3); }
    | expr NEQ expr     { $$ = ($1 != $3); }
    | expr LT expr      { $$ = ($1 < $3); }
    | expr LE expr      { $$ = ($1 <= $3); }
    | expr GT expr      { $$ = ($1 > $3); }
    | expr GE expr      { $$ = ($1 >= $3); }
    | expr AND expr     { $$ = ($1 && $3); }
    | expr OR expr      { $$ = ($1 || $3); }
    | NOT expr          { $$ = !$2; }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}
