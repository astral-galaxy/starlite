cpu_arch := arch()
root_directory := justfile_directory()
run_directory := root_directory / "run"
default_executable := quote(root_directory / "target" / "x86_64-unknown-uefi" / "debug" / "starlite.efi")

# Determine the default target architecture based on the CPU architecture.
default_target := if cpu_arch == "x86_64" {
  "x86_64-unknown-uefi"
} else if cpu_arch == "aarch64" {
  "aarch64-unknown-uefi"
} else if cpu_arch == "x86" {
  "i686-unknown-uefi"
} else {
  "unknown"
}

# Build the project for the specified target architecture.
build target=default_target:
  #!/usr/bin/env sh
  if [ {{target}} = "unknown" ]; then
    echo "Unknown CPU architecture: {{target}}"
    exit 1
  fi
  cargo build --target {{target}}

run-mkdir:
  mkdir -p "{{run_directory}}"

run-copy-files:
  cp /usr/share/OVMF/OVMF_CODE.fd "{{run_directory}}"
  cp /usr/share/OVMF/OVMF_VARS.fd "{{run_directory}}"

run-make-system-partition executable=default_executable:
  mkdir -p "{{run_directory}}/esp/efi/boot"
  cp {{executable}} "{{run_directory}}/esp/efi/boot/bootx64.efi"

run-qemu:
  cd  "{{run_directory}}" && qemu-system-x86_64  -nographic \
    -drive if=pflash,format=raw,readonly=on,file=OVMF_CODE.fd \
    -drive if=pflash,format=raw,readonly=on,file=OVMF_VARS.fd \
    -drive format=raw,file=fat:rw:esp

run target=default_target: (build target) run-mkdir run-copy-files run-make-system-partition run-qemu

run-test executable target=default_target: (build target) run-mkdir run-copy-files (run-make-system-partition executable) run-qemu
  