package staga

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

splitter :: ",\t,"

bytecode_save :: proc(instrs: ^[dynamic]instr, path: string) {
  str := strings.Builder{}
  for ins in instrs {
    fmt.sbprintf(
      &str,
      "{}{}{}{}{}{}",
      cast(int)ins.instr_id,
      splitter,
      cast(int)ins.data_type,
      splitter,
      ins.data,
      splitter,
    )
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
  i := 0
  full := strings.split(file, splitter)
  instrs := [dynamic]instr{}
  for i < len(full) - 3 {
    data: instr
    data.instr_id = auto_cast strconv.atoi(full[i])
    i += 1
    data.data_type = auto_cast strconv.atoi(full[i])
    i += 1
    data.data = full[i]
    i += 1
    append(&instrs, data)
  }
  return instrs[:]
}

