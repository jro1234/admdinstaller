#!/bin/bash
set -e
CWD=`pwd`

# Name for top folders of this installation
# - install any number of envs simultanously
#   by just chaning the name of each one here
INSTALL_NAME="admd-summit"

####################################################
# 0.         Configuration                         #
####################################################
#==================================================#
# 0.1 Options                                      #
#==================================================#
# Do you need MongoDB Installed?
# - can reuse for AdaptiveMD environments
INSTALL_MONGO="True"
MONGOVERSION="linux-x86_64-3.6.10"
# True will trigger RP-Saga-RU from source
USE_RP="False"
# True to let other users execute software
GROUPINSTALL="True"
# This is annoying detail of using the python
# anaconda module below
CONDA_HOME="/sw/summit/python/3.6/anaconda3/5.3.0"

#==================================================#
# 0.2 Platform Layout on Filesystem                #
#==================================================#
#--------------------------------------------------#
# 0.2.1 Change for different HPC filesystems
#--------------------------------------------------#
SOFTWARE_DRIVE="/ccs/proj/bif112"
DATA_DRIVE="/gpfs/alpine/proj-shared/bif112/$USER"
# Download from simtk website, give location here
OPENMM_SOURCE=""
#--------------------------------------------------#
# 0.2.2 Relative layout of Platform Installation
#--------------------------------------------------#
INSTALL_HOME="$SOFTWARE_DRIVE/$INSTALL_NAME"
# - note mongo is outside of the platform scope a bit
#   since you'd typically use it globally
MONGO_HOME="$SOFTWARE_DRIVE"
# - could do like this to install for each platform
#MONGO_HOME="$INSTALL_HOME"
ENV_HOME="$CONDA_HOME"
PKG_HOME="$INSTALL_HOME/packages"
OPENMM_HOME="$PKG_HOME/openmm"
# --> Workflow Templates & Data go here
DATA_HOME="$DATA_DRIVE/$INSTALL_NAME"
WORKFLOW_HOME="$DATA_HOME/workflows"

#==================================================#
# 0.3 AdaptiveMD Platform Packages preparations    #
#==================================================#
#--------------------------------------------------#
# 0.3.1 Unload/Load Modules                        
#     - can swap module for packages below        
#--------------------------------------------------#
module unload xl
module unload python
module load gcc
module load python/3.6.6-anaconda3-5.3.0
#module load py-setuptools
#module load py-pip
#module load py-virtualenv
# FIXME install with linking errors out
module load netlib-lapack

#--------------------------------------------------#
# 0.3.2 Packages via pip/conda
#   - PyEMMA not happy on PowerPC, use Rhea
#--------------------------------------------------#
TASK_PACKAGES1[0]="pyyaml"
TASK_PACKAGES1[1]="mdtraj"
#TASK_PACKAGES1[2]="pyemma"
#TASK_PACKAGES1[1]="cython"
#TASK_PACKAGES2[0]="pandas"
#TASK_PACKAGES2[1]="mdtraj"
#TASK_PACKAGES2[2]="pyemma"

TASK_PACKAGES1[0]="pyyaml"
TASK_PACKAGES1[1]="cython"
TASK_PACKAGES1[2]="numpy"
TASK_PACKAGES1[3]="scipy"
TASK_PACKAGES1[4]="pandas"
TASK_PACKAGES1[5]="mdtraj"
TASK_PACKAGES1[6]="pyemma"

####################################################
#      INSTALLATION OPERATIONS                     #
####################################################
#==================================================#
# 1. Create AdaptiveMD Platform Environment        #
#==================================================#
# Workflows Directory
mkdir $DATA_HOME
mkdir $WORKFLOW_HOME
# Software Directory
mkdir $INSTALL_HOME
mkdir $PKG_HOME
mkdir $OPENMM_HOME

#==================================================#
# 2. MongoDB Installation                          #
#==================================================#
if [ "$INSTALL_MONGO" = "True" ]
then
    cd $MONGO_HOME
    if [ ! -d "mongodb" ]
    then
        curl -O https://fastdl.mongodb.org/linux/mongodb-$MONGOVERSION.tgz
        tar -zxvf mongodb-$MONGOVERSION.tgz
        mkdir mongodb
        mv mongodb-$MONGOVERSION/* mongodb/
        rm mongodb-$MONGOVERSION.tgz
    else
        echo "Found existing 'mongodb' folder, skipping database install"
    fi
fi

#==================================================#
# 3. Create New Virtualenv                         #
#==================================================#
#python -m virtualenv $ENV_HOME
conda config --add channels conda-forge
conda config --add channels omnia
conda create -y -n admdenv
source $ENV_HOME/bin/activate admdenv
echo "PYTHON: $(which python)"
echo "version: $(python --version)"

#==================================================#
# 4. Clone the Chignolin Workflow Test             #
#==================================================#
# Workflow template with chignolin
cd $WORKFLOW_HOME
git clone https://github.com/jrossyra/test-workflows.git

#==================================================#
# 5. CLone the Workflow Generator                  #
#==================================================#
cd $INSTALL_HOME
git clone https://github.com/jrossyra/admdgenerator.git

#==================================================#
# 6. Install task packages                         #
#==================================================#
cd $PKG_HOME
for PACKAGE in "${TASK_PACKAGES1[@]}"
do
  #python -m pip install $PACKAGE --no-cache-dir
  conda install -y $PACKAGE
done

# FIXME linking not working
## ##git clone https://github.com/numpy/numpy.git
## ##cd numpy
## ##echo -e "library_dirs=/autofs/nccs-svm1_sw/summit/.swci/1-compute/opt/spack/20180914/linux-rhel7-ppc64le/gcc-8.1.1/netlib-lapack-3.8.0-p74bsneivus4jck562lq7drw2s7i4ytd/lib64\ninclude_dirs=/autofs/nccs-svm1_sw/summit/.swci/1-compute/opt/spack/20180914/linux-rhel7-ppc64le/gcc-8.1.1/netlib-lapack-3.8.0-p74bsneivus4jck562lq7drw2s7i4ytd/include" > site.cfg
## ##python -m pip install .
## ##
## ##cd $PKG_HOME
## ##git clone https://github.com/scipy/scipy.git
## ##cd scipy
## ##python -m pip install .
## ##
## ##for PACKAGE in "${TASK_PACKAGES2[@]}"
## ##do
## ##  python -m pip install $PACKAGE --no-cache-dir
## ##done

#cd $OPENMM_SOURCE
#expect -c "
#  set timeout -1
#  spawn sh install.sh
#  expect \"Enter?install?location*\"
#  send  \"$OPENMM_HOME\r\"
#  expect \"Enter?path?to?Python*\"
#  send  \"\r\"
#  expect eof
#"

#==================================================#
# 7. Install AdaptiveMD from source                #
#==================================================#
cd $PKG_HOME
git clone https://github.com/jrossyra/adaptivemd.git
cd adaptivemd
git fetch
git checkout devel
pip install .

#==================================================#
# 8. Install Radical Pilot Stack from source       #
#==================================================#
if [ "$USE_RP" = "True" ]
then
    cd $PKG_HOME
    git clone https://github.com/radical-cybertools/radical.utils
    cd radical.utils
    pip install .

    cd $PKG_HOME
    git clone https://github.com/radical-cybertools/saga-python
    cd saga-python
    pip install .

    cd $PKG_HOME
    git clone https://github.com/radical-cybertools/radical.pilot
    cd radical.pilot
    git fetch --all
    # TODO what is the best branch to try?
    #      issue #1755 says this one
    git checkout fix/titan_deactivate
    pip install .
fi

#==================================================#
# 9. Group Permission for using software           #
#==================================================#
if [ "$GROUPINSTALL" = "True" ]
then
    chmod -R +x $ENV_HOME
fi

#======#
#======#
# DONE #
#======#
#======#
cd $CWD
