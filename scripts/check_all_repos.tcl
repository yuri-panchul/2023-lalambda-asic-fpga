#!/usr/bin/env tclsh

set script [file tail $::argv0]

proc my_info {args} {
    global script
    puts stderr "\n$script: [join $args " "]"
}

proc my_error {args} {
    my_info "ERROR:" [join $args " "]
    exit 1
}

proc check_git_status {dir} {
  cd $dir
  if {! [file isdirectory ".git"]} { return }
  my_info $dir

  set files [exec git diff --name-status --diff-filter=R HEAD]

  if {$files ne ""} {
    my_error \n$files \
      \nThere are renamed files in the tree. \
      \nYou should check them in before preparing a release package.
  }

  set files [exec git ls-files --others --exclude-standard]

  if {$files ne ""} {
    my_error \n$files \
      \nThere are untracked files in the tree. \
      \nYou should either remove or check them in \
      before preparing a release package. \
      \n \
      \nYou can also see the file list by running: \
      \n\n "   " git clean -d -n \"$dir\" \
      \n\nAfter reviewing (be careful!), \
      you can remove them by running: \
      \n\n "   " git clean -d -f \"$dir\" \
      \n\nNote that \"git clean\" does not see \
      the files from the .gitignore list.
  }

  set files [exec git ls-files --others]

  if {$files ne ""} {
    my_error \n$files \
      \nThere are files in the tree, ignored by git, \
      based on .gitignore list. \
      \nThis repository is not supposed to have the ignored files. \
      \nYou need to remove them before preparing a release package.
  }

  set files [exec git ls-files --modified]

  if {$files ne ""} {
    my_error \n$files \
      \nThere are modified files in the tree. \
      \nYou should check them in before preparing a release package.
  }
}

foreach parent_dir {"" gitflic gitee github gitlab projects} {
  set parent_path [file join $env(HOME) $parent_dir]
  if {! [file isdirectory $parent_path]} { continue }
  cd $parent_path

  set repos {
    2022-bishkek
    2023-lalambda-asic-fpga
    basics-music-graphics
    fpga-soldering-camp
    schoolRISCV
    systemverilog-homework-private
    valid-ready-etc
    valid-ready-etc-private
    yrv-plus
    yuri-panchul
  }

  set repo_paths {}

  foreach repo $repos {
    set repo_path [file join $parent_path $repo]

    if {[file isdirectory $repo_path]} {
      lappend repo_paths $repo_path
    }
  }
}

foreach repo_path $repo_paths {
  check_git_status $repo_path
}

if {$argc == 1 && [lindex $argv 0] == "-pull"} {
  foreach repo_path $repo_paths {
    cd $repo_path
    puts "before"
    exec git pull
    puts "after"
  }
} elseif {$argc != 0} {
  my_info "Usage: $script \[-pull\]"
}
