## 合并数据流程操作SOP

以下操作以在容器中运行为例，介绍如何安装程序、合并数据。

### 准备安装包

1. 获取程序包`smk-research-merge-nanopore-data-vX.Y.Z.tar.gz`。例如`smk-research-merge-nanopore-data-v0.1.0.tar.gz`。
2. 获取程序运行环境`packages.sif`。
3. 打开终端，输入`cat /etc/os-release`，查看ubuntu系统的版本。若版本为`20.xx.xx`系列，需要获取`singularity-ce_4.3.1-focal_amd64.deb`文件。若版本为`22.xx.x`系列，需要获取`singularity-ce_4.3.1-jammy_amd64.deb`文件。

### 安装软件

1. 将文件`smk-research-merge-nanopore-data-v0.1.0.tar.gz`解压缩到合适的目录，例如`/home/yq/`。
2. 将运行环境`packages.sif`文件拷贝到程序目录下的`sifs`目录下，例如`/home/yq/smk-research-merge-nanopore-data-v0.1.0/sifs/`。
3. 确保机器处于联网状态。打开终端，若版本为`20.xx.xx`系列，执行命令：`sudo apt-get install ./singularity-ce_4.3.1-focal_amd64.deb`。若系统为版本为`22.xx.x`系列，执行命令：`sudo apt-get install ./singularity-ce_4.3.1-jammy_amd64.deb`。
4. 安装完毕后，在终端中执行命令`singularity --version`，测试是否安装成功。

### 日常操作

假如有数据需要合并，根据以下步骤执行。
1. 创建工作目录，例如`/xxx/2025-07-24`。
2. 根据下机数据填写信息表`samples_info.txt`。将该文件保存到工作目录下。
3. 确定需要挂载的数据目录。例如，如果数据存储在`/data/xxx`、`/data02/xxx/`等多个目录下，需要将这些目录传递给singularity，对应的值为`/data,/data02`
4. 在终端中输入`bash /home/yq/smk-research-merge-nanopore-data-v0.1.0/run.sh samples_info.txt test-out-dir /data,/data02`执行合并。`run.sh`需要3个参数，分别为信息表路径、输出目录、挂载的目录。
