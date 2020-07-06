#!/usr/bin/env bash

set -ex

# mount single isilon node on both workers
#for x in hop-dss8440-01 hop-dss8440-02 ; do
#  ssh $x "sudo umount /mnt/f200"
#  ssh $x "sudo mount -t nfs -o rsize=1048576,wsize=1048576,nolock,hard,timeo=600,retrans=2,proto=tcp hop-ps-c.solarch.lab.emc.com:/ifs/genomics/parabricks /mnt/f200"
#done

################## Run tests with 2 workers and 2 Isilon Nodes ##################
# tests with tmp local
./submit_slurm_jobs.py --config ./submit_slurm_jobs_germline.yaml --sample_id_file sample_ids_parabricks_12_low_to_high.txt

# wait for all jobs to complete
while squeue | grep -v JOBID > /dev/null ; do sleep 30 ; done ; sleep 300

# DV 1 GPU
#./submit_slurm_jobs.py --config ./submit_slurm_jobs_deepvariant.yaml --sample_id_file sample_ids_parabricks_12_low_to_high.txt

# wait for all jobs to complete
#while squeue | grep -v JOBID > /dev/null ; do sleep 30 ; done ; sleep 300

# Test deepvariant with 4 gpus
./submit_slurm_jobs.py --config ./submit_slurm_jobs_deepvariant_4gpus.yaml --sample_id_file sample_ids_parabricks_12_low_to_high.txt

# wait for all jobs to complete
while squeue | grep -v JOBID > /dev/null ; do sleep 30 ; done ; sleep 300

# tests with tmp on Isilon
./submit_slurm_jobs.py --config ./submit_slurm_jobs_germline_all_isilon.yaml --sample_id_file sample_ids_parabricks_12_low_to_high.txt

# wait for all jobs to complete
while squeue | grep -v JOBID > /dev/null ; do sleep 30 ; done ; sleep 300

# DV 1 GPU
#./submit_slurm_jobs.py --config ./submit_slurm_jobs_deepvariant_all_isilon.yaml --sample_id_file sample_ids_parabricks_12_low_to_high.txt

# wait for all jobs to complete
#while squeue | grep -v JOBID > /dev/null ; do sleep 30 ; done ; sleep 300

# Test deepvariant with 4 gpus
./submit_slurm_jobs.py --config ./submit_slurm_jobs_deepvariant_all_isilon_4gpus.yaml --sample_id_file sample_ids_parabricks_12_low_to_high.txt

# wait for all jobs to complete
while squeue | grep -v JOBID > /dev/null ; do sleep 30 ; done ; sleep 300
################## END ##################


################### Run tests with 2 workers and 1 Isilon Node
## mount single isilon node on both workers
#for x in hop-dss8440-01 hop-dss8440-02 ; do
#  ssh $x "sudo umount /mnt/f200"
#  ssh $x "sudo mount -t nfs -o rsize=1048576,wsize=1048576,nolock,hard,timeo=600,retrans=2,proto=tcp hop-ps-c.solarch.lab.emc.com:/ifs/genomics/parabricks /mnt/f200"
#done
#
## tests with tmp local
#./submit_slurm_jobs.py --config ./submit_slurm_jobs_germline.yaml --sample_id_file sample_ids_parabricks_12_low_to_high.txt
#
## wait for all jobs to complete
#while squeue | grep -v JOBID > /dev/null ; do sleep 30 ; done ; sleep 300
#
## DV 1 GPU
##./submit_slurm_jobs.py --config ./submit_slurm_jobs_deepvariant.yaml --sample_id_file sample_ids_parabricks_12_low_to_high.txt
#
## wait for all jobs to complete
## while squeue | grep -v JOBID > /dev/null ; do sleep 30 ; done ; sleep 300
#
## Test deepvariant with 4 gpus
#./submit_slurm_jobs.py --config ./submit_slurm_jobs_deepvariant_4gpus.yaml --sample_id_file sample_ids_parabricks_12_low_to_high.txt
#
## wait for all jobs to complete
#while squeue | grep -v JOBID > /dev/null ; do sleep 30 ; done ; sleep 300
#
## test with tmp on Isilon
#./submit_slurm_jobs.py --config ./submit_slurm_jobs_germline_all_isilon.yaml --sample_id_file sample_ids_parabricks_12_low_to_high.txt
#
## wait for all jobs to complete
#while squeue | grep -v JOBID > /dev/null ; do sleep 30 ; done ; sleep 300
#
## DV 1 GPU
##./submit_slurm_jobs.py --config ./submit_slurm_jobs_deepvariant_all_isilon.yaml --sample_id_file sample_ids_parabricks_12_low_to_high.txt
#
## wait for all jobs to complete
## while squeue | grep -v JOBID > /dev/null ; do sleep 30 ; done
#
## Test deepvariant with 4 gpus
#./submit_slurm_jobs.py --config ./submit_slurm_jobs_deepvariant_all_isilon_4gpus.yaml --sample_id_file sample_ids_parabricks_12_low_to_high.txt
#
## wait for all jobs to complete
#while squeue | grep -v JOBID > /dev/null ; do sleep 30 ; done
################### END ##################
#