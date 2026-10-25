// v0.5
package build_odin

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"


exec_and_run_sync :: proc(cmd: []string) -> Maybe(os.Error) {
  procc: os.Process_Desc
  procc.stderr = os.stderr
  procc.stdout = os.stdout
  procc.env = nil
  procc.working_dir = ""

  fmt.println("[CMD]:", cmd)

  procc.command = cmd
  p, err := os.process_start(procc)
  if err != nil do return err
  ps, err2 := os.process_wait(p)
  if err2 != nil do return err2
  if ps.exit_code != 0 do return os.General_Error.None

  return nil

}

exec_and_run_async :: proc(cmd: []string) -> (os.Process, Maybe(os.Error)) {
  procc: os.Process_Desc
  procc.stderr = os.stderr
  procc.stdout = os.stdout
  procc.env = nil
  procc.working_dir = ""

  fmt.println("[CMD]:", cmd)

  procc.command = cmd
  p, err := os.process_start(procc)
  if err != nil do return p, err

  return p, nil
}

kv :: struct($T: typeid) {
  key:   string,
  value: T,
}

odin_commands :: enum {
  none,
  build,
  run,
  check,
  strip_semicolon,
  test,
  doc,
  version,
  report,
  root,
}

optimization_level :: enum {
  minimal,
  none,
  size,
  speed,
  aggressive,
}

export_timings_formats :: enum {
  none,
  json,
  csv,
}

export_dependencies_formats :: enum {
  none,
  make,
  json,
}

bis :: union {
  bool,
  int,
  string,
}

build_modes :: enum {
  none,
  exe,
  dll,
  shared,
  lib,
  static,
  obj,
  object,
  assembly,
  assembler,
  asm_,
  llvm_ir,
  llvm,
}

build_targets :: enum {
  none,
  darwin_amd64,
  darwin_arm64,
  essence_amd64,
  linux_i386,
  linux_amd64,
  linux_arm64,
  linux_arm32,
  linux_riscv64,
  windows_i386,
  windows_amd64,
  freebsd_i386,
  freebsd_amd64,
  freebsd_arm64,
  netbsd_amd64,
  netbsd_arm64,
  openbsd_amd64,
  haiku_amd64,
  freestanding_wasm32,
  wasi_wasm32,
  js_wasm32,
  orca_wasm32,
  freestanding_wasm64p32,
  js_wasm64p32,
  wasi_wasm64p32,
  freestanding_amd64_sysv,
  freestanding_amd64_win64,
  freestanding_arm64,
  freestanding_arm32,
  freestanding_riscv64,
}

microarchs :: enum {
  none,
  x86_64_v2,
  alderlake,
  amdfam10,
  arrowlake,
  arrowlake_s,
  athlon,
  athlon_4,
  athlon_fx,
  athlon_mp,
  athlo_tbird,
  athlo_xp,
  athlon64,
  athlon6_sse3,
  atom,
  atom_sse4_2,
  atom_sse4_2_movbe,
  barcelona,
  bdver1,
  bdver2,
  bdver3,
  bdver4,
  bonnell,
  broadwell,
  btver1,
  btver2,
  c3,
  c3_2,
  cannonlake,
  cascadelake,
  clearwaterforest,
  cooperlake,
  cor_av_i,
  cor_avx2,
  core2,
  core_2_duo_sse4_1,
  core_2_duo_ssse3,
  core_2nd_gen_avx,
  core_3rd_gen_avx,
  core_4th_gen_avx,
  core_4th_gen_avx_tsx,
  core_5th_gen_avx,
  core_5th_gen_avx_tsx,
  core_aes_pclmulqdq,
  core_i7_sse4_2,
  corei7,
  corei_avx,
  emeraldrapids,
  generic,
  geode,
  goldmont,
  goldmont_plus,
  gracemont,
  grandridge,
  graniterapids,
  graniterapids_d,
  haswell,
  i386,
  i486,
  i586,
  i686,
  icelak_client,
  icelak_server,
  icelake_client,
  icelake_server,
  ivybridge,
  k6,
  k6_2,
  k6_3,
  k8,
  k_sse3,
  knl,
  knm,
  lakemont,
  lunarlake,
  meteorlake,
  mic_avx512,
  nehalem,
  nocona,
  opteron,
  opteron_sse3,
  pantherlake,
  penryn,
  pentium,
  pentium_m,
  pentium_mmx,
  pentium2,
  pentium3,
  pentium3m,
  pentium4,
  pentium4m,
  pentium_4,
  pentium_4_sse3,
  pentium_ii,
  pentium_iii,
  pentium_iii_no_xmm_regs,
  pentium_pro,
  pentiumpro,
  prescott,
  raptorlake,
  rocketlake,
  sandybridge,
  sapphirerapids,
  sierraforest,
  silvermont,
  skx,
  skylake,
  skylake_avx512,
  slm,
  tigerlake,
  tremont,
  westmere,
  winchip_c6,
  winchip2,
  x86_64,
  x86_64_v3,
  x86_64_v4,
  yonah,
  znver1,
  znver2,
  znver3,
  znver4,
}

reloc_modes :: enum {
  default,
  static,
  pic,
  dynamic_no_pie,
}

error_pos_styles :: enum {
  default,
  odin,
  unix,
}

sanitaze_options :: enum {
  none,
  address,
  memory,
  thread,
}

subsystems :: enum {
  none,
  console,
  windows,
}

odin_flags :: struct {
  file:                           bool, // in this case directory is used for the file
  out:                            string,
  optimization:                   optimization_level,
  show_timings:                   bool,
  show_more_timings:              bool,
  show_system_calls:              bool,
  export_timings:                 export_timings_formats,
  export_timings_file:            string,
  export_dependencies:            export_dependencies_formats,
  export_dependencies_file:       string,
  thread_count:                   int,
  keep_temp_files:                bool,
  collections:                    [dynamic]kv(string),
  defines:                        [dynamic]kv(bis),
  show_defineables:               bool,
  export_defineables:             string,
  build_mode:                     build_modes,
  target:                         build_targets,
  debug:                          bool,
  disable_assert:                 bool,
  no_bounds_check:                bool,
  no_type_assert:                 bool,
  no_crt:                         bool,
  no_thread_local:                bool,
  lld:                            bool,
  use_separate_modules:           bool,
  no_threaded_checkers:           bool,
  vet:                            bool,
  vet_unused:                     bool,
  vet_unused_variables:           bool,
  vet_unused_imports:             bool,
  vet_shadowing:                  bool,
  vet_using_stmt:                 bool,
  vet_using_params:               bool,
  vet_style:                      bool,
  vet_semicolon:                  bool,
  vet_cast:                       bool,
  vet_tabs:                       bool,
  custom_attributes:              [dynamic]string,
  ignore_unknown_attributes:      bool,
  no_entry_point:                 bool,
  minimum_os_version:             string, // only for macOS appearently
  extra_linker_flag:              [dynamic]string,
  extra_assembler_flag:           [dynamic]string,
  microarch:                      microarchs,
  // target_features TODO: too lazy to do
  strict_target_features:         bool,
  reloc_mode:                     reloc_modes,
  disable_red_zone:               bool,
  dynamic_map_calls:              bool,
  print_linker_flags:             bool,
  disallow_do:                    bool,
  default_to_nil_allocator:       bool,
  strict_style:                   bool,
  ignore_warnings:                bool,
  warnings_as_errors:             bool,
  terse_errors:                   bool,
  json_errors:                    bool,
  erro_pos_style:                 error_pos_styles,
  max_error_count:                int,
  min_link_libs:                  bool,
  foreign_error_procedures:       bool,
  obfuscate_source_code_location: bool,
  sanitize:                       [dynamic]sanitaze_options,
  ignore_vs_search:               bool, // windows only
  ressource:                      string, // windows only TODO: maybe array?
  pdb_name:                       string, // windows only
  // subsystem: 
}

odin_cmd_builder :: struct {
  odin_path: string,
  main_cmd:  odin_commands,
  flags:     odin_flags,
  directory: string,
}

build_cmd :: proc(b: ^odin_cmd_builder) -> [dynamic]string {
  res: [dynamic]string


  if b.odin_path == "" {
    append(&res, "odin")
  } else {
    append(&res, b.odin_path)
  }

  switch b.main_cmd {
  case .run:
    append(&res, "run")
  case .build:
    append(&res, "build")
  case .check:
    append(&res, "check")
  case .strip_semicolon:
    append(&res, "strip-semicolon")
  case .test:
    append(&res, "test")
  case .doc:
    append(&res, "doc")
  case .version:
    append(&res, "version")
  case .report:
    append(&res, "report")
  case .root:
    append(&res, "root")
  case .none:
    fmt.eprintln("you have to choose a main_cmd type to continue")
    os.exit(1)
  }

  if b.directory == "" {
    append(&res, ".")
  } else {
    append(&res, b.directory)
  }

  if b.flags.file {
    append(&res, "-file")
  }

  if b.flags.out != "" {
    append(&res, strings.concatenate({"-out:", b.flags.out}))
  } else {
    append(&res, strings.concatenate({"-out:", os.args[0]}))
  }

  switch b.flags.optimization {
  case .minimal:
  case .aggressive:
    append(&res, "-o:aggressive")
  case .none:
    append(&res, "-o:none")
  case .size:
    append(&res, "-o:size")
  case .speed:
    append(&res, "-o:speed")
  }

  if b.flags.show_timings {
    append(&res, "-show-timings")
  }

  if b.flags.show_system_calls {
    append(&res, "-show-system-flags")
  }

  switch b.flags.export_timings {
  case .none:
  case .json:
    append(&res, "-export-timings:json")
  case .csv:
    append(&res, "-export-timings:csv")
  }

  if b.flags.export_timings_file != "" {
    append(&res, strings.concatenate({"-export-timings-file:", b.flags.export_timings_file}))
  }

  switch b.flags.export_dependencies {
  case .none:
  case .make:
    append(&res, "-export-dependencies:make")
  case .json:
    append(&res, "-export-dependencies:json")
  }

  if b.flags.export_dependencies_file != "" {
    append(
      &res,
      strings.concatenate({"-export-dependencies-file:", b.flags.export_dependencies_file}),
    )
  }

  if b.flags.thread_count > 0 {
    buf := make([]u8, 100)
    append(&res, strings.concatenate({"-thread-count:", strconv.write_int(buf, auto_cast b.flags.thread_count, 10)}))
  }

  if b.flags.keep_temp_files {
    append(&res, "-keep-temp-files")
  }

  for k in b.flags.collections {
    append(&res, strings.concatenate({"-collection:", k.key, "=", k.value}))
  }

  for d in b.flags.defines {
    switch v in d.value {
    case int:
      buf := make([]u8, 100)
      append(&res, strings.concatenate({"-define:", d.key, "=", strconv.write_int(buf, auto_cast d.value.(int), 10)}))
    case bool:
      if d.value.(bool) {
        append(&res, strings.concatenate({"-define:", d.key, "=true"}))
      } else {
        append(&res, strings.concatenate({"-define:", d.key, "=false"}))
      }
    case string:
      append(&res, strings.concatenate({"-define:", d.key, "=", d.value.(string)}))

    }
  }

  if b.flags.show_defineables {
    append(&res, "-show-defineables")
  }

  if b.flags.export_defineables != "" {
    append(&res, strings.concatenate({"-export-defineables:", b.flags.export_defineables}))
  }

  switch b.flags.build_mode {
  case .asm_, .assembler, .assembly:
    append(&res, "-build-mode:asm")
  case .dll, .shared:
    append(&res, "-build-mode:dll")
  case .lib, .static:
    append(&res, "-build-mode:static")
  case .obj, .object:
    append(&res, "-build-mode:object")
  case .exe:
    append(&res, "-build-mode:exe")
  case .llvm, .llvm_ir:
    append(&res, "-build-mode:llvm")
  case .none:
  }

  if b.flags.target != .none {
    s: strings.Builder
    fmt.sbprint(&s, "-target:", b.flags.target, sep = "")
    append(&res, string(s.buf[:]))
  }

  if b.flags.debug {
    append(&res, "-debug")
  }

  if b.flags.disable_assert {
    append(&res, "-disable-assert")
  }

  if b.flags.no_bounds_check {
    append(&res, "-no-bounds-check")
  }

  if b.flags.no_type_assert {
    append(&res, "-no-type-assert")
  }

  if b.flags.no_crt {
    append(&res, "-no-crt")
  }

  if b.flags.no_thread_local {
    append(&res, "-no-thread-local")
  }

  if b.flags.lld {
    append(&res, "-lld")
  }

  if b.flags.use_separate_modules {
    append(&res, "-use-separate-modules")
  }

  if b.flags.no_threaded_checkers {
    append(&res, "-no-threaded-checkers")
  }

  if b.flags.vet {
    append(&res, "-vet")
  }

  if b.flags.vet_unused {
    append(&res, "-vet-unused")
  }
  if b.flags.vet_unused_variables {
    append(&res, "-vet-unused-variables")
  }
  if b.flags.vet_unused_imports {
    append(&res, "-vet-unused-imports")
  }
  if b.flags.vet_shadowing {
    append(&res, "-vet-shadowing")
  }
  if b.flags.vet_using_stmt {
    append(&res, "-vet-using-stmt")
  }
  if b.flags.vet_using_params {
    append(&res, "-vet-using-params")
  }
  if b.flags.vet_style {
    append(&res, "-vet-style")
  }
  if b.flags.vet_semicolon {
    append(&res, "-vet-semicolon")
  }
  if b.flags.vet_cast {
    append(&res, "-vet-cast")
  }
  if b.flags.vet_tabs {
    append(&res, "-vet-tabs")
  }

  for c in b.flags.custom_attributes {
    append(&res, strings.concatenate({"-custom-attribute:", c}))
  }

  if b.flags.ignore_unknown_attributes {
    append(&res, "-ignore-unknown-attributes")
  }

  if b.flags.no_entry_point {
    append(&res, "-no-entry-point")
  }

  if ODIN_OS == .Darwin && b.flags.minimum_os_version != "" {
    append(&res, strings.concatenate({"-minimum-os-version:", b.flags.minimum_os_version}))
  }


  for l in b.flags.extra_linker_flag {
    fmt.assertf(false, "not figured out extra_linker_flag") // TODO: do it
  }

  for a in b.flags.extra_assembler_flag {
    fmt.assertf(false, "not figured out extra_assembler_flag") // TODO: do it
  }

  switch b.flags.microarch {   // Assuming b.flags.microarch holds the enum value
  case .none:
  // Do nothing for 'none'
  case .x86_64_v2:
    append(&res, "-microarch:x86-64-v2")
  case .alderlake:
    append(&res, "-microarch:alderlake")
  case .amdfam10:
    append(&res, "-microarch:amdfam10")
  case .arrowlake:
    append(&res, "-microarch:arrowlake")
  case .arrowlake_s:
    append(&res, "-microarch:arrowlake-s")
  case .athlon:
    append(&res, "-microarch:athlon")
  case .athlon_4:
    append(&res, "-microarch:athlon-4")
  case .athlon_fx:
    append(&res, "-microarch:athlon-fx")
  case .athlon_mp:
    append(&res, "-microarch:athlon-mp")
  case .athlo_tbird:
    append(&res, "-microarch:athlon-tbird")
  case .athlo_xp:
    append(&res, "-microarch:athlon-xp")
  case .athlon64:
    append(&res, "-microarch:athlon64")
  case .athlon6_sse3:
    append(&res, "-microarch:athlon64-sse3")
  case .atom:
    append(&res, "-microarch:atom")
  case .atom_sse4_2:
    append(&res, "-microarch:atom_sse4_2")
  case .atom_sse4_2_movbe:
    append(&res, "-microarch:atom_sse4_2_movbe")
  case .barcelona:
    append(&res, "-microarch:barcelona")
  case .bdver1:
    append(&res, "-microarch:bdver1")
  case .bdver2:
    append(&res, "-microarch:bdver2")
  case .bdver3:
    append(&res, "-microarch:bdver3")
  case .bdver4:
    append(&res, "-microarch:bdver4")
  case .bonnell:
    append(&res, "-microarch:bonnell")
  case .broadwell:
    append(&res, "-microarch:broadwell")
  case .btver1:
    append(&res, "-microarch:btver1")
  case .btver2:
    append(&res, "-microarch:btver2")
  case .c3:
    append(&res, "-microarch:c3")
  case .c3_2:
    append(&res, "-microarch:c3-2")
  case .cannonlake:
    append(&res, "-microarch:cannonlake")
  case .cascadelake:
    append(&res, "-microarch:cascadelake")
  case .clearwaterforest:
    append(&res, "-microarch:clearwaterforest")
  case .cooperlake:
    append(&res, "-microarch:cooperlake")
  case .cor_av_i:
    append(&res, "-microarch:core-avx-i")
  case .cor_avx2:
    append(&res, "-microarch:core-avx2")
  case .core2:
    append(&res, "-microarch:core2")
  case .core_2_duo_sse4_1:
    append(&res, "-microarch:core_2_duo_sse4_1")
  case .core_2_duo_ssse3:
    append(&res, "-microarch:core_2_duo_ssse3")
  case .core_2nd_gen_avx:
    append(&res, "-microarch:core_2nd_gen_avx")
  case .core_3rd_gen_avx:
    append(&res, "-microarch:core_3rd_gen_avx")
  case .core_4th_gen_avx:
    append(&res, "-microarch:core_4th_gen_avx")
  case .core_4th_gen_avx_tsx:
    append(&res, "-microarch:core_4th_gen_avx_tsx")
  case .core_5th_gen_avx:
    append(&res, "-microarch:core_5th_gen_avx")
  case .core_5th_gen_avx_tsx:
    append(&res, "-microarch:core_5th_gen_avx_tsx")
  case .core_aes_pclmulqdq:
    append(&res, "-microarch:core_aes_pclmulqdq")
  case .core_i7_sse4_2:
    append(&res, "-microarch:core_i7_sse4_2")
  case .corei7:
    append(&res, "-microarch:corei7")
  case .corei_avx:
    append(&res, "-microarch:corei7-avx")
  case .emeraldrapids:
    append(&res, "-microarch:emeraldrapids")
  case .generic:
    append(&res, "-microarch:generic")
  case .geode:
    append(&res, "-microarch:geode")
  case .goldmont:
    append(&res, "-microarch:goldmont")
  case .goldmont_plus:
    append(&res, "-microarch:goldmont-plus")
  case .gracemont:
    append(&res, "-microarch:gracemont")
  case .grandridge:
    append(&res, "-microarch:grandridge")
  case .graniterapids:
    append(&res, "-microarch:graniterapids")
  case .graniterapids_d:
    append(&res, "-microarch:graniterapids-d")
  case .haswell:
    append(&res, "-microarch:haswell")
  case .i386:
    append(&res, "-microarch:i386")
  case .i486:
    append(&res, "-microarch:i486")
  case .i586:
    append(&res, "-microarch:i586")
  case .i686:
    append(&res, "-microarch:i686")
  case .icelak_client:
    append(&res, "-microarch:icelake-client")
  case .icelak_server:
    append(&res, "-microarch:icelake-server")
  case .icelake_client:
    append(&res, "-microarch:icelake-client")
  case .icelake_server:
    append(&res, "-microarch:icelake-server")
  case .ivybridge:
    append(&res, "-microarch:ivybridge")
  case .k6:
    append(&res, "-microarch:k6")
  case .k6_2:
    append(&res, "-microarch:k6-2")
  case .k6_3:
    append(&res, "-microarch:k6-3")
  case .k8:
    append(&res, "-microarch:k8")
  case .k_sse3:
    append(&res, "-microarch:k8-sse3")
  case .knl:
    append(&res, "-microarch:knl")
  case .knm:
    append(&res, "-microarch:knm")
  case .lakemont:
    append(&res, "-microarch:lakemont")
  case .lunarlake:
    append(&res, "-microarch:lunarlake")
  case .meteorlake:
    append(&res, "-microarch:meteorlake")
  case .mic_avx512:
    append(&res, "-microarch:mic_avx512")
  case .nehalem:
    append(&res, "-microarch:nehalem")
  case .nocona:
    append(&res, "-microarch:nocona")
  case .opteron:
    append(&res, "-microarch:opteron")
  case .opteron_sse3:
    append(&res, "-microarch:opteron-sse3")
  case .pantherlake:
    append(&res, "-microarch:pantherlake")
  case .penryn:
    append(&res, "-microarch:penryn")
  case .pentium:
    append(&res, "-microarch:pentium")
  case .pentium_m:
    append(&res, "-microarch:pentium-m")
  case .pentium_mmx:
    append(&res, "-microarch:pentium-mmx")
  case .pentium2:
    append(&res, "-microarch:pentium2")
  case .pentium3:
    append(&res, "-microarch:pentium3")
  case .pentium3m:
    append(&res, "-microarch:pentium3m")
  case .pentium4:
    append(&res, "-microarch:pentium4")
  case .pentium4m:
    append(&res, "-microarch:pentium4m")
  case .pentium_4:
    append(&res, "-microarch:pentium4")
  case .pentium_4_sse3:
    append(&res, "-microarch:pentium4-sse3")
  case .pentium_ii:
    append(&res, "-microarch:pentium-ii")
  case .pentium_iii:
    append(&res, "-microarch:pentium-iii")
  case .pentium_iii_no_xmm_regs:
    append(&res, "-microarch:pentium_iii_no_xmm_regs")
  case .pentium_pro:
    append(&res, "-microarch:pentium-pro")
  case .pentiumpro:
    append(&res, "-microarch:pentiumpro")
  case .prescott:
    append(&res, "-microarch:prescott")
  case .raptorlake:
    append(&res, "-microarch:raptorlake")
  case .rocketlake:
    append(&res, "-microarch:rocketlake")
  case .sandybridge:
    append(&res, "-microarch:sandybridge")
  case .sapphirerapids:
    append(&res, "-microarch:sapphirerapids")
  case .sierraforest:
    append(&res, "-microarch:sierraforest")
  case .silvermont:
    append(&res, "-microarch:silvermont")
  case .skx:
    append(&res, "-microarch:skx")
  case .skylake:
    append(&res, "-microarch:skylake")
  case .skylake_avx512:
    append(&res, "-microarch:skylake-avx512")
  case .slm:
    append(&res, "-microarch:slm")
  case .tigerlake:
    append(&res, "-microarch:tigerlake")
  case .tremont:
    append(&res, "-microarch:tremont")
  case .westmere:
    append(&res, "-microarch:westmere")
  case .winchip_c6:
    append(&res, "-microarch:winchip-c6")
  case .winchip2:
    append(&res, "-microarch:winchip2")
  case .x86_64:
    append(&res, "-microarch:x86-64")
  case .x86_64_v3:
    append(&res, "-microarch:x86-64-v3")
  case .x86_64_v4:
    append(&res, "-microarch:x86-64-v4")
  case .yonah:
    append(&res, "-microarch:yonah")
  case .znver1:
    append(&res, "-microarch:znver1")
  case .znver2:
    append(&res, "-microarch:znver2")
  case .znver3:
    append(&res, "-microarch:znver3")
  case .znver4:
    append(&res, "-microarch:znver4")
  }

  if b.flags.strict_target_features {
    append(&res, "-strict-target-features")
  }

  switch b.flags.reloc_mode {
  case .default:
  case .dynamic_no_pie:
    append(&res, "-reloc-mode:dynamic-no-pic")
  case .pic:
    append(&res, "-reloc-mode:pic")
  case .static:
    append(&res, "-reloc-mode:static")
  }

  if b.flags.disable_red_zone {
    append(&res, "-disable-red-zone")
  }

  if b.flags.dynamic_map_calls {
    append(&res, "-dynamic-map-calls")
  }

  if b.flags.print_linker_flags {
    append(&res, "-print-linker-flags")
  }

  if b.flags.disallow_do {
    append(&res, "-disallow-do")
  }

  if b.flags.default_to_nil_allocator {
    append(&res, "-default-to-nil-allocator")
  }

  if b.flags.strict_style {
    append(&res, "-strict-style")
  }

  if b.flags.ignore_warnings {
    append(&res, "-ignore-warnings")
  }

  if b.flags.warnings_as_errors {
    append(&res, "-warnings-as-errors")
  }

  if b.flags.terse_errors {
    append(&res, "-terse-errors")
  }

  if b.flags.json_errors {
    append(&res, "-json-errors")
  }

  switch b.flags.erro_pos_style {
  case .default:
  case .odin:
    append(&res, "-error-pos-style:odin")
  case .unix:
    append(&res, "-error-pos-style:unix")
  }

  if b.flags.max_error_count > 0 {
    bu := make([]u8, 100)
    append(
      &res,
      strings.concatenate({"-max-error-count:", strconv.write_int(bu, auto_cast b.flags.max_error_count, 10)}),
    )
  }

  if b.flags.min_link_libs {
    append(&res, "-min-link-libs")
  }
  if b.flags.foreign_error_procedures {
    append(&res, "-foreign-error-procedures")
  }
  if b.flags.obfuscate_source_code_location {
    append(&res, "-obfuscate_-source-code-location")
  }

  for s in b.flags.sanitize {
    switch s {
    case .address:
      append(&res, "-sanitize:address")
    case .memory:
      append(&res, "-sanitize:memory")
    case .thread:
      append(&res, "-sanitize:thread")
    case .none:
    }
  }

  if (b.flags.target == .windows_amd64 || b.flags.target == .windows_i386) &&
     b.flags.ignore_vs_search {
    append(&res, "-ignore-vs-search")
  }

  if (b.flags.target == .windows_amd64 || b.flags.target == .windows_i386) &&
     b.flags.ressource != "" {
    append(&res, strings.concatenate({"-ressource:", b.flags.ressource}))
  }

  if (b.flags.target == .windows_amd64 || b.flags.target == .windows_i386) &&
     b.flags.pdb_name != "" {
    append(&res, strings.concatenate({"-pdb-name:", b.flags.pdb_name}))
  }

  return res
}
