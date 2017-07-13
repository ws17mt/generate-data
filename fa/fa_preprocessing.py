#!/usr/bin/env python

from __future__ import print_function
import hazm, io, sys, unicodedata

def main(fn):
    normalizer = hazm.Normalizer()
    with io.open(fn, encoding='utf-8') as f:
        for line in f:
            line = unicodedata.normalize('NFKD', line)  # norm some unicode character variants that hazm doesn't
            line = normalizer.normalize(line)           # Persian-specific normalizations
            print(' '.join(hazm.word_tokenize(line.strip())))  # tokenization


if __name__ == '__main__':
    main(sys.argv[1])
