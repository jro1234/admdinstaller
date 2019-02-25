#!/bin/bash
set -e
CWD=`pwd`

# Name for top folders of this installation
# - install any number of envs simultanously
#   by just chaning the name of each one here
INSTALL_NAME="admd-test"

####################################################
# 0.         Configuration                         #
####################################################
#==================================================#
# 0.1 Options                                      #
#==================================================#
# Do you need MongoDB Installed?
# - can reuse for AdaptiveMD environments
INSTALL_MONGO="True"
MONGOVERSION="linux-x86_64-3.3.0"
# True will trigger RP-Saga-RU from source
USE_RP="False"
# True to let other users execute software
GROUPINSTALL="False"

#==================================================#
# 0.2 Platform Layout on Filesystem                #
#==================================================#
#--------------------------------------------------#
# 0.2.1 Change for different HPC filesystems
#--------------------------------------------------#
SOFTWARE_DRIVE="/u/sciteam/$USER"
DATA_DRIVE="/scratch/sciteam/$USER"
# Download from simtk website, give location here
#OPENMM_SOURCE="/ccs/proj/bip149/OpenMM-7.0.1-Linux"
#--------------------------------------------------#
# 0.2.2 Relative layout of Platform Installation
#--------------------------------------------------#
INSTALL_HOME="$SOFTWARE_DRIVE/$INSTALL_NAME"
# - note mongo is outside of the platform scope a bit
#   since you'd typically use it globally
MONGO_HOME="$SOFTWARE_DRIVE"
# - could do like this to install for each platform
#MONGO_HOME="$INSTALL_HOME"
ENV_HOME="$INSTALL_HOME/admdenv"
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
module unload PrgEnv-cray
module load PrgEnv-gnu
module unload gcc
module load gcc/5.3.0
#module unload bwpy
module load bwpy/2.0.1
module load bwpy-mpi
module add cudatoolkit
#--------------------------------------------------#
# 0.3.2 Packages via pip/conda
#--------------------------------------------------#
TASK_PACKAGES[0]="pyyaml"
TASK_PACKAGES[1]="cython==0.29"
TASK_PACKAGES[2]="numpy==1.15.3"
TASK_PACKAGES[3]="scipy==1.1.0"
TASK_PACKAGES[4]="pandas==0.23.4"
TASK_PACKAGES[5]="mdtraj==1.9.1"
TASK_PACKAGES[6]="pyemma==2.5"

####################################################
#      INSTALLATION OPERATIONS                     #
####################################################
#==================================================#
# 1. MongoDB Installation                          #
#==================================================#
if [ "$INSTALL_MONGO" = "True" ]
then
    cd $MONGO_HOME
    curl -O https://fastdl.mongodb.org/linux/mongodb-$MONGOVERSION.tgz
    tar -zxvf mongodb-$MONGOVERSION.tgz
    mv mongodb-$MONGOVERSION/ mongodb
    rm mongodb-$MONGOVERSION.tgz
fi

#==================================================#
# 2. Create AdaptiveMD Platform Environment        #
#==================================================#
# Workflows Directory
mkdir -p $WORKFLOW_HOME
# Software Directory
mkdir -p $PKG_HOME
mkdir -p $OPENMM_HOME

#==================================================#
# 3. Create New Virtualenv                         #
#==================================================#
export EPYTHON="python2.7"
python --version

virtualenv $ENV_HOME
source     $ENV_HOME/bin/activate

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
for PACKAGE in "${TASK_PACKAGES[@]}"
do
  pip install $PACKAGE --no-cache-dir
done

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
