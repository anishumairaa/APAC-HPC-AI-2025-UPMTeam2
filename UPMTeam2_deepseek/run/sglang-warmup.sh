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
