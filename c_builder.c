// #define B_SILENT

#include "c_builder.h"
#include "c_nice.h"

#define compiler "gcc"
#define builder_name "c_builder"
#define builder_build_flags " -O2 "
#define main_build_flags " -g -Wall -Wextra -Wswitch-enum "

#define dir_lib "lib"
#define dir_build "build"
#define dir_include "include"

const char *files_check[] = {"main.c", "c_nice.h", "c_string.h"};
const char *builder_files[] = {"c_builder.c", "c_builder.h"};

int check_build(int z) {
  if (check_file(builder_files[0]) | check_file(builder_files[1]) | (z == 2)) {
    push_str_whitespace(cmd,
                        compiler " %s" main_build_flags builder_build_flags
                                 "-o " builder_name,
                        builder_files[0]);
    exec_and_reset_and_log(cmd);

    reset_string(&temp);
    push_str_whitespace(temp, "./" builder_name);
    if (strcmp(first_arg, "NULL") != 0)
      push_str_whitespace(temp, "%s", strcmp(first_arg, "f_build") == 0 ? "m_build" : first_arg);

    system(get_string_c(&temp));

    return 1;
  }

  int b = 0;

  for (int i = 0; (size_t)i < array_length(files_check); i++) {
    if (check_file(files_check[i]) | (z == 1)) {
      b = 1;
    }
  }

  if (b) {
    push_str_whitespace(cmd, compiler " %s", files_check[0]);
    push_str_whitespace(cmd, main_build_flags);
    // push_str_whitespace(cmd, "-L" dir_lib " -Wl,--enable-new-dtags -lsqlite3");
    push_str_whitespace(cmd, "-g -Wall -Wextra -Wswitch-enum");
    push_str_whitespace(cmd, "-o " dir_build "/main");

    exec_and_reset_and_log(cmd);
  }

  return 0;
}

int main(int argc, char *argv[]) {
  // check_arg_num(2);
  init_builder();

  if (check_arg_is("f_build")) {
    if (check_build(2))
      return 0;
  }else if (check_arg_is("m_build")){
    if (check_build(1))
      return 0;
  } else if (check_arg_is("build")) {
    if (check_build(0))
      return 0;
  }else if (check_arg_is("qbe-test")) {
    if (check_build(0))
      return 0;
    push_str_whitespace(cmd, "qbe -o " dir_build "/qbe/out.s qbe-test.ssa && cc build/qbe/out.s -o build/qbe-test");
    exec_and_reset_and_log(cmd);
    push_str_whitespace(cmd, "./build/qbe-test");
    exec_and_reset_and_log(cmd);
  } else {
    if (check_build(0))
      return 0;

    push_str_whitespace(cmd, "./build/main");
    exec_and_reset_and_log(cmd);
  }

  free_string(&cmd);
  free_string(&temp);

  return 0;
}
