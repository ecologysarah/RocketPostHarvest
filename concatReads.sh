#!/bin/bash
#SBATCH -p defq
#SBATCH --mem-per-cpu=4G
#SBATCH --nodes=1
#SBATCH --tasks-per-node=2
#SBATCH --output OUT/genome.%J
#SBATCH --error ERR/genome.%J
#SBATCH --job-name=genome
#SBATCH --account=sbi9srj

cd /mnt/scratch/sbi9srj/Lama/1-download/211210_NB501042_0305_AHWYNNBGXK-fastqs/

#ls *R1.fastq.gz | while read line; do zcat ${line}; done >> F_reads.fasta &

#ls *R2.fastq.gz | while read line; do zcat ${line}; done >> R_reads.fasta 

tar -czf F_reads.fasta.tar.gz F_reads.fasta &

tar -czf R_reads.fasta.tar.gz R_reads.fasta 

mkdir /mnt/scratch/sbi9srj/Lama/resources/RNAreads

mv *tar.gz /mnt/scratch/sbi9srj/Lama/resources/RNAreads

