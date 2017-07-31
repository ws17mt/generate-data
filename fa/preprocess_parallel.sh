#!/bin/sh

MOSES=$SCRIPTS_DIR/mosesdecoder

# Remove old files
EN_DATA=$TMP_DIR/combined/en
rm $EN_DATA/*.tc
rm $EN_DATA/*.tok

# Now we preprocess the English data, tokenizing, truecasing and BPE'ing it
echo "Generating parallel English data"
for f in `ls $EN_DATA`
do
    echo "Tokenising"
    $MOSES/scripts/tokenizer/tokenizer.perl -a -l en -threads 12 < $EN_DATA/$f > $EN_DATA/$f.tok
    echo "Truecasing"
    $MOSES/scripts/recaser/truecase.perl -model $EN_TC_MODEL/truecase-model.en < $EN_DATA/$f.tok > $EN_DATA/$f.tc
    echo "Applying BPE"
    $APPLY_BPE -c $OUTPUT_DIR/en.bpe.model < $EN_DATA/$f.tc > $OUTPUT_DIR/$f.bpe.en
done

# Same for Farsi
FA_DATA=$TMP_DIR/combined/fa
rm $FA_DATA/*.tc
rm $FA_DATA/*.tok

# Now we preprocess the English data, tokenizing, truecasing and BPE'ing it
echo "Generating parallel Farsi data"
for f in `ls $FA_DATA`
do
    echo "Tokenising and normalising"
    python fa_preprocessing.py $FA_DATA/$f > $FA_DATA/$f.tok
    echo "Applying BPE"
    $APPLY_BPE -c $OUTPUT_DIR/fa.bpe.model < $FA_DATA/$f.tok > $OUTPUT_DIR/$f.bpe.fa
done
