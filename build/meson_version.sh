#!/bin/bash
if $(git describe >/dev/null 2>/dev/null); then
    echo $(git describe --tags) | cut -d- -f1
    exit 0
else
    echo $(head -1 ../git_utils) | cut -d+ -f1
    exit 0
fi
