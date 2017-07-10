#!/bin/sh

# prepare dev and test datasets for the BPE experiments
# Usage: ./dev_test_preprocess.sh

# relevant directories
in_dir=/pylon2/ci560op/gkumar6/code/generate-data/data/fr_dev
out_dir=/pylon2/ci560op/acurrey/data/processed
scripts=tools
#moses=$scripts/mosesdecoder
tc_model=/pylon2/ci560op/gkumar6/code/generate-data/model/fr/truecase-model
para_model=/pylon2/ci560op/acurrey/data/model
mono_model=/pylon2/ci560op/gkumar6/code/generate-data/model/fr/

# vars
src=fr
trg=en

# for each of dev1, dev2, test1
for prefix in dev1 dev2 test1
 do
  # tokenize
  echo "Tokenizing $prefix"
  $scripts/tokenizer.perl -a -l $src -threads 12 <$in_dir/$prefix.$src >$out_dir/$prefix.tok.$src
  $scripts/tokenizer.perl -a -l $trg -threads 12 <$in_dir/$prefix.$trg >$out_dir/$prefix.tok.$trg
  # truecase
  echo "Truecasing $prefix"
  $scripts/truecase.perl -model $tc_model.$src <$out_dir/$prefix.tok.$src >$out_dir/$prefix.tc.$src
  $scripts/truecase.perl -model $tc_model.$trg <$out_dir/$prefix.tok.$trg >$out_dir/$prefix.tc.$trg
 done

# now apply BPE to dev1 and dev2 only (won't use test1 for these experiments for now
# note we need a different one for each experiment
for prefix in dev1 dev2
 do
  for size in 10k 100k 1m
   do
    for bpe_ops in 30000 60000 90000
     do
      $scripts/apply_bpe.sh $para_model/$src$trg.para_bpe.$size.$bpe_ops.bpe $out_dir/$prefix.tc.$src $out_dir/$prefix.$size.para_bpe.$bpe_ops.$src
      $scripts/apply_bpe.sh $para_model/$src$trg.para_bpe.$size.$bpe_ops.bpe $out_dir/$prefix.tc.$trg $out_dir/$prefix.$size.para_bpe.$bpe_ops.$trg
      $scripts/apply_bpe.sh $mono_model/$src$trg.$bpe_ops.bpe $out_dir/$prefix.tc.$src $out_dir/$prefix.$size.mono_bpe.$bpe_ops.$src
      $scripts/apply_bpe.sh $mono_model/$src$trg.$bpe_ops.bpe $out_dir/$prefix.tc.$trg $out_dir/$prefix.$size.mono_bpe.$bpe_ops.$trg
     done
   done
 done
