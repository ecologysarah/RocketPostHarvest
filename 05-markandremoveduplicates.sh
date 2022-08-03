#!/bin/bash

#This script will identify duplicated reads in the BAM files produced by STAR. It produces two versions of the output: one with duplicates marked and retained, and one with duplicates removed. It relies on correctly setting the variables indicated below.
#Written by Sarah Christofides, 2022, based on a script from Rob Andrews. Released under Creative Commons BY-SA.

###VARIABLES TO BE SET###
#Set the path to your directory on scratch (do not end with a /)
myDir=/mnt/scratch/sbi9srj/Petrik2
#Set your username
userProject=sbi9srj
#Set the slurm queue to use: defq for gomphus, epyc for iago, htc for hawk
queue=epyc
######

sampleIDs=$(cat ${myDir}/1-download/SampleFileNames.txt)

mem="30G"
nodes="2"
runTime="00:20:00"
scriptBase="05markdup"

#Set the correct version of picard
PICARD=$(module avail -L picard/ | tail -n 1 | sed -E 's/\s+//')
#Set the correct version of SAMtools
SAMTOOLS=$(module avail -L samtools/ | tail -n 1)
JAVA=$(module avail -L java/ | tail -n 1)

#Make the output directory
if [ ! -d "${myDir}"/5-markduplicates ]
        then mkdir ${myDir}/5-markduplicates
fi

#Run the process for each sample
for sampleID in $sampleIDs
do
        scriptName=${myDir}/temp/${scriptBase}.${sampleID}.sh
        rm -rf ${scriptName} || true
        touch ${scriptName}

        echo "#!/bin/bash" >> ${scriptName}
        echo "#SBATCH --partition=${queue}" >> ${scriptName}
        echo "#SBATCH --mem=${mem}" >> ${scriptName}
        echo "#SBATCH --nodes=1" >> ${scriptName}
        echo "#SBATCH --tasks-per-node=${nodes}" >> ${scriptName}
        echo "#SBATCH -t ${runTime}" >> ${scriptName}
        echo "#SBATCH -o ${myDir}/OUT/${scriptBase}.%J" >> ${scriptName}
        echo "#SBATCH -e ${myDir}/ERR/${scriptBase}.%J" >> ${scriptName}
        echo "#SBATCH --account=${userProject}" >> ${scriptName}

        echo "module load ${PICARD}" >> ${scriptName}
        echo "module load ${JAVA}" >> ${scriptName}
        echo "module load ${SAMTOOLS}" >> ${scriptName}

        ## run the markduplicate and samtools sort commands

	echo "java -jar /trinity/shared/apps/site-local/${PICARD}/picard.jar MarkDuplicates \
	I=${myDir}/4-star/${sampleID}onemap_Aligned.sortedByCoord.out.bam \
	O=${myDir}/5-markduplicates/${sampleID}_markdup.bam \
	M=${myDir}/5-markduplicates/${sampleID}_metrics_markdup.txt \
	REMOVE_DUPLICATES=false \
	VALIDATION_STRINGENCY=SILENT" >> ${scriptName}

	echo "java -jar /trinity/shared/apps/site-local/${PICARD}/picard.jar MarkDuplicates \
	I=${myDir}/4-star/${sampleID}onemap_Aligned.sortedByCoord.out.bam \
	O=${myDir}/5-markduplicates/${sampleID}_rmdup.bam \
	M=${myDir}/5-markduplicates/${sampleID}_metrics_rmdup.txt \
	REMOVE_DUPLICATES=true \
	VALIDATION_STRINGENCY=SILENT" >> ${scriptName}

	echo "samtools index ${myDir}/5-markduplicates/${sampleID}_markdup.bam" >> ${scriptName}
	echo "samtools index ${myDir}/5-markduplicates/${sampleID}_rmdup.bam" >> ${scriptName}

        chmod u+x ${scriptName}

        sbatch ${scriptName}
done

exit 0
