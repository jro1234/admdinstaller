## Using AdaptiveMD on an HPC or Computer Cluster Resource
To work correctly on an HPC platform requires AdaptiveMD to
manage its workflow creation and execution given the LRMS
(ie PBS, Slurm, etc) that distributes compute resources, and
activate repeatedly and correctly in many different locations
on the resource's internal network. Tasks will run on compute
nodes, the workflow runtime instance on a login/head node or
possibly from a remote location. 

To make this all work, AdaptiveMD needs some configuration
to be stored in the user's environment and load automatically
for new shell instances that come up during the course of a
workflow, before (and to help with) any AdaptiveMD components.
For now, the solution is to export a set of environment vars
and functionality from your bashrc file. On a given resource,
different components will require different environments so
some of these values will be overwritten by AdaptiveMD
components downstream of your user profile from bashrc.
More on that later...

When first deploying AdaptiveMD on a new platform, you will
have to spend some time figuring out the filesystem and
preparing for the installation. When using virtualenv,
OpenMM has to be downloaded from behind a login wall on the
internet. The MongoDB functionality may need some
logic tuning. 

To manage multiple hosts you might
utilize in the course of a workflow, you can include if-elif
conditions in your bashrc to do something different for each
different host on the platform like this. In this example, we
needed different
modules to load GNU and virtualenv, have different NETDEVICE,
and only configure OpenMM on one. The commands to get a
helpful ADMD_HOSTNAME will certainly vary by resource.

```bash
ADMD_HOSTNAME=`hostname | awk -F "-" '{print $1}' | tr -d '0123456789'`
if [ "$ADMD_HOSTNAME" = "titan" ]
then
  module load tmux
  module switch PrgEnv-pgi PrgEnv-gnu

  export ADMD_NAME="admd-test"
  export NETDEVICE="bond0"
  export OPENMM_PLATFORM="module load cudatoolkit/7.5.18-1.0502.10743.2.1"

elif [ "$ADMD_HOSTNAME" = "rhea" ]
then
  module switch PE-intel PE-gnu
  module load python_setuptools
  module load python_pip
  module load python_virtualenv

  export ADMD_NAME="admd-rhea"
  export NETDEVICE="ib0"
  export OPENMM_PLATFORM=""

fi
```

In addition to the vars that help create our AdaptiveMD
environment, there are likely modules you
need to load such as CUDA, a (GNU) programming environment,
tmux, and python modules with numerical packages linked to
HPC numeric libraries like BLAS and LAPACK provided by the
admin. (The current OLCF Titan installer does not link
optimized numeric libraries and installs numpy from pip.)
Some of these modules may be needed for AdaptiveMD, some
only for a particular task.
### --> OLCF Titan modules to use AdaptiveMD<br/>
`module load python`<br/>
`module switch PrgEnv-pgi PrgEnv-gnu`<br/>
###   --> OLCF Titan modules to use OpenMM inside MD task:
`module load cudatoolkit`

Task-related Environment Vars that are read by the AdaptiveMD.
Others are created and utilized during workflow execution.

```
 OPENMM_PLATFORM
      name of cuda/gpu module used by OpenMM

 PYEMMA_NJOBS
      number of threads for PyEMMA to use
```

These environment variables are used to create and organize
the AdaptiveMD Workflow Platform. Some are for conveniently
changing the environment, some are actually used and read
by the platform at runtime. These ones are required and can
be specified differently than shown below, but must evaluate
as described for the platform to run correctly.

```
 ADMD_ENV_ACTIVATE
      used as the virtualenv/conda env activation command

 ADMD_ENV_DEACTIVATE
      used as the env deactivation command

 ADMD_FILES
      location used by the platform to look for new MD systems

 ADMD_GENERATOR**
      location of AdaptiveMD workflow generator scripts

 ADMD_RUNTIME**
      location of AdaptiveMD runtime scripts

 ** these ones are part of a setup paradigm that will change
    and these current tools depracated without replacement

 ADMD_PROJECTS
      location of AdaptiveMD project data

 ADMD_SANDBOX
      location of task execution working directories

 ADMD_DBURL
      URL to look for a mongodb

 NETDEVICE
      name of the active network device for connecting to database host
```

Any/all of these values would potentially change when deploying
the platform to a new resource. Additionally, depending on the
location of a platform layer, some of the values might need
overwriting during workflow execution. For example, on the compute
nodes the NETDEVICE is likely different, so before any
AdaptiveMD components are active this var needs to be overwritten.
Another example would be OMP_NUM_THREADS, on a head node this
should be less than the available cores, but on a compute node
it can be as high as the number of cores. 

More environment vars are built somewhere in the AdaptiveMD
platform and required to run workflows successfully. Maybe
there is some logic in them that breaks when moving to new
resources. This possibility should become more remote with the
Python-based AdaptiveMD runtime that is in development now.
Some of these vars are
for the environment, some are required by dependencies:

```
 LOGIN_HOSTNAME
 ADMD_DB
 DBPORT
 OPENMM_CUDA_COMPILER
 OPENMM_CPU_THREADS
```

The logic of building MongoDB ENV VARS needs close attention when
first deploying on a platform. Workflow files should specify a
non-default (other than 27017) port number for mongod, and manage
this automatically so you can use default manually without
extra complication.
```bash
# MONGODB -------------------------------------------------------->>>#
# probably need different NETDEVICE on login vs compute nodes
export NETDEVICE="bond0"
export PATH="$ADMD_SOFTWARE/mongodb/bin/:$PATH"
# this should be pretty general
export LOGIN_HOSTNAME=`ip addr show $NETDEVICE | grep -Eo '(addr:)?([0-9]*\.){3}[0-9]*' | head -n1`
# this will give unpredictable result if more than 1 mongod running
MONGOPORT=`netstat -tnulp 2> /dev/null | grep mongod | tail -n1 | awk -F":" '{print $2}' | awk '{print $1}'`
if [ ! -z "$MONGOPORT" ]; then
  export ADMD_DBURL="mongodb://$LOGIN_HOSTNAME:$MONGOPORT/"
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
```

Change these 3, other ADMD_X vars should largely fall into line
Change only ADMD_NAME if rest is properly configured, and you can
now easily switch between multiple installations of the platform.
```bash
# AdaptiveMD Platform Locations ---------------------------------->>>#
export ADMD_NAME="admd-test"
export ADMD_SOFTWARE="/ccs/proj/bip149/$ADMD_NAME"
export ADMD_DATA="/lustre/atlas/proj-shared/bip149/$USER/$ADMD_NAME"

# HPC Environment ------------------------------------------------>>>#
module load python
export OMP_NUM_THREADS=12

# AdaptiveMD Python ENV ------------------------------------------>>>#
export ADMD_ENV="$ADMD_SOFTWARE/admdenv"
export ADMD_ENV_ACTIVATE="$ADMD_ENV/bin/activate"
export ADMD_ENV_DEACTIVATE="deactivate"
export ADMD_ADAPTIVEMD="$ADMD_SOFTWARE/adaptivemd"
export ADMD_FILES="$ADMD_ADAPTIVEMD/examples/files"
export ADMD_GENERATOR="$ADMD_SOFTWARE/generator"
export ADMD_RUNTIME="$ADMD_GENERATOR/runtime"

# AdaptiveMD Workflow Runtime ------------------------------------>>>#
export ADMD_WORKFLOWS="$ADMD_DATA/workflows"
export ADMD_SANDBOX="$ADMD_DATA/workers"
export ADMD_PROJECTS="$ADMD_DATA/projects"
export ADMD_PROFILE="INFO"
```

Task-related variables, these are currently read . With virtualenv
you'll need to download OpenMM from internet
and figure out which CUDA module works with that version.
```bash
# OpenMM --------------------------------------------------------->>>#
export OPENMM_CPU_THREADS="$OMP_NUM_THREADS"
# this one is run through `eval`
export OPENMM_PLATFORM="module load cudatoolkit/7.5.18-1.0502.10743.2.1"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$ADMD_SOFTWARE/openmm/lib/plugins"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$ADMD_SOFTWARE/openmm/lib"

# PYEMMA  -------------------------------------------------------->>>#
export PYEMMA_NJOBS=$OMP_NUM_THREADS

# For convenience while working with beta version ---------------->>>#
export PATH="$ADMD_RUNTIME:$PATH"
```

Config if using RP, some of these will need updating
```bash
# RP Config ------------------------------------------------------>>>#
export LD_PRELOAD="/lib64/librt.so.1"
export RP_ENABLE_OLD_DEFINES="True"
export RADICAL_PILOT_DBURL="${ADMD_DBURL}rp"
export RADICAL_SAGA_PTY_VERBOSE="WARNING"
export RADICAL_VERBOSE="WARNING"
export RADICAL_SANDBOX="/lustre/atlas/scratch/$USER/bip149/radical.pilot.sandbox"
export RADICAL_PILOT_PROFILE="True"
export RADICAL_PROFILE="True"
```

