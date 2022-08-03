#!/bin/bash

#This script will produced summary statistics for the mapping. It relies on correctly setting the variables indicated below.
#Written by Sarah Christofides, 2022, based on a script from Rob Andrews. Released under Creative Commons BY-SA.

###VARIABLES TO BE SET###
#Set the path to your directory on scratch
myDir=/mnt/scratch/sbi9srj/Petrik2
#Set your username
userProject="sbi9srj"
######

sampleIDs=`cat 1-download/SampleFileNames.txt`

mem="20G"
nodes="4"
runTime="00:05:00"
jobName="06bamstats"
scriptBase="06bamstats"

#Set the correct version of BAMtools
BAMTOOLS=$(module avail -L bamtools/ | tail -n 1)
#Set the correct version of multiqc
multiQC=$(module avail -L multiqc/ | tail -n 1)


#Make the output directory
mkdir ${myDir}/6-bamtools

#Run the process on each sample
for sampleID in $sampleIDs
do
        scriptName=${myDir}/temp/${scriptBase}.${sampleID}.sh
        touch ${scriptName}

        echo "#!/bin/bash" > ${scriptName}
        echo "#SBATCH --partition=epyc" >> ${scriptName}
        echo "#SBATCH --mem=${mem}" >> ${scriptName}
        echo "#SBATCH --nodes=1" >> ${scriptName}
        echo "#SBATCH --tasks-per-node=${nodes}" >> ${scriptName}
        echo "#SBATCH -t ${runTime}" >> ${scriptName}
        echo "#SBATCH -o ${myDir}/OUT/${jobName}.%J" >> ${scriptName}
        echo "#SBATCH -e ${myDir}/ERR/${jobName}.%J" >> ${scriptName}
        echo "#SBATCH --job-name=${jobName}" >> ${scriptName}
        echo "#SBATCH --account=${userProject}" >> ${scriptName}

        echo "module load ${BAMTOOLS}" >> ${scriptName}

        ## run bamtools 

        echo "bamtools stats -in ${myDir}/5-markduplicates/${sampleID}_markdup.bam > ${myDir}/6-bamtools/${sampleID}_markdup_dupstats.txt" >> ${scriptName}
        echo "bamtools stats -in ${myDir}/5-markduplicates/${sampleID}_rmdup.bam > ${myDir}/6-bamtools/${sampleID}_rmdup_dupstats.txt" >> ${scriptName}

        chmod u+x ${scriptName}

        sbatch ${scriptName}
done

#Create and run a slurm script that will do multiQC on the output
scriptName=${myDir}/temp/${jobName}.sh
touch ${scriptName}

echo "#!/bin/bash" > ${scriptName}
echo "#SBATCH --partition=epyc" >> ${scriptName}
echo "#SBATCH --mem-per-cpu=2" >> ${scriptName}
echo "#SBATCH --nodes=1" >> ${scriptName}
echo "#SBATCH --tasks-per-node=${nodes}" >> ${scriptName}
echo "#SBATCH --output ${myDir}/OUT/${scriptBase}${jobName}.%J" >> ${scriptName}
echo "#SBATCH --error ${myDir}/ERR/${scriptBase}${jobName}.%J" >> ${scriptName}

echo "module load ${multiQC}" >> ${scriptName}

#Run multiQC
echo "multiqc ${myDir}/6-bamtools -o ${myDir}/3-fastqc/multiqc/ -i MarkDuplicates" >> ${scriptName}

chmod u+x ${scriptName}

sbatch -d singleton ${scriptName}

exit 0
