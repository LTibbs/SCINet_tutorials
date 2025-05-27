# DeepLoc2.1 Setup and Usage on Atlas

This guide explains how to set up and run the program **DepLoc 2.1** to predict subcellular localization and membrane association of eukaryotic proteins on the SCINet Ceres HPC cluster. 

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
mv Zm-B73-REFERENCE-NAM-5.0_Zm00001eb.1.protein.fa B73.faa

# use faidx to calculate sequence length (output fai file includes sequence length in column 2)
samtools faidx B73.faa

# make input files for the short and long models
# Print the minimum length (column 2)
  awk '{print $2}' "B73.faa.fai" | sort -n | head -n 1

  # Extract long sequences (>1022)
  awk '$2 > 1022 {print $1}' "B73.faa.fai" > "$B73.long.seqs"
  samtools faidx "B73.faa" -r "B73.long.seqs" > "B73.long.faa"

  # Extract short sequences (10 < len ≤ 1022)
  awk '$2 > 9 && $2 <= 1022 {print $1}' "B73.faa.fai" > "B73.short.seqs"
  samtools faidx "B73.faa" -r "B73.short.seqs" > "B73.short.faa"
```

## DeepLoc setup
Enter your information and request to download DeepLoc 2.1 from https://services.healthtech.dtu.dk/cgi-bin/sw_request?software=deeploc&version=2.1&packageversion=2.1&platform=All.

