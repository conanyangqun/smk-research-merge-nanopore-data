# pipeline for merging nanopore data.
import glob
import os
import sys

import pandas as pd

# params.
info_file = config.get('info', '')
out_dir = config.get('out_dir', os.getcwd())
out_gz = True if config.get('out_gz', False) else False

# string templates.
out_sample_name = "{s_id}.tgs.fastq.gz" if out_gz else "{s_id}.tgs.fastq"
out_sample_md5 = out_sample_name + ".md5"

# read samples info, and check.
if info_file.endswith('.txt'):
    samples_df = pd.read_csv(info_file, sep='\t', na_filter=False)
elif info_file.endswith('.xlsx') or info_file.endswith('.xls'):
    samples_df = pd.read_excel(info_file, na_filter=False)
else:
    raise ValueError('info file wrong format.')

samples = {}
for i, row in samples_df.iterrows():
    s_id = row['sample_id']
    s_from_run = row['from_run']
    s_barcode = row['barcode']
    s_compress = row['compress']
    s_merged = row['merged']
    s_run_path = row['path']

    # get the right fastq list.
    s_fastqs = []

    if s_from_run not in ['Y', 'N']:
        print(f"Error: index {i} {s_id} from_run code {s_from_run} is wrong.")
        sys.exit(1)
    
    if s_from_run == 'Y':
        # sample data from run path.

        if ' ' in s_barcode:
            print(f"Error: index {i} {s_id} barcode {s_barcode} has space, please check.")
            sys.exit(1)
        
        barcoded_flag = True if s_barcode else False

        # with barcode, ignore merged flag.
        if not barcoded_flag and not s_merged in ['Y', 'N']:
            print(f"Error: index {i} {s_id}  merged code {s_merged} is wrong.")
            sys.exit(1)

        if not s_compress in ['Y', 'N']:
            print(f"Error: index {i} {s_id} compress code {s_compress} is wrong.")
            sys.exit(1)
        
        s_compress_flag = True if s_compress == 'Y' else False
        s_merged_flag = True if s_merged == 'Y' else False
        
        # without barcode, compress must be merged.
        if not s_barcode and s_compress_flag and not s_merged_flag:
            print(f"Error: {s_id} without barcode, compressed, but without merged, wrong!")
            sys.exit(1) 
        
        if s_barcode:
            # with barcode, ignore s_merge.
            s_fastq = os.path.join(s_run_path, 'barcode', s_barcode + '.fastq')
            s_fastq = s_fastq + '.gz' if s_compress_flag else s_fastq
            s_fastqs = [s_fastq]
        else:
            # no barcode.
            if s_merged_flag:
                # merged.
                s_fastq = os.path.join(s_run_path, 'fastq', 'result.fastq')
                s_fastq = s_fastq + '.gz' if s_compress_flag else s_fastq
                s_fastqs = [s_fastq]
            else:
                # a lot of small fastqs.
                for f in glob.glob(os.path.join(s_run_path, 'fastq', '*.fastq')):
                    s_fastqs.append(f)
    else:
        # sample data is not from run path. path is fastq path.
        s_fastqs = [s_path]
    
    # check all fastq files.
    for f in s_fastqs:
        if not os.path.isfile(f):
            print(f"Error: {s_id} fastq file {f} does not exist, please check!")
            sys.exit(1)
    
    # finish.
    if s_id in samples:
        samples[s_id].extend(s_fastqs)
    else:
        samples[s_id] = s_fastqs


# input function.
def find_fastq_files(wc):
    s_id = wc['s_id']
    assert s_id in samples
    return samples[s_id]

rule all:
    input:
        md5_files = expand(os.path.join(out_dir, '1.Rawdata', out_sample_md5), s_id=samples.keys()),
        nanostats_file = os.path.join(out_dir, '2.Report', 'all.nanostats.txt'),

rule merge_single_sample_data:
    input:
        fastqs = find_fastq_files,
    output:
        out_fastq = os.path.join(out_dir, '1.Rawdata', out_sample_name)
    params:
        out_cmd = "| gzip > " if out_gz else "> ",
    threads: 1
    resources: mem_mb = 2000
    shell:
        """
        echo "{input}" | tr ' ' '\n' | while read f
        do
          ext="${{f##*.}}"
          if [ ${{ext}} == "gz" ]
          then
              zcat ${{f}}
          elif [ ${{ext}} == "fastq" ]
          then
              cat ${{f}}
          else
              echo "${{f}} extension ${{ext}} can't be recognized."
              exit 1
          fi
        done  {params.out_cmd} {output.out_fastq}
        """

# generate MD5.
rule generate_md5:
    input:
        fastq = rules.merge_single_sample_data.output.out_fastq,
    output:
        md5_file = os.path.join(out_dir, '1.Rawdata', out_sample_md5)
    params:
        fastq_path = os.path.join(out_dir, '1.Rawdata'),
    threads: 1
    resources:
        mem_mb = 2000
    shell:
        """
        md5sum {input.fastq} | sed "s|{params.fastq_path}/||g" >{output.md5_file}
        """

# run nanostat on fastq.
rule run_nanostats:
    input:
        fastq = rules.merge_single_sample_data.output.out_fastq,
        r2c = workflow.source_path('scripts/r2c.awk'),
    output:
        nanostats_file = os.path.join(out_dir, '2.Report', '{s_id}.nanostats.txt'),
    params:
        out_dir = os.path.join(out_dir, '2.Report'),
        nanostats_file_name = '{s_id}.nanostats.txt',
    threads: 1
    shell:
        """
        (echo -e "sample\t{wildcards.s_id}";
        NanoStat \
            --fastq {input.fastq} \
            --outdir {params.out_dir} \
            -p {wildcards.s_id} \
            --tsv \
            | tail -n +2) \
            | awk -F '\t' -f {input.r2c} \
            >{output.nanostats_file}
        """

# merge all samples.
rule merge_all_nanostats:
    input:
        nanostats_files = expand(os.path.join(out_dir, '2.Report', '{s_id}.nanostats.txt'), s_id=samples.keys()),
    output:
        merged_nanostats = os.path.join(out_dir, '2.Report', 'all.nanostats.txt'),
    params:
        column_filter_num = '$1,$2,$3,$4,$5,$7,$9,$20,$21,$22,$8'
    threads: 1
    resources: mem_mb = 2000
    shell:
        """
        head -n 1 {input[0]} | awk -F '\\t' 'BEGIN {{OFS="\\t"}} {{print {params.column_filter_num} }}' \
            > {output.merged_nanostats}

        cat {input} | grep -v '^sample' | \
            awk -F '\\t' 'BEGIN {{OFS="\\t"}} {{$3=$3/1000000; print {params.column_filter_num} }}' \
            >>{output.merged_nanostats}
        """
