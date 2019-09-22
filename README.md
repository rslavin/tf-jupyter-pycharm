tf-jupyter-pycharm
===
This project includes configuration steps and a management script to support a Docker-based Tensorflow setup with Jupyter and support remote access and execution with Pycharm. 

#### Tensorflow Container Installation

For general setup instruction, see the [Setup Guide](setup.md). 

#### Pycharm Integration
After installation, the [Pycharm Configuration Guide](pycharm.md) has instructions to enable remote cell execution, remote interpreter configuration, and ntoebook synchronization between the Pycharm client and the Jupyter server on the remote machine. 

#### Management Script
A [shell script](setup.md#shellscript) is included for managing Jupyter containers on a multi-user system. It includes the following commands.

```
init    Initializes the Jupyter container.
start   Starts your personal Jupyter container and sends it to the background.
stop    Stops your personal Jupyter container.
show    Brings your Jupyter container to the foreground (ctrl+p,ctrl+q sends it back).
list    Shows any running containers. Use this to see if anyone else is working.
url     Shows your Jupyter url.
shell   Starts a shell in your running container.
destroy Deletes your container. *This is not the same thing as 'stop'*
```
