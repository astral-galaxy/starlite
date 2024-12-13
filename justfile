cpu_arch := arch()

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