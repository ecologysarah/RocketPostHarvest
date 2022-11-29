#!/bin/bash 
#SBATCH -p defq
#SBATCH --mem-per-cpu=4G
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --output OUT/genome.%J
#SBATCH --error ERR/genome.%J 
#SBATCH --job-name=download.plat
#SBATCH --account=sbi9srj

#Set your working directory
myDir=/mnt/scratch/sbi9srj/Lama

cd ${myDir}/platanus_assembly

# Download binaries
wget -O platanus http://platanus.bio.titech.ac.jp/?ddownload=145
wget -O platanus_trim http://platanus.bio.titech.ac.jp/?ddownload=153
wget -O platanus_internal_trim http://platanus.bio.titech.ac.jp/?ddownload=154

# make them executables
chmod +x platanus*

exit 0
