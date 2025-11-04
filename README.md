
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
* CUDA efficiency settings
* Warm up execution

  
# Results
### NWChem
* Performance scaling across different nodes shows 4 nodes increased by 31.6% CPU Time and 81.3% Wall Time from the baseline.  
<img src="https://github.com/anishumairaa/APAC-HPC-AI-2025-UPMTeam2/blob/73503bc2ea4fbc676fb2a72fb495919acbb2a726/images/nwchem-graph-diff-nodes.png" alt="Sample Image" width="600" height="500">
* Comparative performance of configurations on different memory directives shows 16000/200/16000 increased by 47.4% CPU Time and 84.8% Wall Time from the baseline.  
<img src="https://github.com/anishumairaa/APAC-HPC-AI-2025-UPMTeam2/blob/73503bc2ea4fbc676fb2a72fb495919acbb2a726/images/deepseek-graph.png" alt="Sample Image" width="600" height="500">
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

