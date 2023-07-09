#!/usr/bin/env bash

set -Eeuo pipefail  # See the meaning in scripts/README.md
# set -x  # Print each command

#-----------------------------------------------------------------------------

script_path="$0"
script=$(basename "$script_path")

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

is_command_available_or_error ()
{
    command -v $1 &> /dev/null || \
        error "program $1$ is not in the path or cannot be run"
}

#-----------------------------------------------------------------------------

drive_image=230610_slinux.img

[ -f "$drive_image" ] || error "Expecting file \"$drive_image\" in the current directory"

#-----------------------------------------------------------------------------

avail_drives=$(ls /dev/sd[a-z])

info "Please select an SSD you want to ovewrite"
PS3="Your choice (a number): "

select drive in $avail_drives exit
do
    if [ -z "${drive-}" ] ; then
        info "Invalid SSD choice, please choose one of the listed numbers again"
        continue
    fi

    if [ $drive == "exit" ] ; then
        info "SSD is not selected, please run the script again"
        exit 0
    fi

    info "SSD selected: $drive"
    break
done

#-----------------------------------------------------------------------------

mounted=$(grep -o "^$drive" /proc/mounts || true)

[ -z "$mounted" ] \
    || error "$drive is mounted. Please unmount and rerun the script."

#-----------------------------------------------------------------------------

is_command_available_or_error partprobe

info "Checking partitions before the operations:"

sudo partprobe -d -s $drive || true

#-----------------------------------------------------------------------------

seek_value=$((($(sudo blockdev --getsize64 $drive)-4096)/4096))

info "Seek value to erase the second GPT: $seek_value"

#-----------------------------------------------------------------------------

# read:
#
# -p prompt output the string PROMPT without a trailing newline before
#           attempting to read
#
# -r        do not allow backslashes to escape any characters
# -s        do not echo input coming from a terminal

info "\nAre you absolutely positively sure"                           \
     "\nyou want to erase your SSD,"                                  \
     "\ndestroy all its partition tables"                             \
     "\nand write a new drive image from the file \"$drive_image\"?"  \

read -r -p "Type \"I SWEAR!\" : "

if [ "$REPLY" != "I SWEAR!" ] ; then
    info "You typed \"$REPLY\". Exiting."
    exit 0
fi

#-----------------------------------------------------------------------------

cmd="sudo dd if=/dev/zero of=$drive bs=4096 seek=$seek_value"
info "Erasing the backup GPT. If you see an error it is normal: $cmd"
$cmd || true

cmd="sudo dd if=/dev/zero of=$drive bs=4096 seek=0 count=1"
info "Erasing the primary GPT: $cmd"
$cmd || true

info "Now all the partition tables should be erased:"
sudo partprobe -d -s $drive || true

info "Finally, the main copying:"

sudo dd if="$drive_image" of=$drive bs=1M status=progress && sync \
    || error "Something is wrong"

info "Success, $drive_image is on $drive"
exit 0
