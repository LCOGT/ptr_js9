# JS9 Server for Photon Ranch

This is a collection of scripts used to initialize and manage a server for JS9 analysis.

## Initialization

Create an ec2 instance running Ubuntu Server 18.04 LTS (HVM). Ensure the instance includes an IAM role with the ability to change resource record sets in route53. Include the following script as userdata:

```bash
#!/bin/bash
cd /home/ubuntu
git clone https://github.com/lcogt/ptr_js9
bash /home/ubuntu/ptr_js9/server-management/install-js9-script.sh
```

Note: these startup scripts are configured to set up SSL certificates using a domain setup with aws Route53. You'll have to change `install-js9-script.sh` to work with in environments outside of photon ranch.

## How it works

The `server-management` directory contains stuff used to initialize and update the server with the latest code. No need to change it. 

The `python-scripts` directory contains the actual analysis scripts. They will be called by a bash script, with command line arguments if desired. Make sure the requirements are defined in `requirements.txt`. Note that the actual server task does not need to be written in python, or defined in this directory; as long as it can be called from a bash script (defined in analysis-wrappers and analysis-plugins), it can work.

The `analysis-plugins` directory contains a json file defining/describing each analysis task. A task must be defined here in order to properly communicate with the browser instance. 

The `analysis-wrappers` directory contain scripts reponsible for making sure all the steps involved with the analysis task actually happen. This includes safe argument handling, calling the right scripts, and returning the output or appropriate error message.

- The script `js9Xeq` came with the js9 installation and handles the prebuilt server scripts.
- The script `ptr-scripts`, heavily based on the design of js9Xeq, is used for our custom scripts.

More details and directions on modifying the analysis-wrappers and analysis-plugins can be found here: https://js9.photonranch.org/js9/help/serverside.html

## Push Changes to the Server

The `server-management` directory contains `update-scripts.sh` which is used to update the js9 server to use the latest scripts in this repository. To run the script, open an instance of JS9, enable server-side tasks by uploading the current image, and then select the task 'Pull the latest server scripts'. Once finished, reload js9 and the new tasks will be available.

____

## Example - Creating a Python Analysis Script

### 1. Create the json definition

The JS9 server recognizes tasks that are defined in the `analysis-plugins` directory. To add a new analysis task, create a new file in `analysis-plugins` as a .json file.

The values that can be defined are described as follows:

- name: a short identifier string (typically one word)
- title: a longer string that will be displayed in the Analysis menu
- files: a rule that will be matched against to determine whether this task is available for the current image
- purl: a URL pointing to a web page containing a user parameter form
- action: the command to execute on the server side
- rtype: a return type, which can be text, plot, fits, png, regions, catalog, alert, or none
- hidden: if true, the analysis task is not shown in the Analysis menu

Let's make a file called `echoFilename.json`:
```json
[
  {"name"   : "echo-filename",
   "title"  : "Echo the filename",
   "files"  : "fits",
   "action" : "ptr-scripts echo-filename $filename",
   "hidden" : false,
   "rtype"  : "text"}
]
```

The js9 [documentation](https://js9.photonranch.org/js9/help/serverside.html) on these json definition files is worth reading if you want to write your own scripts.

### 2. Define a corresponding bash command

For security, reasons, the "action" string defined in the json document is never executed directly. The first argument is the wrapper script in the `analysis-wrappers` directory. For now, all photon ranch scrips are run from `ptr-scripts`. The second argument of "action" is the command id which selects the specific case to run within `ptr-scripts`.

In our case, we will add the following case to `ptr-scripts` (nested under the `case` around line 82):

```bash
echo-filename)
    # Activate our python virtual environment in our python scripts directory
    source $PYTHON_SCRIPTS/venv/bin/activate
    # Run the python script we've defined, and sanitize the output path with xsed (defined earlier in the script)
    # Arguments for the script are passed in as command line arguments. In our case, $1 represents the $filename defined in the "action" string of the json definition.
    # Note: stdout will be returned to the browser.
    echo $(python $PYTHON_SCRIPTS/echo_filename.py $1 | xsed)
    exit 0
    ;;
```

Refer to `analysis-wrappers/js9Xeq` to reference examples that were included with JS9.

### 3. Write the python script we want to execute

Python scripts should be defined in the `python-scripts` directory. Make sure to add any dependencies to `requirements.txt`.

Arguments (like the filename of the file we want) are provided as command-line arguments. Here is an example program named echo_filename.py:

```python
import sys
filename = sys.argv[1] # Get the first command-line argument
print(filename) # Recall that the browser will get anything from stdout.
sys.exit(0)
```

### 4. Standard git procedure...

Changes should now include: 

- `analysis-plugins/echoFilename.json` # New file: definition
- `analysis-wrappers/ptr-scripts` # Modified file: include our new command
- `python-scripts/echo_filename.py` # New file: The core script
- `python-scripts/requirements.txt` # Modified file (optional): include dependencies

Run the following to push the changes:
```bash
# Sync with the master and fix merge conflicts if any appear
git pull

# Add all the files we want to include
git add .

# Commit and describe the changes
git commit -m 'Add new script: echo_filename'

# Send them up to github
git push -u origin master
```

### 5. Refresh the server to show the new script

