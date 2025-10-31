#!/bin/bash
#PBS -P 50000032
#PBS -l walltime=00:01:00
#PBS -j oe
#PBS -M 214928@student.upm.edu.my,216638@student.upm.edu.my
#PBS -m abe

date
module purge
module load openmpi/4.1.2-hpe
module load libfabric/1.11.0.4.125

env
cat $PBS_NODEFILE
	
export NCCL_DEBUG=INFO
export NCCL_IB_DISABLE=1
export NCCL_NET_GDR_LEVEL=0
export NCCL_SHM_DISABLE=1

nvidia-smi

cmd="mpirun \
-wdir ${HOME}/scratch/workdir/llama \
-output-filename ${HOME}/run/output/${PBS_JOBNAME}.${PBS_JOBID} \
-map-by ppr:4:node -oversubscribe \
-report-bindings \
-x mpirun -mca btl ^ucx \
-mca coll_hcoll_enable 1 -mca coll_basic_priority 10 \
${HOME}/scratch/workdir/llama/litgpt.py312/bin/litgpt \
finetune_full \
${HOME}/scratch/workdir/llama/model/litgpt/meta-llama/Llama-2-7b-hf \
--data JSON --data.json_path ${HOME}/scratch/workdir/llama/dataset/alpaca1024 \
--out_dir ${HOME}/scratch/workdir/llama/out/finetune/full
--config ${HOME}/scratch/workdir/llama/full.yaml \
--eval.final_validation=false \
--train.epochs=1 \
--devices=4 --num_nodes=2 \
--train.max_steps=${max_steps} \
--train.global_batch_size=${global_batch_size} \
--train.micro_batch_size=${micro_batch_size}"

echo ${cmd}

exec ${cmd}
date
