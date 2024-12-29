#define C_STRING_IMPLEMENTATION
#include "c_nice.h"
#include "c_string.h"
// --------------------
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

string cmd, temp, temp2;

const char *program = NULL;
const char *first_arg = NULL;

#ifndef B_SILENT
#define exec_and_reset_and_log(cmd)                                            \
  eprintfn(P_INFO, str_fmt, print_str(cmd));                                   \
  exec_and_reset(cmd);
#else
#define exec_and_reset_and_log(cmd) exec_and_reset(cmd);

#endif

#define exec_and_reset(cmd)                                                    \
  system(get_string_c(&(cmd)));                                                \
  reset_string(&(cmd));

size_t hash(const char *str) {
  size_t hash = 5381;
  int c;

  while ((c = *str++)) {
    hash = ((hash << 5) + hash) + c;
  }

  return hash;
}

size_t string_to_int(string *s) {
  size_t n = 0;
  for (size_t i = 0; i < s->length; i++) {
    switch (*get_char(s, i)) {
    case '0':
      n = n * 10 + 0;
      break;
    case '1':
      n = n * 10 + 1;
      break;
    case '2':
      n = n * 10 + 2;
      break;
    case '3':
      n = n * 10 + 3;
      break;
    case '4':
      n = n * 10 + 4;
      break;
    case '5':
      n = n * 10 + 5;
      break;
    case '6':
      n = n * 10 + 6;
      break;
    case '7':
      n = n * 10 + 7;
      break;
    case '8':
      n = n * 10 + 8;
      break;
    case '9':
      n = n * 10 + 9;
      break;
    }
  }
  return n;
}

typedef struct {
  const char *path;
  const char *file;
  size_t old_hash;
} checker;

#ifndef dir_build
#define dir_build "build"
#endif

#define check_arg_num(num)                                                     \
  if (argc != num) {                                                           \
    eprintfn(P_ERR, "wrong usage");                                            \
    return -1;                                                                 \
  }

#define init_builder()                                                         \
  cmd = alloc_string();                                                        \
  temp = alloc_string();                                                       \
  temp2 = alloc_string();                                                      \
  first_arg = argc >= 2 ? argv[1] : "NULL";                                    \
  program = argv[0];                                                           \
  system("mkdir -p " dir_build);                                               \
  system("mkdir -p " dir_build "/checker");

#define check_arg_is(b)                                                        \
  (strcmp(first_arg, "NULL") != 0 && strcmp(first_arg, b) == 0)

checker init_checker(const char *read) {
  // eprintfn(P_INFO, "read::%s", read);
  reset_string(&temp);
  reset_string(&temp2);

  checker c = {0};

  read_file(&temp2, read);
  c.file = get_string_c_tmp(&temp2);

  push_to_string(temp, "echo $(touch " dir_build "/checker/%s.ch) >> /dev/null",
                 read);
  exec_and_reset(temp);

  push_to_string(temp, dir_build "/checker/%s.ch", read);
  c.path = get_string_c_tmp(&temp);

  reset_string(&temp);
  reset_string(&temp2);

  read_file(&temp2, c.path);

  size_t l = string_to_int(&temp2);

  if (l != 0) {
    c.old_hash = l;
  } else {
    c.old_hash = 0;
  }

  return c;
}

// 1 -> needs to build || 0 -> no need
int checker_file(checker *check) {
  size_t new_hash = hash(check->file);
  if (new_hash != check->old_hash) {
    FILE *f = fopen(check->path, "w");
    fprintf(f, "%zu", new_hash);
    fclose(f);
    return 1;
  }

  return 0;
}

int check_file(const char *c) {
  checker f = init_checker(c);
  int res = checker_file(&f);
  return res;
}
