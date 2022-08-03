#!/bin/bash

#This script will preprocess RNAseq data ready for RNAseq-guided genome assembly using Trinity. It will add the necessary suffixes to the header of each sequence and merge the sequences into two large files, one for forward and one for reverse reads. It relies on correctly setting the variables indicated below.
#Written by Sarah Christofides, 2022, based on scripts by Peter Kille. Released under Creative Commons BY-SA.

###VARIABLES TO BE SET###
##Set the path to your directory on scratch
myDir=/mnt/scratch/sbi9srj/Lama
##Set your username
userProject=sbi9srj
##Set the slurm queue to use: defq for gomphus, epyc for iago, htc for hawk
queue=epyc
######

sampleIDs=$(cat ${myDir}/1-download/SampleFileNames.txt)

mem="4G"
cpu="1"
runTime="00:20:00"
scriptBase="preprocess"
slurmids=""

##Make the output directory
if [ ! -d "${myDir}"/4A-assembly ]
        then mkdir ${myDir}/4A-assembly
fi

##Check if the output files exist and remove them if so
if [ -f "${myDir}"/4A-assembly/F_reads.fasta ]
	then rm ${myDir}/4A-assembly/F_reads.fasta
fi
if [ -f "${myDir}"/4A-assembly/R_reads.fasta ]
	then rm ${myDir}/4A-assembly/R_reads.fasta
fi

##Loop over each sample in turn
for sampleID in $sampleIDs
do

        ## write a script to the temp/ directory (one for each sample)
        scriptName=${myDir}/temp/${scriptBase}.${sampleID}.sh

        ## make an empty script for writing
        touch ${scriptName}

        ## write the SLURM parameters to the top of the script
        echo "#!/bin/bash" > ${scriptName}
        echo "#SBATCH --partition=${queue}" >> ${scriptName}
        echo "#SBATCH --mem-per-cpu=${mem}" >> ${scriptName}
        echo "#SBATCH --nodes=1" >> ${scriptName}
        echo "#SBATCH --tasks-per-node=${cpu}" >> ${scriptName}
        echo "#SBATCH --output ${myDir}/OUT/${scriptBase}${jobName}.%J" >> ${scriptName}
        echo "#SBATCH --error ${myDir}/ERR/${scriptBase}${jobName}.%J" >> ${scriptName}
	
	#Forward reads
	echo "zcat 2-trim/${sampleID}trim_1.fq.gz | sed 's/\ 1\:N\:0.*$/\/1/g' >  ${myDir}/4A-assembly/${sampleID}processed_1.fq" >> ${scriptName}

	#Repeat for reverse read
	echo "zcat 2-trim/${sampleID}trim_2.fq.gz | sed 's/\ 2\:N\:0.*$/\/2/g'>>  ${myDir}/4A-assembly/${sampleID}processed_2.fq" >> ${scriptName}

	chmod u+x ${scriptName}

        slurmids="${slurmids}:$(sbatch --parsable ${scriptName})"


done

#Create and run a slurm script to merge and remove the modified files
scriptName=${myDir}/temp/${scriptBase}.sh
touch ${scriptName}

echo "#!/bin/bash" > ${scriptName}
echo "#SBATCH --partition=defq" >> ${scriptName}
echo "#SBATCH --mem-per-cpu=${mem}" >> ${scriptName}
echo "#SBATCH --nodes=1" >> ${scriptName}
echo "#SBATCH --tasks-per-node=${cpu}" >> ${scriptName}
echo "#SBATCH --output ${myDir}/OUT/${scriptBase}${jobName}.%J" >> ${scriptName}
echo "#SBATCH --error ${myDir}/ERR/${scriptBase}${jobName}.%J" >> ${scriptName}

echo "
cat ${myDir}/4A-assembly/*1.fq > ${myDir}/4A-assembly/F_reads.fastq
cat ${myDir}/4A-assembly/*2.fq > ${myDir}/4A-assembly/R_reads.fastq
rm ${myDir}/4A-assembly/*processed*.fq
gzip ${myDir}/4A-assembly/*_reads.fastq
" >> ${scriptName}

chmod u+x ${scriptName}

sbatch -d afterok${slurmids} ${scriptName}

exit 0

