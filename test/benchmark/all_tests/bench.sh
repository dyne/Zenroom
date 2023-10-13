#!/bin/env bash
RESET="\033[0m"
RED="\033[31m"
GREEN="\033[32m"

command -v bc >/dev/null || {
    echo "bc not found"; exit 1
}

command -v ccache >/dev/null || {
    echo "ccache not found"; exit 1
}

local_test() {
    tmp=$(mktemp)
    if [ ! -d meson ]; then
        echo "compiling"
        make clean
        make -s meson-ccache
    fi
    echo "testing local build"
    make meson-benchmark | tee $tmp
    cat $tmp | grep -o 'zencode_.*' | tr -d 'OK'> $1
    rm $tmp
}

remote_test() {
    tmp=$(mktemp)
    echo "compiling"
    make -s meson-ccache
    echo "testing"
    make meson-benchmark | tee $tmp
    cat $tmp | grep -o 'zencode_.*' | tr -d 'OK'> $1
    rm $tmp
}

# local folder
echo "testing local $(git rev-parse --abbrev-ref HEAD) branch..."
local_out=$(mktemp)
local_test $local_out

# remote main
echo ""
echo "testing remote main branch..."
remote_dir=$(mktemp -d)
echo "cloning remote main"
git clone -q "https://github.com/dyne/Zenroom.git" $remote_dir
remote_out=$(mktemp)
cd $remote_dir
remote_test $remote_out
cd -
rm -rf $remote_dir

# bench output
printf "%43s %8s\n" "local" "remote"
while read local <&3; do
    test=$(echo $local | tr -s ' ' | cut -d ' ' -f 1)
    local_time=$(echo $local | tr -s ' ' | cut -d ' ' -f 2 | tr -d 's ')
    # to be sure tests are taken in the right order
    remote_time=$(cat $remote_out | grep -w "$test " | tr -s ' ' | cut -d ' ' -f 2 | tr -d 's ')
    printf "%-35s" "$test"
    if (( $(echo "$local_time > $remote_time" |bc -l) )); then
        printf "%b  %5.2fs %b %5.2fs %b\n" "$RED" "$local_time" "$GREEN" "$remote_time" "$RESET"
    else
        printf "%b  %5.2fs %b %5.2fs %b\n" "$GREEN" "$local_time" "$RED" "$remote_time" "$RESET"
    fi
done 3<$local_out
rm $local_out $remote_out
