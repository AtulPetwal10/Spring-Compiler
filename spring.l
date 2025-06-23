%{
#include "spring.tab.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
%}

%%

if                    { return IF; }
else                  { return ELSE; }
show                  { return SHOW; }
take                  { return TAKE; }
"->"                  { return ARROW; }
"<-"                  { return ASSIGN; }
";"                   { return SEMICOLON; }

[0-9]+\.[0-9]+        { yylval.fval = atof(yytext); return FLOAT; }
[0-9]+                { yylval.ival = atoi(yytext); return NUMBER; }

\"[^\"]*\"            {
                          yylval.sval = strdup(yytext);
                          return STRING;
                       }

[a-zA-Z_][a-zA-Z0-9_]* { yylval.sval = strdup(yytext); return ID; }

"+"                   { return '+'; }
"-"                   { return '-'; }
"*"                   { return '*'; }
"/"                   { return '/'; }
"("                   { return '('; }
")"                   { return ')'; }
"%"                   { return '%'; }
"{"                   { return '{'; }
"}"                   { return '}'; }
"=="                  { return EQ; }
"!="                  { return NEQ; }
"<="                  { return LE; }
">="                  { return GE; }
"<"                   { return LT; }
">"                   { return GT; }
"&&"                  { return AND; }
"||"                  { return OR; }
"!"                   { return NOT; }

"//".*                ;   // Ignore single-line comments
[ \t\r\n]+            ;   // Ignore whitespace

.                     { printf("Unknown character: %s\n", yytext); }

%%
