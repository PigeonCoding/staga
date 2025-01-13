#include "c_nice.h"
#define C_STRING
#include "c_string.h"
// ----------------
#include <stdio.h>
#include <string.h>

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
int is_alphabetical(char c) {
  if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')) {
    return 1;
  }
  return 0;
}

int is_numerical(char c) {
  if (c >= '0' && c <= '9') {
    return 1;
  }
  return 0;
}

int is_whitespace(char c) {
  if (c == ' ' || c == '\n') {
    return 1;
  }
  return 0;
}

typedef struct tokenizer {
  size_t count;
  string *og;
} tokenizer;

string_view get_next_token(tokenizer *tok) {
  string_view s = {0};

  while (is_whitespace(pseudo_str(*tok->og)[tok->count]) &&
         tok->count != tok->og->length) {
    tok->count++;
  }

  if (is_numerical(pseudo_str(*tok->og)[tok->count])) {
    s.base_pointer = tok->og->base_pointer + tok->count * char_size;
    s.length++;
    while (is_numerical(pseudo_str(*tok->og)[tok->count]) &&
           tok->count != tok->og->length) {
      s.length++;
      tok->count++;
    }
    s.length--;
    return s;
  }

  if (is_alphabetical(pseudo_str(*tok->og)[tok->count])) {
    s.base_pointer = tok->og->base_pointer + tok->count * char_size;
    s.length++;
    while (is_alphabetical(pseudo_str(*tok->og)[tok->count]) &&
           tok->count != tok->og->length) {
      s.length++;
      tok->count++;
    }
    s.length--;
    return s;
  }

  if (pseudo_str(*tok->og)[tok->count] == '"') {
    s.base_pointer = tok->og->base_pointer + tok->count * char_size;
    s.length++;
    tok->count++;
    while (pseudo_str(*tok->og)[tok->count] != '"') {
      if (pseudo_str(*tok->og)[tok->count] == '\\' &&
          pseudo_str(*tok->og)[tok->count + 1] == '"') {
        s.length++;
        tok->count++;
      }
      tok->count++;
      s.length++;
    }
    s.length++;
    tok->count++;
    return s;
  }

  if (is_whitespace(pseudo_str(*tok->og)[tok->count])) {
    eprintfn(P_ERR, "should not be here");
    return s;
  }

  s.base_pointer = tok->og->base_pointer + tok->count * char_size;
  s.length = 1;
  tok->count++;
  return s;
}

enum type {
  l_none,
  l_function,
  l_string,
  l_number,
  l_add,
  l_minus,
  l_mult,
  l_div,
  l_block,
};

const char *func_names[] = {"printf"};

typedef struct obj_thingy {
  int type;
  int layer;
  string_view value;
  char *var_name;
} obj_thingy;

obj_thingy list[1000] = {0};

obj_thingy maker(string_view s, int lay) {
  obj_thingy o = {0};
  o.layer = lay;
  o.value = s;
  if (pseudo_str(s)[0] == '"') {
    o.type = l_string;
  }

  if (is_numerical(pseudo_str(s)[0])) {
    o.type = l_number;
  }

  if (is_alphabetical(pseudo_str(s)[0])) {
    int is_func = 0;
    for (int z = 0; (size_t)z < array_length(func_names) && !is_func; z++) {
      if (str_cmp(s, func_names[z])) {
        is_func = 1;
      }
    }

    if (is_func) {
      o.type = l_function;
    }
  }

  if (pseudo_str(s)[0] == '(') {
    o.type = l_block;
    o.layer--;
  }

  if (pseudo_str(s)[0] == ')') {
    o.type = l_block;
    // o.layer--;
  }

  if (pseudo_str(s)[0] == '+') {
    o.type = l_add;
  }

  if (pseudo_str(s)[0] == '-') {
    o.type = l_minus;
  }
  if (pseudo_str(s)[0] == '/') {
    o.type = l_div;
  }
  if (pseudo_str(s)[0] == '*') {
    o.type = l_mult;
  }

  return o;
}

size_t list_sz = 0;

void to_qbe() {
  int str = 0;
  int num = 0;
  char buffer[1024];
  for (size_t k = list_sz; k > 0; k--) {
    if (list[k].type == l_string) {
      fprintf(out_f, "data $str%d = { b " str_fmt ", b 0 } ", str,
              print_str(list[k].value));
      sprintf(buffer, "$str%d", str);
      list[k].var_name = malloc((strlen(buffer) - 1) * char_size);
      strcpy(list[k].var_name, buffer);
      putc('\n', out_f);
      str++;
    }
  }

  // for (size_t k = list_sz; k > 0; k--) {

  //   if (new_instr[k].type == l_add) {

  //     if (strcmp(new_instr[k - 1].var_name, "") == 0 &&
  //         strcmp(new_instr[k + 1].var_name, "") == 0) {
  //       fprintf(out_f, "%%num%d =w add %d, %d", num, new_instr[k -
  //       1].value_int,
  //               new_instr[k + 1].value_int);
  //     } else if (strcmp(new_instr[k - 1].var_name, "") != 0 &&
  //                strcmp(new_instr[k + 1].var_name, "") == 0) {
  //       fprintf(out_f, "%%num%d =w add %s, %d", num, new_instr[k -
  //       1].var_name,
  //               new_instr[k + 1].value_int);
  //     } else if (strcmp(new_instr[k - 1].var_name, "") == 0 &&
  //                strcmp(new_instr[k + 1].var_name, "") != 0) {
  //       fprintf(out_f, "%%num%d =w add %d, %s", num, new_instr[k -
  //       1].value_int,
  //               new_instr[k + 1].var_name);
  //     } else {
  //       fprintf(out_f, "%%num%d =w add %s, %s", num, new_instr[k -
  //       1].var_name,
  //               new_instr[k + 1].var_name);
  //     }
  //     putc('\n', out_f);

  //     sprintf(buffer, "%%num%d", num);
  //     new_instr[k + 1].var_name = malloc((strlen(buffer) - 1) * char_size);
  //     strcpy(new_instr[k + 1].var_name, buffer);

  //     num++;
  //   }
  // }

  // putc('\n', out_f);
}
obj_thingy new[1000] = {0};

void order() {
  int start = 0;
  int start_l = 0;
  int end = 0;
  for (size_t z = list_sz - 1; z > 0; z--) {
    if (str_cmp(list[z].value, "(")) {
      start = z;
      start_l = list[z].layer;
    }
    if (list[z].layer == start_l && str_cmp(list[z].value, ")")) {
      end = z;
    }

    int max = 0;
    for (int x = start; x >= end; x--) {
      if (list[x].layer > max) {
        max = list[x].layer;
      }
    }

    for (int x = start; x >= end - 1 && max >= 0; x--) {
      if (list[x].layer == max && !(str_cmp(list[x].value, "(") || str_cmp(list[x].value, "("))) {
        push_to_array(new, list[x]);
      }

      if (x == end) {
        x = start;
        max--;
      }
    }
  }
}

int main() {

  for (int i = 0; (size_t)i < array_length(instr); i++) {
    instr[i].value_int = 0;
    instr[i].var_name = "";
    instr[i].done = 0;
  }

  string full = alloc_string();
  read_file_without_comments(&full, "test.lsek");
  eprintfn(P_INFO, "length: %zu", full.length);

  int layer = 0;
  string_view token = {0};
  tokenizer tok = {.count = 0, .og = &full};
  while (tok.count < full.length) {
    token = get_next_token(&tok);

    if (str_cmp(token, "(")) {
      layer++;
    } else if (str_cmp(token, ")")) {
      layer--;
    }

    push_to_array(list, maker(token, layer));
  }

  for (size_t z = 0; z < array_length(list) && list[z].value.base_pointer != 0;
       z++) {
    list_sz++;
  }

  order();

  for (size_t z = list_sz - 1; z > 0; z--) {
    printf("[INFO]: ");
    for (int k = 0; k < list[z].layer; k++) {
      printf("  ");
    }

    printf("=> " str_fmt "\n", print_str(list[z].value));
  }

  printf("---------------------------\n");

  for (size_t z = list_sz - 1; z > 0; z--) {
    printf("[INFO]: ");
    for (int k = 0; k < new[z].layer; k++) {
      printf("  ");
    }

    printf("=> " str_fmt "\n", print_str(new[z].value));
  }

  // for (int z = 00; z < 20; z++) {

  //   token = get_next_token(&tok);

  //   eprintfn(P_INFO, "%zu => " str_fmt, tok.count, print_str(token));
  // }

  // find_expr(string_to_view(full), &z, 0);
  // instr[current_instr + 1].type = l_none;
  // current_instr++;

  // print_instrs(1);
  // printf("------------------\n");

  to_qbe();

  free_string(&full);
  return 0;
}
