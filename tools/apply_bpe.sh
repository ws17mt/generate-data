#!/bin/sh

# apply a BPE model to a given dataset
# usage: ./apply_bpe.sh bpe_model infile outfile

# get and check input vars
if test "$#" -ne 3; then
 echo "Usage: ./apply_bpe.sh bpe_model infile outfile"
 exit -1
fi

scripts=tools

bpe_model=$1
infile=$2
outfile=$3

$scripts/apply_bpe.py -c $bpe_model <$infile >$outfile
