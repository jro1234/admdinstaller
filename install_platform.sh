#!/bin/bash



function installeroutput {
  echo " -- AdaptiveMD INSTALLER |||  $1"
}

CWD=`pwd`


###############################################################################
#                           Install Configuration                             #
# variables to set locations and configuration for different components of    #
# the AdaptiveMD platform - higher ~ more likely needs modification           #
###############################################################################

# PREFIX to all stored environment variables
#   - useful for multiple installations
#   - probably don't need to modify these ones
ENV_BASE=ADAPTIVEMD
ADD_ENV_VARS=True
ENV_VARS_OUT=~/.bashrc
ENV_LOGLEVEL=info

# Use virtualenv or conda? choose 1
ENV_TYPE='virtualenv'
# TODO conda installation setup...
# TODO taskenv option for separate components

# Leave blank if you won't use RADICAL-Pilot
RADICAL_PILOT='radical.pilot'

# Environment preparations
#   - can do something like this here
LOADS[0]="module swap PrgEnv-pgi PrgEnv-gnu"
LOADS[1]="module load python"
LOADS[2]="module load cudatoolkit"

# Install locations for all the components
#   - Everything will go under INSTALL_HOME
#     except the MongoDB
PROJFOLDER=bip149
INSTALL_HOME=$PROJWORK/$PROJFOLDER/$USER/
FOLDER_INSTALL=admd/
FOLDER_ENV=admdenv/
FOLDER_PACKAGES=packages/
FOLDER_PROJECTS=projects/

# IF USING VIRTUALENV as environment,
# User must download OpenMM-Linux precompiled binaries
# This just tells the script where these
# are located on the filesystem.
# This one came from:
#https://simtk.org/frs/download_confirm.php/file/4904/OpenMM-7.0.1-Linux.zip?group_id=161
OPENMM_LOC=$INSTALL_HOME
FOLDER_OPENMM=OpenMM-7.0.1-Linux
OPENMM_LIBRARY_PREFIX=lib/
OPENMM_PLUGIN_PREFIX=lib/plugins/
OPENMM_INSTALL_LOC=$INSTALL_HOME/$FOLDER_INSTALL/$FOLDER_PACKAGES/openmm

# This installer will check for pre-existing mongod
INSTALL_MONGODB=$INSTALL_HOME
FOLDER_MONGODB=mongodb/
VERSION_MONGODB=3.2.20

# Task packages installed from index
#   - openmm only listed under conda index
#   - pandas didn't install even tho required
#     by mdtraj
TASK_PACKAGES='pandas pyemma==2.4'

# Components installed from source
ADAPTIVEMD_PACKAGE=jrossyra/adaptivemd.git
ADAPTIVEMD_BRANCH=rp_integration
#R_UTILS_PKG=radical-cybertools/radical.utils.git
#R_UTILS_BRANCH=devel
#R_SAGA_PKG=radical-cybertools/saga-python.git
#R_SAGA_BRANCH=devel
#R_PILOT_PKG=radical-cybertools/radical.pilot.git
#R_PILOT_BRANCH=devel
# TODO do we still need RP from repos?
#   - remove or uncomment these guys

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
  # TODO some more will be necessary
  installeroutput "Installing AdaptiveMD in a Conda environment"
  ENV='conda create python=3.6 -n'
else
  installeroutput "Must specify to use virtualenv or conda env for installation"
  installeroutput "with the \"ENV_TYPE\" installer variable"
  exit 1
fi

# Required to use AdaptiveMD setup
PREINSTALL="pip install pyyaml ${RADICAL_PILOT}"

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
  echo "export ${ENV_BASE}_DBURL=XXXXXXSTUFFFFF" >> $ENV_VARS_OUT
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

for load in "${LOADS[@]}"
do
  eval $load
done

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

eval $PREINSTALL

mkdir $FOLDER_PROJECTS
mkdir $FOLDER_PACKAGES

# ADAPTIVEMD INSTALL
cd    $FOLDER_PACKAGES
git   clone https://github.com/$ADAPTIVEMD_PACKAGE
cd    adaptivemd
git   checkout $ADAPTIVEMD_BRANCH
pip   install .

pip install $TASK_PACKAGES

# OPENMM INSTALL
cd    $OPENMM_LOC/$FOLDER_OPENMM
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
installeroutput "The application will only run inside its environment!"
installeroutput "source \$${ENV_BASE}_ACTIVATE"

cd $CWD


