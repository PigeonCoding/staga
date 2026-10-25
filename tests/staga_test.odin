package staga_tests

// End-to-end tests for the Staga interpreter.
//
// The interpreter is built into a temporary directory once, then every test
// runs a real program through it and checks stdout/stderr/exit code. That way
// the tests cover the CLI, diagnostics and stack effects together, and a
// failing program cannot take the test runner down with it.
//
// Run with:
//     odin test tests
//     odin test tests -define:ODIN_TEST_THREADS=4

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:sync"
import "core:testing"

@(private = "file")
lock: sync.Mutex

@(private = "file")
binary: string

@(private = "file")
work_dir: string

@(private = "file")
file_counter: int

@(private = "file")
setup_done: bool

@(private = "file")
setup_ok: bool

Run_Result :: struct {
  stdout:    string,
  stderr:    string,
  exit_code: int,
}

// Builds the interpreter once per test process.
setup :: proc(t: ^testing.T) -> bool {
  sync.mutex_lock(&lock)
  defer sync.mutex_unlock(&lock)

  if setup_done do return setup_ok
  setup_done = true

  tmp, tmp_err := os.temp_dir(context.allocator)
  if tmp_err != nil {
    testing.expectf(t, false, "cannot find a temporary directory: %v", tmp_err)
    return false
  }
  defer delete(tmp)

  dir, join_err := filepath.join(
    []string{tmp, "staga-odin-tests"},
  )
  if join_err != nil {
    testing.expectf(t, false, "cannot build a temporary path: %v", join_err)
    return false
  }
  // The test runner frees test-local allocations when a test finishes, while
  // other threads may still use these paths, so keep them on the heap.
  work_dir = strings.clone(dir, os.heap_allocator())
  delete(dir)
  _ = os.remove_all(work_dir)
  if mk_err := os.make_directory(work_dir); mk_err != nil {
    testing.expectf(t, false, "cannot create '%s': %v", work_dir, mk_err)
    return false
  }

  bin, bin_err := filepath.join([]string{work_dir, "staga_test"})
  if bin_err != nil {
    testing.expectf(t, false, "cannot build the interpreter path: %v", bin_err)
    return false
  }
  binary = strings.clone(bin, os.heap_allocator())
  delete(bin)

  // #directory is ".../tests/". One level up is the repository root.
  root := filepath.dir(strings.trim_right(#directory, "/"))
  src_dir, src_err := filepath.join([]string{root, "src"})
  if src_err != nil {
    testing.expectf(t, false, "cannot locate the source directory: %v", src_err)
    return false
  }

  state, out, err_out, exec_err := os.process_exec(
    os.Process_Desc{command = []string{"odin", "build", src_dir, fmt.tprintf("-out:%s", binary)}},
    context.allocator,
  )
  delete(src_dir)
  defer {
    delete(out)
    delete(err_out)
  }

  if exec_err != nil {
    testing.expectf(t, false, "could not run 'odin build': %v", exec_err)
    return false
  }
  if state.exit_code != 0 {
    testing.expectf(
      t,
      false,
      "could not build the interpreter (exit %d):\n%s",
      state.exit_code,
      err_out,
    )
    return false
  }

  setup_ok = true
  return true
}

@(private = "file")
run_raw :: proc(t: ^testing.T, args: []string) -> Run_Result {
  sync.mutex_lock(&lock)
  defer sync.mutex_unlock(&lock)

  if !setup_ok do return Run_Result{exit_code = -1}

  state, out, err_out, exec_err := os.process_exec(
    os.Process_Desc{command = args},
    context.allocator,
  )
  result := Run_Result{
    stdout    = strings.clone(string(out)),
    stderr    = strings.clone(string(err_out)),
    exit_code = state.exit_code,
  }
  delete(out)
  delete(err_out)

  if exec_err != nil {
    testing.expectf(t, false, "could not execute %v: %v", args, exec_err)
    return Run_Result{exit_code = -1}
  }
  return result
}

@(private = "file")
run_file :: proc(t: ^testing.T, path: string) -> Run_Result {
  return run_raw(t, []string{binary, path})
}

@(private = "file")
run_program :: proc(t: ^testing.T, source: string) -> Run_Result {
  sync.mutex_lock(&lock)
  file_counter += 1
  name := fmt.aprintf("prog_%d.stg", file_counter)
  sync.mutex_unlock(&lock)
  defer delete(name)

  path, join_err := filepath.join([]string{work_dir, name})
  if join_err != nil {
    testing.expectf(t, false, "cannot build the program path: %v", join_err)
    return Run_Result{exit_code = -1}
  }
  defer delete(path)
  if write_err := os.write_entire_file(path, source); write_err != nil {
    testing.expectf(t, false, "cannot write '%s': %v", path, write_err)
    return Run_Result{exit_code = -1}
  }
  return run_file(t, path)
}

// Asserts that the program runs successfully and prints exactly `expected`.
@(private = "file")
expect_output :: proc(t: ^testing.T, name, source, expected: string) {
  r := run_program(t, source)
  defer {
    delete(r.stdout)
    delete(r.stderr)
  }

  if r.exit_code != 0 {
    testing.expectf(
      t,
      false,
      "%s: expected success, got exit code %d\nstderr: %s",
      name,
      r.exit_code,
      r.stderr,
    )
    return
  }

  testing.expectf(
    t,
    r.stdout == expected,
    "%s: wrong output\nexpected: %q\ngot:      %q",
    name,
    expected,
    r.stdout,
  )
}

// Asserts that the program fails with a diagnostic containing `needle`.
@(private = "file")
expect_error :: proc(t: ^testing.T, name, source, needle: string) {
  r := run_program(t, source)
  defer {
    delete(r.stdout)
    delete(r.stderr)
  }

  if r.exit_code == 0 {
    testing.expectf(
      t,
      false,
      "%s: expected a non-zero exit code\nstdout: %s",
      name,
      r.stdout,
    )
    return
  }

  testing.expectf(
    t,
    strings.contains(r.stderr, needle),
    "%s: expected an error containing %q, got %q",
    name,
    needle,
    r.stderr,
  )
  // Diagnostics should come from Staga, never from an Odin assertion.
  testing.expectf(
    t,
    !strings.contains(r.stderr, "runtime assertion"),
    "%s: leaked an Odin runtime assertion: %s",
    name,
    r.stderr,
  )
}

@test
test_arithmetic :: proc(t: ^testing.T) {
  if !setup(t) do return

  expect_output(
    t,
    "arithmetic",
    `
-5 5 + .
6 1 - .
2 10 * .
10 5 / .
`,
    "0\n5\n20\n2\n",
  )

  expect_output(t, "float arithmetic", `1.5 2.5 + . 7.0 2.0 / .`, "4\n3.5\n")
}

@test
test_conditions :: proc(t: ^testing.T) {
  if !setup(t) do return

  expect_output(
    t,
    "comparisons",
    `
5 10 < .
5 10 > .
5 5 = .
5 5 <= .
5 5 >= .
`,
    "1\n0\n1\n1\n1\n",
  )

  expect_output(t, "string comparison", `"abc" "abd" < . "abc" "abc" = .`, "1\n1\n")
}

@test
test_functions :: proc(t: ^testing.T) {
  if !setup(t) do return

  expect_output(
    t,
    "recursion (fib)",
    `
fn fib 1 1
  dup 2 < if
    1 ret
  done
  dup 1 - call fib
  2 swap 2 - call fib
  +
  ret
fend
10 call fib .
`,
    "89\n",
  )

  expect_output(
    t,
    "recursion (factorial)",
    `
fn fact 1 1
  dup 1 <= if
    pop 1 ret
  done
  dup 1 - call fact
  *
  ret
fend
6 call fact .
`,
    "720\n",
  )

  expect_output(
    t,
    "early return drops leftovers",
    `
fn f 1 1
  1 ret
  pop
  ret
fend
42 call f .
`,
    "1\n",
  )

  expect_output(
    t,
    "arguments and return values",
    `
fn add 2 1
  + ret
fend
1 2 call add .
`,
    "3\n",
  )

  expect_output(
    t,
    "nested loops inside a function",
    `
fn f 0 0
  0 while dup 3 < do
    0 while dup 2 < do dup . 1 + end pop
    1 +
  end pop
  ret
fend
call f
`,
    "0\n1\n0\n1\n0\n1\n",
  )
}

@test
test_control_flow :: proc(t: ^testing.T) {
  if !setup(t) do return

  expect_output(
    t,
    "if/else",
    `
1 if "yes" else "no" done .
0 if "yes" else "no" done .
`,
    "yes\nno\n",
  )

  expect_output(
    t,
    "while loop",
    `0 while dup 4 < do dup . 1 + end pop`,
    "0\n1\n2\n3\n",
  )

  expect_output(
    t,
    "nested if inside loop",
    `
0 while dup 4 < do
  dup 2 < if "low" print else "high" print done
  " " print
  1 +
end pop
`,
    "low low high high ",
  )
}

@test
test_macros :: proc(t: ^testing.T) {
  if !setup(t) do return

  expect_output(t, "macros still work", `macro twice dup + fend 5 jmp twice .`, "10\n")

  expect_output(
    t,
    "macro effects are inferred",
    `macro add_two + 2 + fend 1 2 jmp add_two .`,
    "5\n",
  )

  expect_output(
    t,
    "function calling a macro",
    `macro two 2 fend fn f 0 1 jmp two ret fend call f .`,
    "2\n",
  )

  expect_output(
    t,
    "macros share the caller's stack",
    `
macro drop_three pop pop pop fend
1 2 3 4 jmp drop_three 1 + .
`,
    "2\n",
  )
}

@test
test_memory :: proc(t: ^testing.T) {
  if !setup(t) do return

  expect_output(
    t,
    "sparse memory map",
    `
10 2 mems
2 meml .
-5 1000000 mems
1000000 meml .
`,
    "10\n-5\n",
  )
}

@test
test_stack :: proc(t: ^testing.T) {
  if !setup(t) do return

  expect_output(t, "dup and swap", `1 2 3 2 swap . . .`, "2\n3\n1\n")

  expect_output(
    t,
    "stack reporting",
    `1 2 3 stack pop pop pop`,
    "stack ( 3 ): 1 2 3 \n",
  )
}

@test
test_strings :: proc(t: ^testing.T) {
  if !setup(t) do return

  expect_output(
    t,
    "quotes, backslashes and concatenation",
    `
"say \"hi\"" .
"a\\b" .
"foo" "bar" + .
"tab:\there" .
`,
    "say \"hi\"\na\\b\nfoobar\ntab:\there\n",
  )
}

@test
test_static_errors :: proc(t: ^testing.T) {
  if !setup(t) do return

  expect_error(t, "stack underflow", `pop`, "stack underflow")
  expect_error(t, "binary underflow", `1 +`, "stack underflow")
  expect_error(t, "unterminated if", `1 if "x" .`, "never closed")
  expect_error(t, "while without do", `1 while dup . end`, "has no 'do'")
  expect_error(t, "unbalanced branches", `1 if 1 else 1 2 done .`, "different stack depths")
  expect_error(t, "crossed blocks", `1 if 0 while dup 3 < do done end`, "innermost open block")
  expect_error(t, "missing ret", `fn f 1 1 dup fend`, "without 'ret'")
  expect_error(t, "function arity", `fn f 2 1 + ret fend 1 call f .`, "stack underflow")
  expect_error(t, "call a macro", `macro m 1 fend call m`, "is a macro")
  expect_error(t, "jmp a function", `fn f 0 0 ret fend jmp f`, "is a function")
  expect_error(t, "unknown function", `call nope`, "unknown function")
  expect_error(t, "unknown word", `nope`, "unknown word")
  expect_error(t, "duplicate names", `fn f 0 0 ret fend fn f 0 0 ret fend`, "already defined")
  expect_error(t, "ret outside function", `ret`, "only allowed inside a function")
  expect_error(t, "too few return values", `fn f 0 1 ret fend call f .`, "return value")
  expect_error(t, "macro needs values", `macro m + fend 1 jmp m`, "needs 2 value")
}

@test
test_runtime_errors :: proc(t: ^testing.T) {
  if !setup(t) do return

  expect_error(t, "division by zero", `10 0 / .`, "division by zero")
  expect_error(t, "mixed arithmetic", `1 2.5 + .`, "cannot use '+'")
  expect_error(
    t,
    "call stack tree",
    `
fn div 2 1
  / ret
fend
fn rec 1 1
  dup 0 = if
    1 0 call div ret
  done
  dup 1 - call rec
  ret
fend
2 call rec .
`,
    "  call stack:\n    rec()\n    └─ rec()\n       └─ rec()\n          └─ div()",
  )
  expect_error(t, "uninitialised memory", `42 meml .`, "has not been written to")
  expect_error(t, "swap too deep", `1 2 5 swap`, "exceeds the stack size")
  expect_error(t, "swap too shallow", `1 2 0 swap`, "at least 2")
  expect_error(t, "non-int condition", `1.5 if "x" else "y" done .`, "expected an int")
}

@test
test_file_loading :: proc(t: ^testing.T) {
  if !setup(t) do return

  lib_dir, dir_err := filepath.join([]string{work_dir, "lib"})
  if dir_err != nil {
    testing.expectf(t, false, "cannot build the library path: %v", dir_err)
    return
  }
  defer delete(lib_dir)
  if mk_err := os.make_directory(lib_dir); mk_err != nil {
    testing.expectf(t, false, "cannot create '%s': %v", lib_dir, mk_err)
    return
  }

  lib_path, lib_err := filepath.join([]string{lib_dir, "math.stg"})
  if lib_err != nil {
    testing.expectf(t, false, "cannot build the library file path: %v", lib_err)
    return
  }
  defer delete(lib_path)
  if write_err := os.write_entire_file(
    lib_path,
    `
fn double 1 1
  2 * ret
fend
`); write_err != nil {
    testing.expectf(t, false, "cannot write '%s': %v", lib_path, write_err)
    return
  }

  expect_output(
    t,
    "file loading",
    `load "lib/math" 5 call double .`,
    "10\n",
  )

  expect_error(t, "missing load target", `load "nope"`, "file not found")
}

@test
test_cli :: proc(t: ^testing.T) {
  if !setup(t) do return

  help := run_raw(t, []string{binary, "--help"})
  defer {
    delete(help.stdout)
    delete(help.stderr)
  }
  testing.expectf(t, help.exit_code == 0, "--help should succeed, got exit %d", help.exit_code)
  testing.expect(t, strings.contains(help.stdout, "Usage:"))

  too_many := run_raw(t, []string{binary, "a.stg", "b.stg"})
  defer {
    delete(too_many.stdout)
    delete(too_many.stderr)
  }
  testing.expect(t, too_many.exit_code != 0)
  testing.expect(t, strings.contains(too_many.stderr, "expected exactly one"))
}

@test
test_examples :: proc(t: ^testing.T) {
  if !setup(t) do return

  root := filepath.dir(strings.trim_right(#directory, "/"))

  showcase_path, showcase_err := filepath.join(
    []string{root, "examples", "showcase.stg"},
  )
  if showcase_err != nil {
    testing.expectf(t, false, "cannot build the showcase path: %v", showcase_err)
    return
  }
  defer delete(showcase_path)
  showcase := run_file(t, showcase_path)
  defer {
    delete(showcase.stdout)
    delete(showcase.stderr)
  }
  testing.expectf(t, showcase.exit_code == 0, "showcase failed:\n%s", showcase.stderr)
  testing.expect(t, strings.contains(showcase.stdout, "10 / 5 : 2"))
  testing.expect(t, strings.contains(showcase.stdout, "fib(10) = 89"))
  testing.expect(t, strings.contains(showcase.stdout, "this comes from foo.stg"))
  testing.expect(t, !strings.contains(showcase.stdout, "10 / 5 : 50"))

  rule110_path, rule_err := filepath.join(
    []string{root, "examples", "rule110.stg"},
  )
  if rule_err != nil {
    testing.expectf(t, false, "cannot build the rule110 path: %v", rule_err)
    return
  }
  defer delete(rule110_path)
  rule110 := run_file(t, rule110_path)
  defer {
    delete(rule110.stdout)
    delete(rule110.stderr)
  }
  testing.expectf(t, rule110.exit_code == 0, "rule110 failed:\n%s", rule110.stderr)
  testing.expectf(
    t,
    strings.count(rule110.stdout, "\n") == 97,
    "rule110 should print 97 lines, got %d",
    strings.count(rule110.stdout, "\n"),
  )
  testing.expect(t, strings.contains(rule110.stdout, "*"))

  rule110_fns_path, fns_err := filepath.join(
    []string{root, "examples", "rule110_functions.stg"},
  )
  if fns_err != nil {
    testing.expectf(t, false, "cannot build the rule110_functions path: %v", fns_err)
    return
  }
  defer delete(rule110_fns_path)
  rule110_fns := run_file(t, rule110_fns_path)
  defer {
    delete(rule110_fns.stdout)
    delete(rule110_fns.stderr)
  }
  testing.expectf(
    t,
    rule110_fns.exit_code == 0,
    "rule110_functions failed:\n%s",
    rule110_fns.stderr,
  )
  testing.expectf(
    t,
    rule110_fns.stdout == rule110.stdout,
    "rule110_functions should match the macro version",
  )
}
