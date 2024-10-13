#!/bin/bash

set -e

BASEDIR=$PWD
CM_FOLDER=coremark

cd $BASEDIR/$CM_FOLDER

# run the compile
echo "Start compilation"

make PORT_DIR=../riscv-baremetal compile ITERATIONS=1
mv coremark.bare.riscv ../
