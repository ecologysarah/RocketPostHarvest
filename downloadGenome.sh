#!/bin/bash 
#SBATCH -p defq
#SBATCH --mem-per-cpu=4G
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --output OUT/genome.%J
#SBATCH --error ERR/genome.%J 
#SBATCH --job-name=genome
#SBATCH --account=sbi9srj

#Set the name of your species
speciesName="Diplotaxis tenuifolia"
#Set the name of your genome. Do not include spaces/special characters, as this will be the directory name
genomeName=UALgDiploT.01
#Set your working directory
myDir=/mnt/scratch/sbi9srj/Lama


#Check for and create output directory
if [ ! -d "${myDir}"/resources/${genomeName} ]
        then mkdir -p ${myDir}/resources/${genomeName}
fi

cd ${myDir}/resources/${genomeName}

#Download FASTA
curl -sLO https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/014/822/095/GCA_014822095.1_UALgDiploT.01/GCA_014822095.1_UALgDiploT.01_genomic.fna.gz

#Download GFF
curl -sLO https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/014/822/095/GCA_014822095.1_UALgDiploT.01/GCA_014822095.1_UALgDiploT.01_genomic.gbff.gz

#Download md5checksums
curl -slO https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/014/822/095/GCA_014822095.1_UALgDiploT.01/md5checksums.txt

#Check the md5sums
touch ${myDir}/resources/md5checklist.txt
ls ${myDir}/resources/${genomeName} | while read file;do 
	local=$(md5sum ${myDir}/resources/${genomeName}/${file})
	remote=$(grep ${myDir}/resources/${genomeName}/${file} md5checksums.txt)
	if [ ${local} == ${remote} ]
       	then 
		echo "${file} TRUE" >> ${myDir}/resources/md5checklist.txt
       	else 
		echo "${file} FALSE" >> ${myDir}/resources/md5checklist.txt
       	fi
done

result=$(grep -c "FALSE" ${myDir}/resources/md5checklist.txt)

if [ result == 0 ]
then 
	echo "Non-matching md5 sums"
	exit 1
fi

#Unzip the files
gunzip *

echo -e "\nReference genome ${genomeName} downloaded for ${speciesName}" >> ${myDir}/AnalysisReport.txt

exit 0
