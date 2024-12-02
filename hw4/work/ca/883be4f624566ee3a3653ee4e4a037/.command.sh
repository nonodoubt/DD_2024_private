#!/bin/bash -ue
mkdir -p fastqc_output
fastqc SRR292862_1.fastq.gz --outdir fastqc_output
