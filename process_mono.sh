#!/usr/bin/env bash
# This script processes the raw monolingual datasets for WMT fr and en.
# We use this learn truecasing and BPE models that can applied to 
# parallel dataset of varying sizes.
# The BPE model is learnt jointly with with two mono corpora
# NOTE: Clean corpus (max-length) is not applied to mono datasets.

RAW_DATA_DIR=/pylon2/ci560op/fosterg/data/fr/raw-data
PROC_DATA_DIR=data/fr
TOOLS_DIR=tools
MODEL_DIR=model/fr

##############################################
# Max BPE splits
BPE_OPERATIONS=89500
# The monolingual datasets
MONO="news.2007-13"
THREADS_PER_L=12

##############################################

mkdir -p ${PROC_DATA_DIR}
mkdir -p ${MODEL_DIR}

##############################################

for l in fr en; do
  (
  # Tokenize
  echo "*** Tokenizing mono.${l}"
  ${TOOLS_DIR}/tokenizer.perl -a -l $l -threads ${THREADS_PER_L}\
    < ${RAW_DATA_DIR}/${MONO}.${l} \
    > ${PROC_DATA_DIR}/mono.tok.${l}

  echo "*** Learning truecasing model for mono.${l}"
  # Truecaser (train)
  ${TOOLS_DIR}/train-truecaser.perl \
    -corpus ${PROC_DATA_DIR}/mono.tok.${l} \
    -model ${MODEL_DIR}/truecase-model.${l}

  echo "*** Applying truecasing model to mono.${l}"
  # Truecaser (apply)
  ${TOOLS_DIR}/truecase.perl \
    -model ${MODEL_DIR}/truecase-model.${l} \
    < ${PROC_DATA_DIR}/mono.tok.${l} \
    > ${PROC_DATA_DIR}/mono.tc.${l}
  )&
done

wait;

echo "*** Learning BPE model"
# BPE (train)
cat ${PROC_DATA_DIR}/mono.tc.fr ${PROC_DATA_DIR}/mono.tc.en \
  | ${TOOLS_DIR}/learn_bpe.py -s ${BPE_OPERATIONS} > ${MODEL_DIR}/fren.bpe

for l in fr en; do
  echo "*** Applying BPE to mono.${l}"
  # BPE (apply)
  ${TOOLS_DIR}/apply_bpe.py -c ${MODEL_DIR}/fren.bpe \
    < ${PROC_DATA_DIR}/mono.tc.${l} \
    > ${PROC_DATA_DIR}/mono.bpe.${l}
done
