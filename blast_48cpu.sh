#!/bin/bash
#author: Rakhee
#SBATCH --job-name=blast_job
#SBATCH --partition=epyc
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=48
#SBATCH --mem=10G
#SBATCH --error=ERR/blast.%J
#SBATCH --output=OUT/blast.%J

module load blast/2.12.0

       
blastx -query /mnt/scratch/sbi9srj/Lama/4C-evigene/Diplotaxis_tenuifolia_evigene18/okayset/4B-trinity_Diplotaxis_tenuifolia.Trinity.okay.Trinity.fasta \
       -db  /mnt/scratch/sbi9srj/Lama/blast_db/my_db.pdb \
       -num_threads ${SLURM_CPUS_PER_TASK} \
       -max_target_seqs 1 \
       -evalue 1E-10 \
       -outfmt 6 \
       -out output_blast_plants
