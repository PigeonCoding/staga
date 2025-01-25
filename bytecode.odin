package staga

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

splitter :: "\n"

bytecode_save :: proc(instrs: ^[dynamic]instr, path: string) {
  str := strings.Builder{}
  for ins in instrs {
    switch _ in ins.data {
    case int:
      fmt.sbprintfln(&str, "{}//{}//{}", cast(int)ins.instr_id, cast(int)ins.data_type, ins.data)
    case string:
      le := len(ins.data.(string))
      if le == 0 || ins.data.(string) == " " {
        fmt.sbprintfln(&str, "{}//{}//nil", cast(int)ins.instr_id, cast(int)ins.data_type)
      } else {
        fmt.sbprintfln(&str, "{}//{}//{}", cast(int)ins.instr_id, cast(int)ins.data_type, ins.data)
      }
    }
  }

  file, err := os.open(path, os.O_CREATE, 0b0110100100) // this magic number does -rw-r--r--
  if err != nil {
    fmt.eprintln("could not create file cause", err)
    os.exit(1)
  }
  os.close(file)
  file, err = os.open(path, os.O_RDWR)
  if err != nil {
    fmt.eprintln("could not write to file cause", err)
    os.exit(1)
  }
  os.write(file, str.buf[:])
  os.flush(file)
  os.close(file)
}

bytecode_read :: proc(path: string) -> []instr {
  file, err := read_file(path)
  if err != nil {
    fmt.eprintln("could not read file", path, "cause", err)
    os.exit(1)
  }
  full := strings.split(file, "\n")
  instrs := [dynamic]instr{}
  for t in full {
    data: instr

    new := strings.split_n(t, "//", 3)
    if len(new) < 3 {
      continue
    }

    data.instr_id = auto_cast strconv.atoi(new[0])
    data.data_type = auto_cast strconv.atoi(new[1])
    if new[2] == "nil" do data.data = ""
    else if data.data_type == n_type.nint || data.data_type == n_type.cjmp || data.data_type == n_type.mem do data.data = strconv.atoi(new[2])
    else if data.data_type == n_type.nstring do data.data = new[2]
    else {
      // data.data = ""
      fmt.println(new)
      fmt.println(data)
      assert(false, "bullshit")
    }
    // fmt.println(data)
    append(&instrs, data)
  }
  return instrs[:]
}

