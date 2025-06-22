package staga

import "core:fmt"
import "core:os"
import "core:strings"
import fl "thirdparty/flag"

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
  program_name := flags.remaining[0]
  flags.remaining = flags.remaining[1:]

  for f in flags.parsed_flags {
    switch f.flag {
    case "help":
      fmt.println("Usage:", os.args[0], "file.stg")
      fl.print_usage(&flags)
      os.exit(0)
    }
  }

  fmt.assertf(len(flags.remaining) == 1, "we currently only support one file")
  file := flags.remaining[0]
  if !strings.ends_with(file, ".stg") {
    fmt.eprintln("we only support .stg files")
  }

  parse := [dynamic]instr{}
  defer delete(parse)

  // ins := 0
  mac := [dynamic]fn_def{}
  parse_instrs(&parse, &mac, []string{file})

  interpret_instrs(parse[:], mac[:])
}
