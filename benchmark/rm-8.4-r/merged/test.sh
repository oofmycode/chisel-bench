#!/bin/bash

export BENCHMARK_NAME=rm-8.4
export BIN_NAME=rm-8.4-r
export BENCHMARK_DIR=$CHISEL_BENCHMARK_HOME/benchmark/$BIN_NAME/merged
export SRC=$BENCHMARK_DIR/$BENCHMARK_NAME.c
export ORIGIN_BIN=$BENCHMARK_DIR/$BENCHMARK_NAME.origin
export REDUCED_BIN=$BENCHMARK_DIR/$BIN_NAME.reduced
export TIMEOUT="-k 0.5 0.5"
export LOG=$BENCHMARK_DIR/log.txt

source $CHISEL_BENCHMARK_HOME/benchmark/test-base.sh

function clean() {
  rm -rf $LOG $REDUCED_BIN dir file
  chmod -Rf 755 cu-*
  rm -rf cu-*
  return 0
}

function run() {
  mkdir dir
  { timeout $TIMEOUT $REDUCED_BIN -r dir; } >&$LOG
  
 r=$?
 a=1
 b=1

 if [[ $r -eq 0 && ! -d dir ]]; then
    a=0
  fi
grep -E error $LOG

 if [[ $? -eq 0 ]]; then
    a=1
  fi


rm -rf dir 
mkdir dir 
mkdir -p dir/dir/dir/dir/dir/dir/dir/dir/dir/dir
touch file1 file2 dir/1 dir/2

  { timeout $TIMEOUT $REDUCED_BIN -r dir file1 file2 ; } >&$LOG
  r=$?
  if [[ $r -eq 0 && ! -d dir && ! -e file1 && ! -e file2 ]]; then
    b=0
  fi
  rm -rf dir file1 file2

   if [[ $a -eq 0 && $b -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

function run_disaster() {
  mkdir dir
  { timeout $TIMEOUT $REDUCED_BIN -r dir; } >&$LOG
  rm -rf dir
  cat $LOG | grep -q -E $1 || exit 1

  return 0
}


# Desired Options: -r
function desired() {
  run || exit 1
}

function desired_disaster() {
  case $1 in
  memory)
    MESSAGE="memory exhausted"
    ;;
  file)
    MESSAGE="write error"
    ;;
  *)
    return 1
    ;;
  esac
  run_disaster $1 "$MESSAGE" || exit 1
  rm -rf file dir
}

function outputcheckerror() {
  r="$1"
  if grep -q -E "$r" $LOG; then
    return 1
  fi
  return 0
}

function undesired() {
  export srcdir=$CHISEL_BENCHMARK_HOME/benchmark/
  export PATH="$(pwd):$PATH"
  { timeout $TIMEOUT $REDUCED_BIN; } >&$LOG
  err=$?
  outputcheckerror "missing operand" && exit 1
  crash $err && exit 1
  return 0
}

main
