#!/bin/bash
# this script must run outside containder.

bin_path=$(dirname "$(readlink -f "$0")")
sif_file="${bin_path}/sifs/packages.sif"

if [ $# -ne 3 ]
then
    echo "Usage: $0 <samples_info.txt> <out_dir> <data_path>"
    exit 1
fi

singularity exec \
    -e \
    -B "${bin_path}" \
    -B "$3" \
    ${sif_file} \
    snakemake \
    --cores 3 \
    -p \
    -s "${bin_path}/Snakefile" \
    --config info="$1" out_gz="True" out_dir="$2"
