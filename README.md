
### ptr_js9

This is a collection of scripts used to initialize and manage a server for JS9 analysis. 

Create an ec2 instance running Ubuntu Server 18.04 LTS (HVM). Ensure the instance includes an IAM role with the ability to change resource record sets. Include the following script as userdata:

```bash
#!/bin/bash
cd /home/ubuntu
git clone https://github.com/lcogt/ptr_js9
bash /home/ubuntu/ptr_js9/scripts/install-js9-script.sh
bash /home/ubuntu/ptr_js9/scripts/update_plugins.sh
```

