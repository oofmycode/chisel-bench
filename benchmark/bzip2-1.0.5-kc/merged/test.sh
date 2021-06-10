#!/bin/bash

export BENCHMARK_NAME=bzip2-1.0.5
export BIN_NAME=bzip2-1.0.5-kc
export BENCHMARK_DIR=$CHISEL_BENCHMARK_HOME/benchmark/$BIN_NAME/merged
export SRC=$BENCHMARK_DIR/$BENCHMARK_NAME.c
export ORIGIN_BIN=$BENCHMARK_DIR/$BENCHMARK_NAME.origin
export REDUCED_BIN=$BENCHMARK_DIR/$BENCHMARK_NAME.reduced
export TIMEOUT="-k 1 1"
export LOG=$BENCHMARK_DIR/log.txt

source $CHISEL_BENCHMARK_HOME/benchmark/test-base.sh

function clean() {
  rm -rf -- *.bz2
  rm -rf $LOG $REDUCED_BIN *.bz2 *.rb2 *.tst log foo* bar* *.tmp testout.rb2
  rm -f \(*\)
  return 0
}
function run() {
  { timeout $TIMEOUT $REDUCED_BIN $1 <$2 >testout.tmp; } &>$LOG || exit 1
   bzip2 $1 <$2 > testout1.tmp  
   cmp testout1.tmp testout.tmp >&/dev/null || exit 1
   rm -rf *.tmp
    return 0
}
function desired() {
  # -kc
  for file in $(ls test/*) ; do	  
    run "-kc" $file || exit 1
done
return 0
}

function default_disaster_mem() {
  # -kc
  { timeout $TIMEOUT $REDUCED_BIN -kc <references/sample1.ref >testout.rb2; } &>$LOG
  grep -q -E "$1" $LOG || exit 1
return 0
}

function default_disaster_file() {
  # -kc
  { timeout $TIMEOUT $REDUCED_BIN -kc <references/sample1.ref >testout.rb2; } &>$LOG
  grep -q -E "$1" $LOG || exit 1
  return 0
}

OPT1=("-h")
OPT2=("-z" "-q" "-v" "-s" "-1" "-2" "-3" "-4" "-5" "-6" "-7" "-8" "-9")
OPT3=("-L" "-V")
function undesired() {
  { timeout $TIMEOUT $REDUCED_BIN $(cat crash_input); } &>$LOG
  crash $? && exit 1
  { timeout $TIMEOUT $REDUCED_BIN; } 2>$LOG
  crash $? && exit 1

  # keeping the output in the following cases:

  { timeout $TIMEOUT $REDUCED_BIN notexist; } 2>$LOG
  crash $? && exit 1
  diff -q references/side0 $LOG >&/dev/null || exit 1
  rm -rf log

  for opt in ${OPT1[@]}; do
    { timeout $TIMEOUT $REDUCED_BIN $opt; } 2>$LOG
    crash $? && exit 1
    diff -q references/side1 $LOG >&/dev/null || exit 1
    rm -rf log*
  done

  for opt in ${OPT2[@]}; do
    { timeout $TIMEOUT $REDUCED_BIN $opt; } 2>$LOG
    crash $? && exit 1
    diff -q references/side2 $LOG >&/dev/null || exit 1
    rm -rf log*
  done

  for opt in ${OPT3[@]}; do
    { timeout $TIMEOUT $REDUCED_BIN $opt; } 2>$LOG
    crash $? && exit 1
    diff -q references/side3 $LOG >&/dev/null || exit 1
    rm -rf log*
  done

  echo "1234" >foo
  $REDUCED_BIN -kc <foo >foo.bz2 || exit 1
  for opt in ${OPT2[@]}; do
        { timeout $TIMEOUT $REDUCED_BIN -kc $opt <references/sample1.ref >testout.rb2; } 2>$LOG
    crash $? && exit 1
  done

  return 0
}

function desired_disaster() {
  case $1 in
  memory)
    MESSAGE="couldn't allocate enough memory"
    default_disaster_mem "$MESSAGE" || exit 1
    ;;
  file)
    MESSAGE="Bad file descriptor"
    default_disaster_file "$MESSAGE" || exit 1
    ;;
  *)
    return 1
    ;;
  esac
  return 0
}

main
