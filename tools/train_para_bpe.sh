#!/bin/sh

# train BPE model from parallel data with a given vocab size
# usage: ./train_para_bpe.sh src_data tgt_data num_operations outfile

# get and check input vars
if test "$#" -ne 4; then
 echo "Usage: ./train_para_bpe.sh src_data tgt_data num_operations outfile"
 exit -1
fi

scripts=./

src_file=$1
trg_file=$2
BPE_OPS=$3
model=$4

cat $src_file $trg_file | $scripts/learn_bpe.py -s $BPE_OPS >$model
