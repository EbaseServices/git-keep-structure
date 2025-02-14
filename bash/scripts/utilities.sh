#!/bin/bash

# Checks the existence of the second parameter.
# If it doesn't exist the first parameter is printed and the script is exited.
function assertSet #(String: failure_message, <variable to check> )
{
    if [[ -z $2  ]]; then
            printf "\n\n ERROR: $1\n\n"
            exit 1 # a non-successful exit.
    fi
}

# Adds the given string representation of a path if a parent directory has not been added.
#   If using to filter sub directories from a directory listing then that listing should be sorted alphabetically first.
function addIfParentDirectoryNotPresent #(to_add: string, delimiter: char, added:list)
{
    local to_add="$1"
    local delimiter="$2"
    local -n added="$3"
    assertSet "addIfParentDirectoryNotPresent::to_add parameter not provided." "$to_add"
    assertSet "addIfParentDirectoryNotPresent::delimiter parameter not provided." "$delimiter"

    # if the added list is empty, then add the dir to it.
    if [ ${#added[@]} -eq 0 ]; then
        added+=("$to_add")
    else # otherwise check that a parent dir has not already been added.
        for added_dir in "${added[@]}"; do
            if [[ "$to_add" == "$added_dir$delimiter"* ]]; then
                return 0 # a parent directory is present.
            fi
        done

        # a parent directory has not been found - so add the dir
        added+=("$to_add")
    fi

    return 1 # the given dir was added.
}

function addEmptyFileToAllEmptySubdirectories #(start_dir:path, add_file_name:string)
{
    local start_dir="$1"
    local add_file_name="$2"
    assertSet "addEmptyFileToAllEmptySubdirectories:: starting directory not provided." "$start_dir"
    assertSet "addEmptyFileToAllEmptySubdirectories:: name of file to add not provided." "$add_file_name"

    find "$start_dir" -type d -empty | while read -r sub_dir; do
        local add_file="$sub_dir/$add_file_name"
        printf "Adding file: $add_file\n"
        touch "$add_file"
    done
}

function maintainFileStructureForGitRepositories #(root_dir:path, structure_file_name:string, add_file_name:string)
{
    local root_dir="$1"
    local structure_file_name="$2"
    local add_file_name="$3"
    assertSet "maintainFileStructureForGitRepositories:: root directory not provided." "$root_dir"
    assertSet "maintainFileStructureForGitRepositories:: name of the structure file used to determine the root of the file structure to preserve not provided." "$structure_file_name"
    assertSet "maintainFileStructureForGitRepositories:: name of the file to generate in empty subdirectories under every structure file not provided." "$add_file_name"

    # Find all structure files under the root directory and generate empty files in their empty sub directories.
    find "$root_dir" -type f -name "$structure_file_name" | while read -r structure_file; do
        local preserve_structure_root=$(dirname "$structure_file")
        addEmptyFileToAllEmptySubdirectories "$preserve_structure_root" "$add_file_name"
    done
}

function maintainFileStructureForGitRepositories_filtered #(root_folder:path, add_file_name:string)
{
    local root_dir="$1"
    local structure_file_name="$2"
    local add_file_name="$3"
    assertSet "maintainFileStructureForGitRepositories_filtered:: root directory not provided." "$root_dir"
    assertSet "maintainFileStructureForGitRepositories_filtered:: name of the structure file used to determine the root of the file structure to preserve not provided." "$structure_file_name"
    assertSet "maintainFileStructureForGitRepositories_filtered:: name of the file to generate in empty subdirectories under every structure file not provided." "$add_file_name"

    # Find the directories containing the structure files under the root directory and add them to a dirs array.
    #  Note: We have to be careful directories with spaces in their names.
    local dirs=()
    while IFS= read -r -d '' file; do
        local found_dir=$(dirname "$file")
        dirs+=("$found_dir")
    done < <(find "$root_dir" -type f -name "$structure_file_name" -print0)

    # Sort these directories, again being careful about directories containing spaces.
    mapfile -t sorted_dirs < <(printf "%s\n" "${dirs[@]}" | sort)

    # filter out sub directories of directories also in the list.
    local filtered_dirs=()
    for sorted_dir in "${sorted_dirs[@]}"; do
        # Filter the list by looking at each dirs entry at a time.
        addIfParentDirectoryNotPresent "$sorted_dir" "/" filtered_dirs
    done

    # add files to all empty sub directories under each filtered directory.
    for filtered_dir in "${filtered_dirs[@]}"; do
        addEmptyFileToAllEmptySubdirectories "$filtered_dir" "$add_file_name"
    done
}