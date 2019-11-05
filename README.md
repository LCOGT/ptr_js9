
## JS9 Server for Photon Ranch

This is a collection of scripts used to initialize and manage a server for JS9 analysis.

### Initialization

Create an ec2 instance running Ubuntu Server 18.04 LTS (HVM). Ensure the instance includes an IAM role with the ability to change resource record sets in route53. Include the following script as userdata:

```bash
#!/bin/bash
cd /home/ubuntu
git clone https://github.com/lcogt/ptr_js9
bash /home/ubuntu/ptr_js9/scripts/install-js9-script.sh
bash /home/ubuntu/ptr_js9/scripts/update_plugins.sh
```

Note: these startup scripts are configured to set up SSL certificates using a domain setup with aws Route53. You'll have to change `install-js9-script.sh` to work with in environments outside of photon ranch.

### How it works

The `scripts` directory contains stuff used to initialize and update the server with the latest code. No need to change it. 

The `python` directory contains the actual analysis scripts. They will be called by a bash script, with command line arguments if desired. Make sure the requirements are defined in `requirements.txt`. Note that the actual server task does not need to be written in python, or defined in this directory; as long as it can be called from a bash script (defined in analysis-wrappers and analysis-plugins), it can work.

The `analysis-plugins` directory contains a json file defining/describing each analysis task. A task must be defined here in order to properly communicate with the browser instance. 

The `analysis-wrappers` directory contain scripts reponsible for making sure all the steps involved with the analysis task actually happen. This includes safe argument handling, calling the right scripts, and returning the output or appropriate error message.

- The script `js9Xeq` came with the js9 installation and handles the prebuilt server scripts.
- The script `ptr-scripts`, heavily based on the design of js9Xeq, is used for our custom scripts.

More details and directions on modifying the analysis-wrappers and analysis-plugins can be found here: https://js9.photonranch.org/js9/help/serverside.html

### Push Changes to the Server

The `scripts` directory contains `update_plugins.sh` which is used to update the js9 server to use the latest scripts in this repository. To run the script, open an instance of JS9, enable server-side tasks by uploading the current image, and then select the task 'Pull the latest server scripts'. Once finished, reload js9 and the new tasks will be available.