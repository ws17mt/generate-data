#!/bin/sh

# relevant directories
scripts=tools/
indata=/pylon2/ci560op/gkumar6/code/generate-data/data/fr_train
outdata=/pylon2/ci560op/acurrey/data/processed
para_model=/pylon2/ci560op/acurrey/data/model
mono_model=/pylon2/ci560op/gkumar6/code/generate-data/model/fr/
tc_model_prefix=/pylon2/ci560op/gkumar6/code/generate-data/model/fr/truecase-model

# vars
src=fr
trg=en

# for each data set (10k, 100k, 1m)
for size in 10k 100k 1m
 do
  echo "Processing $size dataset"
  # preprocess
  echo "Preprocessing..."
  $scripts/preprocess.sh $indata/train.$size $outdata/train.$size $src $trg $tc_model_prefix
  # for each vocabulary size
  for vocab in 30000 60000 90000
   do
    echo "Learning $vocab BPE"
    # learn BPE from parallel data with the vocab size
    $scripts/train_para_bpe.sh $outdata/train.$size.tc.$src $outdata/train.$size.tc.$trg $vocab $para_model/$src$trg.para_bpe.$size.$vocab.bpe
    echo "Applying $vocab parallel BPE"
    # apply BPE from parallel data with the vocab size
    $scripts/apply_bpe.sh $para_model/$src$trg.para_bpe.$size.$vocab.bpe $outdata/train.$size.tc.$src $outdata/train.$size.para_bpe.$vocab.$src
    $scripts/apply_bpe.sh $para_model/$src$trg.para_bpe.$size.$vocab.bpe $outdata/train.$size.tc.$trg $outdata/train.$size.para_bpe.$vocab.$trg
    echo "Applying $vocab monolingual BPE"
    # apply BPE from monolingual data with the vocab size
    $scripts/apply_bpe.sh $mono_model/$src$trg.$vocab.bpe $outdata/train.$size.tc.$src $outdata/train.$size.mono_bpe.$vocab.$src
    $scripts/apply_bpe.sh $mono_model/$src$trg.$vocab.bpe $outdata/train.$size.tc.$trg $outdata/train.$size.mono_bpe.$vocab.$trg
   done
 done
