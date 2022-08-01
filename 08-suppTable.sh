#!/bin/bash

##This script will create a summary table and back up your completed analysis. It relies on correctly setting the three variables below. It will also set up the required directory structure for the project.

##Written by Sarah Christofides, 2022. Released under Creative Commons BY-SA.

###VARIABLES TO BE SET###
##Set path to directory for saving files (set as "" to omit this step)
SAVEPATH=""
##Set path to working directory on scratch
SCRATCHPATH=/mnt/clusters/gomphus/data/yourusername/yourproject
#Set whether you want to use the version of the data with duplicates kept (mark) or removed (rm)
DUP=mark
#Your username
userProject=
#Set the slurm queue to use: defq for gomphus or iago, htc for hawk
queue=defq
######

scriptName=${SCRATCHPATH}/temp/08-summaryArchive.sh

echo -e "#!/bin/bash
#SBATCH --partition=${queue}
#SBATCH --mem=2G
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH -t 02:00:00
#SBATCH -o $SCRATCHPATH/OUT/08-summaryArchive.%J
#SBATCH -e $SCRATCHPATH/ERR/08-summaryArchive.%J
#SBATCH --account=${userProject}" > ${scriptName}

##Create the summary table
echo "cd ${SCRATCHPATH}
sampleIDs=\$(cat 1-download/SampleFileNames.txt)" >> ${scriptName}

echo -e "echo -e SampleID\\tRawReads\\tReadsPassingQC\\tNumberUniquelyMapped\\tPercentUniquelyMapped\\tNumberMultimapped\\tPercentMultimapped\\tTotalMapped\\tPercentMapped\\tDeduplicatedAndMapped\\tPercentDupliction\\tEstLibSize\\tAssignedToGene\\tPercentAssignedToGene > SuppTable.txt" >> ${scriptName}

echo -e "
for sampleID in \$sampleIDs
do
nraw=\$(cat 3-fastqc/multiqc/Raw_multiqc_report_data/multiqc_general_stats.txt | grep \${sampleID}R1 | cut -f 6)
nstart=\$(cat 4-star/\${sampleID}onemap_Log.final.out | grep 'Number of input reads' | cut -f 2)
nuniq=\$(cat 4-star/\${sampleID}onemap_Log.final.out | grep 'Uniquely mapped reads number' |  cut -f 2)
puniq=\$(cat 4-star/\${sampleID}onemap_Log.final.out | grep 'Uniquely mapped reads %' | cut -f 2)
nmulti=\$(cat 4-star/\${sampleID}onemap_Log.final.out | grep 'Number of reads mapped to multiple loci' | cut -f 2)
pmulti=\$(cat 4-star/\${sampleID}onemap_Log.final.out | grep '% of reads mapped to multiple loci' | cut -f 2)
ntotal=\$((\$nuniq+\$nmulti))
ptotal=\$((\${ntotal}*100)) 
ptotal=\$(echo \$((\${ptotal} / \${nstart}))%)
ndedup=\$(cat 6-bamtools/\${sampleID}_rmdup_dupstats.txt | grep 'Total reads:' | awk '{print \$3}')
pdup=\$(cat 6-bamtools/\${sampleID}_markdup_dupstats.txt  | grep 'Duplicates:' | awk '{print \$3}' | sed -E 's/[\(\)]//g')
estlib=\$(cat 5-markduplicates/\${sampleID}_metrics_markdup.txt | grep -A 1 'ESTIMATED_LIBRARY_SIZE' | cut -f 10 | tail -n 1)
nassigned=\$(cat 7-featurecounts/\${sampleID}_${DUP}dup.featurecount.summary | grep 'Assigned' | awk '{print \$2}')
assigTot=\$(cat 7-featurecounts/\${sampleID}_${DUP}dup.featurecount.summary | awk '{sum+=\$2} END {print sum}')
passigned=\$(echo -e \$((\$nassigned*100/\$assigTot))%)

echo -e \$sampleID\\t\$nraw\\t\$nstart\\t\$nuniq\\t\$puniq\\t\$nmulti\\t\$pmulti\\t\$ntotal\\t\$ptotal\\t\$ndedup\\t\$pdup\\t\$estlib\\t\$nassigned\\t\$passigned >> SuppTable.txt
done
" >> ${scriptName}

##Back up the analysis
if [ ! "${SAVEPATH}" = "" ]; then echo "tar -cvf backup.tar --exclude={'1-download','temp','ERR','OUT'} $SCRATCHPATH" >> ${scriptName}; fi


chmod u+x ${scriptName}

sbatch ${scriptName}

exit 0

