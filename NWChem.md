# NWChem Base Code
## Setting up NWChem on HPC Cluster
This project is based on https://github.com/hpcac/2025-APAC-HPC-AI  
We are using a PBS-based HPC cluster with NWChem 7.0.0.
This project optimizes DFT calculations for water clusters using B3LYP/cc-pVTZ level of theory.
## Base Script - Original Configuration
A baseline script file in `${HOME}/scratch/${USER}/run/` with the following contents:
```
mkdir -p ${HOME}/scratch/${USER}/run

tee ${HOME}/scratch/${USER}/run/nwchem.sh << 'EOF'
#!/bin/bash
#PBS -P pc08
#PBS -q normalsr
#PBS -l walltime=00:05:00
#PBS -l ncpus=104,mem=208gb
#PBS -j oe
#PBS -M 393958790@qq.com
#PBS -m abe
##PBS -l other=hyperthread

# Load required modules
module purge
module load nwchem/7.0.0

env
env | grep -E "(PBS|OMP)" | sort
module list

export OMP_NUM_THREADS=1

# Change to working directory
mkdir -p ${HOME}/scratch/${USER}/nwchem/run/${PBS_JOBID}
cd       ${HOME}/scratch/${USER}/nwchem/run/${PBS_JOBID}

OUTPUT_FILE=${HOME}/run/job.${PBS_JOBNAME}.stdout

time mpirun -np ${NCPUS:-104} \
    nwchem \
    ${HOME}/scratch/${USER}/nwchem/input/w12_b3lyp_cc-pvtz_energy.nw \
    2>&1 | tee ${OUTPUT_FILE}
EOF

```
## NWChem Input File - Original
The original inpuy file in `${HOME}/scratch/${USER}/nwchem/input/w12_b3lyp_cc-pvtz_energy.nw`:
```

echo

start w12_b3lyp_cc-pvtz_energy

memory stack 8000 mb heap 100 mb global 8000 mb noverify

permanent_dir .
scratch_dir /tmp

geometry units angstrom
  O       1.79799517    -2.87189360    -0.91374020
  O       0.96730604    -2.75911220     1.62798799
  O       1.65380168    -0.07006642    -1.01974524
  O       1.02235809     0.07175530     1.65572815
  O      -1.02223258     0.06714841    -1.65231025
  O      -1.65303657    -0.06953734     1.02328922
  O      -1.79714075    -2.87225082     0.91489225
  O      -0.96714604    -2.76268933    -1.62695366
  O      -0.91046484     2.86984708    -1.80205865
  O       1.62976535     2.75963881    -0.96492508
  O       0.90962365     2.87584732     1.79706100
  O      -1.63064745     2.76057720     0.96075175
  H       1.58187452    -2.90533857     0.05372043
  H       2.45880812    -3.55319457    -1.06640225
  H      -1.58013630    -2.90956053    -0.05228132
  H      -2.45728026    -3.55363054     1.07010099
  H       0.05632428     2.90394112    -1.58314254
  H      -1.06231290     3.55393270    -2.46019459
  H      -1.56680088     2.89107809    -0.00131897
  H      -1.92210192     1.83983329     1.06475175
  H       1.34757079     0.06744042     0.72858318
  H       1.14627218     0.98941003     1.95482520
  H      -1.14676057     0.98295160    -1.95675717
  H      -1.34650335     0.06810117    -0.72482129
  H       0.72810518    -0.06186014    -1.34872142
  H       1.95057642    -0.98833069    -1.14558354
  H      -0.72703573    -0.06575415     1.35156867
  H      -1.95270073    -0.98745311     1.14464678
  H       1.56681459     2.89291882    -0.00316599
  H       1.92433921     1.83983329    -1.06611724
  H      -0.00511757    -2.89477284    -1.56679971
  H      -1.07087869    -1.84139535    -1.91693517
  H      -0.05748186     2.90789148     1.57927484
  H       1.06103881     3.56065162     2.45452965
  H       0.00532585    -2.89179177     1.56768173
  H       1.07022772    -1.83898762     1.92167783
end

basis "ao basis" spherical noprint
  * library cc-pvtz
end

scf
  direct
  singlet
  rhf
  thresh 1e-7
  maxiter 100
  vectors input atomic output w12_scf_cc-pvtz.movecs
  noprint "final vectors analysis" "final vector symmetries"
end

task scf energy ignore

dft
  direct
  xc b3lyp
  grid fine
  iterations 100
  vectors input w12_scf_cc-pvtz.movecs
  noprint "final vectors analysis" "final vector symmetries"
end

task dft energy

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
