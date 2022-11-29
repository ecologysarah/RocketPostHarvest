#!/bin/bash 
#SBATCH -p defq
#SBATCH --mem-per-cpu=4G
#SBATCH --nodes=1
#SBATCH --tasks-per-node=16
#SBATCH --output OUT/platanus.%J
#SBATCH --error ERR/platanus.%J 
#SBATCH --job-name=trim.plat
#SBATCH --account=sbi9srj

#Tutorial at https://bioinformaticsworkbook.org/dataAnalysis/GenomeAssembly/Arabidopsis/AT_platanus-genome-assembly.html#gsc.tab=0

#Set your working directory
myDir=/mnt/scratch/sbi9srj/Lama/platanus_assembly

cd ${myDir}
ls

#Add to PATH
export PATH=${myDir}/:$PATH

#Run the trim
gunzip ${myDir}/../resources/UALgDiploT_RawReads/SRR11802588.fastq.gz
platanus_trim -i ${myDir}/../resources/UALgDiploT_RawReads/SRR11802588.fastq -t 16

exit 0
