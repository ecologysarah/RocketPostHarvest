#!/bin/bash
#SBATCH --partition=epyc                       # the requested queue
#SBATCH --nodes=1                               # number of nodes to use
#SBATCH --tasks-per-node=1                      #
#SBATCH --cpus-per-task=16                       #
#SBATCH --mem=128000    # in megabytes, unless unit explicitly stated
#SBATCH --error=/mnt/scratch/sbi9srj/Lama/ERR/busco.%J    # redirect stderr to this file
#SBATCH --output=/mnt/scratch/sbi9srj/Lama/OUT/busco.%J    # redirect stdout to this file


echo "Usable Environment Variables:"
echo "============================="
echo "hostname=$(hostname)"
echo \$SLURM_JOB_ID=${SLURM_JOB_ID} 
echo \$SLURM_NTASKS=${SLURM_NTASKS}
echo \$SLURM_NTASKS_PER_NODE=${SLURM_NTASKS_PER_NODE}
echo \$SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}
echo \$SLURM_JOB_CPUS_PER_NODE=${SLURM_JOB_CPUS_PER_NODE}
echo \$SLURM_MEM_PER_CPU=${SLURM_MEM_PER_CPU}
echo \$SLURM_MEM_PER_NODE=${SLURM_MEM_PER_NODE}
echo \$USER=${USER}

# Generic CharlieCloud ####################################

module load charliecloud/0.20

CCIMAGEDIR=/mnt/scratch/nodelete/CharlieCloud/images
CCIMAGENAME=busco_v5_beta2
CCTARGET=/mnt/scratch/$USER/cc
#/tmp/$USER/cc
CCSCRATCH=/mnt/scratch

# workingdir : folder that contains input files, needs to be an area in /mnt/scratch you already have read&write access
# !! Do not add an extra / to end of WORKINGDIR, otherwise you get a // in file location which fails
WORKINGDIR=/mnt/scratch/$USER/Lama
   
# outputdir : folder name for output files, will be in workingdir
OUTPUTDIR=4D-busco

# genome name for input
#GENOMENAME=genome.fna

# expand the CC filesystem
mkdir -p ${CCTARGET}
[[ -d "${CCTARGET}/${CCIMAGENAME}" ]] || tar xvzf ${CCIMAGEDIR}/${CCIMAGENAME}.tar.gz -C ${CCTARGET}
#
# create scratch folder (bind-mounted to cluster scratch folder)
mkdir -p ${CCTARGET}/${CCIMAGENAME}/${CCSCRATCH}


cat >${CCTARGET}/${CCIMAGENAME}/busco_source_commands.sh <<EOF
# Environment setup for container
PATH=/home/biodocker/sepp/:/ncbi-blast-2.10.1+/bin/:/metaeuk/build/bin/:/augustus/bin:/augustus/scripts:/usr/local/bin/:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/conda/bin:/home/biodocker/bin:$PATH

#call varibles
#source ${WORKINGDIR}/local_scripts/varibles_busco_CC.txt

#for (( i=0 ; i<\${#seqname[@]} ; i++ ));do

# Script, change genomename to correct file name

mkdir ${WORKINGDIR}/${OUTPUTDIR}
cd ${WORKINGDIR}/${OUTPUTDIR}

busco -i ${WORKINGDIR}/4B-trinity_Diplotaxis_tenuifolia.Trinity.fasta -l viridiplantae_odb10 -c ${SLURM_CPUS_PER_TASK} -m trans -f --out Diplotaxis_tenuifolia_busco_full

busco -i ${WORKINGDIR}/4C-evigene/Diplotaxis_tenuifolia_okay18.fasta -l viridiplantae_odb10 -c ${SLURM_CPUS_PER_TASK} -m trans -f --out Diplotaxis_tenuifolia_busco

# Script will occasionaly generate a fail report without this final echo
echo "finished"

#done


EOF

# Enter interactive CharlieCloud container ##############
ch-run  ${CCTARGET}/${CCIMAGENAME} --no-home -b ${CCSCRATCH}:${CCSCRATCH} -- bash  /busco_source_commands.sh
