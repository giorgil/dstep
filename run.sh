#!/bin/sh

./build.sh && ./bin/dstep -Iclangs/clang+llvm-3.7.0-x86_64-apple-darwin/include clangs/clang+llvm-3.7.0-x86_64-apple-darwin/include/clang-c/CXErrorCode.h
