# Helixer Setup and Usage on Atlas

This guide explains how to set up and run **Helixer** for gene annotation on GPUs on the SCINet Atlas HPC cluster.

---

## Directory Setup

Define these two variables in your shell or script to simplify paths throughout this guide:

```bash
# Customize these
export WORKDIR=/your/working/directory/path        # e.g., /90daydata/user/helixer_runs
export PROJECTDIR=/your/project/directory/path     # e.g., /project/labname/user
```

## Download and set up Helixer using Apptainer
```bash
module load apptainer
export TMPDIR=$PROJECTDIR/apptainer
export APPTAINER_CACHEDIR=$TMPDIR
export APPTAINER_TMPDIR=$TMPDIR

apptainer pull docker://gglyptodon/helixer-docker:helixer_v0.3.3_cuda_11.8.0-cudnn8
cp helixer-docker_helixer_v0.3.3_cuda_11.8.0-cudnn8.sif $TMPDIR/helixer.sif

# Download trained models
cd $TMPDIR
apptainer exec helixer.sif fetch_helixer_models.py --all
```

## Create conda environment in project directory
This `yml` file contains packages needed to run on the Atlas GPU.
```bash
module load miniconda3
conda env create -f helixer_gpu_env.yml -p $PROJECTDIR/helixer_gpu_env
source activate $PROJECTDIR/helixer_gpu_env
```

## Run with an example genome
Here, I used the maize B73 genome, downloaded from MaizeGDB.org.

Create directory, then download and unzip B73 genome:
```bash
cd $WORKDIR
mkdir B73_example && cd B73_example
wget https://download.maizegdb.org/Zm-B73-REFERENCE-NAM-5.0/Zm-B73-REFERENCE-NAM-5.0.fa.gz
gunzip Zm-B73-REFERENCE-NAM-5.0.fa.gz
```
Run Helixer on example:
```bash
# set variables
genome=Zm-B73-REFERENCE-NAM-5.0.fa
species="Zea mays subsp. mays"
output=B73-helixer.gff

singularity exec --bind $WORKDIR --nv $TMPDIR/helixer.sif \
  Helixer.py --lineage land_plant \
             --fasta-path $genome \
             --species "$species" \
             --gff-output-path $output
```
---
