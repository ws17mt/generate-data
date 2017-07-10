#!/bin/sh

# script to preprocess parallel training and dev data
# note that the monolingual training data is preprocessed separately
# for training and dev, tokenize, truecase, and apply BPE
# for training only, strip empty and long sentences

# relevant directories
scripts=tools
indata=/pylon2/ci560op/gkumar6/code/generate-data/data/fr_train
indev=/pylon2/ci560op/gkumar6/code/generate-data/data/fr_dev
outdata=/pylon2/ci560op/fosterg/data/fr/processed

# models
bpe_model=/pylon2/ci560op/gkumar6/code/generate-data/model/fr/enfr.30000.bpe
tc_model=/pylon2/ci560op/gkumar6/code/generate-data/model/fr/truecase-model

# vars
src=en
trg=fr

# for each data set size (10k, 100k, 1m, 2.2m, full)
for size in 10k 100k 1m 2m full
 do 
  # preprocess
  echo "Preprocessing $size data"
  $scripts/preprocess.sh $indata/train.$size $outdata/train.$size $src $trg $tc_model
  # apply BPE
  echo "Applying BPE (mono 30k)"
  $scripts/apply_bpe.sh $bpe_model $outdata/train.$size.tc.$src $outdata/train.$size.bpe.$src
  $scripts/apply_bpe.sh $bpe_model $outdata/train.$size.tc.$trg $outdata/train.$size.bpe.$trg
 done

# for each of dev1, dev2, and test1
for prefix in dev1 dev2 test1
 do 
  # preprocess (note can't use preprocessing script because we don't want to cut long sentences)
  echo "tokenizing $prefix"
  $scripts/tokenizer.perl -a -l $src -threads 12 <$indev/$prefix.$src >$outdata/$prefix.tok.$src
  $scripts/tokenizer.perl -a -l $trg -threads 12 <$indev/$prefix.$trg >$outdata/$prefix.tok.$trg
  echo "truecasing $prefix"
  $scripts/truecase.perl -model $tc_model.$src <$outdata/$prefix.tok.$src >$outdata/$prefix.tc.$src
  $scripts/truecase.perl -model $tc_model.$trg <$outdata/$prefix.tok.$trg >$outdata/$prefix.tc.$trg
  # apply BPE
  echo "applying BPE (mono 30k) to $prefix"
  $scripts/apply_bpe.sh $bpe_model $outdata/$prefix.tc.$src $outdata/$prefix.bpe.$src
  $scripts/apply_bpe.sh $bpe_model $outdata/$prefix.tc.$trg $outdata/$prefix.bpe.$trg
 done
