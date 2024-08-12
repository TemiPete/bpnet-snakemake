#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --job-name=preprocess
#SBATCH --account=pi-haky
#SBATCH --output=/project/haky/users/temi/projects/bpnet/logs/preprocess.out
#SBATCH --error=/project/haky/users/temi/projects/bpnet/logs/preprocess.err
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

data_dir=${1} #"/beagle3/haky/users/temi/data/bpnet"
bname=${2}
input_bam=${3}
hg38_chromsizes=${4} # hg38.chrom.sizes

#
merged_bam=${data_dir}/${bname}.merged.bam
plus_bedgraph=${data_dir}/${bname}.plus.bedGraph
minus_bedgraph=${data_dir}/${bname}.minus.bedGraph
plus_bw=${data_dir}/${bname}.plus.bw
minus_bw=${data_dir}/${bname}.minus.bw

samtools merge -f ${merged_bam} ${input_bam}
samtools index ${merged_bam}
#samtools index control.bam

# get coverage of 5’ positions of the plus strand
samtools view -b ${merged_bam} $(cut -f 1 ${hg38_chromsizes}) | \
	bedtools genomecov -5 -bg -strand + -ibam stdin | \
	sort -k1,1 -k2,2n > ${plus_bedgraph}

# get coverage of 5’ positions of the minus strand
samtools view -b ${merged_bam} $(cut -f 1 ${hg38_chromsizes}) | \
        bedtools genomecov -5 -bg -strand - -ibam stdin | \
        sort -k1,1 -k2,2n > ${minus_bedgraph}

# Convert bedGraph files to bigWig files
bedGraphToBigWig ${plus_bedgraph} ${hg38_chromsizes} ${plus_bw}
bedGraphToBigWig ${minus_bedgraph} ${hg38_chromsizes} ${minus_bw}


# # get coverage of 5’ positions of the control plus strand
# samtools view -b control.bam $(cut -f 1 hg38.chrom.sizes) | \
#         bedtools genomecov -5 -bg -strand + -ibam stdin | \
#         sort -k1,1 -k2,2n > control_plus.bedGraph

# # get coverage of 5' positions of the control minus strand
# samtools view -b control.bam $(cut -f 1 hg38.chrom.sizes) | \
#         bedtools genomecov -5 -bg -strand - -ibam stdin | \
#         sort -k1,1 -k2,2n > control_minus.bedGraph

# # Convert bedGraph files to bigWig files
# bedGraphToBigWig control_plus.bedGraph hg38.chrom.sizes control_plus.bw
# bedGraphToBigWig control_minus.bedGraph hg38.chrom.sizes control_minus.bw


printf "INFO - Finished with preprocessing"