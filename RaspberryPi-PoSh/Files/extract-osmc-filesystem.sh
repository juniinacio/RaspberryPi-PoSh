#!/bin/bash
sudo tar -xJpf $1 -C $2 --numeric-owner
if [ -n $3 ]; then
    cd $3
fi