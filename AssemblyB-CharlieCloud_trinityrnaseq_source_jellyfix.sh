#!/bin/bash
#SBATCH --partition=epyc			
#SBATCH --job-name=All_trinity_assembly          
#SBATCH --nodes=1				
#SBATCH --tasks-per-node=1			
#SBATCH --cpus-per-task=32			  
#SBATCH --mem=360gb 				
#SBATCH --error=/mnt/scratch/sbi9srj/Lama/ERR/assemble.%J			
#SBATCH --output=/mnt/scratch/sbi9srj/Lama/OUT/assemble.%J			

echo "Usable Environment Variables:"
echo "============================="
echo "hostname=$(hostname)"
echo \$SLURM_JOB_ID=${SLURM_JOB_ID} 
echo \$SLURM_NTASKS=${SLURM_NTASKS}
echo \$SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}
echo \$SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}
echo \$SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}
echo \$SLURM_MEM_PER_NODE=${SLURM_MEM_PER_NODE}

# Trinity requires max memory in GB not MB, script to convert mem to GB
TOTAL_RAM=$(expr ${SLURM_MEM_PER_NODE} / 1024)

# Generic CharlieCloud ####################################
module load charliecloud/0.20

CCIMAGEDIR=/mnt/scratch/nodelete/CharlieCloud/images
CCIMAGENAME=trinityrnaseq
CCTARGET=/mnt/scratch/$USER/cc
#/tmp/$USER/cc
CCSCRATCH=/mnt/scratch
# workingdir : folder for input and output files, needs to be an area in /mnt/scratch you already have read&write access  
# Do not put a trailing / on end of workingdir
workingdir=/mnt/scratch/sbi9srj/Lama/RNAscripts

#expand the CC filesystem
mkdir -p ${CCTARGET}
[[ -d "${CCTARGET}/${CCIMAGENAME}" ]] || tar xvzf ${CCIMAGEDIR}/${CCIMAGENAME}.tar.gz -C ${CCTARGET}

#
# create scratch folder (bind-mounted to cluster scratch folder)
mkdir -p ${CCTARGET}/${CCIMAGENAME}/${CCSCRATCH}

cat >${CCTARGET}/${CCIMAGENAME}/trinity_source_commands.sh <<EOF
# Environment setup for container
PATH=/usr/local/bin/trinityrnaseq:/usr/local/src/salmon-latest_linux_x86_64/bin:$PATH:/bin
export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

#call varibles
source ${workingdir}/variables_transcript_pipeline

for (( i=0 ; i<\${#seqname[@]} ; i++ ));do

# Script,trinity output file location needs to start with trinity
Trinity --seqType fq \
        --left "/mnt/scratch/sbi9srj/Lama/4A-assembly/F_reads.fastq.gz" \
        --right "/mnt/scratch/sbi9srj/Lama/4A-assembly/R_reads.fastq.gz" \
        --max_memory ${TOTAL_RAM}G \
        --CPU ${SLURM_CPUS_PER_TASK} \
        --output "\${dir}/4C-trinity_\${seqname[\${i}]}/" \
        --full_cleanup

sed -i "s/TRINITY_DN/\${seqname[\${i}]}_/g" "\${dir}/4C-trinity_\${seqname[\${i}]}.fasta"
sed -i "s/TRINITY_DN/\${seqname[\${i}]}_/g" "\${dir}/4C-trinity_\${seqname[\${i}]}.gene_trans_map"

/usr/local/bin/trinityrnaseq/util/TrinityStats.pl "\${dir}/4C-trinity_\${seqname[\${i}]}.fasta" > "\${dir}/4C-trinity_\${seqname[\${i}]}_stats.txt"

done

# Check
echo TOTAL_RAM=${TOTAL_RAM}
echo CPU=${SLURM_CPUS_PER_TASK}
EOF

# Enter interactive CharlieCloEmarL2_NNMUHEP_22072016ud container ##############
ch-run  ${CCTARGET}/${CCIMAGENAME} --no-home -b ${CCSCRATCH}:${CCSCRATCH} -- bash  /trinity_source_commands.sh
