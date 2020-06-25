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

### Install the git repository into your isilon share

```bash
sudo mkdir /mnt/isilon
sudo mount -t nfs <ISILON_IP/FQDN>:<NFS_EXPORT_NAME> /mnt/isilon
cd /mnt/isilon
git clone https://github.com/damienmas/ai-benchmark-util.git
```

### Install Singularity (on every workers nodes, worker node means server with GPU cards)

```bash
# For complete list of servers : http://neuro.debian.net
# for some reasons the US-CA server didn't work for me on Ubuntu 18.04 ...
wget -O- http://neuro.debian.net/lists/bionic.de-m.full | sudo tee /etc/apt/sources.list.d/neurodebian.sources.list
sudo apt-key adv --recv-keys --keyserver hkp://pool.sks-keyservers.net:80 0xA5D32F012649A5A9
sudo apt-get update
sudo apt-get install singularity-container
singularity --version
```

### Install Parabricks (on a single worker node)

***The Parabricks application can be requested from Parabricks by contacting <https://developer.nvidia.com/clara-parabricks>***

```bash
# Unzip the package
tar -zxvf parabricks.tar.gz

# Install parabricks
sudo ./parabricks/installer.py --install-location localdir --container singularity

cd localdir
tar -zcvf parabricks_install.tar.gz parabricks
cp parabricks_install.tar.gz /mnt/isilon/ai-benchark-util/parabricks/
```
