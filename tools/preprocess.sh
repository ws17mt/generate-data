#!/bin/sh

# preprocess a parallel data set

# usage: ./preprocess.sh infile_prefix outfile_prefix src trg tc_model_prefix

# get and check input vars
if test "$#" -ne 5; then
 echo "Usage: ./preprocess.sh infile_prefix outfile_prefix src trg tc_model_prefix"
 exit -1
fi

moses=tools/

in_prefix=$1
out_prefix=$2
src=$3
trg=$4
tc_prefix=$5

# tokenize
$moses/tokenizer.perl -a -l $src -threads 12 <$in_prefix.$src >$out_prefix.tok.$src
$moses/tokenizer.perl -a -l $trg -threads 12 <$in_prefix.$trg >$out_prefix.tok.$trg

# clean corpus (remove empty / long sentences)
$moses/clean-corpus-n.perl $out_prefix.tok $src $trg $out_prefix.clean 1 80

# truecase
$moses/truecase.perl -model $tc_prefix.$src <$out_prefix.clean.$src >$out_prefix.tc.$src
$moses/truecase.perl -model $tc_prefix.$trg <$out_prefix.clean.$trg >$out_prefix.tc.$trg
