#!/bin/sh

# script to apply BPE to a given file
# applies the "official" EN-FR BPE models that we have already trained
# usage: ./bpe_only.sh infile

# read in infile
if test "$#" -ne 1; then
 echo "Usage: ./bpe_only.sh infile"
 exit -1
fi

infile=$1

# relevant directories
scripts=../tools

# models
bpe_model=/pylon2/ci560op/gkumar6/code/generate-data/model/fr/fren.30000.bpe

# vars
src=en
trg=fr

# apply BPE to the infile
echo "Applying BPE to $infile"
$scripts/apply_bpe.py -c $bpe_model <$infile >$infile.bpe
