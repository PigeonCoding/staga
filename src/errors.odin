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

// A runtime error. Same format, plus the call stack, so a failure inside a
// recursive function says where it happened instead of dumping an Odin assert.
runtime_fail :: proc(loc: src_loc, format: string, args: ..any) -> ! {
  fmt.eprintf("%s:%d:%d: runtime error: ", loc.file, loc.row, loc.col)
  fmt.eprintln(fmt.tprintf(format, ..args))
  if len(frames) > 0 {
    fmt.eprint("  call stack:")
    shown := 0
    for i := len(frames) - 1; i >= 0 && shown < MAX_TRACE_FRAMES; i -= 1 {
      fmt.eprintf(" %s()", frames[i].name)
      shown += 1
    }
    if len(frames) > MAX_TRACE_FRAMES {
      fmt.eprintf(" ... (%d more)", len(frames) - MAX_TRACE_FRAMES)
    }
    fmt.eprintln()
  }
  os.exit(1)
}
