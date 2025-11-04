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
The original input file in `${HOME}/scratch/${USER}/nwchem/input/w12_b3lyp_cc-pvtz_energy.nw`:
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
The implementation of fast storage, application of OpenMP and MPI and adjustment in the input, allowing for a comparative analysis of the results to identify the most efficient configuration
## Creation of Shell script of input file
Creation of Shell script of input file which allows modifications and execution of the input file, `input.sh`:
```

#!/bin/bash

# Create directory structure
mkdir -p ${HOME}/scratch/${USER}/nwchem/input

# Create the NWChem input file
tee ${HOME}/scratch/${USER}/nwchem/input/w12_b3lyp_cc-pvtz_energy.nw << 'EOF'
echo
start w12_b3lyp_cc-pvtz_energy
memory stack 8000 mb heap 100 mb global 8000 mb noverify
permanent_dir .
scratch_dir /scratch/${USER}/${PBS_JOBID}
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

dft
  semidirect memsize 2000000000 filesize 0
  xc b3lyp
  grid fine
  iterations 100
  vectors input atomic
  noprint "final vectors analysis" "final vector symmetries"
end
task dft energy
EOF

echo "Input file created at: ${HOME}/scratch/${USER}/nwchem/input/w12_b3lyp_cc-pvtz_energy.nw"

```
## The implication of modification:
- Application of fast storage which separates the slow and fast storage and directing the high-volume data to the parallel file system
- Implementation of Hybrid Parallelization where threads would share memory efficiently within a node (OpenMP + MPI)
- Adjustments in the input file such changing the memory directives and removal of SCF energy block
## Optimized PBS Script
From the baseline script, we created an optimized version `script.pbs`
```
#!/bin/bash
#PBS -P ph60
#PBS -q normalsr
#PBS -l walltime=00:05:00
#PBS -l ncpus=416
#PBS -l mem=2048gb
#PBS -j oe
#PBS -m abe
##PBS -l other=hyperthread

# Load required modules
module purge
module load nwchem/7.0.0

# Display environment
env
env | grep -E "(PBS|OMP)" | sort
module list

# Set OpenMP parameters
export OMP_NUM_THREADS=4
export OMP_PLACES=cores
export OMP_PROC_BIND=close

export UCX_LOG_LEVEL=error
export UCX_MEMTYPE_CACHE=n

# Create and move to scratch directory
mkdir -p /scratch/${USER}/${PBS_JOBID}
cd /scratch/${USER}/${PBS_JOBID}

# Set output file location
OUTPUT_FILE=${HOME}/run/run.${PBS_JOBNAME}.stdout
mkdir -p ${HOME}/run

# Run NWChem
time mpirun -np 104 --map-by ppr:26:node:PE=4 --bind-to core \
    nwchem \
    ${HOME}/scratch/${USER}/nwchem/input/w12_b3lyp_cc-pvtz_energy.nw \
    2>&1 | tee ${OUTPUT_FILE}

```

# Different of Baseline vs Optimized Script
## PBS Script Changes
| Feature          | Baseline             | Optimized            |
|------------------|----------------------|----------------------|
| **Resources**        | ncpus=04,mem=208gb   | ncpus=416+mem2048gb  |      
| **Nodes**            | 1 node               | 4 node               |
## Key Script Modification
### Added in optimized version
```
# OpenMP thread control
export OMP_NUM_THREADS=4
export OMP_PLACES=cores
export OMP_PROC_BIND=close

# UCX optimization
export UCX_LOG_LEVEL=error
export UCX_MEMTYPE_CACHE=n
```
### Working directory change
```
# Baseline:
mkdir -p ${HOME}/scratch/${USER}/nwchem/run/${PBS_JOBID}
cd       ${HOME}/scratch/${USER}/nwchem/run/${PBS_JOBID}

# Optimized:
mkdir -p /scratch/${USER}/${PBS_JOBID}
cd /scratch/${USER}/${PBS_JOBID}
```
### MPI execution change
```
# Baseline: Pure MPI (104 processes)
mpirun -np ${NCPUS:-104} nwchem ...

# Optimized: Hybrid MPI+OpenMP (104 MPI × 4 OpenMP)
mpirun -np 104 --map-by ppr:26:node:PE=4 --bind-to core nwchem ...
```

### NWChem Input File Changes

| Feature | Baseline | Optimized | Impact |
|---------|----------|-----------|--------|
| **Scratch directory** | `scratch_dir /tmp` | `scratch_dir /scratch/${USER}/${PBS_JOBID}` | Better I/O on parallel filesystem |
| **Calculation workflow** | SCF + DFT (two-step) | Direct DFT (single-step) | Simpler, faster startup |
| **Integral method** | `direct` (recompute) | `semidirect memsize 2000000000 filesize 0` | 2-5x faster with memory caching |
| **Initial vectors** | SCF orbitals from file | Atomic orbitals | No intermediate files needed |

**Removed from optimized version:**
```
# SCF pre-calculation removed
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
```

**Key optimization in DFT block:**
```
# Baseline:
dft
  direct
  xc b3lyp
  grid fine
  iterations 100
  vectors input w12_scf_cc-pvtz.movecs
  ...
end

# Optimized:
dft
  semidirect memsize 2000000000 filesize 0
  xc b3lyp
  grid fine
  iterations 100
  vectors input atomic
  ...
end
```
# Configuraion Instructions
## Build Instructions
### Prerequisies and Enviroment Setup
```
# Load required modules
module purge
module load nwchem/7.0.0

# Verify NWChem installation
which nwchem
nwchem --version
```
## Configuring Parameters
Our implementation are proven to follow all competition rules.
### Requirements; Library Dependencies
Our implementation requires:
- **NWChem**: Version 7.0.0 (pre-installed on cluster)
- **MPI**: OpenMPI 4.1.x or IntelMPI
- **Linear Algebra**: Intel MKL or OpenBLAS (pre-configured)
### System Settings
**1. OpenMP Thread Configuration**
```
# Hybrid MPI+OpenMP parallelization
export OMP_NUM_THREADS=4
export OMP_PLACES=cores
export OMP_PROC_BIND=close

# For pure MPI (alternative approach)
export OMP_NUM_THREADS=1
```
**2. MPI Communication Optimization**
```
# UCX (Unified Communication X) optimization
export UCX_LOG_LEVEL=error
export UCX_MEMTYPE_CACHE=n

# NCCL settings (if applicable)
export NCCL_DEBUG=WARN
```
**3. NUMA and CPU Affinity**
```
# CPU frequency and NUMA optimization
export OMP_PROC_BIND=close
export OMP_PLACES=cores

# MPI process binding
mpirun --bind-to core --map-by ppr:26:node:PE=4 ...
```
**4. File System and I/O**
```
# Use high-performance scratch filesystem
export SCRATCH_DIR=/scratch/${USER}/${PBS_JOBID}
mkdir -p ${SCRATCH_DIR}
cd ${SCRATCH_DIR}
```
## Steps in optimzing and runnning
**1. Adjust and run `input.sh`**
- Configure the input by editing the `input.sh` file and run the script by
```
./input.sh
```
**2. Execute the optimized script `script.pbs`**
To submit jobs, we run command like
```
qsub script.pbs
```
**3. Read Result**
To read result from a command that is ran, we run command like
```
grep "Total times:" ./run.script.pbs.stdout
```
# Performance Results
## Table 1: Node and MPI Process Scaling
| Feature | Baseline (1 node) | Optimized (1 node) | Optimized (2 nodes) | Optimized (4 nodes) | Impact |
|---------|-------------------|-------------------|---------------------|---------------------|--------|
| **Nodes** | 1 | 1 | 2 | 4 | More parallel resources |
| **Total CPUs** | 104 | 104 | 208 | 416 | Linear scaling |
| **MPI Processes** | 104 | 26 | 52 | 104 | Reduced per-node count |
| **OpenMP Threads** | 1 (pure MPI) | 4 | 4 | 4 | Hybrid parallelization |
| **Total Parallelism** | 104 | 104 (26×4) | 208 (52×4) | 416 (104×4) | Same total threads |
| **MPI Mapping** | Default | `ppr:26:node:PE=4` | `ppr:26:node:PE=4` | `ppr:26:node:PE=4` | Controlled placement |
| **Thread Binding** | None | `--bind-to core` | `--bind-to core` | `--bind-to core` | Better cache locality |
| **Wall Time (s)** | 241.8 | 149.6 | 75.3 | 45.0 | Progressive improvement |
| **Speedup vs Baseline** | 1.00× | 1.62× | 3.21× | 5.37× | Up to 5.37× faster |

## Table 2: Memory Configuration Impact
| Feature | Low Memory | Medium Memory | High Memory | Impact |
|---------|-----------|---------------|-------------|--------|
| **Stack (MB)** | 4000 | 8000 | 16000 | More per-process memory |
| **Heap (MB)** | 50 | 100 | 200 | Minimal impact |
| **Global (MB)** | 5000 | 8000 | 16000 | More parallel memory |
| **Total per Process (MB)** | ~9,050 | ~16,100 | ~32,200 | 3.5× difference |
| **Total Memory (104 procs)** | ~941 GB | ~1,674 GB | ~3,349 GB | Higher utilization |
| **Wall Time (s)** | 44.8 | 45.0 | 36.5 | 18% improvement |
| **Speedup vs Baseline** | 5.40× | 5.37× | 6.63× | Best: 6.63× |

## Table 3: Performance Summary Table
| Configuration | Nodes | MPI×OMP | Memory (stack/heap/global) | Wall Time (s) | Speedup | Efficiency |
|--------------|-------|---------|---------------------------|---------------|---------|------------|
| Baseline | 1 | 104×1 | 8000/100/8000 | 241.8 | 1.00× | 100% |
| Optimized 1N | 1 | 26×4 | 8000/100/8000 | 149.6 | 1.62× | 162% |
| Optimized 2N | 2 | 52×4 | 8000/100/8000 | 75.3 | 3.21× | 161% |
| Optimized 4N | 4 | 104×4 | 8000/100/8000 | 45.0 | 5.37× | 134% |
| Optimized 4N (low mem) | 4 | 104×4 | 4000/50/5000 | 44.8 | 5.40× | 135% |
| **Optimized 4N (high mem)** | **4** | **104×4** | **16000/200/16000** | **36.5** | **6.63×** | **166%** |

# Result analysis

## Graph 1 – Performance Scaling Across Nodes

* Shows how NWChem execution time improves when the number of nodes increases (1 → 2 → 4).

* Wall Time (real elapsed time) drops significantly as more nodes are added.

* Demonstrates effective parallelization where workloads are successfully distributed across multiple CPUs.

* Speedup trend indicates near-linear scaling up to 4 nodes.

* Confirms that multi-node execution reduces computation bottlenecks for large datasets.
* Performance scaling across different nodes shows 4 nodes increased by 31.6% CPU Time and 81.3% Wall Time from the baseline.  
<img src="https://github.com/anishumairaa/APAC-HPC-AI-2025-UPMTeam2/blob/main/images/nwchem-graph-diff-nodes.png?raw=true" alt="NWChem Graph" width="600">
<img src="https://github.com/anishumairaa/APAC-HPC-AI-2025-UPMTeam2/blob/main/images/nwchem-graph-analysis-4nodes.png?raw=true" alt="NWChem Graph" width="600">

## Graph 2 – Comparative Performance on 4 Processing Nodes

* Compares different configuration/job sizes (e.g., 4000, 8000, 16000) under the same 4-node setup.

* The largest configuration (16000) achieves the fastest completion time, meaning NWChem performs best under higher workloads.

* Medium and small configurations (4000 & 8000) take relatively longer, showing less efficiency for smaller-scale jobs.

* Indicates resource utilization on multiple nodes is maximized for larger problem sizes.

* Suggests possible overhead or idle cycles during smaller tasks, reducing parallel efficiency.

* Comparative performance of configurations on different memory directives shows 16000/200/16000 increased by 47.4% CPU Time and 84.8% Wall Time from the baseline.
* 
<img src="https://github.com/anishumairaa/APAC-HPC-AI-2025-UPMTeam2/blob/main/images/nwchem-graph-diff-conf.png?raw=true" alt="NWChem Graph" width="600">
<img src="https://github.com/anishumairaa/APAC-HPC-AI-2025-UPMTeam2/blob/main/images/nwchem-graph-analysis-memory.png?raw=true" alt="NWChem Graph" width="600">

## Graph Analysis Summary (NWChem)

* More nodes = faster computation — demonstrates scalability and efficiency of hybrid MPI+OpenMP implementation.

* Parallel processing is validated — CPU Time far exceeds Wall Time, confirming simultaneous multi-thread execution.

* Speedup ratio improves substantially when doubling or quadrupling node count.

* Optimal performance observed with high workloads on 4-node configuration, aligning with expected HPC scaling behavior.

* Inference: The system performs best when given heavy computational tasks that fully utilize available CPU and memory resources.
