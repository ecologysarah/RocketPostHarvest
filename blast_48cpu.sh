#!/bin/bash
#author: Rakhee
#SBATCH --job-name=blast_job
#SBATCH --partition=epyc
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=48
#SBATCH --mem=10G
#SBATCH --error=%J.err
#SBATCH --output=%J.out
#SBATCH --mail-user=dhorajiwalar@cardiff.ac.uk  # email address used for event notification
#SBATCH --mail-type=all                                   # email on job start, failure and end


module load blast/2.12.0

       
blastx -query /mnt/scratch/c1203192/tmpblast/trinity_all.Trinity.okay.tr \
       -db /mnt/scratch/c1203192/tmpblast/db/plants \
       -num_threads ${SLURM_CPUS_PER_TASK} \
       -max_target_seqs 1 \
       -evalue 1E-10 \
       -outfmt 6 \
       -out output_blast_plants
