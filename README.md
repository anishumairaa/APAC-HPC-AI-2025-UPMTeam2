
# APAC HPC-AI Competition 2025 - UPM Team 2

Welcome to our project submission for the APAC HPC-AI Competition 2025. This README file provides an overview of our project, the methodologies used, and the results obtained.

Please review https://github.com/anishumairaa/APAC-HPC-AI-2025-UPMTeam2

# Team Members
* Anis Humaira Azman - Team leader
* Nurul Farizatul Aina Mohammad Farizal
* Muhammad Aqil Iqbal Mohd Jamil
* Muhammad Akmal Wanahari

# Project Description
Our project for the APAC HPC AI Competition 2025 focuses on the implementation and optimization of NWChem and DeepSeek-SGLang on the NCI Gadi and NSCC Aspire2p SG supercomputers.

# Objectives
The objective is to leverage these advanced computational tools and high-performance computing resources to solve complex problems in quantum chemical molecular dynamics (NWChem) and large language model (DeepSeek) efficiently, with a primary focus on achieving maximum optimization.
### NwChem
In NWChem, we were tasked with running the NWChem input file with large, iterative matrix multiplications, and heavy operations within 5 minutes time constraint. We need **to improve performance by accomplishing lower processing time used by CPUs and elapsed time.**  
  
Performance metric:
1. CPU time (sec)
2. Wall time (sec)
### DeepSeek-SGLang
In DeepSeek-SGLang, we were tasked with running the DeepSeek-R1 model on the SGLang framework using the ShareGPT dataset, with the goal of completing execution within just 7 minutes. We are required **to improve performance by accomplishing higher value of total token processing speed and other metrics.**  
  
Performance metric:
1. Total token throughput (tokens/sec)
2. Input token throughput (tokens/sec)
3. Output token throughput (tokens/sec)
4. Request throughput (req/sec)

# Optimization Method
### NWChem
* Implementation of fast storage
* Application of OpenMP and MPI (Hybrid Parallelization)
* Changes in input file

### DeepSeek-SGLang
* NCCL communication tuning
```
export NCCL_IB_HCA=mlx5
```
> Specifies mlx5 RDMA interface to use for communication
```
export NCCL_NET_GDR_LEVEL=PHB
```
> Control when to use GPU Direct RDMA between a NIC and a GPU

```
export NCCL_SOCKET_IFNAME="ib0,bond0,eno1,eth0"
```
> Specifies the network interfaces NCCL should use: InfiniBand

>
* CUDA efficiency settings
 ```
export CUDA DEVICE MAX CONNECTIONS=1
```
> Limits how many concurrent connections each CUDA device (GPU) can have 
 ```
export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,,6,7
```
> Makes only GPUs 0–7 visible to the program. 
 ```
export NVIDIA_TF32_OVERRIDE=0
```
> Disable TF32 to only adhere to bfloat16 for more math accuracy

* Warm up execution
  
# Results
### NWChem
* (achievement, graphs)
### DeepSeek-SGLang
* Total token throughput that defines as speed of token processed and generated is increased by 11% from the baseline.  
<img src="https://github.com/anishumairaa/APAC-HPC-AI-2025-UPMTeam2/blob/73503bc2ea4fbc676fb2a72fb495919acbb2a726/images/deepseek-graph.png" alt="Sample Image" width="600" height="500">


# Challenges
* Memory Management – handling large molecular datasets and optimizing memory use is complex and resource-intensive.
* Time-Consuming Process – Frequent errors and repeated test runs increased total development time.
* Walltime exceeded
* Batch jobs stuck in a queue

# Conclusion
The optimized NWChem runs showed significant improvements in execution time and scalability, achieving faster Wall Time and better parallel efficiency as more cores were added.  
  
The optimized DeepSeek model has shown an increasing improvements in throughput and scalability, achieving higher token generation speed and better GPU utilization. These optimizations allow the model to fully leverage the underlying multi-GPU (16×H100) infrastructure, delivering faster inference times while maintaining output consistency and accuracy.

