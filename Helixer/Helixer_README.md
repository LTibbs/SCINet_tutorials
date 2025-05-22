# Helixer Setup and Usage on Atlas

This guide explains how to set up and run **Helixer** for gene annotation on GPUs on the SCINet Atlas HPC cluster. 

The Helixer workflow is based on the tutorial at https://rcac-bioinformatics.readthedocs.io/en/latest/helixer.html. For more information abot Helixer see https://github.com/weberlab-hhu/Helixer.

---

## Directory setup
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
Run on GPUs via SLURM script
```bash
sbatch run_helixer_github.sh Zm-B73-REFERENCE-NAM-5.0.fa B73-helixer.gff "Zea mays subsp. mays" # provide input and output file names as well as species name
```
Check output:
```bash
grep -v "^#" B73-helixer.gff | cut -f 3 | sort | uniq -c
```

Expected output:
```
2419488  CDS
241560  exon
 52607  five_prime_UTR
 41923  gene
 41923  mRNA
 52298  three_prime_UTR
```

## Post-processing: Sanitize and standardize GFF, extract CDS and PEP sequences
Sanitize GFF3 with GenomeTools (https://genometools.org/). This sorts the GFF3 features and tidies. `-force` forces writing to an output file.
```bash
ml genometools

gff3_file=B73-helixer.gff # set gff file input
gt gff3 -sort -tidy -setsource "helixer" -force -o B73-helixer_gt.gff3 $gff3_file
```
Standardize with AGAT (https://github.com/NBISweden/AGAT). This removes duplicate features, fixes duplicated IDs, etc. to turn any GFF file into a full sorted GFF file.
```bash
conda install -c bioconda agat # install agat into your conda environment
agat_convert_sp_gxf2gxf.pl -g B73-helixer_gt.gff3 -o B73-helixer_v1.0.gff3
```
Extract CDS and peptide (PEP) sequences using cufflinks (https://github.com/cole-trapnell-lab/cufflinks?tab=readme-ov-file).
```bash
conda install bioconda::cufflinks # install cufflinks into your conda environment
gffread B73-helixer_v1.0.gff3 \
        -g Zm-B73-REFERENCE-NAM-5.0.fa \
        -x B73-helixer_v1.0.cds.fasta \
        -y B73-helixer_v1.0.pep.fasta
```
---

