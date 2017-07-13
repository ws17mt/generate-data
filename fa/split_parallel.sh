#!/bin/bash

# This generates the splits for English-Farsi.
# This script should be run on its folder to work properly
# since it assumes paths for the original corpora

# First we start by concatenating the 'news' and 'found' corpora from LDC
# Then we join both corpora and shuffle it into a single file.
echo "Processing News and Found"
mkdir -p $TMP_DIR/news_found
cat $LDC_NEWS_EN $LDC_FOUND_EN > $TMP_DIR/news_found/en.txt
cat $LDC_NEWS_FA $LDC_FOUND_FA > $TMP_DIR/news_found/fa.txt
paste $TMP_DIR/news_found/en.txt $TMP_DIR/news_found/fa.txt > $TMP_DIR/news_found/en-fa.txt
shuf --random-source=$SEED $TMP_DIR/news_found/en-fa.txt > $TMP_DIR/news_found/en-fa_shuf.txt

# Now we do the same with the TED talks data
# For this data we also do a simple filtering where we get rid of
# the preamble for each talk, which has URLs and IDs stuff.
# The preamble also has a brief description of each talk but these are
# not sentence split so we discard them as well. We do however keep
# the talk title.
echo "Processing TED"
mkdir -p $TMP_DIR/ted
paste $TED_EN $TED_FA > $TMP_DIR/ted/en-fa.txt
python clean_ted.py $TMP_DIR/ted/en-fa.txt > $TMP_DIR/ted/en-fa_clean.txt
shuf --random-source=$SEED $TMP_DIR/ted/en-fa_clean.txt > $TMP_DIR/ted/en-fa_shuf.txt

# Now we make the splits, first we do it in a per domain basis to ensure balance
# TODO: hard numbers are ugly, should find a better way...
echo "Splitting"
tail -1112 $TMP_DIR/news_found/en-fa_shuf.txt > $TMP_DIR/news_found/en-fa_test.txt
tail -1946 $TMP_DIR/news_found/en-fa_shuf.txt | head -834 > $TMP_DIR/news_found/en-fa_dev2.txt
tail -2780 $TMP_DIR/news_found/en-fa_shuf.txt | head -834 > $TMP_DIR/news_found/en-fa_dev1.txt
head -27563 $TMP_DIR/news_found/en-fa_shuf.txt > $TMP_DIR/news_found/en-fa_train.txt
head -2778 $TMP_DIR/news_found/en-fa_shuf.txt > $TMP_DIR/news_found/en-fa_train_small.txt

tail -2888 $TMP_DIR/ted/en-fa_shuf.txt > $TMP_DIR/ted/en-fa_test.txt
tail -5054 $TMP_DIR/ted/en-fa_shuf.txt | head -2166 > $TMP_DIR/ted/en-fa_dev2.txt
tail -7220 $TMP_DIR/ted/en-fa_shuf.txt | head -2166 > $TMP_DIR/ted/en-fa_dev1.txt
head -70595 $TMP_DIR/ted/en-fa_shuf.txt > $TMP_DIR/ted/en-fa_train.txt
head -7222 $TMP_DIR/ted/en-fa_shuf.txt > $TMP_DIR/ted/en-fa_train_small.txt

# Now we combine each respective set, shuffling them again afterwards.
echo "Combining both corpora"
mkdir -p $TMP_DIR/combined
cat $TMP_DIR/news_found/en-fa_test.txt $TMP_DIR/ted/en-fa_test.txt | shuf --random-source=$SEED > $TMP_DIR/combined/en-fa_test.txt
cat $TMP_DIR/news_found/en-fa_dev2.txt $TMP_DIR/ted/en-fa_dev2.txt | shuf --random-source=$SEED > $TMP_DIR/combined/en-fa_dev2.txt
cat $TMP_DIR/news_found/en-fa_dev1.txt $TMP_DIR/ted/en-fa_dev1.txt | shuf --random-source=$SEED > $TMP_DIR/combined/en-fa_dev1.txt
cat $TMP_DIR/news_found/en-fa_train.txt $TMP_DIR/ted/en-fa_train.txt | shuf --random-source=$SEED > $TMP_DIR/combined/en-fa_train.txt
cat $TMP_DIR/news_found/en-fa_train_small.txt $TMP_DIR/ted/en-fa_train_small.txt | shuf --random-source=$SEED > $TMP_DIR/combined/en-fa_train_small.txt

# Finally we split between English and Farsi, putting into their corresponding folders
echo "Splitting between English and Farsi"
mkdir -p $TMP_DIR/combined/en
cut -f1 $TMP_DIR/combined/en-fa_test.txt > $TMP_DIR/combined/en/test
cut -f1 $TMP_DIR/combined/en-fa_dev2.txt > $TMP_DIR/combined/en/dev2
cut -f1 $TMP_DIR/combined/en-fa_dev1.txt > $TMP_DIR/combined/en/dev1
cut -f1 $TMP_DIR/combined/en-fa_train.txt > $TMP_DIR/combined/en/train.full
cut -f1 $TMP_DIR/combined/en-fa_train_small.txt > $TMP_DIR/combined/en/train.10k

mkdir -p $TMP_DIR/combined/fa
cut -f2 $TMP_DIR/combined/en-fa_test.txt > $TMP_DIR/combined/fa/test
cut -f2 $TMP_DIR/combined/en-fa_dev2.txt > $TMP_DIR/combined/fa/dev2
cut -f2 $TMP_DIR/combined/en-fa_dev1.txt > $TMP_DIR/combined/fa/dev1
cut -f2 $TMP_DIR/combined/en-fa_train.txt > $TMP_DIR/combined/fa/train.full
cut -f2 $TMP_DIR/combined/en-fa_train_small.txt > $TMP_DIR/combined/fa/train.10k
