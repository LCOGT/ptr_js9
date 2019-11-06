#! /bin/bash

cd /home/ubuntu/ptr_js9
git pull

# Restart node helper: 
su - ubuntu -c "kill -USR2 `ps guwax | egrep js9Helper | egrep -v egrep | awk '{print $2}'`"

# Update python requirements in our virtual environment
source /home/ubuntu/ptr_js9/python-scripts/venv/bin/activate 
pip3 install -r /home/ubuntu/ptr_js9/python-scripts/requirements.txt
deactivate

#### OLD

#SCRIPTS_DIR="/home/ubuntu/scripts"
#PREV_SCRIPTS_DIR="/home/ubuntu/prev_scripts"
#TEMP_SCRIPTS_DIR="/home/ubuntu/temp_scripts"
#ANALYSIS_WRAPPERS_DIR="/var/www/js9/analysis-wrappers"
#ANALYSIS_PLUGINS_DIR="/var/www/js9/analysis-plugins"
#
#mkdir -p /home/ubuntu/prev_scripts/analysis-wrappers
#mkdir -p /home/ubuntu/prev_scripts/analysis-plugins
#mkdir -p /home/ubuntu/prev_scripts/python
#mkdir -p /home/ubuntu/scripts
#chown -R ubuntu:ubuntu /home/ubuntu/
#
## Pull from git: analysis-plugins, analysis-wrappers, actual scripts, 
#git clone https://github.com/lcogt/ptr_js9 $TEMP_SCRIPTS_DIR
#
## Move old content to archive-like directory
#mv $ANALYSIS_WRAPPERS_DIR/* /home/ubuntu/prev_scripts/analysis-wrappers
#mv $ANALYSIS_PLUGINS_DIR/* /home/ubuntu/prev_scripts/analysis-plugins
#mv $SCRIPTS_DIR/*.py /home/ubuntu/prev_scripts/python
#
## Move new content into place
#mv $TEMP_SCRIPTS_DIR/analysis-wrappers/* $ANALYSIS_WRAPPERS_DIR/
#mv $TEMP_SCRIPTS_DIR/analysis-plugins/* $ANALYSIS_PLUGINS_DIR/
#mv $TEMP_SCRIPTS_DIR/python/*.py $SCRIPTS_DIR/
#mv $TEMP_SCRIPTS_DIR/python/requirements.txt $SCRIPTS_DIR/
#
## Restart node helper: 
#su - ubuntu -c "kill -USR2 `ps guwax | egrep js9Helper | egrep -v egrep | awk '{print $2}'`"
#
## Update python requirements in our virtual environment
#source $SCRIPTS_DIR/venv/bin/activate 
#pip3 install -r $SCRIPTS_DIR/requirements.txt
#deactivate
#
## Remove the git directory we cloned initially
#rm -rf $TEMP_SCRIPTS_DIR


