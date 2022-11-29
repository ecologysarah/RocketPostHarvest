#!/bin/bash
#author: Peter Kille
#SBATCH --partition=jumbo # the requested queue
#SBATCH --job-name=trans-pipe
#SBATCH --nodes=1              # number of nodes to use
#SBATCH --tasks-per-node=1     #
#SBATCH --cpus-per-task=64      #
#SBATCH --mem=128000     # in megabytes, unless unit explicitly stated
#SBATCH --error=ERR/rsem.%J         # redirect stderr to this file
#SBATCH --output=OUT/rsem.%J        # redirect stdout to this file


echo "Some Usable Environment Variables:"
echo "================================="
echo "hostname=$(hostname)"
echo \$SLURM_JOB_ID=${SLURM_JOB_ID}
echo \$SLURM_NTASKS=${SLURM_NTASKS}
echo \$SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}
echo \$SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}
echo \$SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}
echo \$SLURM_MEM_PER_NODE=${SLURM_MEM_PER_NODE}


module load bowtie2/v2.4.1
module load samtools/1.10
module load trinityrnaseq/Trinity-v2.6.6
module load RSEM/v1.3.3

#assembly full path
assembly="/mnt/scratch/sbi9srj/Lama/4C-evigene/Diplotaxis_tenuifolia_evigene18/okayset/4B-trinity_Diplotaxis_tenuifolia.Trinity.okay.Trinity.fasta"

#read dir
reads="/mnt/scratch/sbi9srj/Lama/2-trim"

#output_path
out="/mnt/scratch/sbi9srj/Lama/5-RSEM"

get_Trinity_gene_to_trans_map.pl ${assembly} > ${assembly}.gene_trans_map

#output file for mapping stats
output_filename="/mnt/scratch/sbi9srj/Lama/4C-evigene/evigene_mapping_stats.csv"


#define varibles
declare -a seqname=($(cat /mnt/scratch/sbi9srj/Lama/1-download/SampleFileNames.txt))

for (( i=0 ; i<${#seqname[@]} ; i++ ));do

align_and_estimate_abundance.pl --transcripts ${assembly} \
                                --seqType fq \
                                --left "${reads}/${seqname[${i}]}trim_1.fq.gz" \
				--right "${reads}/${seqname[${i}]}trim_2.fq.gz" \
				--est_method RSEM \
                                --aln_method bowtie2 \
                                --trinity_mode \
                                --thread_count ${SLURM_CPUS_PER_TASK} \
                                --prep_reference \
                                --output_dir "${out}/${seqname[${i}]}"

done

