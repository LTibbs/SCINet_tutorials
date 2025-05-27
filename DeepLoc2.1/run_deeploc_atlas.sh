#!/bin/bash
#SBATCH -A $ACCOUNT  # Account name for the job
#SBATCH --partition=atlas  # Partition to submit the job
#SBATCH --job-name="deeploc"   #name of this job
#SBATCH --mem=20GB              # memory requested
#SBATCH --ntasks=8              # number of tasks
#SBATCH --nodes=1               # number of nodes requested
#SBATCH -t 24:00:00           # time allocated for this job hours:mins:seconds
#SBATCH -o log/%j_deeploc    # standard output, %j adds job number to output file name and %N adds the node name
#SBATCH --mail-user=$EMAIL  # email address to send updates
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL


date                          #optional, prints out timestamp at the start of the job in stdout file

# load and activate conda environment
module load miniconda3
source activate /project/maizegdb/ltibbs/conda_envs/deeploc2.1

# get arguments: input file (without the ".fa" ending), and model name
infile=$1
model=$2 

# set your desired working directory, where input files are found and outfiles will be placed
MYDIR=/your/input/directory/path # for example /90daydata/maizegdb/ltibbs/deeploc2.1/

mkdir ${MYDIR}/${infile}/
cd ${MYDIR}/${infile}/

# run deeploc
# model names (-m) are: Accurate or Fast
deeploc2 -f ${MYDIR}/${infile}.fa -o ${MYDIR}/${infile} -m ${model}

#End of file