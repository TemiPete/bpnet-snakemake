# Description: Given a TF and tissue (or context) , this pipeline trains logistic elastic net models of that TF binding activity in that tissue
# Author: Temi
# Date: Wed Mar 29 2023
# Usage: --> see README

import os, glob, sys, re, yaml, subprocess
from snakemake.io import glob_wildcards
import numpy as np
import itertools
from collections import Iterable

sys.path.append('workflow/src')
sys.path.append('workflow/modules')

# import helpers

print_progress = False

runname = config['dataset']
rundate = config['date']
run = f'{runname}_{rundate}'

# directories

#DATA_DIR = os.path.join('data') 
DATA_DIR = 'data' # here I want to have some common files (like the motif files; this should not need to run everytime if already available)

METADATA_DIR = 'metadata'

RUN_DIR = os.path.join(DATA_DIR, f"{runname}_{rundate}") 
FILES_DIR = os.path.join(RUN_DIR, 'files')
MODEL_DIR = os.path.join(RUN_DIR, 'model')
PREDICTIONS_DIR = os.path.join(RUN_DIR, 'predictions')

rule all:
    input:
        expand(os.path.join(FILES_DIR, '{runid}.outliers_bpnet.json'), runid = runname),
        expand(os.path.join(FILES_DIR, '{runid}.peaks_inliers.bed'), runid = runname),
        expand(os.path.join(FILES_DIR, '{runid}.genomewide_gc_stride_1000_flank_size_1057.gc.bed'), runid = runname),
        expand(os.path.join(FILES_DIR, '{runid}.genomewide_gc_stride_1000_flank_size_1057.gc.awked.bed'), runid = runname),
        expand(os.path.join(FILES_DIR, '{runid}.gc_negatives.bed'), runid = runname),
        expand(os.path.join(FILES_DIR, '{runid}.candidate_negatives.bed'), runid = runname),
        expand(os.path.join(FILES_DIR, '{runid}.input_bpnet.json'), runid = runname),
        expand(os.path.join(MODEL_DIR, '{runid}.bpnet-AR.h5_split000'), runid = runname)


rule create_input:
    output:
        os.path.join(FILES_DIR, '{runid}.outliers_bpnet.json')
    message: 
        "working on {wildcards}"
    params:
        run = run,
        jobname = '{runid}',
        f1 = config['bw_file'],
        f2 = config['peaks_file']
    resources:
        partition="caslake",
        mem_cpu=2,
        cpu_task=2
    shell:
        """
        python3 workflow/src/create_input_json.py --find_outliers --signal_source {params.f1} --loci_source {params.f2} --output_json {output}
        """
    
rule filter_input:
    input:
        rules.create_input.output
    output:
        f1=os.path.join(FILES_DIR, '{runid}.peaks_inliers.bed'),
        f2=os.path.join(FILES_DIR, '{runid}.genomewide_gc_stride_1000_flank_size_1057.gc.awked.bed'),
        f3=os.path.join(FILES_DIR, '{runid}.gc_negatives.bed'),
        f4=os.path.join(FILES_DIR, '{runid}.genomewide_gc_stride_1000_flank_size_1057.gc.bed'),
        f5=os.path.join(FILES_DIR, '{runid}.candidate_negatives.bed'),
        f6=os.path.join(FILES_DIR, '{runid}.input_bpnet.json')
    message: 
        "working on {wildcards}"
    params:
        run = run,
        jobname = '{runid}',
        hg38_chromsizes = config['hg38_chromsizes'],
        chroms_list = config['chroms_list'],
        blacklist_bed = config['blacklist_bed'],
        genome = config['genome'],
        bwfile = config['bw_file'],
        bias_file = config['bias_file'],
        bed_prefix=lambda wildcards, output: re.sub(".bed$", "", output.f4),
        neg_prefix=lambda wildcards, output: re.sub(".bed$", "", output.f3)
    resources:
        partition="caslake",
        mem_cpu=8,
        cpu_task=8,
        mem_mb=24000
    shell:
        """
        bash workflow/src/filtering.sbatch {input} {params.hg38_chromsizes} {params.chroms_list} {params.blacklist_bed} {output.f1} {params.genome} {params.bed_prefix} {output.f2} {params.neg_prefix} {output.f5} &&
        python3 workflow/src/create_input_json.py --signal_source {params.bwfile} --loci_source {output.f1} --background_loci_source {output.f3} --bias_source {params.bias_file} --output_json {output.f6}
        """

rule train_bpnet:
    input:
        rules.filter_input.output.f6
    output:
        directory(os.path.join(MODEL_DIR, '{runid}.bpnet-AR.h5_split000'))
    message: 
        "working on {wildcards}"
    params:
        run = run,
        jobname = '{runid}',
        hg38_chromsizes = config['hg38_chromsizes'],
        chroms_list = config['chroms_list'],
        blacklist_bed = config['blacklist_bed'],
        genome = config['genome'],
        mdir=MODEL_DIR,
        cv_splits = config['cv_splits'],
        model_params = config['model_params'],
        bname = '{runid}.bpnet-AR.h5'
    resources:
        partition="caslake",
        time="36:00:00", 
        mem_cpu=2,
        cpu_task=2
    shell:
        """
        sbatch workflow/src/train.sbatch {input} {params.mdir} {params.genome} {params.hg38_chromsizes} {params.chroms_list} {params.bname} {params.cv_splits} {params.model_params}
        """