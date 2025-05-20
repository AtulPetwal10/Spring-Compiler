#include <stdio.h>

extern FILE *yyin;
extern int yyparse();

int main(int argc, char *argv[]) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            perror("Failed to open input file");
            return 1;
        }
    } else {
        yyin = stdin;
    }

    int result = yyparse();

    if (yyin != stdin) fclose(yyin);

    return result;
}
