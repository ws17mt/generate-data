#!/bin/bash
#SBATCH -N 1
#SBATCH -p RM
#SBATCH -t 8:00:00
#SBATCH --ntasks-per-node 12

#echo commands to stdout
set -x

#move to working directory if required
WORKING_FOLDER=/pylon2/ci560op/acurrey/data/generate-data

#run script
./preprocess_para.sh
