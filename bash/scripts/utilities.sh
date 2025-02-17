#!/bin/bash
# Ebase Technology Ltd, 2025.

# Checks the existence of the second parameter.
# If it doesn't exist the first parameter is printed and the script is exited.
function assertSet #(String: failure_message, <variable to check> )
{
    if [[ -z $2  ]]; then
            printf "\n\n ERROR: $1\n\n"
            exit 1 # a non-successful exit.
    fi
}


# Adds the given string representation of a path to a array if that array doesn't already contain its parent path.
#   For example, it will add a/b/c to the list if a or a/b is not already present.
#
# This works for parent/child strings like a/b and 1.1, although they can't be mixed.
#
# Sorting lists of paths to add prior to using this method is essential.
#
# Parameters:
#   to_add - the string to add, of the form a/b/c or 1.2.3. Spaces between the separators are fine, e.g. a b/c d/f.
#   separator - the separator in the to_add string to use to split it up.
#   added - to_add will be added to this array if its parent path is not already present. 
#
# Returns:
#   0 - if to_add was not added.
#   1 - if to_add was added.
function addIfParentDirectoryNotPresent #(to_add: string, separator: char, added:array)
{
    local to_add="$1"
    local separator="$2"
    local -n added="$3"
    assertSet "addIfParentDirectoryNotPresent::to_add parameter not provided." "$to_add"
    assertSet "addIfParentDirectoryNotPresent::separator parameter not provided." "$separator"

    # if the added list is empty, then add the dir to it.
    if [ ${#added[@]} -eq 0 ]; then
        added+=("$to_add")
    else # otherwise check that a parent dir has not already been added.
        for added_dir in "${added[@]}"; do
            if [[ "$to_add" == "$added_dir$separator"* ]]; then
                return 0 # a parent directory is present.
            fi
        done

        # a parent directory has not been found - so add the dir
        added+=("$to_add")
    fi

    return 1 # the given dir was added.
}


# Adds empty files of the specified name to every empty directory under a root directory. 
#
# Parameters:
#   root_dir - path to the starting directory.
#   add_file_name - the name of the empty file to be created.
function addEmptyFileToAllEmptySubdirectories #(root_dir:path, add_file_name:string)
{
    local root_dir="$1"
    local add_file_name="$2"
    assertSet "addEmptyFileToAllEmptySubdirectories:: root directory not provided." "$root_dir"
    assertSet "addEmptyFileToAllEmptySubdirectories:: name of file to add not provided." "$add_file_name"

    find "$root_dir" -type d -empty | while read -r sub_dir; do
        local add_file="$sub_dir/$add_file_name"
        printf "Adding file: $add_file\n"
        touch "$add_file"
    done
}

# Looks for all structure files (e.g. .gitkeepstructure) under a root directory and for each file found adds an empty file to
#   every empty subdirectory under each of the found structure files' owing directory.
#
# This can be use to preserve an otherwise empty directory structure in git.
#
# Parameters:
#   root_dir - path to the starting directory.
#   structure_file_name - the name of the structure files.
#   add_file_name - the name of the empty file to be created.
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


# Looks for all structure files (e.g. .gitkeepstructure) under a root directory and for each file found adds an empty file to
#   every empty subdirectory under each of the found structure files' owing directory.
#
# This can be use to preserve an otherwise empty directory structure in git.
#
# This version filters out structure files in subdirectories of other structure files (as their empty sub directories will already be processed).
#   So, depending on your project this may be more efficient. Generally though its probably better to go for the simpler version of this method.
#
# Parameters:
#   root_dir - path to the starting directory.
#   structure_file_name - the name of the structure files.
#   add_file_name - the name of the empty file to be created.
function maintainFileStructureForGitRepositories_filtered #(root_dir:path, structure_file_name:string, add_file_name:string)
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


# Removes all files of the given name under they specified directory.
# Use with caution.
#
# Parameters:
#   root_dir - path to the starting directory.
#   remove_file_name - the name of the file to be removed.
function removeKeepFiles #(root_dir:path, remove_file_name:string)
{
    local root_dir="$1"
    local remove_file_name="$2"
    assertSet "removeKeepFiles:: root directory not provided." "$root_dir"
    assertSet "removeKeepFiles:: name of the file to generate in empty subdirectories under every structure file not provided." "$remove_file_name"

    find "$root_dir" -type f -name "$remove_file_name" -delete
}