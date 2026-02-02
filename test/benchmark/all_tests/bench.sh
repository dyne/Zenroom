#!/bin/env bash

# add any new test to bucket by simpling add |test_identifier"
bucket="foreach|cookbook"

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
        make -s linux-exe CCACHE=1
        make -s linux-lib CCACHE=1
    fi
    echo "testing local build"
    meson setup meson/ build/ -D "tests=['benchmark']" && ninja -C meson benchmark | tee $tmp
    cat $tmp | grep -o 'zencode_.*' | tr -d 'OK'> $1
    rm $tmp
}

remote_test() {
    tmp=$(mktemp)
    echo "compiling"
    make -s linux-exe CCACHE=1
    make -s linux-lib CCACHE=1
    echo "testing remote build"
    meson setup meson/ build/ -D "tests=['benchmark']" && ninja -C meson benchmark | tee $tmp
    cat $tmp | grep -o 'zencode_.*' | tr -d 'OK'> $1
    rm $tmp
}

print_result() {
    printf "%-35s" "$1"
    if (( $(echo "$2 > $3" | bc -l) )); then
        printf "%b  %6ss %b %6ss %b\n" "$RED" "$2" "$GREEN" "$3" "$RESET"
    else
        printf "%b  %6ss %b %6ss %b\n" "$GREEN" "$2" "$RED" "$3" "$RESET"
    fi
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
bucket_size=0
local_sum=0
remote_sum=0
printf "%43s %9s\n" "local" "remote"
while read local <&3; do
    test=$(echo $local | tr -s ' ' | cut -d ' ' -f 1)
    local_time=$(echo $local | tr -s ' ' | cut -d ' ' -f 2 | tr -d 's ')
    # to be sure tests are taken in the right order
    remote_time=$(cat $remote_out | grep -w "$test " | tr -s ' ' | cut -d ' ' -f 2 | tr -d 's ')
    if [[ $(echo "$test" | grep -E "$bucket") != "" ]]; then
	bucket_size=$((bucket_size+1))
        local_sum=$(echo "$local_sum + $local_time" | bc -l)
        remote_sum=$(echo "$remote_sum + $remote_time" | bc -l)
    fi
    print_result $test $local_time $remote_time
done 3<$local_out
local_sum=$(echo "scale=2; $local_sum / $bucket_size" | bc -l)
remote_sum=$(echo "scale=2; $remote_sum / $bucket_size" | bc -l)
print_result $bucket $local_sum $remote_sum
rm $local_out $remote_out
