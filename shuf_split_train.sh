#!/usr/bin/env bash

# Split the small training dataset for fr-en into 10k, 100k, 1m
# Only splits a combination of the europarl and news commentary datasets
# Ignores the giant 200m fr-en training datasets

CORPUS_1=/pylon2/ci560op/fosterg/data/fr/raw-data/europarl-v7.fr-en
CORPUS_2=/pylon2/ci560op/fosterg/data/fr/raw-data/news-commentary-v9.fr-en

S_EXT=fr
T_EXT=en

MAX_SENT_LEN=80

TOOLS_DIR=tools
OUTDIR=data/fr_train

mkdir -p $OUTDIR

cat ${CORPUS_1}.${S_EXT} ${CORPUS_2}.${S_EXT} > ${OUTDIR}/train.raw.${S_EXT}
cat ${CORPUS_1}.${T_EXT} ${CORPUS_2}.${T_EXT} > ${OUTDIR}/train.raw.${T_EXT}

# Clean (truncate max length)
echo "*** Cleaning corpus.${l}"
${TOOLS_DIR}/clean-corpus-n.perl ${OUTDIR}/train.raw \
  ${S_EXT} ${T_EXT} ${OUTDIR}/train.clean 1 $MAX_SENT_LEN

# Concatenate files
paste ${OUTDIR}/train.clean.${S_EXT} ${OUTDIR}/train.clean.${T_EXT} > ${OUTDIR}/train.clean.${S_EXT}${T_EXT}

# Shuffle
echo "*** Shuffling"
cat ${OUTDIR}/train.clean.${S_EXT}${T_EXT} | shuf > ${OUTDIR}/train.shuf.${S_EXT}${T_EXT}

# Split concatenated files
cut -f1 ${OUTDIR}/train.shuf.${S_EXT}${T_EXT} > ${OUTDIR}/train.fr
cut -f2 ${OUTDIR}/train.shuf.${S_EXT}${T_EXT} > ${OUTDIR}/train.en

# Create data partitions
echo "*** Creating data partitions"
head -n10000 ${OUTDIR}/train.fr > ${OUTDIR}/train.10k.fr
head -n10000 ${OUTDIR}/train.en > ${OUTDIR}/train.10k.en

head -n100000 ${OUTDIR}/train.fr > ${OUTDIR}/train.100k.fr
head -n100000 ${OUTDIR}/train.en > ${OUTDIR}/train.100k.en

head -n1000000 ${OUTDIR}/train.fr > ${OUTDIR}/train.1m.fr
head -n1000000 ${OUTDIR}/train.en > ${OUTDIR}/train.1m.en

echo "*** Done. Cleaning up"
rm ${OUTDIR}/train.raw.*
rm ${OUTDIR}/train.clean.*
rm ${OUTDIR}/train.shuf.${S_EXT}${T_EXT}
