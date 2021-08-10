#!/usr/bin/env bash

if [ ! "$(uname -s)" == "Darwin" ]
then
    exit 0
fi

find $(dirname $0) -name *.defaults | while read defaults; do source ${defaults} ; done
