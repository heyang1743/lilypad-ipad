#include <libguile.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
    (void)argc;
    (void)argv;

    scm_init_guile();

    SCM value = scm_c_eval_string("(+ 1 2)");
    int result = scm_to_int(value);
    if (result != 3) {
        fprintf(stderr, "expected 3, got %d\n", result);
        return 2;
    }

    scm_c_eval_string("(display \"hello-guile-ios\")");
    scm_c_eval_string("(newline)");
    return 0;
}
