# EnTAP Setup and Usage on Ceres

This guide explains how to set up and run **EnTAP** on the SCINet Ceres HPC cluster. EnTAP (Eukyarotic Non-Model Transcriptome Annotation Pipeline) is used for functional annotation of de novo transcriptomes in eukaryotes.

For more information abot EnTAP see https://entap.readthedocs.io/en/latest/index.html and https://gitlab.com/PlantGenomicsLab/EnTAP.

---

## Directory setup
Define these two variables in your shell or script to simplify paths throughout this guide:
```bash
# set working directory (usually 90daydata, for shorter-term storage) and project directory (project, for longer storage)
export WORKDIR=/your/working/directory/path        # e.g., /90daydata/user/EnTAP_runs
export PROJECTDIR=/your/project/directory/path     # e.g., /project/labname/user
```

## Download and set up EnTAP and needed files
```bash
cd ${PROJECTDIR}
git clone https://github.com/harta55/EnTAP.git
cd EnTAP

# download required interproscan files
mkdir interproscan
cd interproscan
wget https://ftp.ebi.ac.uk/pub/software/unix/iprscan/5/5.66-98.0/interproscan-5.66-98.0-64-bit.tar.gz
wget https://ftp.ebi.ac.uk/pub/software/unix/iprscan/5/5.66-98.0/interproscan-5.66-98.0-64-bit.tar.gz.md5

# Recommended checksum to confirm the download was successful:
md5sum -c interproscan-5.66-98.0-64-bit.tar.gz.md5
# Must return *interproscan-5.66-98.0-64-bit.tar.gz: OK*
tar -pxvzf interproscan-5.66-98.0-*-bit.tar.gz

# and set up interproscan
ml python_3
cd interproscan-5.66-98.0
python3 setup.py -f interproscan.properties

#Entap installation: back in EnTAP folder
cd ${PROJECTDIR}/EnTAP
ml cmake
ml gcc
#generate makefile:
cmake CMakeLists.txt
#then make:
make

# Get uniprot databases:
wget ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz

# Get pfam database:
wget https://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.fasta.gz

# Get plant databases using NCBI-genome-download bioconda package
module load miniconda
# first time only: create conda environment and install package:
conda create --prefix ${PROJECTDIR}/ncbi_genome_download/
conda install bioconda::ncbi-genome-download
# every time, activate the conda environment:
source activate ${PROJECTDIR}/ncbi_genome_download/
# continue to download ncbi plant databases in desired folder:
mkdir ncbi
cd ncbi
ncbi-genome-download --formats=protein-fasta plant
cd refseq
# combine and compress all files:
find plant -type f -name "*.faa.gz" -exec gzip -cd {} + > refseq_plant.faa
mv all_refseq_plant_proteins.faa ${PROJECTDIR}/EnTAP/test_data/refseq_plant.faa
# these have unusual line breaks, so fix that:
# check how many sequences in file:
cd ${PROJECTDIR}/EnTAP/
grep -c "^>" test_data/refseq_plant.faa     
# 2146352
# fix lines:
awk '/^>/ {if (seq) print seq; print; seq=""} /^[^>]/ {seq = seq $0} END {if (seq) print seq}' test_data/refseq_plant.faa > test_data/refseq_plant_oneline.faa
# check number of sequences again, does it match?
grep -c "^>" test_data/refseq_plant_oneline.faa     
# 2146352 - yes, it matches. Good. Now, rename to the expected name for this database.
mv test_data/refseq_plant_oneline.faa test_data/refseq_plant.faa 
```

## 


---

