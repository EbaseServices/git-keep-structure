#!/bin/bash
# Ebase Technology Ltd, 2025.

# parse the utilities.
source utilities.sh

# Set up default values. These can be overridden via the command line.
DEFAULT_STRUCTURE_FILE=".gitkeepstructure"
DEFAULT_KEEP_FILE=".gitkeep"


# The help text
function displayHelp
{
    echo
    echo "Commands:"
    echo "  addKeepFiles: Finds all structure files under a directory and generates keep files in every empty subdirectory in each structure file's owning directory."
    echo "     Usage:"
    echo "        addKeepFiles --root-dir <dir> [--structure-file <filename>] [--keep-file <filename>]"
    echo "            --root-dir - the path to the directory to start searching in."
    echo "            --structure-file - the name of the structure files to find. Optional - defaults to $DEFAULT_STRUCTURE_FILE."
    echo "            --keep-file - the name of the empty file to add to every empty directory. Optional - defaults to $DEFAULT_KEEP_FILE."
    echo
    echo "  removeKeepFiles: Removes all keep files with a specified name under a directory."
    echo "     Usage:"
    echo "        removeKeepFiles --root-dir <dir> [--keep-file <filename>]"
    echo "            --root-dir - the path to the directory to start searching in."
    echo "            --keep-file - the name of the file to remove. Optional - defaults to $DEFAULT_KEEP_FILE."
    echo
}


# Parse options provided
function parseOptions #(<Pass in $*>)
{
    local options=`getopt -s bash -o hr:s:k: --long help,root-dir:,structure-file:,keep-file: -- "$@"`
    eval set -- "$options"

    while true
    do
        case "$1" in
            -h | --help)
                displayHelp
                exit 0
                ;;
            -r | --root-dir)
                COMMAND_ROOT_DIR="$2"
                shift 2
                ;;
            -s | --structure-file)
                COMMAND_STRUCTURE_FILE="$2"
                shift 2
                ;;
            -k | --keep-file)
                COMMAND_KEEP_FILE="$2"
                shift 2
                ;;
            --)
                # end of all options
                shift
                break
                ;;
            -*)
                # unknown option
                echo "Error: Unknown option: $1." >&2
                echo
                displayHelp
                exit 1
                ;;
            *)
                # No more options
                break
                ;;
        esac
    done
}

function runCommand
{
	# setup common defaults for passed in options
	if [ -z "$COMMAND_STRUCTURE_FILE" ]; then
		COMMAND_STRUCTURE_FILE="$DEFAULT_STRUCTURE_FILE"
	fi

	if [ -z "$COMMAND_KEEP_FILE" ]; then
		COMMAND_KEEP_FILE="$DEFAULT_KEEP_FILE"
	fi


	# Run command(s)
    while true
    do
        case "$1" in
            help)
                displayHelp
                exit 0
                ;;

            addKeepFiles)
                if [ -z "$COMMAND_ROOT_DIR" ]; then
                    echo "Root directory not specified."
                    displayHelp
                    exit 1
                fi

                command_addKeepFiles "$COMMAND_ROOT_DIR" "$COMMAND_STRUCTURE_FILE" "$COMMAND_KEEP_FILE"
                exit 0
                ;;

            removeKeepFiles)
                if [ -z "$COMMAND_ROOT_DIR" ]; then
                    echo "Root directory not specified."
                    displayHelp
                    exit 1
                fi

                command_removeKeepFiles "$COMMAND_ROOT_DIR" "$COMMAND_KEEP_FILE"
                exit 0
                ;;

            *)
                echo "Error: No command specified. Use help command" >&2
                displayHelp
                exit 1
                ;;
        esac
    done
}


function command_addKeepFiles #(root_dir:path, structure_file_name:string, keep_file:string)
{
    local root_dir="$1"
    local structure_file_name="$2"
    local keep_file="$3"
    assertSet "addKeepFiles:: root directory not provided. Usage: addKeepFiles --root-dir <dir> [--structure-file <filename>] [--keep-file <filename>]." "$root_dir"
    assertSet "addKeepFiles:: name of the structure file used not provided. Usage: addKeepFiles --root-dir <dir> [--structure-file <filename>] [--keep-file <filename>]." "$structure_file_name"
    assertSet "addKeepFiles:: name of the keep file not provided. Usage: addKeepFiles --root-dir <dir> [--structure-file <filename>] [--keep-file <filename>]." "$keep_file"

    printf "Running addKeepFiles -r=$root_dir -s=$structure_file_name -k=$keep_file ...\n"
    maintainFileStructureForGitRepositories "$root_dir" "$structure_file_name" "$keep_file"
    printf "...done.\n"
}


function command_removeKeepFiles #(root_dir:path, structure_file_name:string, keep_file:string)
{
    local root_dir="$1"
    local keep_file="$2"
    assertSet "removeKeepFiles:: root directory not provided. Usage: removeKeepFiles --root-dir <dir> [--keep-file <filename>]." "$root_dir"
    assertSet "removeKeepFiles:: name of the keep file not provided. Usage: removeKeepFiles --root-dir <dir> [--keep-file <filename>]." "$keep_file"

    printf "Running removeKeepFiles -r=$root_dir -k=$keep_file ...\n"
    removeKeepFiles "$root_dir" "$keep_file"
    printf "...done.\n"
}


parseOptions $*
runCommand $*
