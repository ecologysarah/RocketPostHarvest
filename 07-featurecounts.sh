#!/bin/bash

#This script will count the number of reads mapping to each gene. It relies on correctly setting the variables indicated below.
#Written by Sarah Christofides, 2022, based on a script from Rob Andrews. Released under Creative Commons BY-SA.

###VARIABLES TO BE SET###
#Set the path to your directory on scratch
myDir=/mnt/scratch/sbi9srj/Petrik2
#Set your username
userProject=sbi9srj
#Set whether you want to use the version of the data with duplicates kept (mark) or removed (rm)
DUP=mark
#Indicate if the data is single-end (SE) or paired-end (PE)
ends=SE
#Set the path to your reference genome directory, FASTA file and GTF/GFF file
GENOME=${myDir}/resources/GRCm39mouse
FASTA=GCF_000001635.27_GRCm39_genomic.fna
GTF=GCF_000001635.27_GRCm39_genomic.gff
#Set the slurm queue to use: defq for gomphus, epyc for iago, htc for hawk
queue=epyc
######

sampleIDs=$(cat ${myDir}/1-download/SampleFileNames.txt)

mem="4G"
nodes="2"
scriptBase="07counts"
runTime="00:20:00"

#Set the correct version of SAMtools
SAMTOOLS=$(module avail -L samtools | tail -n 1)
#Set the correct version of subread
SUBREAD=$(module avail -L subread | tail -n 1)

#Make the output directory
mkdir ${myDir}/7-featurecounts

#Count the reads for each feature in each sample
for sampleID in $sampleIDs
do
        scriptName=${myDir}/temp/${scriptBase}.${sampleID}.sh
        rm -rf ${scriptName} || true
        touch ${scriptName}

        echo "#!/bin/bash" >> ${scriptName}
        echo "#SBATCH --partition=${queue}" >> ${scriptName} #epyc
        echo "#SBATCH --mem=${mem}" >> ${scriptName}
        echo "#SBATCH --nodes=1" >> ${scriptName}
        echo "#SBATCH --tasks-per-node=${nodes}" >> ${scriptName}
        echo "#SBATCH -t ${runTime}" >> ${scriptName}
        echo "#SBATCH -o ${myDir}/OUT/${scriptBase}${jobName}.%J" >> ${scriptName}
        echo "#SBATCH -e ${myDir}/ERR/${scriptBase}${jobName}.%J" >> ${scriptName}
        echo "#SBATCH --account=${userProject}" >> ${scriptName}

        echo "module load ${SAMTOOLS}" >> ${scriptName}
        echo "module load ${SUBREAD}" >> ${scriptName}

        ## run featurecounts 

	echo "samtools sort -n ${myDir}/5-markduplicates/${sampleID}_${DUP}dup.bam -o ${myDir}/7-featurecounts/${sampleID}_${DUP}dup.sorted" >> ${scriptName}

	echo -n "cd ${myDir}/7-featurecounts/
	featureCounts " >> ${scriptName} 
        if [ "${ends}" = PE ]; then echo -n "-p " >> ${scriptName}; fi
	echo "-F GTF -t gene -g ID -a ${GENOME}/${GTF} -o ${myDir}/7-featurecounts/${sampleID}_${DUP}dup.featurecount ${myDir}/7-featurecounts/${sampleID}_${DUP}dup.sorted" >> ${scriptName}


        chmod u+x ${scriptName}

        sbatch ${scriptName}

done

exit 0

