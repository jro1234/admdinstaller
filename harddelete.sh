#!/bin/bash


INSTALL_NAME="$1"

if [ ! -z "$INSTALL_NAME" ]
then
    INSTALL_HOME="/ccs/proj/bip149/$USER/$INSTALL_NAME"
    DATA_HOME="/lustre/atlas/proj-shared/bip149/$USER/$INSTALL_NAME"
    rm -rf $INSTALL_HOME
    rm -rf $DATA_HOME
fi
