#!/bin/bash

# Author: Daniel Beck
# This generates all data we need for English-Farsi.
# It assumes the existence of the corpora mentioned in the README.
# Set up their respective paths below.
# Since some of the steps can take sometime (especially BPE), this script assumes
# explicit arguments, so the person running this knows exactly
# what preprocessing needs to be done.
# Important: the monolingual English corpus is assumed to be tokenised
# and truecased (it saves us time).

export EN_FA_DIR=/pylon2/ci560op/fosterg/data/fa

export LDC_NEWS_EN=$EN_FA_DIR/parallel/ldc/en/ldc-news-eng.txt
export LDC_FOUND_EN=$EN_FA_DIR/parallel/ldc/en/ldc-found-eng.txt
export TED_EN=$EN_FA_DIR/parallel/ted/en/ted2013.en-fa.txt
export MONO_EN=/pylon2/ci560op/gkumar6/code/generate-data/data/fr/mono.tc.en

export LDC_NEWS_FA=$EN_FA_DIR/parallel/ldc/fa/ldc-news-fas.txt
export LDC_FOUND_FA=$EN_FA_DIR/parallel/ldc/fa/ldc-found-fas.txt
export TED_FA=$EN_FA_DIR/parallel/ted/fa/ted2013.en-fa.txt
export MONO_FA=$EN_FA_DIR/monolingual/hamshahri1/hamshahri1.txt

export OUTPUT_DIR=$EN_FA_DIR/processed
export TMP_DIR=$EN_FA_DIR/tmp
mkdir -p $OUTPUT_DIR
mkdir -p $TMP_DIR


# We also have to inform the place for preprocessing scripts and other vars
export SCRIPTS_DIR=/pylon2/ci560op/acurrey/data/scripts
export APPLY_BPE=/pylon2/ci560op/fosterg/bin/apply_bpe.py
export BPE_OPS=30000
export EN_TC_MODEL=/pylon2/ci560op/gkumar6/code/generate-data/model/fr
export SEED=$LDC_NEWS_EN

if [ "$#" -ne 6 ]; then
    echo "Usage: this script requires 6 arguments: "
    echo " one per each preprocessing step."
    echo " 1) Preprocess monolingual English and train the BPE model."
    echo " 2) Apply BPE to monolingual English."
    echo " 3) Preprocess monolingual Farsi and train the BPE model."
    echo " 4) Apply BPE to monolingual Farsi."
    echo " 5) Generate parallel data splits."
    echo " 6) Preprocess parallel splits."
    echo ""
    echo "For each step, there is a corresponding positional argument."
    echo "Just use 'y' if you want to perform that step or 'n' to skip it."
    echo ""
    echo "For instance, to perform every step, just use:"
    echo "./generate_all.sh y y y y y y"
    echo ""
    echo "To process only the parallel data:"
    echo "./generate_all.sh n n n n y y"
    echo ""
    echo "To process only Farsi data (including parallel):"
    echo "./generate_all.sh n n y y y y"
    echo "This one is useful because preprocessing the monolingual"
    echo "English data can take a lot of time."
    echo ""
    echo "Bear in mind that if you skip some steps, the script"
    echo "will assume you have the previous steps outputs in"
    echo "their respectve folders above."
    exit
fi


#############################################
# 1) Preprocess the monolingual English data
# This includes training the BPE model

if [ "$1" == "y" ]; then
    echo "TODO: add tokenization and truecasing model training."
    echo "We are currently using a previously trained truecased model"
    echo "from the en-fr dataset, using the same corpus."

    echo "Training BPE on English mono"
    cat $MONO_EN | $SCRIPTS_DIR/learn_bpe.py -s $BPE_OPS > $OUTPUT_DIR/en.bpe.model
fi

#############################################
# 2) Apply BPE to the monolingual English data

if [ "$2" == "y" ]; then
    echo "Applying BPE to the mono English data"
    $APPLY_BPE -c $OUTPUT_DIR/en.bpe.model < $MONO_EN > $OUTPUT_DIR/mono.bpe.en
fi

#############################################
# 3) Preprocess the monolingual Farsi data
# This includes training the BPE model

if [ "$3" == "y" ]; then
    echo "Tokenizing and standardizing the mono Farsi corpus"
    python fa_preprocessing.py $MONO_FA > $TMP_DIR/hamshahri.txt.tok

    echo "Training BPE on Farsi mono"
    cat $TMP_DIR/hamshahri.txt.tok | $SCRIPTS_DIR/learn_bpe.py -s $BPE_OPS > $OUTPUT_DIR/fa.bpe.model
fi

#############################################
# 4) Apply BPE to the monolingual Farsi data

if [ "$4" == "y" ]; then
    echo "Applying BPE to the mono Farsi data"
    $APPLY_BPE -c $OUTPUT_DIR/fa.bpe.model < $TMP_DIR/hamshahri.txt.tok > $OUTPUT_DIR/mono.bpe.fa
fi

#############################################
# 5) Generate the splits from the parallel data

if [ "$5" == "y" ]; then
    ./split_parallel.sh
fi

#############################################
# 6) Preprocess the splits, including tokenization,
# English truecasing, Farsi normalization and BPE

if [ "$6" == "y" ]; then
    ./preprocess_parallel.sh
fi
