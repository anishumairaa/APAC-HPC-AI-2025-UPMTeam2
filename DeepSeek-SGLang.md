# DeepSeek-SGLang Base Code
## Base Code Information
We are using Aspire2P as our cluster.  
This project used the base script `sglang.sh` from [2025-APAC-HPC-AI. ](https://github.com/hpcac/2025-APAC-HPC-AI/blob/main/5_1_SGLang_DeepSeek_Application_Notes_ASPIRE2A%2B.md)  **This script is used as baseline.**  
  
A script file `${HOME}/sglang-baseline.sh` with the following contents  
```
#PBS -P 50000112
#PBS -l walltime=00:07:00
#PBS -l select=2:ncpus=112:ngpus=8:mpiprocs=2:mem=1880gb
#PBS -j oe
#PBS -m abe
#PBS -M 216638@student.upm.edu.my
##PBS -l other=hyperthread

module load cuda

time /usr/mpi/gcc/openmpi-4.1.7a1/bin/mpirun \
-hostfile ${PBS_NODEFILE} \
-map-by ppr:1:node:PE=112 -oversubscribe -use-hwthread-cpus \
-bind-to none --report-bindings -display-map \
-tag-output -output-filename ${HOME}/run/sglang-baseline.${PBS_JOBID} \
-x PATH \
-x NCCL_DEBUG=INFO \
-x DIST_INIT_ADDR=$(head -n 1 $PBS_NODEFILE) \
bash -c 'time ${HOME}/scratch/py312/bin/python3 \
-m sglang.bench_offline_throughput \
--model-path deepseek-ai/DeepSeek-R1 \
--dataset-path ${HOME}/scratch/ShareGPT_V3_unfiltered_cleaned_split.json \
--num-prompts 2000 --load-format dummy --seed 2025 --dtype bfloat16 \
--tp 16 --nnodes 2 --trust-remote-code \
--dist-init-addr ${DIST_INIT_ADDR}:5000 --node-rank ${OMPI_COMM_WORLD_RANK}' \
2>&1 | tee ${HOME}/run/stdout.sglang-baseline.${PBS_JOBID}
```

# Script Modifications
From the baseline script `${HOME}/sglang-baseline.sh`, we modified it into `${HOME}/sglang-warmup.sh`  
Our tuned-script file `${HOME}/sglang-warmup.sh` with the following contents  
```
#!/bin/bash
#PBS -P 50000112
#PBS -l walltime=00:07:00
#PBS -l select=2:ncpus=112:ngpus=8:mpiprocs=2:mem=1880gb
#PBS -j oe
#PBS -m abe
#PBS -M 216638@student.upm.edu.my
##PBS -l other=hyperthread

module load cuda

export CUDA_DEVICE_MAX_CONNECTIONS=1
export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export NVIDIA_TF32_OVERRIDE=0                # keep math stable
export NCCL_IB_HCA=mlx5
export NCCL_SOCKET_IFNAME="ib0,bond0,eno1,eth0"
export NCCL_NET_GDR_LEVEL=PHB
export DIST_INIT_PORT=5000


PYTHON=${HOME}/scratch/py312/bin/python3


COMMON_FLAGS="\
  --model-path deepseek-ai/DeepSeek-R1 \
  --dataset-path ${HOME}/scratch/ShareGPT_V3_unfiltered_cleaned_split.json \
  --seed 2025 \
  --dtype bfloat16 \
  --trust-remote-code \
  --tp 16 --nnodes 2 \
  --dist-init-addr ${DIST_INIT_ADDR}:${DIST_INIT_PORT} \
  --node-rank \${OMPI_COMM_WORLD_RANK} \
  \
"

#-------- OPTIMIZATION: WARM UP ---------
/usr/mpi/gcc/openmpi-4.1.7a1/bin/mpirun \
  -hostfile ${PBS_NODEFILE} \
  -map-by ppr:1:node \
  -bind-to none \
  -x PATH \
  -x NCCL_DEBUG=INFO \
  -x DIST_INIT_ADDR=$(HEAD -N 1 $PBS_NODEFILE) \
  bash -c "time ${PYTHON} -m sglang.bench_offline_throughput \
    ${COMMON_FLAGS} \
    --num-prompts 64 \
    --load-format dummy \
  " || true


# ---------- OFFLINE BENCHMARK ----------
time /usr/mpi/gcc/openmpi-4.1.7a1/bin/mpirun \
  -hostfile ${PBS_NODEFILE} \
  -map-by ppr:1:node \
  -bind-to none --report-bindings -display-map \
  -tag-output -output-filename ${HOME}/scratch/run/sglang-warmup.${PBS_JOBID} \
  -x PATH \
  -x NCCL_DEBUG=INFO \
  -x DIST_INIT_ADDR=$(head -n 1 $PBS_NODEFILE) \
  bash -c "time ${PYTHON} -m sglang.bench_offline_throughput \
    ${COMMON_FLAGS} \
    --num-prompts 2000 \
    --load-format dummy \
  " 2>&1 | tee ${HOME}/scratch/run/stdout.sglang-warmup.${PBS_JOBID}
```
### Diff of baseline vs finetuned script
We added and modified few lines in `sglang-warmup.sh`, that are:
```
export CUDA_DEVICE_MAX_CONNECTIONS=1
export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export NVIDIA_TF32_OVERRIDE=0                # keep math stable
export NCCL_IB_HCA=mlx5
export NCCL_SOCKET_IFNAME="ib0,bond0,eno1,eth0"
export NCCL_NET_GDR_LEVEL=PHB
export DIST_INIT_PORT=5000
```
Warm up to ensure that the gpu is fully activated
```
COMMON_FLAGS="\
  --model-path deepseek-ai/DeepSeek-R1 \
  --dataset-path ${HOME}/scratch/ShareGPT_V3_unfiltered_cleaned_split.json \
  --seed 2025 \
  --dtype bfloat16 \
  --trust-remote-code \
  --tp 16 --nnodes 2 \
  --dist-init-addr ${DIST_INIT_ADDR}:${DIST_INIT_PORT} \
  --node-rank \${OMPI_COMM_WORLD_RANK} \
  \
"

#-------- OPTIMIZATION: WARM UP ---------
/usr/mpi/gcc/openmpi-4.1.7a1/bin/mpirun \
  -hostfile ${PBS_NODEFILE} \
  -map-by ppr:1:node \
  -bind-to none \
  -x PATH \
  -x NCCL_DEBUG=INFO \
  -x DIST_INIT_ADDR=$(HEAD -N 1 $PBS_NODEFILE) \
  bash -c "time ${PYTHON} -m sglang.bench_offline_throughput \
    ${COMMON_FLAGS} \
    --num-prompts 64 \
    --load-format dummy \
  " || true

```
# Configuration Instructions
## Build Instructions  

#### Install Miniforge
```
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O ${HOME}/scratch/Miniforge3-Linux-x86_64.sh

bash ${HOME}/scratch/Miniforge3-Linux-x86_64.sh -b -p ~/scratch/miniforge

${HOME}/scratch/miniforge/bin/conda init

bash
```


#### Install Python3.12
```
conda create -p ${HOME}/scratch/py312 python=3.12 -y
```


#### Install SGLang into Python
```
${HOME}/scratch/py312/bin/pip install --upgrade pip

${HOME}/scratch/py312/bin/pip install "sglang[all]>=0.5.0rc2"
```

#### Download Json Dataset File
```
wget https://huggingface.co/datasets/anon8231489123/ShareGPT_Vicuna_unfiltered/resolve/main/ShareGPT_V3_unfiltered_cleaned_split.json
```
## Configuring parameters
Our implementation are proven to follow all competition rules.  
### System Settings
```
module load cuda
```

### Configuration Settings
- Number of nodes: 2 GPU nodes
- Total GPUs: 16
- Total CPUs: 224
- Total memory allocation: 3760GB
- Benchmark prompts: 2000
- Load format: Dummy
- Random seed: 2025
- Time limit: 420 seconds
- MPI processes: 2 per node  

### Model and Dataset Settings
- model_path = deepseek-ai/DeepSeek-R1
- dataset_path = ${HOME}/scratch/ShareGPT_V3_unfiltered_cleaned_split.json
- num_prompts = 2000
- load_format = dummy
- seed = 2025
- dtype = bfloat16
- trust_remote_code = True


### Warm Up Settings (All config settings are the same except for num_prompts)

- num_prompts = 64

## Submit jobs
To submit jobs, we run command in [submit_job_sglang.txt ](UPMTeam2_deepseek/build/submit_job_sglang.txt)  
```
cd $HOME/scratch/run
qsub $HOME/sglang-warmup.sh
```
## Read results
```
cat ${HOME}/scratch/run/sglang-warmup.sh.o<JOB_ID> | grep "Offline Throughput Benchmark Result" -A 11
```
# Reference Results
## Performance metrics
Training time (s): This measures how long it takes to complete the training.  
Our goal is to lower the training time as much as we can.  
## Workload profile
- Workload: Llama-2-7b finetune-full
- Max Seq Length: 512
- Number of Epochs: 1
- Dataset

| Supercomputer	| NSCC SG Aspire-2A iterations	|
|:--------------|:------------------------------|
| Dataset	| Alpaca1024/train.json	        |


## Value initialization
These values are constant throughout the performance improvement process.
| Num. of nodes | Num. of GPUs | Num. of CPUs | Num. of Epochs | Global Batch Size | Micro Batch Size | Max Steps |
|:--------------|:-------------|:-------------|:---------------|:------------------|:-----------------|:----------|
| 2             | 8            | 128          | 1              | 128               | 32               | 20        |

## Results, improvements, and advantages
### Baseline
| Num. of nodes | Num. of GPUs | Num. of CPUs | Memory Requested | Average Training Time |
|:--------------|:-------------|:-------------|:-----------------|:----------------------|
| 2             | 8            | 128          | 17.73            | 41.57s                |  

`llana.sh` script:
- uses OpenMPI version 4.1.2
- uses Libfabric
- uses `mpirun` to do MPI job
- maps 4 processes per node
- oversubscribes which allows running more MPI processes than there are physical cores available
- uses MCA (Modular Component Architecture) parameters for optimizing MPI job
- disables Infiniband support in NCCL
- excludes the UCX layer in MPI
- disables GPU Direct RDMA

### Improved script
| Num. of nodes | Num. of GPUs | Num. of CPUs | Memory Requested | Average Training Time |
|:--------------|:-------------|:-------------|:-----------------|:----------------------|
| 2             | 8            | 128          | 17.73            | 28.09s                |  

Our `tuningllama.sh` script:
- uses exact configurations as baseline script, except that,
- `mpirun` command is using export which makes these variables available globally to all processes
- disables shared memory communication `NCCL_SHM_DISABLE=1` that will reduce conflicts or contention during processes' communication
- enables High-Performance Collectives (HCOLL) `coll_hcoll_enable 1`
- lowers the priority of the basic collective module `coll_basic_priority 10` to ensure HCOLL is used preferentially if available  

Although our script has improved slightly in the training speed, but our script is focused on improving inter-node communication performance and stability where shared memory access might cause bottlenecks or instability. In HPC environments where data transfer between GPUs needs efficiency, which can increase training speed. Thus, it is important to concentrated on communication settings in this job.

## Output file
Our output file for `tuningllama.sh` is in [llama.nodes2.GBS128.MBS32.o8613326](https://github.com/anishumairaa/HPC-AI-UPM-Team-3/blob/main/script_job_output_logs/llama.nodes2.GBS128.MBS32.o8613326) 
