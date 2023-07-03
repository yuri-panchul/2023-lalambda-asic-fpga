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

  set ret [exec git diff --name-status --diff-filter=R HEAD]

  if {$ret ne ""} {
    my_error \n$ret \
      \nThere are renamed files in the tree. \
      \nYou should check them in before preparing a release package.
  }

  set ret [exec git ls-files --others --exclude-standard]

  if {$ret ne ""} {
    my_error \n$ret \
      \nThere are untracked files in the tree. \
      \nYou should either remove or check them in \
      before preparing a release package. \
      \n \
      \nYou can also see the file list by running: \
      \n\n "   " (cd \"$dir\" \; git clean -d -n) \
      \n\nAfter reviewing (be careful!), \
      you can remove them by running: \
      \n\n "   " (cd \"$dir\" \; git clean -d -f) \
      \n\nNote that \"git clean\" without \"-x\" option \
      does not see the files from the .gitignore list.
  }

  set ret [exec git ls-files --others]

  if {$ret ne ""} {
    my_error \n$ret \
      \nThere are files in the tree, ignored by git, \
      based on .gitignore list. \
      \nThis repository is not supposed to have the ignored files. \
      \nYou need to remove them before preparing a release package. \
      \nYou can also see the file list by running: \
      \n\n "   " (cd \"$dir\" \; git clean -d -x -n) \
      \n\nAfter reviewing (be careful!), \
      you can remove them by running: \
      \n\n "   " (cd \"$dir\" \; git clean -d -x -f) \
  }

  set ret [exec git ls-files --modified]

  if {$ret ne ""} {
    my_error \n$ret \
      \nThere are modified files in the tree. \
      \nYou should check them in before preparing a release package.
  }

  set ret [exec git cherry -v]

  if {$ret ne ""} {
    my_error \n$ret \
      \n\nThere are commits which are not pushed (checked using \"git cherry\").
      \nYou should run \"git push\" before preparing a release package.
  }

  set ret [exec git log --branches --not --remotes]
  
  if {$ret ne ""} {
    my_error \n$ret \
      \n\nThere are commits which are not pushed (checked using \"git log\").
      \nYou should run \"git push\" before preparing a release package.
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
    basics-graphics-music
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

    if {[catch { exec git pull } ret]} {
      my_error "$repo_path: $ret"
    } else {
      my_info "$repo_path: $ret"
    }
  }
} elseif {$argc != 0} {
  my_info "Usage: $script \[-pull\]"
}
