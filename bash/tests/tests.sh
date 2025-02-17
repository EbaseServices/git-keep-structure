#!/bin/bash

source ../scripts/utilities.sh


# Tests the filtering out of parent directories from a list.
function simpleFilterTest1
{
    local dirs=("a/b" "a/b/c" "a/b/c/d" "a/b/e" "a/f")
    local filtered_dirs=()

    # Filter the list by looking at each dirs entry at a time.
    for dir in "${dirs[@]}"; do
        addIfParentDirectoryNotPresent "$dir" "/" filtered_dirs
    done

    # test the filtered list
    if [ "${#filtered_dirs[@]}" -eq 2 ] && [ "${filtered_dirs[0]}" == "a/b" ] && [ "${filtered_dirs[1]}" == "a/f" ]; then
        printf "simpleFilterTest1:: Passed.\n"
    else
        printf "simpleFilterTest1: Failed - expecting a/b, a/f - got:/n"
        printf "%s\n" "${filtered_dirs[@]}"
        exit 1
    fi
}

# Tests the filtering out of different dot versions from a list.
function simpleFilterTest2
{
    local versions=("1.1" "1.2.2" "1.1.2.1" "1.12" "1.1.1")
    local filtered_versions=()

    # Filter the list by looking at each dirs entry at a time.
    for version in "${versions[@]}"; do
        addIfParentDirectoryNotPresent "$version" "." filtered_versions
    done

    # test the filtered list
    if [ "${#filtered_versions[@]}" -eq 3 ] && [ "${filtered_versions[0]}" == "1.1" ] && [ "${filtered_versions[1]}" == "1.2.2" ] && [ "${filtered_versions[2]}" == "1.12" ]; then
        printf "simpleFilterTest2:: Passed.\n"
    else
        printf "simpleFilterTest2: Failed - expecting 1.1, 1.2.2, 1.12 - got:\n"
        printf "%s\n" "${filtered_versions[@]}"
        exit 1
    fi
}

# Tests the filtering out of parent directories from a list.
function simpleFilterTestWithSpaces
{
    local dirs=("a a/b b" "a a/b b/c c" "a a/b b/c/d" "a/b/e" "a a/f")
    local filtered_dirs=()

    # Filter the list by looking at each dirs entry at a time.
    for dir in "${dirs[@]}"; do
        addIfParentDirectoryNotPresent "$dir" "/" filtered_dirs
    done

    # test the filtered list
    if [ "${#filtered_dirs[@]}" -eq 3 ] && [ "${filtered_dirs[0]}" == "a a/b b" ] && [ "${filtered_dirs[1]}" == "a/b/e" ] && [ "${filtered_dirs[2]}" == "a a/f" ]; then
        printf "simpleFilterTestWithSpaces:: Passed.\n"
    else
        printf "simpleFilterTestWithSpaces: Failed - expecting a a/b b, a/b/e, a a/f - got:\n"
        printf "%s\n" "${filtered_dirs[@]}"
        exit 1
    fi
}


# Run all tests
function runTests
{
    simpleFilterTest1
    simpleFilterTest2
    simpleFilterTestWithSpaces

    exit 0
}


runTests