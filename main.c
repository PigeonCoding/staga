#include "nice.h"
#include <stdio.h>
#include <string.h>
#define C_STRING
#include "cstring.h"

typedef struct {
  int cmd;
  int layer;
  int values_int[10];
  string_view strings;
} Cmd;

Cmd instr[100] = {0};
size_t current_instr = 0;

enum OP_Code {
  none,
  add,
  minus,
  mult,
  ndiv,
  number,
  func,
  nstring,
};

void find_expr(string_view full, size_t *index, int layerz) {
  size_t i = *index + 1;
  int k = 0;
  int spe = 0;
  do {
    spe = 0;
    instr[current_instr].layer = layerz;

    // char current = pseudo_str(full)[i];
    switch (pseudo_str(full)[i]) {
    case '(':
      find_expr(full, &i, layerz + 1);
      spe = 1;
      break;
    case ')':
      k = 1;
      spe = 1;
      break;
    case ' ':
    case '\n':
      spe = 1;
      break;

    // nummbers
    case '0' ... '9':
      instr[current_instr].cmd = number;
      for (size_t j = i; j < full.length; j++) {
        switch (pseudo_str(full)[j]) {
        case '0':
          instr[current_instr].values_int[0] =
              instr[current_instr].values_int[0] * 10 + 0;
          break;
        case '1':
          instr[current_instr].values_int[0] =
              instr[current_instr].values_int[0] * 10 + 1;
          break;
        case '2':
          instr[current_instr].values_int[0] =
              instr[current_instr].values_int[0] * 10 + 2;
          break;
        case '3':
          instr[current_instr].values_int[0] =
              instr[current_instr].values_int[0] * 10 + 3;
          break;
        case '4':
          instr[current_instr].values_int[0] =
              instr[current_instr].values_int[0] * 10 + 4;
          break;
        case '5':
          instr[current_instr].values_int[0] =
              instr[current_instr].values_int[0] * 10 + 5;
          break;
        case '6':
          instr[current_instr].values_int[0] =
              instr[current_instr].values_int[0] * 10 + 6;
          break;
        case '7':
          instr[current_instr].values_int[0] =
              instr[current_instr].values_int[0] * 10 + 7;
          break;
        case '8':
          instr[current_instr].values_int[0] =
              instr[current_instr].values_int[0] * 10 + 8;
          break;
        case '9':
          instr[current_instr].values_int[0] =
              instr[current_instr].values_int[0] * 10 + 9;
          break;
        default:
          j = full.length + 1;
          i -= 2;
          break;
        }
        i++;
      }

      break;

    // math ops
    case '+':
      instr[current_instr].cmd = add;
      break;
    case '-':
      instr[current_instr].cmd = minus;
      break;
    case '*':
      instr[current_instr].cmd = mult;
      break;
    case '/':
      instr[current_instr].cmd = ndiv;
      break;

    case 'a' ... 'z':
    case 'A' ... 'Z':
    case '_':
      instr[current_instr].cmd = func;
      instr[current_instr].strings.base_pointer =
          full.base_pointer + i * char_size;

      do {
        instr[current_instr].strings.length++;
        i++;
      } while (((pseudo_str(full)[i] >= 'a' && pseudo_str(full)[i] <= 'z') ||
                (pseudo_str(full)[i] >= 'A' && pseudo_str(full)[i] <= 'Z') ||
                pseudo_str(full)[i] == '_') &&
               (i < full.length));
      // while (pseudo_str(full)[i] != ',' || pseudo_str(full)[i] == '(') {
      //   i++;
      // }
      // i++;
      // string_view arg = (string_view){
      //     .base_pointer = instr[current_instr].strings.base_pointer =
      //         full.base_pointer + i * char_size,
      //     .length = 1};
      // while (pseudo_str(full)[i] != ',' && i < full.length) {
      //   arg.length++;
      //   i++;
      // }
      // current_instr++;
      // size_t in = 0;
      // find_expr(arg, &in, instr[current_instr].layer + 1);

      break;

    case '"':
      instr[current_instr].cmd = nstring;
      instr[current_instr].strings.base_pointer =
          full.base_pointer + (i + 1) * char_size;
      i++;
      while (pseudo_str(full)[i] != '"') {
        if (pseudo_str(full)[i] == '\\') {
          i++;
          instr[current_instr].strings.length++;
        }
        i++;
        instr[current_instr].strings.length++;
      }

      break;
    }

    if (!spe) {
      current_instr += 1;
    }

    i++;
  } while (k == 0 && i < full.length);

  *index = i;
}

#define string_to_view(s)                                                      \
  (string_view) { .base_pointer = s.base_pointer, .length = s.length }

int main() {

  for (int i = 0; (size_t)i < array_length(instr); i++) {
    instr[i].values_int[0] = 0;
  }

  string full = alloc_string();
  read_file_without_comments(&full, "test.lsek");

  size_t z = 0;
  find_expr(string_to_view(full), &z, 0);

  for (size_t k = 0; k < array_length(instr) && k < current_instr; k += 1) {
    printf("%d", instr[k].layer);
    for (int z = 0; z <= instr[k].layer; z++) {
      printf("  ");
    }
    switch (instr[k].cmd) {
    case number:
      printf("int: %d", instr[k].values_int[0]);
      break;
    case nstring:
      printf("\"" str_fmt "\"", print_str(instr[k].strings));
      break;
    case func:
      printf("func: "str_fmt, print_str(instr[k].strings));
      break;
    case add:
      printf("+");
      break;
    case minus:
      printf("-");
      break;
    case ndiv:
      printf("/");
      break;
    case mult:
      printf("*");
      break;
    }
    putchar('\n');
  }

  free_string(&full);
  return 0;
}