#pragma once

// version 0.4

/*
  string test_string = alloc_string();

  push_string(&test_string, "Hello World!");

  printf("%s\n", get_string_c(&test_string));

  free_string(&test_string);
*/

#define STRING_BUFFER_SIZE 1024 * 1024
#define char_size sizeof(char)
#define pseudo_str(s) ((char *)(s).base_pointer)
#define print_str(s) (int)((s).length), pseudo_str(s)
#define string_to_view(s)                                                      \
  (string_view) { .base_pointer = s.base_pointer, .length = s.length }

#ifndef V_ALLOC
#include <stdlib.h>
#define V_MALLOC malloc
#define V_REALLOC realloc
#endif

#ifndef V_EXIT
#include <stdlib.h>
#define V_EXIT(x) exit(x)
#endif

#ifndef V_MEMCPY
#include <string.h>
#define V_MEMCPY memcpy
#endif

#ifndef V_FPRINTF
#include <stdio.h>
#define V_FPRINTF fprintf
#endif

typedef struct {
  void *base_pointer;
  size_t size;
  size_t length;
} string;

typedef struct {
  void *base_pointer;
  size_t length;
} string_view;

string alloc_string();
void prealloc_string(string *s, size_t num);
void *get_string_data_pointer(string *a, size_t size);
void push_char_string(string *s, char c);
void push_string_whitespace(string *s, const char *c);
void push_string(string *s, const char *c);
void push_string_view(string *s, string_view s2);
char *get_string_c(string *s);
short int compare_str(const char *s1, const char *s2, size_t size,
                      short int check_sz);
char *get_char(string *s, size_t index);
void read_file(string *s, const char *filename);
void read_file_without_comments(string *s, const char *filename);
void insert_into_string(string *s, char c, size_t index);
void chop_string(string *s, size_t index);
void shift_string_left(string *s, size_t length, size_t index);
void remove_trailing_whitespace(string *s);
string copy_string(string *s);
void free_string(string *s);
void reset_string(string *s);
int is_chars_empty(char *s);
#ifndef sforeach_ref
#define sforeach_ref(name, str, i)                                             \
  for (unsigned long i = 0; i < str.length; i++) {                             \
    char *name = get_char(&str, i);
#endif // sforeach_ref
#ifndef sforeach_val
#define sforeach_val(name, str, i)                                             \
  for (unsigned long i = 0; i < str.length; i++) {                             \
    char name = *get_char(&str, i);
#endif // sforeach_val
#ifndef end_foreach
#define end_foreach }
#endif // end_foreach
#ifndef str_fmt
#define str_fmt "%.*s"
#endif
#ifndef str_cmp
#define str_cmp(str, other)                                                    \
  (str).length >= strlen(other) &&                                             \
      strncmp(pseudo_str(str), other, (str).length) ==                         \
          0 // compares string/string_view to const char*
#endif
// #define C_STRING
#ifdef C_STRING

short int compare_str(const char *s1, const char *s2, size_t size,
                      short int check_sz) {

  if ((size > strlen(s1) || size > strlen(s2)) && check_sz) {
    return -1;
  }

  for (size_t i = 0; i < size; i++) {
    if (s1[i] != s2[i]) {
      return 0;
    }
  }
  return 1;
}

string alloc_string() {
  string s;
  s.base_pointer = V_MALLOC(char_size * 2);
  if (s.base_pointer == NULL) {
    V_FPRINTF(stderr, "buy more ram :)");
    V_EXIT(1);
  }

  s.size = char_size * 2;
  s.length = 0;
  return s;
}

void prealloc_string(string *s, size_t num) {
  s->base_pointer = V_REALLOC(s->base_pointer, char_size * num * 2);
  s->size = char_size * num * 2;
}

void *get_string_data_pointer(string *a, size_t size) {
  if (a->base_pointer == NULL) {
    V_FPRINTF(stderr,
              "base pointer is null either it was not initialized or it "
              "has been freed:)\n ");
    V_EXIT(1);
  }

  if (size < a->size - (a->length - 1) * char_size) {
    void *out = (a->base_pointer + (a->length - 1) * char_size);
    return out;
  }
  V_FPRINTF(stderr,
            "ERROR: tried to allocate more than the arena had %zu > %zu\n",
            size, a->size - (a->length - 1) * char_size);
  V_EXIT(1);
}

char *get_char(string *s, size_t index) {
  return (char *)(s->base_pointer + index * char_size);
}

void read_file(string *s, const char *filename) {
  FILE *fptr;
  fptr = fopen(filename, "r");
  if (fptr == NULL) {
    V_FPRINTF(stderr, "[ERROR]: cannot read file %s\n", filename);
    return;
  }

  char content[STRING_BUFFER_SIZE];
  while (fgets(content, 100, fptr)) {
    if (!is_chars_empty((char *)s->base_pointer)) {
      push_string(s, content);
      remove_trailing_whitespace(s);
    }
  }
  fclose(fptr);
}

void read_file_without_comments(string *s, const char *filename) {
  FILE *fptr;
  fptr = fopen(filename, "r");
  if (fptr == NULL) {
    V_FPRINTF(stderr, "[ERROR]: cannot read file %s\n", filename);
    return;
  }

  char content[1024 * 1024];
  while (fgets(content, 100, fptr)) {
    if (!(compare_str(content, "//", 2, 0) ||
          compare_str(content, "#", 1, 0)) &&
        !is_chars_empty((char *)s->base_pointer))
      push_string(s, content);
    // remove_trailing_whitespace(s);
  }
  fclose(fptr);
}

void remove_trailing_whitespace(string *s) {
  while (*get_char(s, s->length - 1) == ' ') {
    s->length--;
  }
}

int is_chars_empty(char *s) {
  for (size_t i = 0; i < STRING_BUFFER_SIZE; i++) {
    if (s[i] != ' ' || s[i] != '\n') {
      return 0;
    }
  }
  return 1;
}

void insert_into_string(string *s, char c, size_t index) {
  s->length++;

  if (s->length * char_size < s->size) {
    prealloc_string(s, s->length + 1);
  }

  char *cc = (char *)s->base_pointer;

  for (size_t i = s->length; i > index; i--) {
    cc[i] = cc[i - 1];
  }
  cc[index] = c;
}

void chop_string(string *s, size_t index) {
  if (index < 1) {
    return;
  }
  for (size_t y = index; y < s->length; y++) {
    pseudo_str(*s)[y] = pseudo_str(*s)[y + 1];
  }
  s->length -= 1;
}

void shift_string_left(string *s, size_t length, size_t index) {
  for (size_t i = 0; i < length; i++) {
    chop_string(s, index - i);
  }
}

void push_char_string(string *s, char c) {
  s->length++;

  if (s->length * char_size < s->size) {
    prealloc_string(s, s->length + 1);
  }

  void *g = get_string_data_pointer(s, char_size);
  V_MEMCPY(g, (void *)(&c), char_size);
}

void push_string_whitespace(string *s, const char *c) {
  char *h;
  for (h = (char *)c; *h; h++) {
    push_char_string(s, *h);
  }
  push_char_string(s, ' ');
}

void push_string(string *s, const char *c) {
  char *h;
  for (h = (char *)c; *h; h++) {
    push_char_string(s, *h);
  }
}

void push_string_view(string *s, string_view s2) {
  for (size_t i = 0; i < s2.length; i++) {
    push_char_string(s, pseudo_str(s2)[i]);
  }
}

char *get_string_c(string *s) {
  *(char *)(s->base_pointer + s->length) = '\0';
  return (char *)s->base_pointer;
}

string copy_string(string *s) {
  string ss = alloc_string();
  prealloc_string(&ss, s->length);
  ss.length = s->length;
  ss.size = s->size;
  memcpy(ss.base_pointer, s->base_pointer, s->size);
  return ss;
}

void reset_string(string *s) {
  s->base_pointer = realloc(s->base_pointer, 1);
  *(int *)(s->base_pointer) = 0;
  s->size = char_size * 2;
  s->length = 0;
}

void free_string(string *s) {
  free(s->base_pointer);
  s->base_pointer = NULL;
  s->size = 0;
  s->length = 0;
}
#endif // C_STRING
