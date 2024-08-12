#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --job-name=filtering
#SBATCH --account=pi-haky
#SBATCH --output=/beagle3/haky/users/temi/projects/bpnet-snakemake/filtering.out
#SBATCH --error=/beagle3/haky/users/temi/projects/bpnet-snakemake/filtering.err
#SBATCH --time=02:00:00	
#SBATCH --partition=caslake

date
module load openmpi
module load parallel

slurm_workdir=${SLURM_SUBMIT_DIR}
SLURM_O_WORKDIR=${slurm_workdir}

mkdir -p ${SLURM_O_WORKDIR}
echo Working directory is $SLURM_O_WORKDIR
cd $SLURM_O_WORKDIR

echo Jobid: $SLURM_JOBID
echo Running on host `hostname`

printf "Starting to run\n"
source ~/.bashrc
conda activate /project/haky/users/temi/software/conda_envs/bpnet

# data_dir="/project/haky/users/temi/projects/bpnet-AR/data"
input_outliers=${1} #"/project/haky/users/temi/projects/bpnet-AR/config/input.outliers.bpnet-AR.json"
hg38_chromsizes=${2}
chroms_list=${3} # chroms.txt
blacklist_bed=${4} # blacklist.bed
peaks_inliers=${5} # peaks_inliers.bed
genome=${6} # genome.fa file
genome_gc_bed=${7} # genomewide_gc_stride_1000_flank_size_1057.gc.bed  but the prefix i.e. genomewide_gc_stride_flank_size.gc
genome_gc_bed_awked=${8} # genomewide_gc_stride_1000_flank_size_1057.gc.awked.bed
gc_negatives=${9} # gc_negatives.bed but the prefix i.e. gc_negatives
candidate_negatives=${10} # candidate_negatives.bed

bpnet-outliers \
    --input-data ${input_outliers}  \
    --quantile 0.99 \
    --quantile-value-scale-factor 1.2 \
    --task 0 \
    --chrom-sizes ${hg38_chromsizes} \
    --chroms $(paste -s -d ' ' ${chroms_list}) \
    --sequence-len 1000 \
    --blacklist ${blacklist_bed} \
    --global-sample-weight 1.0 \
    --output-bed ${peaks_inliers}

# # bpnet-gc-reference - get gc content after binning the entire genome into bins - You might be choose to run just once for a genome for a specific input sequence length and reuse the genomewide_gc_stride_flank_size.gc.bed output for other datasets

bpnet-gc-reference \
        --ref_fasta ${genome} \
        --chrom_sizes ${hg38_chromsizes} \
        --out_prefix ${genome_gc_bed} \
        --inputlen 2114 \
        --stride 1000

# this file seems to have 5 columns
n=$(cat ${genome_gc_bed}.bed | awk -F '\t' '{print NF;}' | uniq | sort | uniq)
awk -F'\t' 'BEGIN {OFS=FS} {$NF=""; NF--}1' ${genome_gc_bed}.bed > ${genome_gc_bed_awked}
# if [ $n -gt 4 ]; then
#     printf "INFO - Removing the 5th column";
#     awk -F'\t' 'BEGIN {OFS=FS} {$NF=""; NF--}1' genomewide_gc_stride_1000_flank_size_1057.gc.bed > genomewide_gc_stride_1000_flank_size_1057.gc.bed
# fi
        
bpnet-gc-background \
        -i ${peaks_inliers} \
        -d ./ \
        -rgb ${genome_gc_bed_awked} \
        -o ${gc_negatives} \
        -fl 1057 \
        -npr 4 \
        -g ${genome} \
        -c ${candidate_negatives}

# printf "INFO - Finished with filtering"

# this error comes up a lot:

# Error: Type checker found wrong number of fields while tokenizing data line.
# Perhaps you have extra TAB at the end of your line? Check with "cat -t"

# solution
# 1. Install bedops
# 2. use: 
# 3. change in `/project/haky/users/temi/software/conda_envs/bpnet/lib/python3.7/site-packages/bpnet/cli/gc/get_gc_background.py`
#     :
# # bedtools intersect -v -a genomewide_gc_stride_1000_flank_size_1057.gc.bed -b peaks_gc.bed > test.bed
# bedops --intersect genomewide_gc_stride_1000_flank_size_1057.gc.bed peaks_gc.bed > test.bed
# # cat genomewide_gc_stride_1000_flank_size_1057.gc.bed peaks_gc.bed | sort-bed - | bedops --merge - > test.bed

# cat genomewide_gc_stride_1000_flank_size_1057.gc.bed | awk -F '\t' '{print NF;}' | uniq | sort | uniq
# cat peaks_gc.bed | awk -F '\t' '{print NF;}' | uniq | sort | uniq

# awk -F '\t' '(int($5)==0) {print FILENAME,NF,NR, $0;}' genomewide_gc_stride_1000_flank_size_1057.gc.bed

# awk -F'\t' 'NF==4' genomewide_gc_stride_1000_flank_size_1057.gc.bed


# awk -F'\t' 'BEGIN {OFS=FS} {$NF=""; NF--}1' genomewide_gc_stride_1000_flank_size_1057.gc.bed > out.bed
# cat out.bed | awk -F '\t' '{print NF;}' | uniq | sort | uniq
