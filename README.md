# AdaptiveMD Installer
Installer scripts for AdaptiveMD providing a workflow platform and configuration.

  - Branch :: Machine
  - titan_olcf :: Titan supercomputer at ORNL
  - master :: Condo cluster at ORNL
  - *local :: for personal computers with Linux
  - *local_mac :: for personal computers with Linux
  - *empty :: no configuration variables entered

AdaptiveMD runs workflows using a distributed system model, so there isn't a one-size-fits-all installation as different clusters and HPCs have different hardware and connectivity rules. There are multiple packages required, and we also write environment variables to help navigate the filesystem and coordinate the workflows. Additionally, the tasks AdaptiveMD creates can be run with or without RADICAL-Pilot [info](LINK to some info here). 

So, there are many configuration options to figure out. Each branch of this repository has an installer for the indicated resource. If the installer does not work for you on the specified resource, please post an issue with the branch name and error so the branch can be updated. 

Some use cases will require different components installed on different machines, so running a single installation script wouldn't complete the setup. If you want to install the platform on a new resource, you will have to change some of the configuration variables at the top of the installer starting from a branch of your choosing.
