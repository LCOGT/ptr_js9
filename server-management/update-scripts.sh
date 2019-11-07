#! /bin/bash

cd /home/ubuntu/ptr_js9
git pull

# Restart node helper: 
su - ubuntu -c "kill -USR2 `ps guwax | egrep js9Helper | egrep -v grep | awk '{print $2}'`"

# Update python requirements in our virtual environment
su - ubuntu -c "source /home/ubuntu/ptr_js9/python-scripts/venv/bin/activate 
pip3 install -r /home/ubuntu/ptr_js9/python-scripts/requirements.txt
deactivate"