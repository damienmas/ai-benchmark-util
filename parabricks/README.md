# Parabricks utility

## Provides an easy way to start and tests parabricks pipeline using slurm cluster

### Prerequisites

* Access to the internet
* nvidia-driver that supports cuda-10.0
* singularity version 2.6.1 or higher
* Python 3
* curl, wget
* git
* Isilon / PowerScale

### Copy the git repository into your isilon share

```bash
sudo mkdir /mnt/isilon
sudo mount -t nfs <ISILON_IP/FQDN>:<NFS_EXPORT_NAME> /mnt/isilon
cd /mnt/isilon
mkdir data
cd data
git clone https://github.com/damienmas/ai-benchmark-util.git
```

## On every worker nodes

worker node means server with GPU cards

### Install Singularity

```bash
# For complete list of servers : http://neuro.debian.net
# for some reasons the US-CA server didn't work for me on Ubuntu 18.04 ...
wget -O- http://neuro.debian.net/lists/bionic.de-m.full | sudo tee /etc/apt/sources.list.d/neurodebian.sources.list
sudo apt-key adv --recv-keys --keyserver hkp://pool.sks-keyservers.net:80 0xA5D32F012649A5A9
sudo apt-get update
sudo apt-get install singularity-container
singularity --version
```

### Install Test Driver Script Prerequisites

```bash
sudo apt install python3-pip
cd ai-benchmark-util/parabricks
pip3 install setuptools
pip3 install --requirement requirements.txt
sudo timedatectl set-timezone UTC
```

## On a single worker node

### Configure the slurm cluster

```bash
sudo apt-get install ansible
cd ai-benchmark-util/ansible
git clone https://github.com/refual/ansible-slurm.git
dd if=/dev/urandom bs=1 count=1024 > munge.key

# Edit slurm_vars_xyz.yaml and inventory.yaml as needed
# please note that it's recommended to run the slurmdbd and slurmctl service on another server than your workers
# so by example if you have 2 workers with GPUs cards a third machine (without GPUs) will be required to run the slrumdbd and slurmctl service
# this third machine is called nvidia-mgmt, and can run on a VM
```

```yaml
# edit the following options in slurm_vars_xyz.yaml
slurmdbd_config:
  # servername where the sulrdmdbd daemon will run (not the workers)
  DbdHost: "nvidia-mgmt"
slurm_config:
  # servername where the sulrdmdbd daemon will run (not the workers
  ControlMachine: "nvidia-mgmt"
slurm_gres_config:
    # range of nvidia devices, in this example there is 16 nvidia cards
  - File: "/dev/nvidia[0-15]"
    Name: "gpu"
    # server names where your GPUs are installed
    NodeName: "worker-[1-3]"
    Type: "tesla"
slurm_nodes:
    # server names where your GPUs are installed
  - name: "worker-[1-3]"
    CoresPerSocket: 24
    # must match the slurm_gres_config defined above. 16 corresponds to 16 nvidia cards.
    Gres: "gpu:tesla:16"
    Sockets: 2
    ThreadsPerCore: 2
slurm_partitions:
  - name: "gpu"
    # server names where your GPUs are installed
    Nodes: "worker-[1-3]"
```

```yaml
# edit the following options in inventory.yaml
# set the ips for your workers and your mgmt host
```

### Deploy and start the slurm cluster

```bash
./run_slurm_playbook.sh
sinfo
```

### Install Parabricks

***The Parabricks application can be requested from Parabricks <https://developer.nvidia.com/clara-parabricks>***

```bash
# Unzip the package
tar -zxvf parabricks.tar.gz

# Install parabricks
sudo ./parabricks/installer.py --install-location localdir --container singularity
cd localdir
tar -zcvf parabricks_install.tar.gz parabricks
cp parabricks_install.tar.gz /mnt/isilon/data/ai-benchark-util/parabricks/
```

### Verfy Installation

```bash
# Download sample data to your local drive
wget https://s3.amazonaws.com/parabricks.sample/parabricks_sample.tar.gz

# untar the file
tar -zxvf parabricks_sample.tar.gz

# Test the sample data using the following command
<INSTALL_DIR>/parabricks/pbrun fq2bam \
  --ref parabricks_sample/Ref/Homo_sapiens_assembly38.fasta \
  --in-fq parabricks_sample/Data/sample_1.fq.gz parabricks_sample/Data/sample_2.fq.gz \
  --out-bam output.bam \
  --num-gpus 4

# The test should finish in ~150 seconds
```

### Reference files

The following reference files were used with Parabricks secondary analysis pipeline:

* Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
* Homo_sapiens_assembly38.dbsnp138.vcf
* Homo_sapiens_assembly38.fasta

**These files must be present locally on every workers.**

They can be downloaded from <https://console.cloud.google.com/storage/browser/genomics-public-data/resources/broad/hg38/v0?pli=1>

Download every files under ```/home/${USER}/genomics/Ref```
```bash
mkdir -p /home/${USER}/genomics/Ref
```

***Remark:*** It's recommended to store these files on a fast drive like SSD or NVMe.

### Download fastq files

The following 12 librairies were used:

|Libray_name_id (Sample Name)|ENA RUN ACCESSION ID / URL|coverage|
|-|-|-|
|LP6005441-DNA_A10|<https://www.ebi.ac.uk/ena/data/view/ERR1419095>|33.59|
|LP6005442-DNA_B12|<https://www.ebi.ac.uk/ena/data/view/ERR1419185>|33.86|
|LP6005442-DNA_A04|<https://www.ebi.ac.uk/ena/data/view/ERR1419173>|33.95|
|LP6005442-DNA_H09|<https://www.ebi.ac.uk/ena/data/view/ERR1347676>|34.11|
|SS6004478|<https://www.ebi.ac.uk/ena/data/view/ERR1395601>|44.4
|SS6004472|<https://www.ebi.ac.uk/ena/data/view/ERR1395595>|44.45
|LP6005443-DNA_G11|<https://www.ebi.ac.uk/ena/data/view/ERR1347738>|44.48
|LP6005441-DNA_G04|<https://www.ebi.ac.uk/ena/data/view/ERR1419152>|44.56
|LP6005441-DNA_A06|<https://www.ebi.ac.uk/ena/data/view/ERR1419092>|68.6
|LP6005441-DNA_D05|<https://www.ebi.ac.uk/ena/data/view/ERR1419124>|68.83
|LP6005441-DNA_B06|<https://www.ebi.ac.uk/ena/data/view/ERR1625860>|80.02
|LP6005441-DNA_C06|<https://www.ebi.ac.uk/ena/data/view/ERR1625861>|83.23

***Remark:*** Please note that you can use the script ```./download_fastq.py``` to download the FASTQ.GZ files automatically. These files must be stored on Isilon to be accessible from every workers. **You'll need ~1.6TB of available storage.**

It might take 24 hours to download these files depending of your network connection. Please be patient !

TO BE CONTINUED
