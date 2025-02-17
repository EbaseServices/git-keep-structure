#!/bin/bash
# Ebase Technology Ltd, 2025.

# Parse the utilities (load them relative to this script as who knows what the working directory will be).
source $(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"/utilities.sh"

# Set up default values. These can be overridden via the command line.
DEFAULT_STRUCTURE_FILE=".gitkeepstructure"
DEFAULT_KEEP_FILE=".gitkeep"


# The help text
function displayHelp
{
    echo
    echo "Options:"
    echo "  -h : show the help page."
    echo "  -r : the path to the directory to start searching in."
    echo "  -s : the name of the structure files to find."
    echo "  -k : the name of the file to add to every empty directory."
    echo
    echo "Commands:"
    echo "  addKeepFiles: Finds all structure files under a directory and generates keep files in every empty subdirectory in each structure file's owning directory."
    echo "     Usage:"
    echo "        -r \"<dir>\" [-s \"<filename>\"] [-k \"<filename>\"] addKeepFiles"
    echo "            -r : the path to the directory to start searching in."
    echo "            -s : the name of the structure files to find. Optional - defaults to $DEFAULT_STRUCTURE_FILE."
    echo "            -k : the name of the file to add to every empty directory. Optional - defaults to $DEFAULT_KEEP_FILE."
    echo
    echo "  removeKeepFiles: Removes all keep files with a specified name under a directory."
    echo "     Usage:"
    echo "        -r \"<dir>\" [-k \"<filename>\"] removeKeepFiles"
    echo "            -r : the path to the directory to start searching in."
    echo "            -k : the name of the file to add to every empty directory. Optional - defaults to $DEFAULT_KEEP_FILE."
    echo
    echo "  help: Shows this help page."
    echo "     Usage:"
    echo "         help"
    echo
}


# Parse options provided
function parseOptions
{
    while getopts hr:s:k: option; do
        case "$option" in
            h)
                displayHelp
                exit 0
                ;;
            r)
                COMMAND_ROOT_DIR="$OPTARG"
                ;;
            s)
                COMMAND_STRUCTURE_FILE="$OPTARG"
                ;;
            k)
                COMMAND_KEEP_FILE="$OPTARG"
                ;;
            \?)
                echo "Error: Invalid option: -$OPTARG" >&2
                exit 1
                ;;
            :)
                echo "Error: Option -$OPTARG requires an argument." >&2
                exit 1
                ;;
        esac
    done

 	# Setup defaults for passed in options
	if [ -z "$COMMAND_STRUCTURE_FILE" ]; then
		COMMAND_STRUCTURE_FILE="$DEFAULT_STRUCTURE_FILE"
	fi

	if [ -z "$COMMAND_KEEP_FILE" ]; then
		COMMAND_KEEP_FILE="$DEFAULT_KEEP_FILE"
	fi
}

function runCommand
{
	# Run command
    if [ $# -gt 0 ]; then
        command=$1
        shift
    fi

    case "$command" in
        help)
            displayHelp
            exit 0
            ;;

        addKeepFiles)
            if [ -z "$COMMAND_ROOT_DIR" ]; then
                echo "Error: Root directory not specified. Use option: -r \"<dir>\"." >&2
                displayHelp
                exit 1
            fi

            command_addKeepFiles "$COMMAND_ROOT_DIR" "$COMMAND_STRUCTURE_FILE" "$COMMAND_KEEP_FILE"
            exit 0
            ;;

        removeKeepFiles)
            if [ -z "$COMMAND_ROOT_DIR" ]; then
                echo "Error: Root directory not specified. Use option: -r \"<dir>\"." >&2
                displayHelp
                exit 1
            fi

            command_removeKeepFiles "$COMMAND_ROOT_DIR" "$COMMAND_KEEP_FILE"
            exit 0
            ;;

        *)
            echo "Error: Unknown command specified: $command" >&2
            displayHelp
            exit 1
            ;;
    esac
}


function command_addKeepFiles #(root_dir:path, structure_file_name:string, keep_file:string)
{
    local root_dir="$1"
    local structure_file_name="$2"
    local keep_file="$3"
    assertSet "addKeepFiles:: root directory not provided. Usage: -r \"<dir>\" [-s \"<filename>\"] [-k \"<filename>\"] addKeepFiles." "$root_dir"
    assertSet "addKeepFiles:: name of the structure file used not provided. Usage:  -r \"<dir>\" [-s \"<filename>\"] [-k \"<filename>\"] addKeepFiles." "$structure_file_name"
    assertSet "addKeepFiles:: name of the keep file not provided. Usage:  -r \"<dir>\" [-s \"<filename>\"] [-k \"<filename>\"] addKeepFiles.." "$keep_file"

    printf "Running addKeepFiles -r=$root_dir -s=$structure_file_name -k=$keep_file ...\n"
    maintainFileStructureForGitRepositories "$root_dir" "$structure_file_name" "$keep_file"
    printf "...done.\n"
}


function command_removeKeepFiles #(root_dir:path, structure_file_name:string, keep_file:string)
{
    local root_dir="$1"
    local keep_file="$2"
    assertSet "removeKeepFiles:: root directory not provided. Usage: -r \"<dir>\" [-k \"<filename>\"] removeKeepFiles." "$root_dir"
    assertSet "removeKeepFiles:: name of the keep file not provided. Usage: -r \"<dir>\" [-k \"<filename>\"] removeKeepFiles." "$keep_file"

    printf "Running removeKeepFiles -r=$root_dir -k=$keep_file ...\n"
    removeKeepFiles "$root_dir" "$keep_file"
    printf "...done.\n"
}


# Parse and options passing in the 
parseOptions "$@"

# Remove the parsed options from the positional parameters.
# Note its important to do this here as they scoped in the parseOptions function and so shifting them 
#   there will not have remove them for the following runCommand.
shift $((OPTIND-1))

# Run the specified command.
runCommand "$@"
