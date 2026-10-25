package staga

import "core:fmt"
import "core:os"
import "core:strings"
import fl "../thirdparty/flag"

main :: proc() {
  flags: fl.flag_container
  fl.add_flag(&flags, "help", false, "displays the help message")

  if len(os.args) < 2 {
    fmt.println("no file provided")
    fmt.println("Usage:", os.args[0], "file.stg")
    fl.print_usage(&flags)
    os.exit(1)
  }

  fl.check_flags(&flags)

  // The vendored flag parser only understands single-dash flags, so accept the
  // usual double-dash spelling here as well.
  for arg in os.args[1:] {
    if arg == "-help" || arg == "--help" {
      fmt.println("Usage:", os.args[0], "file.stg")
      fl.print_usage(&flags)
      os.exit(0)
    }
  }

  // flags.remaining still contains argv[0].
  if len(flags.remaining) != 2 {
    fail(
      {file = "<command line>", row = 1, col = 1},
      "expected exactly one .stg file, but got %d argument(s)",
      len(flags.remaining) - 1,
    )
  }

  file := flags.remaining[1]
  if !strings.ends_with(file, ".stg") {
    fail({file = file, row = 1, col = 1}, "only .stg files are supported")
  }

  p := parse_program(file)
  verify_program(p)
  run(p)
}
