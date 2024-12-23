#include "nice.h"
#include <stdio.h>
#include <string.h>
#define C_STRING
#include "cstring.h"

#define out_f stdout

typedef struct {
  int type;
  int layer;
  int value_int;
  string_view string;
  char *var_name;
  int done;
} Cmd;

Cmd instr[1000] = {0};
Cmd new_instr[1000] = {0};
size_t current_instr = 0;
size_t new_current_instr = 0;

size_t z = 0;

enum OP_Code {
  l_none,
  l_block,
  l_comma,
  l_add,
  l_minus,
  l_mult,
  l_div,
  l_int,
  l_func,
  l_string,
};

void find_expr(string_view full, size_t *index, int layerz) {
  size_t i = *index + 1;
  int k = 0;
  int spe = 0;
  while (k == 0 && i < full.length) {
    spe = 0;
    instr[current_instr].layer = layerz;

    switch (pseudo_str(full)[i]) {
    // misc stuff
    case '(':
      // instr[current_instr].type = l_block;
      // current_instr++;
      find_expr(full, &i, layerz + 1);
      spe = 1;
      // current_instr--;
      break;
    case ')':
      instr[current_instr].type = l_block;
      // spe = 1;

      // current_instr--;
      k = 1;
      i--;
      ;
      break;
    case ',':
      instr[current_instr].type = l_comma;
      break;
    case ' ':
    case '\n':
      spe = 1;
      break;

    // nummbers
    case '0' ... '9':
      instr[current_instr].type = l_int;
      for (size_t j = i; j < full.length; j++) {
        switch (pseudo_str(full)[j]) {
        case '0':
          instr[current_instr].value_int =
              instr[current_instr].value_int * 10 + 0;
          break;
        case '1':
          instr[current_instr].value_int =
              instr[current_instr].value_int * 10 + 1;
          break;
        case '2':
          instr[current_instr].value_int =
              instr[current_instr].value_int * 10 + 2;
          break;
        case '3':
          instr[current_instr].value_int =
              instr[current_instr].value_int * 10 + 3;
          break;
        case '4':
          instr[current_instr].value_int =
              instr[current_instr].value_int * 10 + 4;
          break;
        case '5':
          instr[current_instr].value_int =
              instr[current_instr].value_int * 10 + 5;
          break;
        case '6':
          instr[current_instr].value_int =
              instr[current_instr].value_int * 10 + 6;
          break;
        case '7':
          instr[current_instr].value_int =
              instr[current_instr].value_int * 10 + 7;
          break;
        case '8':
          instr[current_instr].value_int =
              instr[current_instr].value_int * 10 + 8;
          break;
        case '9':
          instr[current_instr].value_int =
              instr[current_instr].value_int * 10 + 9;
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
      instr[current_instr].type = l_add;
      break;
    case '-':
      instr[current_instr].type = l_minus;
      break;
    case '*':
      instr[current_instr].type = l_mult;
      break;
    case '/':
      instr[current_instr].type = l_div;
      break;

    // functions
    case 'a' ... 'z':
    case 'A' ... 'Z':
    case '_':
      instr[current_instr].type = l_func;
      instr[current_instr].string.base_pointer =
          full.base_pointer + i * char_size;

      while (((pseudo_str(full)[i] >= 'a' && pseudo_str(full)[i] <= 'z') ||
              (pseudo_str(full)[i] >= 'A' && pseudo_str(full)[i] <= 'Z') ||
              pseudo_str(full)[i] == '_') &&
             (i < full.length)) {
        instr[current_instr].string.length++;
        i++;
      }

      while (pseudo_str(full)[i] != ',' || pseudo_str(full)[i] == '(') {
        i++;
      }
      i--;
      break;

    case '"':
      instr[current_instr].type = l_string;
      instr[current_instr].string.base_pointer =
          full.base_pointer + (i + 1) * char_size;
      i++;
      while (pseudo_str(full)[i] != '"') {
        if (pseudo_str(full)[i] == '\\') {
          i++;
          instr[current_instr].string.length++;
        }
        i++;
        instr[current_instr].string.length++;
      }

      break;
    }

    if (!spe) {
      current_instr += 1;
    }
    i++;
  }

  *index = i;
}

void print_instrs(int q) {
  Cmd n_instr[1000] = {0};
  size_t count = 0;
  if (q) {
    count = current_instr;
    memcpy(n_instr, instr, sizeof(instr));
  } else {
    count = new_current_instr;
    memcpy(n_instr, new_instr, sizeof(instr));
  }

  for (size_t k = 0; k < array_length(n_instr) && k < count; k += 1) {
    // printf("%zu :: %d", k, n_instr[k].layer);
    // putchar(' ');
    // for (int z = 0; z < n_instr[k].layer; z++) {
    //   putchar('-');
    // }
    switch (n_instr[k].type) {
    case l_int:
      printf(" int : %d", n_instr[k].value_int);
      break;
    case l_string:
      printf(" \"" str_fmt "\"", print_str(n_instr[k].string));
      break;
    case l_func:
      printf(" func: " str_fmt, print_str(n_instr[k].string));
      break;
    case l_add:
      printf(" op  : +");
      break;
    case l_minus:
      printf(" op  : -");
      break;
    case l_div:
      printf(" op  : /");
      break;
    case l_mult:
      printf(" op  : *");
      break;
    case l_comma:
      printf(" --------");
      break;
    case l_block:
      printf(" block");
      break;
    default:
      printf(" wtf");
      break;
    }
    putchar('\n');
  }
}

void order() {
  int last = 0;

  // int end = 0;
  for (int k = 0; k < array_length(instr) && k <= current_instr; k++) {

    if ((instr[k].type == l_block && instr[k + 1].type != l_block)) {
      int max = 0;
      for (int i = last; i < k - 1; i++) {
        if (max < instr[i].layer) {
          max = instr[i].layer;
        }
      }

      int i = 0;
      while (max > 0 && i < k + 1) {

        if (instr[k - i].type == l_block) {

        } else {
          if (instr[k - i].layer == max && instr[k - i].done == 0) {
            instr[k - i].done = 1;
            instr[k - i].layer = 0;
            push_to_array(new_instr, instr[k - i]);
            new_current_instr++;
          }
        }

        if (i == k) {
          max--;
          i = 0;
        }
        i++;
      }
      k++;
    }
  }
  putchar('\n');

  for (int k = 0; k <= new_current_instr; k++) {
    if (new_instr[k].type == l_div || new_instr[k].type == l_minus) {
      Cmd temp;
      temp = new_instr[k - 1];
      new_instr[k - 1] = new_instr[k + 1];
      new_instr[k + 1] = temp;
    }
  }

  print_instrs(0);
}

void to_qbe() {
  int str = 0;
  int num = 0;
  char buffer[1024];
  for (size_t k = new_current_instr; k > 0; k--) {
    if (new_instr[k].type == l_string) {

      fprintf(out_f, "data $str%d = { b \"" str_fmt "\", b 0 } ", str,
              print_str(new_instr[k].string));
      sprintf(buffer, "$str%d", str);
      new_instr[k].var_name = malloc((strlen(buffer) - 1) * char_size);
      strcpy(new_instr[k].var_name, buffer);
      putc('\n', out_f);
      str++;
    }
  }

  for (size_t k = new_current_instr; k > 0; k--) {

    if (new_instr[k].type == l_add) {

      if (strcmp(new_instr[k - 1].var_name, "") == 0 &&
          strcmp(new_instr[k + 1].var_name, "") == 0) {
        fprintf(out_f, "%%num%d =w add %d, %d", num, new_instr[k - 1].value_int,
                new_instr[k + 1].value_int);
      } else if (strcmp(new_instr[k - 1].var_name, "") != 0 &&
                 strcmp(new_instr[k + 1].var_name, "") == 0) {
        fprintf(out_f, "%%num%d =w add %s, %d", num, new_instr[k - 1].var_name,
                new_instr[k + 1].value_int);
      } else if (strcmp(new_instr[k - 1].var_name, "") == 0 &&
                 strcmp(new_instr[k + 1].var_name, "") != 0) {
        fprintf(out_f, "%%num%d =w add %d, %s", num, new_instr[k - 1].value_int,
                new_instr[k + 1].var_name);
      } else {
        fprintf(out_f, "%%num%d =w add %s, %s", num, new_instr[k - 1].var_name,
                new_instr[k + 1].var_name);
      }
      putc('\n', out_f);

      sprintf(buffer, "%%num%d", num);
      new_instr[k + 1].var_name = malloc((strlen(buffer) - 1) * char_size);
      strcpy(new_instr[k + 1].var_name, buffer);

      num++;
    }
  }

  // putc('\n', out_f);
}

int main() {

  for (int i = 0; (size_t)i < array_length(instr); i++) {
    instr[i].value_int = 0;
    instr[i].var_name = "";
    instr[i].done = 0;
  }

  string full = alloc_string();
  read_file_without_comments(&full, "test.lsek");

  find_expr(string_to_view(full), &z, 0);
  instr[current_instr + 1].type = l_none;
  current_instr++;

  print_instrs(1);
  printf("------------------\n");
  order();

  to_qbe();

  free_string(&full);
  return 0;
}