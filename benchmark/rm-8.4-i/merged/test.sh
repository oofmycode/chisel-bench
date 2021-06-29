#!/bin/bash

export BENCHMARK_NAME=rm-8.4
export BIN_NAME=rm-8.4-i
export BENCHMARK_DIR=$CHISEL_BENCHMARK_HOME/benchmark/$BIN_NAME/merged
export SRC=$BENCHMARK_DIR/$BENCHMARK_NAME.c
export ORIGIN_BIN=$BENCHMARK_DIR/$BENCHMARK_NAME.origin
export REDUCED_BIN=$BENCHMARK_DIR/$BIN_NAME.reduced
export TIMEOUT="-k 0.5 0.5"
export LOG=$BENCHMARK_DIR/log.txt

source $CHISEL_BENCHMARK_HOME/benchmark/test-base.sh

function clean() {
  rm -rf $LOG $REDUCED_BIN dir file*
  chmod -Rf 755 cu-*
  /bin/rm -rf cu-*
  return 0
}

function run1() {
  touch filei
  { timeout $TIMEOUT echo "Y" | timeout $TIMEOUT $REDUCED_BIN -i filei; } >&$LOG
  r=$?
  if [[ $r -eq 0 && ! -f filei ]]; then
    ran=0
  else
    clean
    return 1
  fi

  grep -E error $LOG
  if [[ $? -eq 0 ]]; then
    return 1
  fi
  touch filei
  { timeout $TIMEOUT echo "N" | timeout $TIMEOUT $REDUCED_BIN -i filei; } >&$LOG
  r=$?
  if [[ $r -eq 0 && -f filei ]]; then
    ran=0
  else
    clean
    return 1
  fi
  grep -E error $LOG
  if [[ $? -eq 0 ]]; then
    return 1
  fi
  grep -E error $LOG
  if [[ $? -eq 0 ]]; then
    return 1
  fi
  touch filei
  echo 123 > filei
  { timeout $TIMEOUT echo "Y" | timeout $TIMEOUT $REDUCED_BIN -i filei; } >&$LOG
  r=$?
  if [[ $r -eq 0 && ! -f filei ]]; then
    ran=0
  else
    clean
    return 1
  fi
  grep -E error $LOG
  if [[ $? -eq 0 ]]; then
    return 1
  fi
  touch filei
  echo 123 > filei
  { timeout $TIMEOUT echo "N" | timeout $TIMEOUT $REDUCED_BIN -i filei; } >&$LOG
  r=$?
  if [[ $r -eq 0 && -f filei ]]; then
    return 0
  else
    clean
    return 1
  fi

  rm filei
}

function run1_disaster() {
  touch filei
  { timeout $TIMEOUT echo "Y" | timeout $TIMEOUT $REDUCED_BIN -i filei; } >&$LOG
  cat $LOG | grep -q -E $1 || exit 1

  touch filei
  { timeout $TIMEOUT echo "N" | timeout $TIMEOUT $REDUCED_BIN -i filei; } >&$LOG
  cat $LOG | grep -q -E $1 || exit 1

  return 0
}

# Desired Options: -r, -f, -i
function desired() {
  run1 || exit 1
  rm -rf file dir
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
  rm -rf file dir
  run1_disaster $1 "$MESSAGE" || exit 1
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
