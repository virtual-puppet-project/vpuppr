#!/bin/sh

cd $(dirname "$0")

echo "Updating git submodules"
git submodule update --recursive --remote

echo "Building rust lib"
cargo build --manifest-path=vpuppr-rust-lib/Cargo.toml
cargo build --release --manifest-path=vpuppr-rust-lib/Cargo.toml

echo "Copying gdextension files"
cp libvpuppr/libvpuppr.gdextension .

