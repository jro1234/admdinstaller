
# HPC Environment ------------------------------------------------>>>#
module load python
export OMP_NUM_THREADS=12

# AdaptiveMD Platform Locations ---------------------------------->>>#
export ADMD_NAME="admd-test"
export ADMD_SOFTWARE="/ccs/proj/bip149/$USER/$ADMD_NAME"
export ADMD_DATA="/lustre/atlas/proj-shared/bip149/$USER/$ADMD_NAME"

ADMD_HOSTNAME=`hostname | awk -F "-" '{print $1}' | tr -d '0123456789'`
#ADMD_HOSTNAME=$(cut -d '-' -f1 <<< `hostname`)
if [ "$ADMD_HOSTNAME" = "titan" ]
then
  module load tmux
  module switch PrgEnv-pgi PrgEnv-gnu

  export ADMD_NAME="admd-test"
  export NETDEVICE="bond0"
  # this one is run through `eval`
  export OPENMM_PLATFORM="module load cudatoolkit/7.5.18-1.0502.10743.2.1"
elif [ "$ADMD_HOSTNAME" = "rhea" ]
then
  module unload PE-intel
  module load PE-gnu
  module load python_setuptools
  module load python_pip
  module load python_virtualenv
  
  export ADMD_NAME="admd-rhea"
  export NETDEVICE="ib0"
  export OPENMM_PLATFORM=""
fi

# MONGODB -------------------------------------------------------->>>#
# probably need different NETDEVICE on login vs compute nodes
export NETDEVICE="bond0"
export PATH="$/ccs/proj/bip149/$USER/mongodb/bin/:$PATH"
# this should be pretty general
export LOGIN_HOSTNAME=`ip addr show $NETDEVICE | grep -Eo '(addr:)?([0-9]*\.){3}[0-9]*' | head -n1`
# this will give unpredictable result if more than 1 mongod running
DBPORT=`netstat -tnulp 2> /dev/null | grep mongod | tail -n1 | awk -F":" '{print $2}' | awk '{print $1}'`
if [ ! -z "$DBPORT" ]; then
  export ADMD_DBURL="mongodb://$LOGIN_HOSTNAME:$DBPORT/"
else
  export ADMD_DBURL="mongodb://$LOGIN_HOSTNAME:27017/"
fi

# These are for convenience, `kill_amongod` is not safe to use if
# multiple mongod are running and you want to kill specific one.
function list_mongods {
  mongods=`ps faux | grep "mongod" | grep -v "grep"`
  echo "Current mongod processes:"
  printf '%s\n' "${mongods[@]}"
}

function kill_amongod {
  kill `ps faux | grep "mongod" | grep -v "grep"| tail -n1 | awk '{print $2}'`
}

# AdaptiveMD Python ENV ------------------------------------------>>>#
export ADMD_ENV="$ADMD_SOFTWARE/admdenv"
export ADMD_ENV_ACTIVATE="$ADMD_ENV/bin/activate"
export ADMD_ENV_DEACTIVATE="deactivate"
export ADMD_PACKAGES="$ADMD_SOFTWARE/packages"
export ADMD_ADAPTIVEMD="$ADMD_PACKAGES/adaptivemd"
export ADMD_FILES="$ADMD_ADAPTIVEMD/examples/files"
export ADMD_GENERATOR="$ADMD_SOFTWARE/admdgenerator"
export ADMD_RUNTIME="$ADMD_GENERATOR/runtime"

# AdaptiveMD Workflow Runtime ------------------------------------>>>#
export ADMD_WORKFLOWS="$ADMD_DATA/workflows"
export ADMD_SANDBOX="$ADMD_DATA/workers"
export ADMD_PROJECTS="$ADMD_DATA/projects"
export ADMD_PROFILE="INFO"

# OpenMM --------------------------------------------------------->>>#
export OPENMM_CPU_THREADS="$OMP_NUM_THREADS"
# this one is run through `eval`
export OPENMM_PLATFORM="module load cudatoolkit/7.5.18-1.0502.10743.2.1"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$ADMD_PACKAGES/openmm/lib/plugins"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$ADMD_PACKAGES/openmm/lib"

# PYEMMA  -------------------------------------------------------->>>#
export PYEMMA_NJOBS=$OMP_NUM_THREADS

# For convenience while working with beta version ---------------->>>#
export PATH="$ADMD_RUNTIME:$PATH"

# RP Config ------------------------------------------------------>>>#
export LD_PRELOAD="/lib64/librt.so.1"
export RP_ENABLE_OLD_DEFINES="True"
export RADICAL_PILOT_DBURL="${ADMD_DBURL}rp"
export RADICAL_SAGA_PTY_VERBOSE="WARNING"
export RADICAL_VERBOSE="WARNING"
export RADICAL_SANDBOX="/lustre/atlas/scratch/$USER/bip149/radical.pilot.sandbox"
export RADICAL_PILOT_PROFILE="True"
export RADICAL_PROFILE="True"
