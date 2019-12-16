#!/bin/bash

if [ "$1" == "sinkholecli" ]; then
    go build -o "./bin/sinkholecli" "./cmd/sinkholecli/main.go" \
        && echo "./bin/sinkholecli"
    exit
fi

echo Building plugins
for d in ./plugins/* ; do
    # Handle empty dir
    if [ "$d" == "./plugins/*" ]; then continue; fi
    echo $d
    name=`basename "$d"`
    go build -buildmode=plugin -o "bin/$name.so" "$d/main.go"
done

echo Building sinkholed
mkdir -p "./bin"
go build -o "./bin/sinkholed" "./cmd/sinkholed/main.go" \
    && echo "./bin/sinkholed"
go build -o "./bin/sinkholecli" "./cmd/sinkholecli/main.go" \
    && echo "./bin/sinkholecli"

