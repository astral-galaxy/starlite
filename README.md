# 🌠 Starlight

Starlight is a simple, lightweight, and fast UEFI bootloader for UEFI-compliant operating systems. It's also the bootloader for the [Astral Operating System](https://github.com/astral-galaxy/astral). It is written in Rust and is designed to be easy to use and extend.

## Features

- **Fast**: Starlight is designed to be fast, we want to make the boot process as quick as possible.
- **Lightweight**: Starlight is designed to be lightweight and minimal. We don't include any unnecessary features neither support legacy BIOS systems.
- **Secure**: Starlight is designed to be secure and memory-safe.

## Building

To build Starlight, you need to have Rust installed. You can install Rust by following the instructions on the [official website](https://www.rust-lang.org/tools/install).

### Building for x86_64

```bash
rustup target add x86_64-unknown-uefi
git clone https://github.com/astral-galaxy/astral.git
cd astral
cargo build --release --target x86_64-unknown-uefi
```

### Building for aarch64

```bash
rustup target add aarch64-unknown-uefi
git clone https://github.com/astral-galaxy/astral.git
cd astral
cargo build --release --target aarch64-unknown-uefi
```

## Usage

To use Starlight, you need to copy the `starlight.efi` file to the **EFI partition** of your system (This file is located in the `target/x86_64-unknown-uefi/release` directory on **x86_64** and `target/aarch64-unknown-uefi/release` on **aarch64**). You can do this by mounting the EFI partition and copying the file to the `EFI/BOOT` directory. We will provide automated installation scripts in the future as the project becomes more mature.

## Contributing

We welcome contributions from everyone. Feel free to open an issue or a pull request.

## License

Starlight is dual-licensed under the [MIT](./LICENSE-MIT) and [Apache 2.0](./LICENSE-APACHE) licenses. You may choose either license to use this software.