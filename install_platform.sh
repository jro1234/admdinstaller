#!/bin/bash


function installeroutput {
  echo " -- AdaptiveMD INSTALLER |||  $1"
}

CWD=`pwd`


###############################################################################
#                           Install Configuration                             #
# variables that set the install locations for different components of        #
# the AdaptiveMD platform                                                     #
###############################################################################

# The installer will check for pre-existing mongod and obort if found
INSTALL_MONGODB=/lustre/or-hydra/cades-bsd/osz/
FOLDER_MONGODB=mongodb/
VERSION_MONGODB=3.3.0
ADDRESS_MONGODB=

# Add the adaptivemd environment variables?
ADD_ENV_VARS=True
ENV_LOGLEVEL=info

# Use virtualenv or conda? choose 1
ENV_TYPE='virtualenv'

# PREFIX to all stored environment variables
#   - useful for multiple installations
ENV_BASE=ADAPTIVEMD

#
INSTALL_HOME=/lustre/or-hydra/cades-bsd/$USER/
FOLDER_INSTALL=admd/
FOLDER_ENV=admdenv/
FOLDER_PACKAGES=packages/
FOLDER_PROJECTS=projects/

#LOAD_PYTHON="module load python/2.7.13"
LOAD_PYTHON="echo \"Using default Python `which python`\""
LOAD_CUDA="module load cuda/7.5"
#LOAD_CUDA="module load cuda/9.2"

ADAPTIVEMD_PKG=jrossyra/adaptivemd.git
ADAPTIVEMD_BRANCH=rp_integration

R_UTILS_PKG=radical-cybertools/radical.utils.git
R_UTILS_BRANCH=devel

R_SAGA_PKG=radical-cybertools/saga-python.git
R_SAGA_BRANCH=devel

R_PILOT_PKG=radical-cybertools/radical.pilot.git
R_PILOT_BRANCH=devel

# USING VIRTUALENV as environment
# User must download OpenMM-Linux precompiled binaries
# and untar it. This just tells the script where these
# are located on the filesystem.
# This one came from:
#https://simtk.org/frs/download_confirm.php/file/4904/OpenMM-7.0.1-Linux.zip?group_id=161
OPENMM_LOC=$HOME
FOLDER_OPENMM=OpenMM-7.0.1-Linux
OPENMM_LIBRARY_PREFIX=lib/
OPENMM_PLUGIN_PREFIX=lib/plugins/
OPENMM_INSTALL_LOC=$INSTALL_HOME/$FOLDER_INSTALL/$FOLDER_PKG/openmm

ENV_VARS_OUT=~/.bashrc

###############################################################################
#                  some checks of installer variables                         #
###############################################################################
if [ "$ENV_TYPE" == "virtualenv" ]
then
  installeroutput "Installing AdaptiveMD in a Virtualenv environment"
  if [ -z $OPENMM_LOC ];
  then
    installeroutput "If using virtualenv, you must pre-download OpenMM"
    installeroutput "binaries and give the location in the variable \"OPENMM_LOC\""
    exit 1
  else
    ENV='virtualenv'
  fi
elif [ "$ENV_TYPE" == *"conda" ]
then
  installeroutput "Installing AdaptiveMD in a Conda environment"
  ENV='conda create python=3.6 -n'
else
  installeroutput "Must specify to use virtualenv or conda env for installation"
  installeroutput "with the \"ENV_TYPE\" installer variable"
  exit 1
fi

###############################################################################
#                           Install MongoDB                                   #
###############################################################################
if [ ! -x "$(command -v mongod)" ]; then
  installeroutput "No MongoDB found, downloading version $VERSION_MONGODB"
  cd $INSTALL_MONGODB
  curl -O https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-$VERSION_MONGODB.tgz
  tar -zxvf mongodb-linux-x86_64-$VERSION_MONGODB.tgz
  mkdir $FOLDER_MONGODB
  mv mongodb-linux-x86_64-$VERSION_MONGODB/ $FOLDER_MONGODB
  rm mongodb-linux-x86_64-$VERSION_MONGODB.tgz
  mongodb_bins=${INSTALL_MONGODB}/${FOLDER_MONGODB}/mongodb-linux-x86_64-$VERSION_MONGODB/bin/
  echo -e "\n\n#################################" >> $ENV_VARS_OUT
  echo "#    Adding MongoDB to PATH     #" >> $ENV_VARS_OUT
  echo "export PATH=${mongodb_bins}:\$PATH" >> $ENV_VARS_OUT
  echo "export ADAPTIVEMD_DBURL=XXXXXXSTUFFFFF" >> $ENV_VARS_OUT
  echo -e "#################################\n" >> $ENV_VARS_OUT
  source $ENV_VARS_OUT
  installeroutput "MongoDB daemon installed here: "
else
  installeroutput "Found MongoDB already installed at: "
fi
installeroutput `which mongod`
cd $CWD

###############################################################################
#                           Installing Workflow Components                    #
###############################################################################

eval  $LOAD_PYTHON
cd    $INSTALL_HOME
mkdir $FOLDER_INSTALL
cd    $FOLDER_INSTALL
$ENV $INSTALL_HOME/$FOLDER_INSTALL/$FOLDER_ENV

if [ "$ADD_ENV_VARS" = "True" ]
then
  installeroutput "Appending $ENV_VARS_OUT with AdaptiveMD workflow variables"
  installeroutput "and LD_LIBRARY_PATH with OpenMM libraries"
  echo -e "\n\n##############################################" >> $ENV_VARS_OUT
  echo "#   START OF WORKFLOW ENVIRONMENT VARIABLES  #" >> $ENV_VARS_OUT
  echo "export ${ENV_BASE}_ENV=${INSTALL_HOME}/${FOLDER_INSTALL}/${FOLDER_ENV}" >> $ENV_VARS_OUT
  echo "export ${ENV_BASE}_ENV_ACTIVATE=\${${ENV_BASE}_ENV}/bin/activate" >> $ENV_VARS_OUT
  echo "export ${ENV_BASE}_ENV_DEACTIVATE=deactivate" >> $ENV_VARS_OUT
  echo "export ${ENV_BASE}_LOGLEVEL=$ENV_LOGLEVEL" >> $ENV_VARS_OUT
  echo "export ${ENV_BASE}_SANDBOX=" >> $ENV_VARS_OUT
  echo "export ${ENV_BASE}_PROJECTS=${INSTALL_HOME}/${FOLDER_INSTALL}/${FOLDER_PROJECTS}/" >> $ENV_VARS_OUT
  #echo "export ${ENV_BASE}_RUNS=$INSTALL_HOME${FOLDER_}/runs/" >> ~/.bashrc
  #echo "export ${ENV_BASE}_ADAPTIVEMD=$INSTALL_HOME$FOLDER_ADMDRP${FOLDER_ADMDRP_PKG}adaptivemd/" >> ~/.bashrc
  echo "export ${ENV_BASE}_DATA=${INSTALL_HOME}/${FOLDER_INSTALL}" >> $ENV_VARS_OUT
  echo "export ${ENV_BASE}_PACKAGES=${INSTALL_HOME}${FOLDER_INSTALL}/${FOLDER_PACKAGES}" >> $ENV_VARS_OUT
  echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${OPENMM_INSTALL_LOC}/${OPENMM_PLUGIN_PREFIX}" >> $ENV_VARS_OUT
  echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${OPENMM_INSTALL_LOC}/${OPENMM_LIBRARY_PREFIX}" >> $ENV_VARS_OUT
  echo "#source \$${ENV_BASE}_ENV_ACTIVATE" >> $ENV_VARS_OUT
  echo -e "##############################################\n" >> $ENV_VARS_OUT
fi

# ACTIVATE ENV
source $ENV_VARS_OUT
eval source \$${ENV_BASE}_ENV_ACTIVATE

# Required to use installer
pip install pyyaml

mkdir $FOLDER_PROJECTS
mkdir $FOLDER_PACKAGES

# ADAPTIVEMD INSTALL
cd    $FOLDER_INSTALL/$FOLDER_PACKAGES
git   clone https://github.com/$ADAPTIVEMD_PKG
cd    adaptivemd
git   checkout $ADAPTIVEMD_BRANCH
pip   install .

# OPENMM INSTALL
cd    $OPENMM_LOC/$FOLDER_OPENMM
eval  $LOAD_CUDA
OPENMM_CUDA_COMPILER=`which nvcc`

expect -c "
    set timeout 100
    spawn sh install.sh
    expect \"Enter?install?location*\"
    send  \"$OPENMM_INSTALL_LOC\r\"
    expect \"Enter?path?to?Python*\"
    send  \"\r\"
    expect eof
    "


installeroutput "FOR YOUR WORKFLOW TO RUN PROPERLY, UNCOMMENT THIS LINE IN"
installeroutput "YOUR $ENV_VARS_OUT FILE (or issue the same command in each task)"
installeroutput "source \$${ENV_BASE}_ACTIVATE"

cd $CWD


