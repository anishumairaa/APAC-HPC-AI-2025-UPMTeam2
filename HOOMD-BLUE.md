# HOOMD-Blue Base Code
This project is based on https://github.com/hpcac/2024-APAC-HPC-AI  
We copied baseline code from that github link, and changed the pbs initializations such as project code and email address. GCC is being utilized as the compiler for this project.  
The copied `hoomd.sh` with this content:
```
#!/bin/bash
#PBS -j oe  
#PBS -M 216990@student.upm.edu.my,214928@student.upm.edu.my,215541@student.upm.edu.my,215014@student.upm.edu.my,214511@student.upm.edu.my
#PBS -m abe
#PBS -P zd64
#PBS -l ngpus=0
#PBS -l walltime=00:00::60
#PBS -l other=hyperthread
#-report-bindings \

module purge
module load ${HOME}/hpcx-v2.20-gcc-mlnx_ofed-redhat8-cuda12-x86_64/modulefiles/hpcx-ompi

hosts=$(sort -u ${PBS_NODEFILE} | paste -sd ',')

cmd="time mpirun \
    -host ${hosts} \
    -wdir ${HOME}/scratch/workdir/hoomd \
    -output-filename ${HOME}/run/output/${PBS_JOBNAME}.${PBS_JOBID} \
    -map-by ppr:$((1*${NCPUS})):node \
    -oversubscribe -use-hwthread-cpus \
    -x PYTHONPATH=${HOME}/scratch/workdir/hoomd/build/hoomd-openmpi4.1.5:${HOME}/scratch/workdir/hoomd/hoomd-benchmarks \
    ${HOME}/scratch/workdir/hoomd/hoomd.py312/bin/python \
    -m hoomd_benchmarks.md_pair_wca \
    --device CPU -v \
    -N ${N} --repeat ${repeat} \
    --warmup_steps ${warmup_steps} --benchmark_steps ${benchmark_steps}"

echo ${cmd}

exec ${cmd}

```

# Modifications to the code 
The number of nodes, walltime configuration,warmup steps and benchmark steps were adjusted to optimize performance, allowing for a comparative analysis of the results to identify the most efficient configuration

## Our code vs base code
Below are the base code according to our reference on https://github.com/hpcac/2024-APAC-HPC-AI  

This configuration allocates:
- 8 nodes with customized walltime to accommodate the required computational intensity.
- A higher warmup step count (40000) and benchmark step count (80000) to ensure the benchmarking tests adequately stabilize and yield representative performance data.
- Memory and CPU allocation based on nodes to utilize available processing power efficiently.

```
cd ${HOME}/run

nodes=8 walltime=00:00:200 \
warmup_steps=40000 benchmark_steps=80000 repeat=1 N=200000 \
bash -c \
'qsub -V \
-l walltime=${walltime},select=${nodes}:ncpus=$((128*1)):mem=$((128*2))gb \
-N hoomd.nodes${nodes}.WS${warmup_steps}.BS${benchmark_steps}.N${N} \
hoomd.sh'
```

We increase the value of the walltime used,warmup steps and benchmark steps by using different number of nodes for each job and compare their optimization.

Our modified configuration allocates:

- 32 nodes with a moderate increase in walltime to support enhanced parallelization and scalability testing.
- Reduced warmup steps (10000) and benchmark steps (8000) to focus on efficient benchmarking with minimal initialization overhead.
- Memory and CPU dynamically allocated per node, ensuring resources are used efficiently across the larger node allocation.

```
nodes=32 walltime=00:10:00 \
warmup_steps=10000 benchmark_steps=8000 repeat=1 N=200000 \
bash -c \
'qsub -V \
-l walltime=${walltime},ncpus=$((48*nodes)),mem=$((48*nodes*1))gb \
-N hoomd.nodes${nodes}.WS${warmup_steps}.BS${benchmark_steps} \
hoomd.sh'

```
## Submit jobs
To submit jobs, we run command in [submit_job_hoomd.txt](https://github.com/anishumairaa/HPC-AI-UPM-Team-3/blob/main/script_job_output_logs/submit_job_hoomd.txt)  

# Reference Results
## Performance Metrics
- Steps per second: This measures how fast the system can simulate particle movements over time
- Execution time (s): This shows how long the task takes to complete
- Speedup: This measures how much faster a task completes when multiple processors are used compared to using a single processor
- Efficiency: This measures how effectively the processors are being used in parallel

## Value initialization
| Number of nodes | Number of cores used | Warmup/Benchmark   | Walltime Requested | Memory Requested |
|------------------|----------------------|--------------------|--------------------|------------------|
| 1 x 2            | 48 x 1              | 40,000/80,000      | 10 mins            | 48GB             |
| 2 x 2            | 48 x 2              | 40,000/80,000      | 10 mins            | 96GB             |
| 4 x 2            | 48 x 4              | 40,000/80,000      | 10 mins            | 192GB            |
| 8 x 2            | 48 x 8              | 40,000/80,000      | 10 mins            | 384GB            |
| 16 x 2           | 48 x 16             | 10,000/160,000     | 10 mins            | 768GB            |
| 32 x 2           | 48 x 32             | 10,000/320,000     | 10 mins            | 1536GB           |

## Results
| Number of nodes | Number of cores used | Total Cores | Memory requested (GB) | Walltime Used | Memory Used (GB) | Steps per second |
|------------------|----------------------|-------------|------------------------|---------------|------------------|------------------|
| 1 x 2            | 48 x 1              | 48          | 48                     | 0:55          | 21.54            | 423              |
| 2 x 2            | 48 x 2              | 96          | 96                     | 0:27          | 31.68            | 1058             |
| 4 x 2            | 48 x 4              | 192         | 192                    | 0:18          | 62.11            | 2142             |
| 8 x 2            | 48 x 8              | 384         | 384                    | 0:15          | 123.58           | 3431             |
| 16 x 2           | 48 x 16             | 768         | 768                    | 0:14          | 249.8            | 4831             |
| 32 x 2           | 48 x 32             | 1536        | 1536                   | 0:14          | 494.79           | 6431             |

## Result Analysis 
The steps per second increases substantially with a higher number of nodes:
  - 1 node, 48 cores: 423 steps per seconds
  - 32 nodes, 1536 cores: 6431 steps per second

The execution time decreases as more nodes were added:
  - 1 node, 48 cores: 55 seconds
  - 32 nodes, 1536 cores: 14 seconds

The simulation speed increases with the total number of cores:
  - 1 node, 48 cores: 1.00s
  - 32 nodes, 1536 cores: 3.93s

The system becomes less efficient as more cores are added:
  - 1 node, 48 cores: 0.02
  - 32 nodes, 1536 cores: 0.003

# Improvements
This project uses parallel computing to simulate particle movements with High-Performance Computing (HPC) for greater efficiency. Key improvements include:

## 1. Enhanced Performance with Increased Nodes and Cores
- **Speed and Execution Time:** Increasing nodes and cores leads to faster steps per second and reduced execution time. This shows effective parallel processing, allowing more tasks to complete quickly.
  
- **Trade-off in Efficiency:** While speed increases with more cores, individual core efficiency decreases due to the coordination required among processors. This is a common trade-off in parallel computing.

## 2. Improved Scalability
- The system supports up to 32 nodes, managing larger workloads effectively. However, efficiency slightly declines at high core counts due to increased communication overhead among cores.

## 3. Optimized Resource Allocation and Memory Management
- Memory was allocated based on node and core requirements, scaling from 48 GB to 1536 GB to handle large-scale tasks smoothly. This ensures the system can operate reliably for intensive simulations.

## 4. Resource Optimization
- Balances speed and resource use for optimal performance, achieving a good trade-off between performance gains and resource efficiency.


## Advantages of the Modified Code

- Improved Scalability: The modified code utilizes up to 32 nodes, and the distribution of a load is effective, enabling a system to easily handle high workloads. It allows significant improvement in computational performance.

- Improved Execution Time: The code optimizes walltime, nodes, and benchmark settings in such a way that execution time goes down as low as 14 seconds from 55 seconds while node count scales up, showing decent improvement in speed.

- Efficient Resource Allocation: This will perform dynamic memory and CPU allocation with respect to node count for efficiency while keeping memory utilization proportional to the computational load.

- Flexible Benchmarking: The code provides flexibility in benchmarking by allowing the warm-up and benchmark step to be changed, testing for a wide range of workloads/scenarios from high-intensity benchmarking to a fast test with less initialization overhead.

- Performance Analysis: Since the setup of the code will enable easy gathering and analysis of performance data, it will provide a complete comparative analysis between configurations.

# Configuration Instructions
### Prerequisites
- **GCC** (version 7.5 or higher) or any other C++ compiler
- **Phyton** (version 3.6 or higher)

### Modules load
```
module purge
module load ${HOME}/hpcx-v2.20-gcc-mlnx_ofed-redhat8-cuda12-x86_64/modulefiles/hpcx-ompi
```
## Enable MPI Support for HOOMD-blue
1. Load administrator-provided Environment modules to configure environment variables for running shell
2. Run the command with `mpirun`, which is the MPI execution command.
```
module load ${HOME}/hpcx-v2.20-gcc-mlnx_ofed-redhat8-cuda12-x86_64/modulefiles/hpcx-ompi

cmd="time mpirun \
    -host ${hosts} \
    ...
```

## Configuring parameters
Please refer to [submit_job_hoomd.txt](https://github.com/anishumairaa/HPC-AI-UPM-Team-3/blob/main/script_job_output_logs/submit_job_hoomd.txt)  
This command is used for configuring initialization parameters such as number of nodes, number of CPUs, benchmark step, warmup step and walltime.

## Read results
Methods to read output file  
`cat hoomd.nodes32.WS10000.BS8000.o126506599`

Check time steps per second  
`grep “time steps per second” ${HOME}/run/hoomd.* -r`

## Testing Methods
1. Refer to the configuration instructions to set up the environment.  
2. Create `hoomd.sh` script in `cd $HOME/run`  
3. Submit job command using the `submit_job_hoomd.txt`  
4. Read output file and check time steps per second as mentioned ealier.
