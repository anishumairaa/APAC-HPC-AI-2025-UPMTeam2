# install miniforge

wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O ${HOME}/scratch/Miniforge3-Linux-x86_64.sh

bash ${HOME}/scratch/Miniforge3-Linux-x86_64.sh -b -p ~/scratch/miniforge

${HOME}/scratch/miniforge/bin/conda init

bash


# install python3.12

conda create -p ${HOME}/scratch/py312 python=3.12 -y



# install sglang into python

${HOME}/scratch/py312/bin/pip install --upgrade pip

${HOME}/scratch/py312/bin/pip install "sglang[all]>=0.5.0rc2"


# download json dataset file

wget https://huggingface.co/datasets/anon8231489123/ShareGPT_Vicuna_unfiltered/resolve/main/ShareGPT_V3_unfiltered_cleaned_split.json
