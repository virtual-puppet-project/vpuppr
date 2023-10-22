#!/bin/sh

cd $(dirname "$0")

echo "Updating git submodules"
git submodule update --init --recursive --remote

echo "Building rust lib"
mv libvpuppr/target/debug/deps/libvpuppr.dll libvpuppr/target/debug/deps/libvpuppr.dll.bak || true
mv libvpuppr/target/debug/libvpuppr.dll libvpuppr/target/debug/libvpuppr.dll.bak || true
python libvpuppr/build.py --debug
rm -f libvpuppr/target/debug/deps/libvpuppr.dll.bak || true
rm -f libvpuppr/target/debug/libvpuppr.dll.bak || true

echo "Copying gdextension files"
cp libvpuppr/libvpuppr.gdextension .

