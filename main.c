#include "c_nice.h"
#define C_STRING
#include "c_string.h"
// ----------------
// #include <stdio.h>
#include <string.h>

#define out_f stdout

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
    while ((is_alphabetical(pseudo_str(*tok->og)[tok->count]) ||
            is_numerical(pseudo_str(*tok->og)[tok->count])) &&
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

const char *func_names[] = {"printf"};

string_view all[100] = {0};

enum n_instr { n_none, n_push, n_consume, n_add, n_div, n_mult, n_minus };

typedef struct {
  int instr_id;
  string_view data;
} instr;

instr list[100] = {0};

int main() {

  string full = alloc_string();
  read_file_without_comments(&full, "test.lsek");

  int array_len = 0;

  string_view token = {0};
  tokenizer tok = {.count = 0, .og = &full};
  while (tok.count < full.length) {
    token = get_next_token(&tok);
    push_to_array(all, token);
    array_len++;
  }

  for (size_t i = array_len - 1; i > 0; i--) {
    if (!(str_cmp(all[i], "(")) && !(str_cmp(all[i], ")"))) {
      instr stuff = {0};
      if (pseudo_str(all[i])[0] == '+') {
        stuff = (instr){.instr_id = n_add, .data = all[i - 1]};
        i -= 1;
      } else if (pseudo_str(all[i])[0] == '-') {
        stuff = (instr){.instr_id = n_minus, .data = all[i - 1]};
        i -= 1;
      } else if (pseudo_str(all[i])[0] == '/') {
        stuff = (instr){.instr_id = n_div, .data = all[i - 1]};
        i -= 1;
      } else if (pseudo_str(all[i])[0] == '*') {
        stuff = (instr){.instr_id = n_mult, .data = all[i - 1]};
        i -= 1;
      } else if (pseudo_str(all[i])[0] == '"' ||
                 is_numerical(pseudo_str(all[i])[0])) {
        stuff = (instr){.instr_id = n_push, .data = all[i]};
      }

      for (int z = 0; (size_t)z < array_length(func_names); z++) {
        if (str_cmp(all[i], func_names[z])) {
          stuff = (instr){.instr_id = n_consume, .data = all[i]};
        }
      }

      if (stuff.instr_id == n_none) {
        eprintfn(P_ERR, "something fishy here" str_fmt, print_str(all[i]));
        return 1;
      }
      push_to_array(list, stuff);
    }
  }
  array_len = 0;
  while (list[array_len].instr_id != n_none) {
    array_len++;
  }
  for (int i = 0; i <= array_len / 2; i++) {
    instr tmp = list[i];
    list[i] = list[array_len - i];
    list[array_len - i] = tmp;
  }
  array_len++;

  for (int i = 1; i < array_len; i++) {
    eprintfn(P_INFO, "%d::" str_fmt, list[i].instr_id, print_str(list[i].data));
  }

  free_string(&full);
  return 0;
}
