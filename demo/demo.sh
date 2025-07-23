#!/bin/bash
# make toy data and test.

binpath="$(dirname $(readlink -f $0))"
demo="${binpath}/demo.txt"

cut -f6-8 "${demo}" | tail -n +2 | while read run_name read_str fastq_name
do
    mkdir -p "${run_name}/fastq"
    mkdir -p "${run_name}/barcode"
    
    ext="${fastq_name##*.}"
    if [ ${ext} == "gz" ]
    then
        echo -e "${read_str}" | gzip >"${run_name}/${fastq_name}"
    elif [ ${ext} == "fastq" ]
    then
        echo -e "${read_str}" >"${run_name}/${fastq_name}"
    else
        echo "${ext} can't be recognized."
        exit 1
    fi
done

cut -f1-6 "${demo}">samples_info.txt

echo "Finish making demo."
