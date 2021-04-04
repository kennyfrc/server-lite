#!/bin/bash

if [[ $# -eq 0 ]]; then
    echo "Missing client request. Default IP and port is 'http://127.0.0.1:9000/"
    echo 
    exit 0
fi

( killall ruby; ./lib/server-lite.rb& ) && 
( sleep 1; curl -v $1 )