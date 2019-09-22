# Integrating Containerized Jupyter with Pycharm
For Pycharm to work with Jupyter, three things should be enabled: the execution of cells on the remote machine, remote interpreter configuration to link code references, and the synchronization of notebooks between the local and remote machines.

### Remote Cell Execution
To make Pycharm execute cells on the remote, containerized Jupyter installation, do the following.

1. Create a new Jupyter notebook in Pycharm
2. Use the Jupyter Server dropdown menu at the top of the notebook to enter your remote server's url *including the token*.

### Configure Remote Interpreter
With the above step complete, you can now run your code on the remote Jupyter installation. However, since the remote interpreter may have different packages and files, Pycharm will not recognize some references in the code and report errors. To alleviate this, Pycharm must be configured to use the remote environment. This requires configuration on both the client and the server.

#### Enable the Docker API Eaemon
1. Edit `/etc/systemd/system/docker.service.d/override.conf` to enable the daemon by including the -H options. **Do not remove any other configurations, including the `-add-runtime` option.**

```
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375
```
		
2. Modify your firewall to allow connections on the specified port.
3. Restart the daemon and Docker.
```
sudo systemctl daemon-reload
sudo systemctl restart docker.service
```

#### Configure Pycharm to use the Remote Interpreter

1. Accesss **Settings>Projects>Project Interpreter**.
2. Set up a Docker interpreter on your remote server with the correct port. This allows Pycharm to connect through the API daemon.
3. Select the appropriate image name from the dropdown list (e.g., tensorflow/tensorflow:latest-py3-jupyter).
	
### Synchronize Notebooks between Jupyter and Pycharm
Optionally, you may configure Pycharm to synchronize the local notebooks with the server so they can be viewed within Jupyter in your web browser. Note that the `-v` option must be enabled for the container instance as described in the [setup guide](setup.md).
1. In Pycharm, access **Settings>Build, Execution, Deployment>Deployment**.
2. Set up an sftp connection and set the "Root path" remote directory ($HOME/notebooks if you followed the [setup guide](setup.md)).
3. Under the "Mappings" tab, set "Local Path:" to your local project directory and "Deployment path:" to `/` (the root path set in the previous step).
4. Optionally, exclude the .idea and venv directories using the "Excluded Paths" tab.
5. Right click the new conection and set as default in order to enable automatic uploads.
6. Access **Settings>Build, Execution, Deployment>Deployment>Options** and select "Always" in the "Upload changed files automatically to default server". 
