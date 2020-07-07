#!/usr/bin/env bash

set -ex

##### tests with tmp local
# Run Germline pipeline with 4 GPUs
./submit_slurm_jobs.py --config ./submit_slurm_jobs_germline.yaml --sample_id_file sample_ids_parabricks_12_low_to_high.txt

# wait for all jobs to complete
while squeue | grep -v JOBID > /dev/null ; do sleep 30 ; done ; sleep 300

# Run deepvariant pipeline with 1 GPU
./submit_slurm_jobs.py --config ./submit_slurm_jobs_deepvariant.yaml --sample_id_file sample_ids_parabricks_12_low_to_high.txt

# wait for all jobs to complete
while squeue | grep -v JOBID > /dev/null ; do sleep 30 ; done ; sleep 300

# Run deepvariant pipeline with 4 GPU
./submit_slurm_jobs.py --config ./submit_slurm_jobs_deepvariant_4gpus.yaml --sample_id_file sample_ids_parabricks_12_low_to_high.txt

# wait for all jobs to complete
while squeue | grep -v JOBID > /dev/null ; do sleep 30 ; done ; sleep 300


##### tests with tmp on Isilon
# Run Germline pipeline with 4 GPUs
./submit_slurm_jobs.py --config ./submit_slurm_jobs_germline_all_isilon.yaml --sample_id_file sample_ids_parabricks_12_low_to_high.txt

# wait for all jobs to complete
while squeue | grep -v JOBID > /dev/null ; do sleep 30 ; done ; sleep 300

# Run deepvariant pipeline with 1 GPU
./submit_slurm_jobs.py --config ./submit_slurm_jobs_deepvariant_all_isilon.yaml --sample_id_file sample_ids_parabricks_12_low_to_high.txt

# wait for all jobs to complete
while squeue | grep -v JOBID > /dev/null ; do sleep 30 ; done ; sleep 300

# Run deepvariant pipeline with 4 GPUs
./submit_slurm_jobs.py --config ./submit_slurm_jobs_deepvariant_all_isilon_4gpus.yaml --sample_id_file sample_ids_parabricks_12_low_to_high.txt

# wait for all jobs to complete
while squeue | grep -v JOBID > /dev/null ; do sleep 30 ; done ; sleep 300
################## END ##################
