#!/bin/bash 
#SBATCH -p defq
#SBATCH --mem-per-cpu=4G
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --output OUT/genome.%J
#SBATCH --error ERR/genome.%J 
#SBATCH --job-name=genome
#SBATCH --account=sbi9srj

module load fastqc/

#Set the name of your genome. Do not include spaces/special characters, as this will be the directory name
genomeName=UALgDiploT_RawReads
#Set your working directory
myDir=/mnt/scratch/sbi9srj/Lama

cd ${myDir}/resources/${genomeName}

#Run fastQC
fastqc *.fastq.gz

exit 0
