#!/bin/bash
#SBATCH -A $ACCOUNT          # your group's account on Ceres, e.g. maizegdb
#SBATCH --job-name="EnTAP"   #name of this job
#SBATCH --qos=$MYQOS         # your group's partition, if applicable
#SBATCH -p ceres             #name of the partition (queue) you are submitting to
#SBATCH --mem=72GB           # memory requested
#SBATCH --ntasks=8           # number of threads requested
#SBATCH --nodes=1
#SBATCH -t 4:00:00           # about 3 hr per genome
#SBATCH -o "./log/%j_EnTAP"   # output log file
#SBATCH --mail-user=${EMAIL}  # email address to send updates
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL

date                          #optional, prints out timestamp at the start of the job in stdout file

ml rsem
ml diamond
ml transdecoder
ml gcc
module load miniconda
source activate ${PROJECTDIR}/eggnog/

cd ${PROJECTDIR}/EnTAP 

# run EnTAP 
# -i is the input cds.fa file, -d are the diamond database paths, and -t is the number of threads available
./EnTAP --runP -i ${WORKDIR}/Zm-B73-REFERENCE-NAM-5.0_Zm00001eb.1.canonical.cds.fa -d config_data/bin/refseq_plant.dmnd -d config_data/bin/uniprot_sprot.dmnd -t ${SLURM_CPUS_ON_NODE} 

# rename and remove the entap_outfiles folder to prevent interference with future runs
mkdir ${WORKDIR}/Zm-B73-REFERENCE_entap_outfiles
cp -r entap_outfiles ${WORKDIR}/Zm-B73-REFERENCE_entap_outfiles
rm -rf entap_outfiles

date                          #optional, prints out timestamp when the job ends
#End of file