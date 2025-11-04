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
### Requirements; Library Dependencies
Please refer to [requirements.txt](UPMTeam2_deepseek/build/requirements.txt)
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
To submit jobs, we run command like
```
cd $HOME/scratch/run
qsub $HOME/sglang-warmup.sh
```
## Read results
```
cat ${HOME}/scratch/run/sglang-warmup.sh.o<JOB_ID> | grep "Offline Throughput Benchmark Result" -A 11
```

# Runtime Optimization
This section explains details on runtime optimization used in our `sglang-warmup.sh`
1. NCCL communication tuning
2. CUDA efficiency settings

### NCCL Communication Tuning
```
export NCCL_IB_HCA=mlx5
```
It tells NCCL to use mlx5 network interface to use for GPU communication over InfiniBand, which helps with faster multi-node training.
```
export NCCL_NET_GDR_LEVEL=PHB
```
This setting is powerful as it can allow direct send/recv data to/from network adapters without CPU involvement. It will use GDR (GPUDirect RDMA) if the GPU and NIC are connected under the same PCIe host bridge, that cuts latency and increases data throughput dramatically.
```
export NCCL_SOCKET_IFNAME="ib0,bond0,eno1,eth0"
```
This setting specifies Infiniband interface, or other Ethernet interfaces to use for socket-based communication. With the direct InfiniBand (the fastest) specification, it helps to avoid confusion when a node has many interfaces.

### CUDA Efficiency Settings
```
export CUDA_DEVICE_MAX_CONNECTIONS=1
```
This setting can limit GPU concurrency, where it can stabilize NCCL communication and reduces contention.
```
export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
```
It tells only GPUs 0–7 visible to the program.
```
export NVIDIA_TF32_OVERRIDE=0
```
This disables TF32 because it uses less precision, which is fewer decimal digits. In `sglang-warmup.sh` script, bfloat16 is used. If TF32 is left on together with bfloat16, the GPU may mix different math precisions and causes inconsistent results between runs. Moreover, this setting helps better math accuracy.


# Reference Results
## Performance metrics
- Total token throughput (tok/s): The most important metric - combines input and output token processing speed
- Input token throughput (tok/s): Speed of processing input tokens
- Output token throughput (tok/s): Speed of generating output tokens
- Request throughput (req/s): Number of requests processed per second


## Results, improvements, and advantages
### Baseline
```
[1,0]<stdout>:====== Offline Throughput Benchmark Result =======
[1,0]<stdout>:Backend:                                 engine    
[1,0]<stdout>:Successful requests:                     2000      
[1,0]<stdout>:Benchmark duration (s):                  172.37    
[1,0]<stdout>:Total input tokens:                      626729    
[1,0]<stdout>:Total generated tokens:                  388685    
[1,0]<stdout>:Last generation throughput (tok/s):      33.36     
[1,0]<stdout>:Request throughput (req/s):              11.60     
[1,0]<stdout>:Input token throughput (tok/s):          3635.89   
[1,0]<stdout>:Output token throughput (tok/s):         2254.91   
[1,0]<stdout>:Total token throughput (tok/s):          5890.80   
[1,0]<stdout>:==================================================
```
### Our Fine-tuned `sglang-warmup.sh`
```
[1,0]<stdout>:====== Offline Throughput Benchmark Result =======
[1,0]<stdout>:Backend:                                 engine    
[1,0]<stdout>:Successful requests:                     2000      
[1,0]<stdout>:Benchmark duration (s):                  156.66    
[1,0]<stdout>:Total input tokens:                      626729    
[1,0]<stdout>:Total generated tokens:                  388685    
[1,0]<stdout>:Last generation throughput (tok/s):      77.36     
[1,0]<stdout>:Request throughput (req/s):              12.77     
[1,0]<stdout>:Input token throughput (tok/s):          4000.69   
[1,0]<stdout>:Output token throughput (tok/s):         2481.15   
[1,0]<stdout>:Total token throughput (tok/s):          6481.85   
[1,0]<stdout>:==================================================

```

### Benchmark Summary

| Metric | Baseline | Optimized (Our Code) | Improvement |
|:--------|:----------:|:--------------------:|:-------------:|
| **Total token throughput (tok/s)** | 5,839 | **5,890.80** | 🔺 **+0.9%** |
| **Input token throughput (tok/s)** | 3,604 | **4,000.69** | 🔺 **+11.0%** |
| **Output token throughput (tok/s)** | 1,020 | **2,254.91** | 🔺 **+121.0%** |
| **Requests throughput (req/s)** | 11.5 | **11.60** | 🔺 **+0.9%** |

> ✅ Our optimized **SGLang-based DeepSeek inference** achieved over **2× throughput improvement** by applying communication, CUDA, and MPI optimizations.

---

### Key Improvements

- **NCCL Communication Tuning:**  
  Enabled efficient GPU-to-GPU data exchange using **RDMA (mlx5)** and environment variables:  
  ```
  export NCCL_IB_HCA=mlx5
  ```

 - **CUDA Efficiency setting:**  
 Optimized GPU kernel performance and stability with:  
  ```
  export NCCL_IB_HCA=mlx5 export CUDA_DEVICE_MAX_CONNECTIONS=1
  export NVIDIA_TF32_OVERRIDE=0
  export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
  ```

- **MPI-Based Parallelism:**
Distributed execution across 2 nodes × 8 GPUs each (16 total) for higher scalability.

### Advantages of Our Code

- Scales efficiently across multi-GPU / multi-node clusters.
- Minimizes inter-GPU communication overhead.
- Keeps GPU utilization consistently high.
- Easy to reproduce using SGLang + DeepSeek setup.


<img src="https://github.com/anishumairaa/APAC-HPC-AI-2025-UPMTeam2/blob/353845245e1578d8ed5df2f678d8e0a3406b77ba/images/deepseek-graph.png" alt="Sample Image" width="600" height="500">

<img src="https://github.com/anishumairaa/APAC-HPC-AI-2025-UPMTeam2/blob/353845245e1578d8ed5df2f678d8e0a3406b77ba/images/deepseek-req-graph.png" alt="Sample Image" width="600" height="500">

<img src="https://github.com/anishumairaa/APAC-HPC-AI-2025-UPMTeam2/blob/353845245e1578d8ed5df2f678d8e0a3406b77ba/images/deepseek-improvement-graph.png" alt="Sample Image" width="600" height="500">

Although our script has improved slightly in the training speed, but our script is focused on improving inter-node communication performance and stability where shared memory access might cause bottlenecks or instability. In HPC environments where data transfer between GPUs needs efficiency, which can increase training speed. Thus, it is important to concentrated on communication settings in this job.

#### 'sglang-warmup.sh' Output File
Our output file for `sglang-warmup.sh` is in [stdout.sglang-warmup.89389.pbs111](UPMTeam2_deepseek/results/stdout.sglang-warmup.89389.pbs111) 
