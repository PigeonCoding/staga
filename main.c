#include "nice.h"
#include <stdio.h>
#include <string.h>
#define C_STRING
#include "cstring.h"

int instr[100] = {0};
size_t current_instr = 0;

enum OP_Code {
  add,
  minus,
  mult,
  ndiv,
};




int main() {
  string full = alloc_string();
  read_file_without_comments(&full, "test.lsek");

  for (size_t i = 0; i < full.length; i++) {

    char current = pseudo_str(full)[i];
    switch (pseudo_str(full)[i]) {
    case ' ':
    case '\n':
      break;

    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      for (size_t j = i; j < full.length; j++) {
        switch (pseudo_str(full)[j]) {
        case '0':
          instr[current_instr] = instr[current_instr] * 10 + 0;
          break;
        case '1':
          instr[current_instr] = instr[current_instr] * 10 + 1;
          break;
        case '2':
          instr[current_instr] = instr[current_instr] * 10 + 2;
          break;
        case '3':
          instr[current_instr] = instr[current_instr] * 10 + 3;
          break;
        case '4':
          instr[current_instr] = instr[current_instr] * 10 + 4;
          break;
        case '5':
          instr[current_instr] = instr[current_instr] * 10 + 5;
          break;
        case '6':
          instr[current_instr] = instr[current_instr] * 10 + 6;
          break;
        case '7':
          instr[current_instr] = instr[current_instr] * 10 + 7;
          break;
        case '8':
          instr[current_instr] = instr[current_instr] * 10 + 8;
          break;
        case '9':
          instr[current_instr] = instr[current_instr] * 10 + 9;
          break;
        default:
          j = full.length + 1;
          i -= 2;
          break;
        }
        i++;
      }

      break;

    case '+':
      instr[current_instr] = add;
      break;
    case '-':
      instr[current_instr] = minus;
      break;
    case '*':
      instr[current_instr] = mult;
      break;
    case '/':
      instr[current_instr] = ndiv;
      break;
    default:
      eprintfn(P_INFO, "no idea wtf is %c", current);
      current_instr--;
    }

    current_instr += 1;
  }

  for (size_t k = 0; k < array_length(instr); k++) {
    printf("%d", instr[k]);
  }
  putchar('\n');

  free_string(&full);
  return 0;
}