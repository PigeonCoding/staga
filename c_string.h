// version 0.4

/*
  string test_string = alloc_string();

  push_char_ptr(&test_string, "Hello World!");

  printf("%s\n", get_string_c(&test_string));

  free_string(&test_string);
*/

#include "c_nice.h"

#ifndef STRING_BUFFER_SIZE
#define STRING_BUFFER_SIZE 1024
#endif
#ifndef char_size
#define char_size sizeof(char)
#endif
#ifndef pseudo_str
#define pseudo_str(s) ((char *)(s).base_pointer)
#endif
#ifndef print_str
#define print_str(s) (int)((s).length), pseudo_str(s)
#endif
#ifndef string_to_view
#define string_to_view(s)                                                      \
  (string_view) { .base_pointer = s.base_pointer, .length = s.length }
#endif

#ifndef V_STDLIB
#define V_STDLIB
#include <stdlib.h>
#define V_MALLOC malloc
#define V_REALLOC realloc
#define V_CALLOC calloc
#define V_FREE free
#define V_EXIT(x) exit(x)
#endif

#ifndef V_STRING
#define V_STRING
#include <string.h>
#define V_MEMCPY memcpy
#define V_STRNCPY strncpy
#endif

#ifndef V_STDIO
#define V_STDIO
#include <stdio.h>
#define V_FPRINTF fprintf
#define V_SPRINTF sprintf
#endif

typedef struct string string;
typedef struct string_view string_view;

string alloc_string();
void prealloc_string(string *s, size_t num);
void *get_string_data_pointer(string *a, size_t size);
void push_char_to_string(string *s, char c);
void push_char_ptr(string *s, const char *c);
void push_string_view(string *s, string_view s2);
char *get_string_c(string *s);
char *get_string_c_tmp(string *s);
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
#ifndef push_to_string
#define push_to_string(s, ...)                                                 \
  {                                                                            \
    char buff431423154[1024 * 1024] = {0};                                     \
    sprintf(buff431423154, __VA_ARGS__);                                       \
    push_char_ptr(&(s), buff431423154);                                        \
  }
#endif
#ifndef push_str_whitespace
#define push_str_whitespace(s, ...)                                            \
  push_to_string(s, __VA_ARGS__);                                              \
  push_char_to_string(&(s), ' ');
#endif
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

#define C_STRING_IMPLEMENTATION
#ifdef C_STRING_IMPLEMENTATION

struct string {
  void *base_pointer;
  size_t size;
  size_t length;
};

struct string_view {
  void *base_pointer;
  size_t length;
};

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
  s->size += char_size * (num * 2);
  s->base_pointer = realloc(s->base_pointer, s->size);
}

void *get_string_data_pointer(string *a, size_t size) {
  if (a->base_pointer == NULL) {
    V_FPRINTF(stderr,
              "[ERR]: base pointer is null either it was not initialized or it "
              "has been freed:)\n ");
    V_EXIT(1);
  }

  if (size < a->size - (a->length - 1) * char_size) {
    void *out = (a->base_pointer + (a->length - 1) * char_size);
    return out;
  }
  V_FPRINTF(stderr,
            "[ERR]: tried to allocate more than the arena had %zu > %zu\n",
            size, a->size - (a->length - 1) * char_size);
  V_EXIT(1);
}

char *get_char(string *s, size_t index) {
  return (char *)(s->base_pointer + index * char_size);
}

void read_file(string *s, const char *filename) {

  FILE *file;
  int charCount = 0;

  // Open the file
  file = fopen(filename, "r");
  if (file == NULL) {
    printf("[ERR]: Failed to open file %s\n", filename);
    return;
  }

  // Count the characters
  char c;
  while ((c = fgetc(file)) != EOF) {
    charCount++;
  }

  char content[STRING_BUFFER_SIZE] = {0};

  rewind(file);

  while (1) {

    size_t bytes_to_read = (size_t)charCount <= STRING_BUFFER_SIZE
                               ? (size_t)charCount
                               : STRING_BUFFER_SIZE;
    if (fgets(content, bytes_to_read, file) == NULL) {
      break;
    }

    push_char_ptr(s, content);
  }

  // Close the file
  fclose(file);
}

void read_file_without_comments(string *s, const char *filename) {
  FILE *fptr;
  fptr = fopen(filename, "r");
  if (fptr == NULL) {
    V_FPRINTF(stderr, "[ERROR]: cannot read file %s\n", filename);
    return;
  }

  char content[STRING_BUFFER_SIZE];

  while (fgets(content, STRING_BUFFER_SIZE, fptr)) {
    if (!(compare_str(content, "//", 2, 0) ||
          compare_str(content, "#", 1, 0)) &&
        !is_chars_empty((char *)s->base_pointer))
      push_char_ptr(s, content);
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
    prealloc_string(s, 2);
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

void push_char_to_string(string *s, char c) {
  s->length++;

  if (s->length * char_size < s->size) {
    prealloc_string(s, 2);
  }

  void *g = get_string_data_pointer(s, char_size);
  V_MEMCPY(g, (void *)(&c), char_size);
}

void push_char_ptr(string *s, const char *c) {
  char *h;
  for (h = (char *)c; *h; h++) {
    push_char_to_string(s, *h);
  }
}

void push_string_view(string *s, string_view s2) {
  for (size_t i = 0; i < s2.length; i++) {
    push_char_to_string(s, pseudo_str(s2)[i]);
  }
}

char *get_string_c(string *s) {
  push_char_to_string(s, '\0');
  return (char *)s->base_pointer;
}

char *get_string_c_tmp(string *s) {
  char *tmp = (char *)V_CALLOC((s->length + 1), char_size);
  V_STRNCPY(tmp, (char *)s->base_pointer, (s->length) * char_size);
  return tmp;
}

string copy_string(string *s) {
  string ss = alloc_string();
  prealloc_string(&ss, s->length);
  ss.length = s->length;
  ss.size = s->size;
  V_MEMCPY(ss.base_pointer, s->base_pointer, s->size);
  return ss;
}

void safe_free(void *ptr) {
  if (ptr != NULL) {
    V_FREE(ptr);
    ptr = NULL;
  }
}

void *safe_realloc(void *ptr, size_t size) {
  void *new_ptr = V_REALLOC(ptr, size);
  if (new_ptr == NULL) {
    // Handle memory allocation error
    V_FPRINTF(stderr, "[ERR]: Memory allocation failed");
    V_EXIT(1); // or some other error handling mechanism
  }
  return new_ptr;
}

void reset_string(string *s) {
  // s->base_pointer = V_REALLOC(s->base_pointer, 1);
  // s->size = char_size * 2;
  *(char *)(s->base_pointer) = ' ';
  s->length = 0;
}

void free_string(string *s) {
  safe_free(s->base_pointer);
  s->base_pointer = NULL;
  s->size = 0;
  s->length = 0;
}
#endif // C_STRING_IMPLEMENTATION
