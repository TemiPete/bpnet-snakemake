#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --job-name=train
#SBATCH --account=pi-haky
#SBATCH --time=36:00:00	
#SBATCH --partition=beagle3
#SBATCH --gres=gpu:1

date


printf "Starting to run\n"
source ~/.bashrc
conda activate /project/haky/users/temi/software/conda_envs/bpnet
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/project/haky/users/temi/software/conda_envs/bpnet/lib

nvidia-smi

# base_dir="/project/haky/users/temi/projects/bpnet-AR"

# mkdir -p ${base_dir}/models

INPUT_DATA=${1}
MODEL_DIR=${2}
REFERENCE_GENOME=${3}
CHROM_SIZES=${4}
CHROM_LIST=${5}
OUTPUT_h5=${6}
CV_SPLITS=${7} #$params_dir/splits.json
# INPUT_DATA=${8} #$params_dir/input_bpnet-AR.json
MODEL_PARAMS=${8} #$params_dir/bpnet_params.json

mkdir -p $MODEL_DIR
bpnet-train \
    --input-data $INPUT_DATA \
    --output-dir $MODEL_DIR \
    --reference-genome $REFERENCE_GENOME \
    --chroms $(paste -s -d ' ' $CHROM_LIST) \
    --chrom-sizes $CHROM_SIZES \
    --splits $CV_SPLITS \
    --model-arch-name BPNet \
    --model-arch-params-json $MODEL_PARAMS \
    --sequence-generator-name BPNet \
    --model-output-filename $OUTPUT_h5 \
    --input-seq-len 2114 \
    --output-len 1000 \
    --shuffle \
    --threads 10 \
    --epochs 100 \
    --batch-size 64 \
    --reverse-complement-augmentation \
    --early-stopping-patience 10 \
    --reduce-lr-on-plateau-patience 5 \
    --learning-rate 0.001