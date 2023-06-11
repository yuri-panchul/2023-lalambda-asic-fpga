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

if git rev-parse --is-inside-work-tree &> /dev/null
then
    info "Running inside Git repository"

    true_repo_name=$(basename $(git rev-parse --show-toplevel))
    
    [ "$true_repo_name" == "$repo_name" ] \
        || error "Unexpected repository name: \"$true_repo_name\" != \"$repo_name\""
        
    git clean -d -n -x

    read -n 1 -r -p "About to remove the files and directories above. Are you sure? "
    [[ $REPLY =~ ^[Yy]$ ]] || error "Exiting"

    git clean -d -f -x
else
    info "Not running inside Git repository. Will prompt before removing every directory or a top-level file."
    rm -i -r [1-9]_*
fi

#-----------------------------------------------------------------------------

git clone https://gitflic.ru/project/yuri-panchul/fpga-soldering-camp.git \
  1_fpga_soldering_camp

git clone https://github.com/yuri-panchul/schoolRISCV.git \
  4_school_risc_v

git clone https://gitflic.ru/project/yuri-panchul/valid-ready-etc.git \
  5_valid-ready-etc

git clone https://github.com/yuri-panchul/yrv-plus.git \
  6_yrv_plus

rm -rf */.git

pushd 5_yrv_plus
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
