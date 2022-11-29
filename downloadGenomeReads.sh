#!/bin/bash 
#SBATCH -p defq
#SBATCH --mem-per-cpu=4G
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --output OUT/genome.%J
#SBATCH --error ERR/genome.%J 
#SBATCH --job-name=genome
#SBATCH --account=sbi9srj

#Set the name of your genome. Do not include spaces/special characters, as this will be the directory name
genomeName=UALgDiploT_RawReads
#Set your working directory
myDir=/mnt/scratch/sbi9srj/Lama


#Check for and create output directory
if [ ! -d "${myDir}"/resources/${genomeName} ]
        then mkdir -p ${myDir}/resources/${genomeName}
fi

cd ${myDir}/resources/${genomeName}

#Download FASTA
curl -sLO "ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR118/088/SRR11802588/SRR11802588.fastq.gz"

exit 0
