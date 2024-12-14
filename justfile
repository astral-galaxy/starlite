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

run-copy-files qemu-system="x86_64":
  #!/usr/bin/env sh
  if [ "{{qemu-system}}" = "aarch64" ]; then
    dd if=/dev/zero of="{{run_directory}}/flash1.img" bs=1M count=64
    dd if=/dev/zero of="{{run_directory}}/flash0.img" bs=1M count=64
    
    if [ -f /usr/share/qemu-efi-aarch64/QEMU_EFI.fd ]; then
      dd if=/usr/share/qemu-efi-aarch64/QEMU_EFI.fd of="{{run_directory}}/flash0.img" conv=notrunc
      dd if=/usr/share/qemu-efi-aarch64/QEMU_VARS.fd of="{{run_directory}}/flash1.img" conv=notrunc
    elif [ -f /usr/share/edk2/aarch64/QEMU_EFI.fd ]; then
      dd if=/usr/share/edk2/aarch64/QEMU_EFI.fd of="{{run_directory}}/flash0.img" conv=notrunc
      dd if=/usr/share/edk2/aarch64/QEMU_VARS.fd of="{{run_directory}}/flash1.img" conv=notrunc
    fi
  # Check if it is running on x86_64 or i686
  elif [ "{{qemu-system}}" = "x86_64" ] || [ "{{qemu-system}}" = "i686" ]; then
    cp /usr/share/OVMF/OVMF_CODE.fd "{{run_directory}}"
    cp /usr/share/OVMF/OVMF_VARS.fd "{{run_directory}}"
  else
    echo "Unknown CPU architecture: {{qemu-system}}"
    exit 1
  fi

run-make-system-partition qemu-system="x86_64" executable=default_executable:
  #!/usr/bin/env sh
  mkdir -p "{{run_directory}}/esp/efi/boot"
  if [ "{{qemu-system}}" = "aarch64" ]; then
    cp {{executable}} "{{run_directory}}/esp/efi/boot/BOOTAA64.EFI"
  elif [ "{{qemu-system}}" = "i686" ]; then
    cp {{executable}} "{{run_directory}}/esp/efi/boot/BOOTIA32.EFI"
  elif [ "{{qemu-system}}" = "x86_64" ]; then
    cp {{executable}} "{{run_directory}}/esp/efi/boot/BOOTX64.efi"
  else
    echo "Unknown CPU architecture: {{qemu-system}}"
    exit 1
  fi

run-qemu qemu-system="x86_64":
  #!/usr/bin/env sh
  if [ "{{qemu-system}}" = "aarch64" ]; then
     cd "{{run_directory}}" && qemu-system-aarch64 -nographic \
      -drive format=raw,file=fat:rw:esp \
      -drive if=none,id=code,format=raw,file=flash0.img,readonly=on \
      -drive if=none,id=vars,format=raw,file=flash1.img,snapshot=on \
      -machine virt,pflash0=code,pflash1=vars -m 512M -cpu max -smp 4
  elif [ "{{qemu-system}}" = "i686" ]; then
    cd "{{run_directory}}" && qemu-system-i386 -nographic \
      -machine pc \
      -drive if=pflash,format=raw,readonly=on,file=OVMF_CODE.fd \
      -drive if=pflash,format=raw,readonly=on,file=OVMF_VARS.fd \
      -drive format=raw,file=fat:rw:esp
  elif [ "{{qemu-system}}" = "x86_64" ]; then
    cd "{{run_directory}}" && qemu-system-x86_64 -nographic \
      -machine pc \
      -drive if=pflash,format=raw,readonly=on,file=OVMF_CODE.fd \
      -drive if=pflash,format=raw,readonly=on,file=OVMF_VARS.fd \
      -drive format=raw,file=fat:rw:esp
  else
    echo "Unknown CPU architecture: {{qemu-system}}"
    exit 1
  fi

run qemu-system="x86_64" target=default_target: (build target) run-mkdir (run-copy-files qemu-system) (run-make-system-partition qemu-system) (run-qemu qemu-system)

run-test qemu-system executable target=default_target: (build target) run-mkdir (run-copy-files qemu-system) (run-make-system-partition qemu-system executable) (run-qemu qemu-system)
  