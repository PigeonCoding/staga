package builder

import odin_builder "./build_odin"
import "core:fmt"
import "core:os"

EXE_SUFFIX :: ".exe" when ODIN_OS == .Windows else ""
DEBUG_OUT :: "build/staga_debug" + EXE_SUFFIX
RELEASE_OUT :: "build/staga" + EXE_SUFFIX

make_builder :: proc(out: string, debug: bool) -> odin_builder.odin_cmd_builder {
  b: odin_builder.odin_cmd_builder
  b.main_cmd = .build
  b.directory = "src"
  b.flags.out = out
  b.flags.thread_count = 4
  b.flags.debug = debug
  b.flags.erro_pos_style = .unix
  if !debug do b.flags.optimization = .speed
  return b
}

run :: proc(b: ^odin_builder.odin_cmd_builder) {
  if !os.exists("build") do os.make_directory("build")
  cmd := odin_builder.build_cmd(b)
  if err, not_ok := odin_builder.exec_and_run_sync(cmd[:]).?; not_ok {
    fmt.eprintln(err)
    os.exit(1)
  }
}

build_debug :: proc() {
  b := make_builder(DEBUG_OUT, true)
  run(&b)
}

build_release :: proc() {
  b := make_builder(RELEASE_OUT, false)
  run(&b)
}

main :: proc() {
  if len(os.args) < 2 {
    fmt.eprintln("ERROR: no command provided")
    fmt.eprintln("Usage:")
    fmt.eprintln("   odin run builder -- [debug|release|all]")
    os.exit(1)
  }

  switch os.args[1] {
  case "debug":
    build_debug()
  case "release":
    build_release()
  case "all":
    build_debug()
    build_release()
  case:
    fmt.eprintfln("ERROR: unknown command %q", os.args[1])
    fmt.eprintln("Usage:")
    fmt.eprintln("   odin run builder -- [debug|release|all]")
    os.exit(1)
  }
}
