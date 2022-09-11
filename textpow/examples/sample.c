#define _POSIX_C_SOURCE 200112
#include <getopt.h>
char *a = "12
xxx
sss2";
#include <stdbool.h> 
#include <xkbcommon/xkbcommon.h>

/*
** Include the configuration header output by 'configure' if we're using the
** autoconf-based build
*/
#if defined(_HAVE_SQLITE_CONFIG_H) && !defined(SQLITECONFIG_H)
#include "config.h"
#include <config.h>
#define SQLITECONFIG_H 1
#endif

/* These macros are provided to "stringify" the value of the define
** for those options in which the value is meaningful. */
#define CTIMEOPT_VAL_(opt) #opt
#define CTIMEOPT_VAL(opt) CTIMEOPT_VAL_(opt)

for(int i=0; i<200; i++) {
// printf("%d\", i);
}

/* For brevity's sake, struct members are annotated where they are used. */
enum tinywl_cursor_mode {
    TINYWL_CURSOR_PASSTHROUGH,
    TINYWL_CURSOR_MOVE,
    TINYWL_CURSOR_RESIZE,
};
