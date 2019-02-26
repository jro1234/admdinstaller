#!/bin/bash


INSTALL_NAME="$1"

if [ ! -z "$INSTALL_NAME" ]
then
    INSTALL_HOME="/ccs/proj/bif112/$INSTALL_NAME"
    DATA_HOME="/gpfs/alpine/proj-shared/bif112/$USER/$INSTALL_NAME"
    CONDA_HIDDEN="/ccs/home/$USER/.conda/envs/admdenv"
    rm -rf $INSTALL_HOME
    rm -rf $DATA_HOME
    rm -rf $CONDA_HIDDEN
fi
