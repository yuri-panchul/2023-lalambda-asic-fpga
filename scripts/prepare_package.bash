#!/usr/bin/env bash

set -Eeuo pipefail  # See the meaning in scripts/README.md
# set -x  # Print each command

#-----------------------------------------------------------------------------

script_path="$0"
script=$(basename "$script_path")
script_dir=$(dirname "$script_path")

run_dir="$PWD"
cd "$script_dir/.."

repo_dir=$(readlink -e .)
repo_name=$(basename "$repo_dir")

#-----------------------------------------------------------------------------

info ()
{
    printf "\n$script: $*\n" 1>&2
}

error ()
{
    info ERROR: $*
    exit 1
}

#-----------------------------------------------------------------------------

# -n nchars  return after reading NCHARS characters rather than waiting
#            for a newline, but honor a delimiter if fewer than
#            NCHARS characters are read before the delimiter
#
# -p prompt  output the string PROMPT without a trailing newline before
#            attempting to read
#
# -r         do not allow backslashes to escape any characters

read -n 1 -r -p "The script $script is about to erase the changes you did to the files inside\"$repo_dir\". Are you sure? "
[[ $REPLY =~ ^[Yy]$ ]] || error "Exiting"

if ! git rev-parse --is-inside-work-tree &> /dev/null
then
    info "Not running inside Git repository. Will prompt before removing every directory or a top-level file."
    rm -i -r [1-9]_*
else
    info "Running inside Git repository"

    true_repo_name=$(basename $(git rev-parse --show-toplevel))

    [ "$true_repo_name" == "$repo_name" ] \
        || error "Unexpected repository name: \"$true_repo_name\" != \"$repo_name\""

    files_to_remove=$(git clean -d -n -x)

    if [ -n "${files_to_remove-}" ]
    then
        info "Files to remove:\n$files_to_remove"

        read -n 1 -r -p "About to remove the files and directories above. Are you sure? "
        [[ $REPLY =~ ^[Yy]$ ]] || error "Exiting"
        echo
        git clean -d -f -x
    fi

    #-------------------------------------------------------------------------

    f=$(git diff --name-status --diff-filter=R HEAD)

    if [ -n "${f-}" ]
    then
        error "there are renamed files in the tree."                            \
              "\nYou should check them in before preparing a release package."  \
              "\nSpecifically:\n\n$f"
    fi

    f=$(git ls-files --others --exclude-standard)

    if [ -n "${f-}" ]
    then
        error "there are untracked files in the tree."          \
              "\nYou should either remove or check them in"     \
              "before preparing a release package."             \
              "\nSpecifically:\n\n$f"                           \
              "\n\nYou can also see the file list by running:"  \
              "\n    git clean -d -n \"$repo_dir\""             \
              "\n\nAfter reviewing (be careful!),"              \
              "you can remove them by running:"                 \
              "\n    git clean -d -f \"$repo_dir\""             \
              "\n\nNote that \"git clean\" does not see"        \
              "the files from the .gitignore list."
    fi

    f=$(git ls-files --others)

    if [ -n "${f-}" ]
    then
        error "there are files in the tree, ignored by git,"                    \
              "based on .gitignore list."                                       \
              "\nThis repository is not supposed to have the ignored files."    \
              "\nYou need to remove them before preparing a release package."   \
              "\nSpecifically:\n\n$f"
    fi

    f=$(git ls-files --modified)

    if [ -n "${f-}" ]
    then
        error "there are modified files in the tree."                           \
              "\nYou should check them in before preparing a release package."  \
              "\nSpecifically:\n\n$f"
    fi
fi

#-----------------------------------------------------------------------------

# Search for the text files with DOS/Windows CR-LF line endings

# -r     - recursive
# -l     - file list
# -q     - status only
# -I     - Ignore binary files
# -U     - don't strip CR from text file by default
# $'...' - string literal in Bash with C semantics ('\r', '\t')

if [ "$OSTYPE" = linux-gnu ] && grep -rqIU $'\r$' *
then
    grep -rlIU $'\r$' *

    error "there are text files with DOS/Windows CR-LF line endings." \
          "You can fix them by doing:" \
          "\ngrep -rlIU \$'\\\\r\$' \"$repo_dir\"/* | xargs dos2unix"
fi

exclude_urg="--exclude-dir=urgReport"

if grep -rqI $exclude_urg $'\t' *
then
    grep -rlI $exclude_urg $'\t' *

    error "there are text files with tabulation characters." \
          "\nTabs should not be used." \
          "\nDevelopers should not need to configure the tab width" \
          " of their text editors in order to be able to read source code." \
          "\nPlease replace the tabs with spaces" \
          "before checking in or creating a package." \
          "\nYou can find them by doing:" \
          "\ngrep -rlI $exclude_urg \$'\\\\t' \"$repo_dir\"/*" \
          "\nYou can fix them by doing the following," \
          "but make sure to review the fixes:" \
          "\ngrep -rlI $exclude_urg \$'\\\\t' \"$repo_dir\"/*" \
          "| xargs sed -i 's/\\\\t/    /g'"
fi

if grep -rqI $exclude_urg '[[:space:]]\+$' *
then
    grep -rlI $exclude_urg '[[:space:]]\+$' *

    error "there are spaces at the end of line, please remove them." \
          "\nYou can fix them by doing:" \
          "\ngrep -rlI $exclude_urg '[[:space:]]\\\\+\$' \"$repo_dir\"/*" \
          "| xargs sed -i 's/[[:space:]]\\\\+\$//g'"
fi

#-----------------------------------------------------------------------------

git clone https://gitflic.ru/project/yuri-panchul/fpga-soldering-camp.git \
  1_fpga_soldering_camp

#git clone https://github.com/yuri-panchul/schoolRISCV.git \
#  4_school_risc_v

git clone https://gitflic.ru/project/yuri-panchul/valid-ready-etc.git \
  5_valid_ready_etc

git clone https://github.com/yuri-panchul/yrv-plus.git \
  6_yrv_plus

rm -rf */.git

pushd 6_yrv_plus
rm -rf Lattice Xilinx
pushd Plus
mv * .gitignore ..
popd
rm -rf Plus
popd

#-----------------------------------------------------------------------------

temp_dir=$(mktemp -d)
package="${repo_name}_$(date '+%Y%m%d')"
package_path="$temp_dir/$package"

mkdir "$package_path"
cp -r * .gitignore "$package_path"

#-----------------------------------------------------------------------------

if ! command -v zip &> /dev/null
then
    printf "$script: cannot find zip utility"

    if [ "$OSTYPE" = "msys" ]
    then
        printf "\n$script: download zip for Windows from https://sourceforge.net/projects/gnuwin32/files/zip/3.0/zip-3.0-setup.exe/download"
        printf "\n$script: then add zip to the path: %s" '%PROGRAMFILES(x86)%\GnuWin32\bin'
    fi

    exit 1
fi

#-----------------------------------------------------------------------------

pushd "$temp_dir"
rm -rf "$run_dir/$repo_name"_*.zip
zip -r "$run_dir/$package.zip" "$package"
popd
rm -rf "$temp_dir"
