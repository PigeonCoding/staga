package staga

import "core:fmt"
import "core:os"

MAX_TRACE_FRAMES :: 10

// A compile-time (parse / verify) error. Always carries a source location.
fail :: proc(loc: src_loc, format: string, args: ..any) -> ! {
  fmt.eprintf("%s:%d:%d: error: ", loc.file, loc.row, loc.col)
  fmt.eprintln(fmt.tprintf(format, ..args))
  os.exit(1)
}

// The active frames form one branch of the call tree: the program at the root,
// then each callee nested under its caller. Print it that way so recursion
// depth is visible at a glance.
print_call_stack :: proc() {
  if len(frames) == 0 do return

  fmt.eprintln("  call stack:")

  // Keep the innermost frames, since those are the ones near the failure.
  start := len(frames) - MAX_TRACE_FRAMES
  if start < 0 do start = 0
  if start > 0 {
    fmt.eprintf("    ... %d more frame(s)\n", start)
  }

  for i := start; i < len(frames); i += 1 {
    depth := i - start
    fmt.eprint("    ")
    if depth > 0 {
      for _ in 0 ..< depth - 1 do fmt.eprint("   ")
      fmt.eprint("└─ ")
    }
    fmt.eprintf("%s()\n", frames[i].name)
  }
}

// A runtime error. Same format, plus the call stack, so a failure inside a
// recursive function says where it happened instead of dumping an Odin assert.
runtime_fail :: proc(loc: src_loc, format: string, args: ..any) -> ! {
  fmt.eprintf("%s:%d:%d: runtime error: ", loc.file, loc.row, loc.col)
  fmt.eprintln(fmt.tprintf(format, ..args))
  print_call_stack()
  os.exit(1)
}
