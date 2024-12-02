#!/bin/bash -ue
mkdir -p fastqc_output
fastqc SRR292678_1.fastq.gz --outdir fastqc_output
