# EnTAP Setup and Usage on Ceres

This guide explains how to set up and run **EnTAP** on the SCINet Ceres HPC cluster. EnTAP (Eukyarotic Non-Model Transcriptome Annotation Pipeline) is used for functional annotation of de novo transcriptomes in eukaryotes. Input file is a CDS fasta file for the genome.

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

# --version argument doesn't work with current diamond version on Ceres (as of May 2025),
# so need to make a wrapper script to work around it
# see EnTAP/diamond_wrapper.sh file,
# and if needed update the wrapper file with the current path and version of Diamond
# make the file executable:
ml diamond
chmod +x diamond_wrapper.sh
# you will also need to update the .ini file to point diamond-exe to this diamond wrapper script (see below for updating .ini file)

# use diamond to make databases:
diamond makedb --in test_data/uniprot_sprot.pep -d test_data/uniprot_sprot
diamond makedb --in test_data/refseq_plant.faa -d test_data/refseq_plant

# install Eggnog:
# load modules and conda environment
ml rsem
ml diamond
ml transdecoder
ml gcc
module load miniconda
source activate ${PROJECTDIR}/eggnog/
conda install bioconda::eggnog-mapper

```
## Update EnTAP config.ini and .param files
The default `entap_config.ini` file needs to be updated to include FULL paths to your databases, programs, etc. For example, I needed to set the path to my EnTAP binary database: `entap-db-bin=/project/maizegdb/ltibbs/EnTAP/config_data/bin/entap_database.bin`.  For help finding the location of a given program, for example emapper, try: `which emapper.py` which should output the location of the version of that program you are currently using.
Use `EnTAP/entap_config_example.ini` file as a model for your updated file.

In line 149 of the `entap_run.param` file, set what contaminants you want to search for and remove from the data. For example, in `Entap/entap_run_example.param` I set `contam=insecta,fungi,bacteria`.

## Configure EnTAP
Download and configure up-to-date EnTAP database.
```bash
# download
wget  https://treegenesdb.org/FTP/EnTAP/latest/databases/entap_database.bin.gz

# configure locally
./EnTAP --data-generate --config -d test_data/uniprot_sprot.pep --out-dir config_data/
./EnTAP --data-generate --config -d test_data/refseq_plant.faa --out-dir config_data/
```

## Example run of EnTAP
NOTE: each run of EnTAP will try to re-use output files from a previous run if they are still there. If you want to do a complete re-run, you'll need to remove (or move/rename) the full `entap_outfiles` folder.
```bash
# download B73 reference CDS to use as example input file:
cd ${WORKDIR}
wget https://download.maizegdb.org/Zm-B73-REFERENCE-NAM-5.0/Zm-B73-REFERENCE-NAM-5.0_Zm00001eb.1.canonical.cds.fa.gz
gunzip Zm-B73-REFERENCE-NAM-5.0_Zm00001eb.1.canonical.cds.fa.gz

# go to EnTAP directory
cd ${PROJECTDIR}/EnTAP 

# load modules and environment
ml rsem
ml diamond
ml transdecoder
ml gcc
module load miniconda
source activate ${PROJECTDIR}/eggnog/

# run EnTAP 
# -i is the input cds.fa file, -d are the diamond database paths, and -t is the number of threads available
./EnTAP --runP -i ${WORKDIR}/Zm-B73-REFERENCE-NAM-5.0_Zm00001eb.1.canonical.cds.fa -d config_data/bin/refseq_plant.dmnd -d config_data/bin/uniprot_sprot.dmnd -t ${SLURM_CPUS_ON_NODE} 

# rename and remove the entap_outfiles folder to prevent interference with future runs
mkdir ${WORKDIR}/Zm-B73-REFERENCE_entap_outfiles
cp -r entap_outfiles ${WORKDIR}/Zm-B73-REFERENCE_entap_outfiles
rm -rf entap_outfiles
```
To submit EnTAP run using SLURM script:
```bash
sbatch run_EnTAP.sh
```

For a single genome, EnTAP took about 3 hours and 64 GB of memory.
---

