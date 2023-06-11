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

    read -n 1 -r -p "About the remove the files and directories above. Are you sure? "
    [[ $ REPLY =~ ^[Yy]$ ]] || error "Exiting"
else
    info "Not running inside Git repository"
fi

if [ -d .git ] ; then
    info "Running inside Git repository"
else
    info "Running outinside Git repository, not all changes might be reverted"
fi

exit 0


rm    -rf public_repository
mkdir -p  public_repository
cd        public_repository

cp -r ../misc ../LICENSE ../README.md .

git clone https://gitflic.ru/project/yuri-panchul/fpga-soldering-camp.git \
  1_fpga_soldering_camp

git clone https://github.com/yuri-panchul/schoolRISCV.git \
  3_school_risc_v

git clone https://gitflic.ru/project/yuri-panchul/valid-ready-etc.git \
  4_valid-ready-etc

git clone https://github.com/yuri-panchul/yrv-plus.git \
  5_yrv_plus

rm -rf */.git

pushd 5_yrv_plus
rm -rf Lattice Xilinx
pushd Plus
mv * .gitignore ..
popd
rm -rf Plus
popd

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

rm -rf ${pkg_src_root_name}_*.zip

cd "$tgt_pkg_dir"

zip -r "$run_dir/$package_script_oriented.zip" "$package_script_oriented"
zip -r "$run_dir/$package_gui_oriented.zip"    "$package_gui_oriented"
