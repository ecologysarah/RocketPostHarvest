#!/bin/bash

#This script will index the reference genome and map reads to it using STAR. It relies on correctly setting the variables indicated below.
#Written by Sarah Christofides, 2022, based on a script from Rob Andrews. Released under Creative Commons BY-SA.

###VARIABLES TO BE SET###
#Set the path to your directory on scratch
myDir=/mnt/scratch/sbi9srj/Lama
#Set your username
userProject=sbi9srj
#Set the path to your reference genome directory, FASTA file and GTF/GFF file
GENOME=${myDir}/resources/UALgDiploT.01
FASTA=GCA_014822095.1_UALgDiploT.01_genomic.fna
GTF=
#Indicate if the data is single-end (SE) or paired-end (PE)
ends=PE
#Set the slurm queue to use: defq for gomphus, epyc for iago, htc for hawk
queue=epyc
######


sampleIDs=$(cat ${myDir}/1-download/SampleFileNames.txt)

mem="40G"
nodes="4"
runTime="02:00:00"
scriptBase="04map"

#Set the correct version of STAR
STAR=$(module avail -L star | tail -n 1)
##Append this information to the report
echo -e "\nReads mapped to genome with ${STAR}" >> ${myDir}/AnalysisReport.txt

#Make the output directory
if [ ! -d "${myDir}"/4-star ]
        then mkdir ${myDir}/4-star
fi

#Step1: Index the reference genome

scriptName=${myDir}/temp/${scriptBase}.index.sh
touch ${scriptName}

echo "#!/bin/bash" > ${scriptName}

echo "#SBATCH --partition=${queue}" >> ${scriptName} 
echo "#SBATCH --mem-per-cpu=40G" >> ${scriptName} 
echo "#SBATCH --nodes=1" >> ${scriptName}
echo "#SBATCH --tasks-per-node=4" >> ${scriptName}
echo "#SBATCH -o ${myDir}/OUT/${scriptBase}${jobName}.%J" >> ${scriptName}
echo "#SBATCH -e ${myDir}/ERR/${scriptBase}${jobName}.%J" >> ${scriptName}
echo "#SBATCH --job-name=index" >> ${scriptName}
echo "#SBATCH --account=${userProject}" >> ${scriptName}

echo "if [ ! -f ${GENOME}/SAindex ]; then

	module load ${STAR}

	STAR --runThreadN 4 --runMode genomeGenerate --genomeDir ${GENOME} --genomeFastaFiles ${GENOME}/${FASTA} --limitGenomeGenerateRAM 320000000000 --sjdbGTFfile ${GENOME}/${GTF} --sjdbGTFtagExonParentTranscript Parent

fi

exit 0" >> ${scriptName}

chmod u+x ${scriptName}

INDEXJOB=$(sbatch --parsable ${scriptName})

#Step 2: Map the samples against the genome
for sampleID in $sampleIDs
do
	scriptName=${myDir}/temp/${scriptBase}.${sampleID}.sh
	touch ${scriptName}

	echo "#!/bin/bash" > ${scriptName} 
        echo "#SBATCH --partition=${queue}" >> ${scriptName} 
        echo "#SBATCH --mem=${mem}" >> ${scriptName}
        echo "#SBATCH --nodes=1" >> ${scriptName}
        echo "#SBATCH --tasks-per-node=${nodes}" >> ${scriptName}
        echo "#SBATCH -t ${runTime}" >> ${scriptName}
        echo "#SBATCH -o ${myDir}/OUT/${scriptBase}${jobName}.%J" >> ${scriptName}
        echo "#SBATCH -e ${myDir}/ERR/${scriptBase}${jobName}.%J" >> ${scriptName}
        echo "#SBATCH --account=${userProject}" >> ${scriptName}

        echo "module load ${STAR}" >> ${scriptName}

	## run the star mapping command

	echo -n "STAR \
	--outSAMunmapped Within KeepPairs \
	--outMultimapperOrder Random \
	--outSAMmultNmax 1 \
	--runThreadN ${nodes} \
	--runMode alignReads \
	--quantMode GeneCounts \
	--outSAMtype BAM SortedByCoordinate \
	--outFileNamePrefix ${myDir}/4-star/${sampleID}onemap_ \
	--readFilesCommand zcat \
	--genomeDir ${GENOME} \
	--readFilesIn ${myDir}/2-trim/${sampleID}trim_1.fq.gz" >> ${scriptName} 
	if [ "${ends}" = PE ]; then echo " ${myDir}/2-trim/${sampleID}trim_2.fq.gz" >> ${scriptName}; fi
	
	echo -e "\nexit 0" >> ${scriptName}

	chmod u+x ${scriptName}

	sbatch -d afterok:${INDEXJOB} ${scriptName}
done

exit 0
