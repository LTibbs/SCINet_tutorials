# DeepLoc2.1 Setup and Usage on Atlas

This guide explains how to set up and run the program **DeepLoc 2.1** to predict subcellular localization and membrane association of eukaryotic proteins on the SCINet Atlas HPC cluster. 

For more information about DeepLoc see https://services.healthtech.dtu.dk/services/DeepLoc-2.1/, where a webserver allows prediction of up to 500 proteins at a time. To predict a full proteome on a server or personal machine, an academic download of DeepLoc 2.1 is available from https://services.healthtech.dtu.dk/cgi-bin/sw_request?software=deeploc&version=2.1&packageversion=2.1&platform=All.

---

## Sequence preparation
DeepLoc 2.1 has two models available: slow (also called "accurate") and fast. The maximum protein length for the fast model is 1022. Therefore, we will split our proteome into short sequences (≤1022 residues, suitable for the fast model) and long sequences (need to use the slow model). Also, neither model accepts sequences <10 residues, so we will check for and exclude those. Using the B73 genome from MaizeGDB as an example:
```bash
# load modules
module load samtools
module load seqkit

# download genome, unzip, and rename it
wget https://download.maizegdb.org/Genomes/B73/Zm-B73-REFERENCE-NAM-5.0/Zm-B73-REFERENCE-NAM-5.0_Zm00001eb.1.protein.fa.gz
gunzip Zm-B73-REFERENCE-NAM-5.0_Zm00001eb.1.protein.fa.gz
mv Zm-B73-REFERENCE-NAM-5.0_Zm00001eb.1.protein.fa B73.fa

# use faidx to calculate sequence length (the output .fai file includes sequence length in column 2)
samtools faidx B73.fa

# make input files for the short and long models
# Print the minimum length (column 2)
# this will show you if any sequences are less than 10 residues and therefore cannot be analyzed by DeepLoc
  awk '{print $2}' "B73.fa.fai" | sort -n | head -n 1

  # Extract long sequences (>1022)
  awk '$2 > 1022 {print $1}' B73.fa.fai > B73.long.seqs
  samtools faidx B73.fa -r B73.long.seqs > B73.long.fa


  # Extract short sequences (10 < len ≤ 1022)
  awk '$2 > 9 && $2 <= 1022 {print $1}' B73.fa.fai > B73.short.seqs
  samtools faidx "B73.fa" -r B73.short.seqs > B73.short.fa
```

## DeepLoc setup
Enter your information and request to download DeepLoc 2.1 from https://services.healthtech.dtu.dk/cgi-bin/sw_request?software=deeploc&version=2.1&packageversion=2.1&platform=All. This will give you a download called deeploc-2.1.All.tar.gz.

```bash
# set working directory (usually 90daydata, for shorter-term storage) and project directory (project, for longer storage)
export WORKDIR=/your/working/directory/path        # e.g., /90daydata/user/deeploc
export PROJECTDIR=/your/project/directory/path     # e.g., /project/labname/user

# load modules and create conda environment
# using the deeploc2.1_atlas.yml file
module load miniconda3
conda env create -f deeploc2.1_atlas.yml -p ${PROJECTDIR}/deeploc2.1
source activate ${PROJECTDIR}/deeploc2.1
cd ${PROJECTDIR}/deeploc2.1

# Now, make sure the deeploc-2.1.All.tar.gz that you downloaded is uploaded to ${PROJECTDIR}/deeploc2.1
which pip # check that this is the conda version of pip to ensure correct installation
python -m pip install deeploc-2.1.All.tar.gz # use to install deeploc

# first run: DeepLoc will be installing the models, so need to make sure they're installed in the right place:
mkdir ${PROJECTDIR}/torch_cache
mkdir ${PROJECTDIR}/huggingface_cache
export TORCH_HOME=${PROJECTDIR}/torch_cache
export HF_HOME=${PROJECTDIR}/huggingface_cache

# quick test: extract the test.fasta file from the deeploc-2.1.All.tar.gz download and use it to run a test
# these test runs will also download the Fast and Accurate models automatically
# -f: provide the input fasta file name; -o: provide the output folder name; -m: provide the model (Fast or Accurate)
deeploc2 -f test.fasta -o test.fast -m Fast # compare output with results_testfast.csv 
deeploc2 -f test.fasta -o test.accurate -m Accurate # compare output with results_testaccurate.csv 
```

## Run DeepLoc
Use the `run_deeploc_atlas.sh` file to submit slurm jobs to run DeepLoc on full proteomes. Running `B73.short` with the `Fast` model takes about 37 hours and 13GB. Running `B73.long` with the `Accurate` model takes about 13 hours and 15GB.

```bash
# for the B73 example: run this in the same directory with `B73.short.fa` and `B73.long.fa`
# NOTE: need to edit run_deeploc_atlas.sh in lines 19-20 based on your directory structure
# as well as your account and email information in lines 2 and 10
# first argument: input file base name (no .fa), which will also be the name of the output folder
# second argument: desired model (Fast for short sequences or Accurate for long sequences)
sbatch run_deeploc_atlas.sh B73.short Fast
sbatch run_deeploc_atlas.sh B73.long Accurate 
```

## Combine results of both models
This takes results files stored in `prefix.long` and `prefix.short` subfolders and combines them into a single results `.csv ` file.
```bash
for prefix in $(find . -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | cut -d. -f1 | sort -u); do
output_file="${prefix}.results.csv"
first=1
reference_header=""

for subdir in ${prefix}.*; do
csv_file=$(find "$subdir" -maxdepth 1 -type f -name 'results_*.csv')

if [[ -f "$csv_file" ]]; then
current_header=$(head -n 1 "$csv_file")

if [[ $first -eq 1 ]]; then
reference_header="$current_header"
cat "$csv_file" > "$output_file"
first=0
else
  if [[ "$current_header" != "$reference_header" ]]; then
echo "Header mismatch in $csv_file — skipping!" >&2
continue
fi
tail -n +2 "$csv_file" >> "$output_file"
fi
else
  echo "No results_*.csv in $subdir" >&2
fi
done

echo "Written $output_file"
done

```

