// v0.1 from https://github.com/PigeonCoding/flag.odin
package flag

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

flag_val_types :: union {
  int,
  string,
  bool,
}

flag_t :: struct {
  flag:        string,
  value:       flag_val_types,
  description: string,
}

flag_container :: struct {
  private_flag_list: [dynamic]flag_t,
  parsed_flags:      []^flag_t,
  remaining:         []string,
}

add_flag :: proc(
  container: ^flag_container,
  flag_name: string,
  initial_val: flag_val_types,
  description: string,
) {
  t: flag_t
  t.flag = flag_name
  t.value = initial_val
  t.description = description

  append(&container.private_flag_list, t)
}

// (this function does not modify os.args)
check_flags :: proc(container: ^flag_container) {
  ff: [dynamic]^flag_t
  rem: [dynamic]string

  arg_i := 0
  for arg_i < len(os.args) {

    if os.args[arg_i] == "---" {
      break
    }

    if strings.starts_with(os.args[arg_i], "-") {
      for &f in container.private_flag_list {
        if os.args[arg_i][1:] == f.flag {
          yes := false
          switch v in f.value {
          case bool:
            // fmt.println("yes")
            yes = true
          case int:
            arg_i += 1
            if os.args[arg_i][0] == '-' || (os.args[arg_i][0] >= '0' && os.args[arg_i][0] <= '9') {
              f.value = strconv.atoi(os.args[arg_i])
              yes = true
            }
          case string:
            arg_i += 1
            yes = true
            f.value = os.args[arg_i]
          }

          if yes do append(&ff, &f)

        }
      }
    } else {
      append(&rem, os.args[arg_i])
    }
    arg_i += 1
  }

  for i in arg_i ..< len(os.args) {
    append(&rem, os.args[i])
  }

  container.parsed_flags = ff[:]
  container.remaining = rem[:]
}

print_usage :: proc(container: ^flag_container) {
  max_len := 0

  for f in container.private_flag_list {
    if len(f.flag) > max_len {
      max_len = len(f.flag)
    }
  }

  for f in container.private_flag_list {
    t: string
    switch v in f.value {
    case int:
      t = "(int)   "
    case bool:
      t = "(bool)  "
    case string:
      t = "(string)"
    }

    fmt.printfln("%-*.s: {}", max_len + 1 + 9, strings.concatenate({"-", f.flag, t}), f.description)
  }
}

free_flag_container :: proc(container: ^flag_container) {
  delete(container.private_flag_list)
  delete(container.parsed_flags)
  delete(container.remaining)
}
