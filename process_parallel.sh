#!/usr/bin/env bash

# Applies tokenization, cleaning, truecasing and BPE to a parallel corpus

#####################################################################
# Utility functions
#####################################################################

function errcho() {
  >&2 echo $1
}

function check_file_exists() {
  if [ ! -f $1 ]; then
    clean_exit "FATAL: Could not find $1"
  fi
}

function show_help() {
  errcho "Pre-processes a parallel corpus"
  errcho "usage: sh process_parallel.sh [-h] -c CORPUS -s SOURCE_EXT -t TARGET_EXT -b BPE_MODEL -m TC_MODEL -o OUTPUT_DIR"
}

#####################################################################
# User supplied args
#####################################################################

THREADS_PER_L=12

while getopts ":h?s:t:b:c:o:" opt; do
  case "$opt" in
  h|\?)
    show_help
    exit 0
    ;;
  c)  CORPUS=$OPTARG
    ;;
  s)  SOURCE_EXT=$OPTARG
    ;;
  t)  TARGET_EXT=$OPTARG
    ;;
  b)  BPE_MODEL=$OPTARG
    ;;
  m)  TC_MODEL=$OPTARG
    ;;
  o)  OUTPUT_DIR=$OPTARG
    ;;
  esac
done

if [ -z $CORPUS ] || [ -z $SOURCE_EXT ] || [ -z $TARGET_EXT ] || [ -z $BPE_MODEL ] || [ -z $TC_MODEL ]; then
  errcho "Missing arguments"
  show_help
  exit 1
fi

check_file_exists ${CORPUS}.${SOURCE_EXT}
check_file_exists ${CORPUS}.${TARGET_EXT}
check_file_exists $BPE_MODEL
check_file_exists $TC_MODEL.${SOURCE_EXT}
check_file_exists $TC_MODEL.${TARGET_EXT}

TOOLS_DIR=tools
CORPUS_NAME=`basename $CORPUS`

##############################################

mkdir -p ${PROC_DATA_DIR}
mkdir -p ${MODEL_DIR}
mkdir -p ${OUTPUT_DIR}

##############################################

for l in $SOURCE_EXT $TARGET_EXT; do
  (
  # Tokenize
  echo "*** Tokenizing corpus.${l}"
  ${TOOLS_DIR}/tokenizer.perl -a -l $l -threads ${THREADS_PER_L}\
    < ${CORPUS}.${l} \
    > ${OUTPUT_DIR}/${CORPUS_NAME}.tok.${l} #TODO:Corpus name missing
  )&
done

wait;

# Clean
echo "*** Cleaning corpus.${l}"
${TOOLS_DIR}/clean-corpus-n.perl ${OUTPUT_DIR}/${CORPUS_NAME}.tok \
  ${SOURCE_EXT} ${TARGET_EXT} ${OUTPUT_DIR}/${CORPUS_NAME}.clean 1 80

for l in $SOURCE_EXT $TARGET_EXT; do
  (
  # Truecaser (apply)
  echo "*** Applying truecasing model to corpus.${l}"
  ${TOOLS_DIR}/truecase.perl \
    -model ${TC_MODEL}.${l} \
    < ${OUTPUT_DIR}/${CORPUS_NAME}.clean.${l} \
    > ${PROC_DATA_DIR}/${CORPUS_NAME}.tc.${l}

  # BPE (apply)
  echo "*** Applying BPE to mono.${l}"
  ${TOOLS_DIR}/apply_bpe.py -c ${BPE_MODEL} \
    < ${OUTPUT_DIR}/${CORPUS_NAME}.tc.${l} \
    > ${OUTPUT_DIR}/${CORPUS_NAME}.bpe.${l}
  )&
done

wait;
