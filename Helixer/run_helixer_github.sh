#!/bin/bash
#SBATCH -A $ACCOUNT               # Account name for the job
#SBATCH --partition=gpu-a100  #gpu-a100-mig7              # Partition to submit the job (can use either one for A100 GPUs)
#SBATCH --job-name=helixer_gpu               # Name of the job
#SBATCH --output=./log/helixer.%J.out     # output log file with job ID
#SBATCH -t 5:00:00                       # Maximum runtime: B73 example takes under 5 hours with these settings
#SBATCH --mem=14GB                        # Allocate memory
#SBATCH --ntasks-per-node=6               # Number of tasks (using 2 CPU cores here)
#SBATCH --gres=gpu:1                     # Request 1 GPU resource
#SBATCH --mail-user=$EMAIL              # email address to send updates
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL

date

module load apptainer
module load miniconda3

# set the directory where your helixer environment is located
export PROJECTDIR=/your/project/directory/path 
# activate environment
source activate $PROJECTDIR/helixer_gpu_env 

# set directories needed for Helixer Apptainer run
export TMPDIR=$PROJECTDIR/apptainer
export APPTAINER_CACHEDIR=$TMPDIR
export APPTAINER_TMPDIR=$TMPDIR

# read in command line arguments 
genome=$1 # Zm-B73-REFERENCE-NAM-5.0.fa
output=$2 # B73-helixer.gff
species=$3 #"Zea mays subsp. mays"

# run Helixer
singularity exec --bind ${WORKDIR} --nv $TMPDIR/helixer.sif Helixer.py --lineage land_plant --fasta-path ${genome} --species "${species}" --gff-output-path ${output}   

conda deactivate

date                          #optional, prints out timestamp when the job ends
#End of file
