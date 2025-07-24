# smk-research-merge-nanopore-data
A toy pipeline for merging nanopore raw data, written using snakemake.

### 描述

这是一个用于合并纳米孔测序下机数据的简单流程，以snakemake编写，主要面向缺少linux基本操作的实验人员。

鉴于本流程主要是内部使用，因此版本号采用`0.y.z`形式。若后续情况发生变化，需要正式发布时，`1.0.0`作为第一个发行版。

### 应用场景

本流程主要解决样本下机数据的合并、压缩、哈希和生成等问题。对合并后的数据用`nanostats`统计，提取部分关键信息。特别的，某个样本可能会跨多个时间段、在多张芯片上测序。

下机数据run的目录结构如下：

```
a/b/h5/ResultFiles/
    fastq
    barcode
```

基本情况如下：
- 未添加barcode。测序软件选择“合并”时，会在`fastq`目录下生成`result.fastq`文件。选择“合并+压缩”时，会在`fastq`目录下生成`result.fastq.gz`文件。“不合并”，则在`fastq`目录下为小型的fastq文件。“不合并 + 压缩”，未测试。本程序会提示“错误逻辑”。注意，合并成功后会删除所有的小fastq文件。
- 添加了barcode。不压缩，在`barcode`目录下生成`<barcode>.fastq`文件。压缩，则生成`<barcode>.fastq.gz`文件。忽略“合并与否”。

### 软件安装

有两种方式。
- 方式1。通过`singularity`容器运行。需要在机器上安装`singularity`软件，镜像`packages.sif`中打包了`snakemake, pandas, nanostat`等软件。具体见[docs/sop.md]。
- 方式2。机器上安装`snakemake, pandas, nanostat`等软件后，直接运行。

### 基本用法

- 建立信息表。支持excel、txt（tab分隔）两种格式。
- 执行合并程序。

### 信息表

信息表主要包含以下字段，用于控制合并的数据来源。
- `sample_id`。具有相同ID的样本最后会合并成单个样本。最终输出文件命名为：`<sample_id>.tgs.fastq.gz`或者`<sample_id>.tgs.fastq`。
- `from_run`。填写该数据是否来自标准的测序路径。`Y`表示来自标准的测序路径，`N`表示不是来自标准的测序路径。注意，填写`N`时，`path`列为fastq文件的绝对路径。
- `barcode`。只在`from_run = "Y"`时有效。与`path`配合寻找对应的数据文件。注意区分大小写。例如：`BC01.fastq`。
- `merged`。只在`from_run = "Y"`时有效。填`Y`时，表示下机数据合并，`N`表示不合并。若填写了`barcode`，则不考虑此字段。
- `compress`。只在`from_run = "Y"`时有效。填`Y`时表示数据压缩，`N`表示数据不压缩。
- `path`。若数据来自标准的测序路径（`from_run = "Y"`），此参数需要填数据路径到`ResultFiles`目录。例如：`/xxx/h5/ResultFiles`。若数据不是来自标准的测序路径（`from_run = "N"`），此路径为fastq文件的绝对路径。

**数据来自标准的测序路径时，以上参数组合实现的寻找fastq文件的规则如下**：

barcode|merged|compress|寻找的fastq文件
---|---|---|---
|N|N|fastq目录下所有`*.fastq`文件
|Y|N|fastq目录下`result.fastq`文件
|Y|Y|fastq目录下`result.fastq.gz`文件
`<XXX>`||N|barcode目录下`<XXX>.fastq`文件
`<XXX>`||Y|barcode目录下`<XXX>.fastq.gz`文件

注意事项如下：
- `barcode`为空、`compress = Y`时，必须设置`merged = Y`。
- `barcode`不能包含空格。

**数据来自非标准的测序路径时（`from_run == N`），直接获取`path`处的fastq文件。

对于找到的所有fastq文件，程序会检查其是否存在。参考[demo.txt](demo/demo.txt)文件。

### 程序参数

基本用法为：

```bash
singularity exec -e \
    /xxx/packages.sif \
    snakemake \
    --cores 3 \
    -p \
    -s /xxx/smk-research-merge-nanopore-data/Snakefile \
    --config info=/xxx/samples_info.txt [out_dir="/xxx"] [out_gz="True"]
```

其中`--config`指定配置参数。具体如下：
- `info`，设置信息表的路径，必填参数。
- `out_dir`，指定输出目录，可选参数。未指定时在当前工作目录输出。
- `out_gz`，设置输出文件是否用`gzip`压缩，可选参数，设置时压缩，不设置时不压缩。

**对于缺少linux基础操作的人员，可以参考[docs/sop.md](docs/sop.md)，运行`run.sh`这个脚本**。

~~### demo数据测试~~

**此部分内容废弃**！

以容器运行为例。

创建测试目录。`mkdir test && cd test`。

生成测试数据。程序会在当前目录生成测试数据，并创建`samples_info.txt`文件。

```bash
singularity exec -e \
    /home/qitan/smk-research-merge-nanopore-data.v0.1.0.sif \
    bash /biosrc/smk-research-merge-nanopore-data/demo/demo.sh
```

运行。运行成功后，程序在当前目录下生成`S01.tgs.fastq, S01.tgs.fastq.md5`文件。

```
singularity exec -e \
    /home/qitan/smk-research-merge-nanopore-data.v0.1.0.sif \
    snakemake \
    --cores all \
    -p \
    -s /biosrc/smk-research-merge-nanopore-data/Snakefile \
    --config info=samples_info.txt
```





