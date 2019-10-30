#! /bin/bash

SCRIPTS_DIR="/home/ubuntu/scripts"
PREV_SCRIPTS_DIR="/home/ubuntu/prev_scripts"
TEMP_SCRIPTS_DIR="/home/ubuntu/temp_scripts"
ANLAYSIS_WRAPPERS_DIR="/var/www/js9/analysis-wrappers"
ANLAYSIS_PLUGINS_DIR="/var/www/js9/analysis-plugins"

mkdir -p /home/ubuntu/prev_scripts/analysis-wrappers
mkdir -p /home/ubuntu/prev_scripts/analysis-plugins
mkdir -p /home/ubuntu/prev_scripts/python

# Pull from git: analysis-plugins, analysis-wrappers, actual scripts, 
git clone https://github.com/lcogt/ptr_js9 $TEMP_SCRIPTS_DIR

# Move old content to archive-like directory
mv $ANALYSIS_WRAPPERS_DIR/* 			/home/ubuntu/prev_scripts/analysis-wrappers
mv $ANALYSIS_PLUGINS_DIR/* 			/home/ubuntu/prev_scripts/analysis-plugins
mv /home/ubuntu/scripts/*.py 			/home/ubuntu/prev_scripts/python

# Move new content into place
mv $TEMP_SCRIPTS_DIR/analysis-wrappers/* 	$ANALYSIS_WRAPPERS_DIR/
mv $TEMP_SCRIPTS_DIR/analysis-plugins/* 	$ANALYSIS_PLUGINS_DIR/
mv $TEMP_SCRIPTS_DIR/python/*.py 		$SCRIPTS_DIR/
mv $TEMP_SCRIPTS_DIR/python/requirements.txt	$SCRIPTS_DIR/

# Restart node helper: 
sudo -u ubuntu kill -USR2 `ps guwax | egrep js9Helper | egrep -v egrep | awk '{print $2}'`

# Update python requirements
pip3 install -r $SCRIPTS_DIR/requirements.txt

# Remove the git directory we cloned initially
rm -rf $TEMP_SCRIPTS_DIR

