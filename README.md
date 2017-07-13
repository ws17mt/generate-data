### Data generation and processing scripts for fr-en

1. The TC and BPE models are trained on the mono corpora. (Use process_mono.sh)
2. These are then applied to the respective parallel datasets. (Use process_parallel.sh)

### For BPE experiments (BPE dir)
1. create_datasets.sh does the following:
	- preprocess the parallel training data (tokenize, remove long sentences, truecase)
	- learn the BPE models on the parallel data for each data size and vocab size
	- apply the learned BPE models
	- apply the monolingual BPE models
2. dev_test_preprocess.sh does the following for dev1, dev2, and test1:
	- preprocess (tokenize, truecase)
	- apply each of the different BPE models (18 total) to dev1 and dev2 only

### Processing parallel data once BPE is chosen (30k, monolingual)
1. preprocess_para.sh to preprocess parallel training, dev, and test sets
2. process_mono.sh to apply BPE to the monolingual sets
