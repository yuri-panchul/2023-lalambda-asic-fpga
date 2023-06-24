#!/usr/bin/env tclsh

proc my_info {args} {
    set script [file tail $::argv0]
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
      \n
      \nYou can also see the file list by running: \
      \n    git clean -d -n \"$dir\" \
      \nAfter reviewing (be careful!), \
      \nyou can remove them by running: \
      \n    git clean -d -f \"$dir\" \
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

  foreach project {
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
  } {
    set project_path [file join $parent_path $project]

    if {[file isdirectory $project_path]} {
      cd $project_path
      check_git_status $project_path
    }
  }
}
