#!/bin/bash

##This script will download, back up and upzip your raw sequencing data. It relies on correctly setting the variables below. It will also set up the required directory structure for the project and start a report documenting the steps.

##Written by Sarah Christofides, 2022. Released under Creative Commons BY-SA.

###VARIABLES TO BE SET###
##Set path to working directory on scratch
SCRATCHPATH=/mnt/scratch/sbi9srj/Lama
##Paste in the URLs to your files here, e.g. DOWNLOADURL=("https://url1" "https://url2")
DOWNLOADURL=("https://leopard.bios.cf.ac.uk/nextcloud/index.php/s/1is4yv1R2tk2ukq")
#Set the slurm queue to use: defq for gomphus, epyc for iago, htc for hawk
queue=epyc
######

##Set up the directories: check if they exist and create them if not
DIRLIST=("4E-scaffolding" "4E-scaffolding/software")
for DIRECTORY in "${DIRLIST[@]}"
do 
	if [ ! -d "${SCRATCHPATH}/$DIRECTORY" ]; then
	  mkdir ${SCRATCHPATH}/${DIRECTORY}
	fi
done

##Download the programmes
## write a script to the temp/ directory
scriptName="${SCRATCHPATH}/temp/getSoftware.sh"

## remove the script if it exists already
rm -rf ${scriptName} || true

## make an empty script for writing
touch ${scriptName}

## write the SLURM parameters to the top of the script
echo "#!/bin/bash" >> ${scriptName}
echo "#SBATCH --partition=${queue}" >> ${scriptName}       # the requested queue
echo "#SBATCH --nodes=1" >> ${scriptName}      # number of nodes to use
echo "#SBATCH --tasks-per-node=1" >> ${scriptName}     #
echo "#SBATCH --cpus-per-task=1" >> ${scriptName}      #
echo "#SBATCH --mem-per-cpu=1000" >> ${scriptName}     # in megabytes, unless unit explicitly stated
echo "#SBATCH --error=${SCRATCHPATH}/ERR/software.%J" >> ${scriptName}     # redirect stderr to this file
echo "#SBATCH --output=${SCRATCHPATH}/OUT/software.%J" >> ${scriptName}    # redirect stdout to this file

##Download the software
echo -e "

cd ${SCRATCHPATH}/4E-scaffolding/software

#Download blat
if [ ! -f "${SCRATCHPATH}/4E-scaffolding/software/blat" ]
	then
	wget http://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/blat/blat 
#	sed -i '1d' ${SCRATCHPATH}/4E-scaffolding/software/blat
	chmod +x ${SCRATCHPATH}/4E-scaffolding/software/blat
fi

#Download L RNA Scaffolder
if [ ! -d "${SCRATCHPATH}/4E-scaffolding/software/L_RNA_scaffolder" ]
	then
	git clone https://github.com/CAFS-bioinformatics/L_RNA_scaffolder.git
	#wget https://github.com/CAFS-bioinformatics/L_RNA_scaffolder/tarball/master
fi

#Download pblat
if [ ! -d "${SCRATCHPATH}/4E-scaffolding/software/icebert-pblat-e26bf6b" ]
	then
	wget https://github.com/icebert/pblat/tarball/master
	tar -zxvf ${SCRATCHPATH}/4E-scaffolding/software/master
	cd ${SCRATCHPATH}/4E-scaffolding/software/icebert-pblat-e26bf6b/
	make
fi

echo 'Downloads complete'

exit 0" >> ${scriptName}

## make the script into an 'executable'
chmod u+x ${scriptName}

## submit the script to the compute queue
predec="$(sbatch --parsable ${scriptName})"

#Run blat
scriptName="${SCRATCHPATH}/temp/blat.sh"
##Create the empty script
touch ${scriptName}

## write the SLURM parameters to the top of the script
echo "#!/bin/bash" > ${scriptName}
echo "#SBATCH --partition=${queue}" >> ${scriptName}       # the requested queue
echo "#SBATCH --nodes=1" >> ${scriptName}      # number of nodes to use
echo "#SBATCH --tasks-per-node=1" >> ${scriptName}     #
echo "#SBATCH --cpus-per-task=1" >> ${scriptName}      #
echo "#SBATCH --mem-per-cpu=1000" >> ${scriptName}     # in megabytes, unless unit explicitly stated
echo "#SBATCH --error=ERR/blat.%J" >> ${scriptName}     # redirect stderr to this file
echo "#SBATCH --output=OUT/blat.%J" >> ${scriptName}    # redirect stdout to this file

echo "
cd ${SCRATCHPATH}/4E-scaffolding/software
#./blat ${SCRATCHPATH}/resources/UALgDiploT.01/GCA_014822095.1_UALgDiploT.01_genomic.fna ${SCRATCHPATH}/4C-evigene/Diplotaxis_tenuifolia_okay18.fasta -t=dna -q=dna -noHead -maxIntron=10000 -dots=500 output.psl
" >> ${scriptName}

##Make the script into an 'executable'
chmod u+x ${scriptName}
##Submit the script to the compute queue
predec2="$(sbatch -d afterok:${predec} --parsable ${scriptName})"

#Run L_RNA_scaffolder
scriptName="${SCRATCHPATH}/temp/scaffold.sh"
##Create the empty script
touch ${scriptName}

## write the SLURM parameters to the top of the script
echo "#!/bin/bash" > ${scriptName}
echo "#SBATCH --partition=${queue}" >> ${scriptName}       # the requested queue
echo "#SBATCH --nodes=1" >> ${scriptName}      # number of nodes to use
echo "#SBATCH --tasks-per-node=1" >> ${scriptName}     #
echo "#SBATCH --cpus-per-task=1" >> ${scriptName}      #
echo "#SBATCH --mem-per-cpu=1000" >> ${scriptName}     # in megabytes, unless unit explicitly stated
echo "#SBATCH --error=ERR/scaffold.%J" >> ${scriptName}     # redirect stderr to this file
echo "#SBATCH --output=OUT/scaffold.%J" >> ${scriptName}    # redirect stdout to this file

echo "
module load bioperl-live/release-1-7-2 
cd ${SCRATCHPATH}/4E-scaffolding/software
chmod -R +x ${SCRATCHPATH}/4E-scaffolding/software/L_RNA_scaffolder/
./L_RNA_scaffolder/L_RNA_scaffolder.sh -d ${SCRATCHPATH}/4E-scaffolding/software/L_RNA_scaffolder -i output.psl -j ${SCRATCHPATH}/resources/UALgDiploT.01/GCA_014822095.1_UALgDiploT.01_genomic.fna -p 0.9 -e 10000 1>lrna.out 2>lrna.err" >> ${scriptName}

##Make the script into an 'executable'
chmod u+x ${scriptName}
##Submit the script to the compute queue
sbatch -d afterok:${predec2} ${scriptName}

exit 0
