# Tensorflow Container Installation
The following instructions are specifically for installing Docker and a Tensorflow container (including Jupyter)
to Ubuntu 18.04. However, the general instructions can be adapted to other platforms.

### Install Nvidia Drivers
The following instructions are derived from the [official Nvidia documentation](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html) but only include what is necessary for a Docker installation.

1. Universe repository is required for some dependencies.

`sudo add-apt-repository universe`

2. Install cuda. Note that some tutorials will say *not* to install the drivers, but they are necessary
for the Docker host machine.

```
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin
sudo mv cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600
sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
sudo add-apt-repository "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/ /"
sudo apt-get update
sudo apt-get -y install cuda
```

3. Reboot and check that the drivers are working. [Post set up](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#post-installation-actions) is not necessary with a Docker installation. 

`nvidia-debugdump --list`

### Install Docker for Tensorflow
Full instructions are available at https://www.tensorflow.org/install/docker. Be sure to pull the correct image for your installation (e.g., `docker pull tensorflow/tensorflow:latest-gpu-py3-jupyter`).

### Configure Docker with Nvidia Environment
This installation uses the [nvidia-container-runtime](https://github.com/nvidia/nvidia-container-runtime). 

1. Add the repository.
```
curl -s -L https://nvidia.github.io/nvidia-container-runtime/gpgkey | \
  sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-runtime.list
sudo apt-get update
```

2. Install the runtime.

```
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/systemd/system/docker.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --host=fd:// --add-runtime=nvidia=/usr/bin/nvidia-container-runtime
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

```
sudo tee /etc/docker/daemon.json <<EOF
{
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF
sudo pkill -SIGHUP dockerd
```

### Test the Installation

`docker run --runtime=nvidia --rm nvidia/cuda nvidia-smi`

### Run Jupyter

*Consider using the bundled [shell script](#shellscript) instead of the commands below*

Non-persistent execution:

```
docker run --runtime=nvidia -it -p 8888:8888 tensorflow/tensorflow:latest-gpu-py3-jupyter
```

Use the `--name` option to persist the container for later use and the `-v [hostdir]:/tf` to mount and sync a directory on the host machine.

```
docker run --runtime=nvidia -it --name myJupyterContainer -v "$HOME/notebooks":/tf -p 8888:8888 tensorflow/tensorflow:latest-gpu-py3-jupyter
```

### Using jupyter.sh
<a name="shellscript"></a>

Instead of using the commands above, consider using the included [jupyter.sh](jupyter.sh) shell script which includes useful commands for managing Jupyter containers on a multi-user system. To do so, add `source jupyter.sh` to your .bashrc or corresponding file. Consider sourcing the script in the default .bashrc file located at `/etc/skel/.bashrc`.

The shell script enables the following commands:

      jc init    Initializes the Jupyter container.
      jc start   Starts your personal Jupyter container and sends it to the background.
      jc stop    Stops your personal Jupyter container.
      jc show    Brings your Jupyter container to the foreground (ctrl+p,ctrl+q sends it back).
      jc list    Shows any running containers. Use this to see if anyone else is working.
      jc url     Shows your Jupyter url.
      jc shell   Starts a shell in your running container.
      jc destroy Deletes your container. *This is not the same thing as 'stop'*
