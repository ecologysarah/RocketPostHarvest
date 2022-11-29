#!/bin/bash
#author: Peter Kille
#SBATCH --job-name=trans-pipe
#SBATCH --partition=epyc
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=32      #
#SBATCH --mem=128000     # in megabytes, unless unit explicitly stated
#SBATCH --error=/mnt/scratch/sbi9srj/Lama/ERR/evigene.%J         # redirect stderr to this file
#SBATCH --output=/mnt/scratch/sbi9srj/Lama/OUT/evigene.%J        # redirect stdout to this file

echo "Some Usable Environment Variables:"
echo "================================="
echo "hostname=$(hostname)"
echo \$SLURM_JOB_ID=${SLURM_JOB_ID}
echo \$SLURM_NTASKS=${SLURM_NTASKS}
echo \$SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}
echo \$SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}
echo \$SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}
echo \$SLURM_MEM_PER_NODE=${SLURM_MEM_PER_NODE}

module load evigene/18jan01
module load trinityrnaseq/Trinity-v2.6.6
 
#call varibles
myDir=/mnt/scratch/sbi9srj/Lama
source ${myDir}/RNAscripts/variables_transcript_pipeline

#Make output directory
mkdir -p "${myDir}/4C-evigene/${seqname[${i}]}_evigene18"
cd ${myDir}/4C-evigene/${seqname[${i}]}_evigene18 

for (( i=0 ; i<${#seqname[@]} ; i++ ));do

tr2aacds.pl -mrnaseq "${myDir}/4B-trinity_${seqname[${i}]}.Trinity.fasta" -MINCDS=60 -NCPU=${SLURM_CPUS_PER_TASK} -MAXMEM=${SLURM_MEM_PER_NODE} -logfile -tidyup

cp "okayset/4B-trinity_${seqname[${i}]}.Trinity.okay.Trinity.fasta" "${myDir}/4C-evigene/${seqname[${i}]}_okay18.fasta"

TrinityStats.pl "${myDir}/4C-evigene/${seqname[${i}]}_okay18.fasta" > "${myDir}/4C-evigene/${seqname[${i}]}_okay18_stats.txt"

rm -r inputset
rm -r tmpfiles

rm "4B-trinity_${seqname[${i}]}.nrcd1x_db.ndb"
rm "4B-trinity_${seqname[${i}]}.nrcd1x_db.not"
rm "4B-trinity_${seqname[${i}]}.nrcd1x_db.ntf"
rm "4B-trinity_${seqname[${i}]}.nrcd1x_db.nto"
rm "4B-trinity_${seqname[${i}]}.nrcd1x_db.perf"
rm "4B-trinity_${seqname[${i}]}.tr2aacds.log"
rm "4B-trinity_${seqname[${i}]}.trclass"
rm "4B-trinity_${seqname[${i}]}.trclass.sum.txt"

done
