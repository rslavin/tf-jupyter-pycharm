## Author: Rocky Slavin
# This program is for use with a Docker Tensorflow installation following
# the steps at http://github.com/rslavin/tf-jupyter-pycharm
# source this script in your .bashrc file to enable `jc` commands.
##

# The user must be in the 'docker' group to use these commands
export JUPYTER_CONT="jupyter-$USER"
host="somehost.com"
# note that docker automatically modifies iptables so ufw rules won't affect this
hostport=8888
containerport=8888
apiport=2375 # must be set in /lib/systemd/system/docker.service
image=tensorflow/tensorflow:latest-gpu-py3-jupyter
mountdir=$HOME/notebooks # can be overriden with init

jc(){
	case "$1" in
		init) 
			if [[ "$#" > 1 ]]; then
				mountdir="$2"
			fi
			docker run -d --runtime=nvidia -u $(id -u):$(id -g) -v "$mountdir":/tf -it --name $JUPYTER_CONT -p $hostport:$containerport $image
			sleep 4
			"$0" url;;
		stop) docker stop $JUPYTER_CONT;;
		show) docker attach $JUPYTER_CONT;;
		list|status) docker ps;;
		shell) docker container exec -i $JUPYTER_CONT /bin/bash;;
		url) docker logs $JUPYTER_CONT | grep '  http.*\?token' | tail -1 | \
			sed '-e s/^ *//' "-e s/(.\+)/$host/" "-e s/:$containerport/:$hostport/";;
		start) docker start $JUPYTER_CONT && sleep 3 && "$0" url;;
		destroy) $0 stop &> /dev/null; docker rm $JUPYTER_CONT;;
		log) docker logs $JUPYTER_CONT;; 
		*)
			printf "usage: $0 <command>\n"
			printf "API daemon running on port $apiport\n"
			printf "Notebooks synced with $mountdir\n"
			printf "Permissions problems? Make sure you're in the 'docker' group\n"
			printf "For first-time setup, run \`$0 init\`. After that, you can use the following arguments:

			init [dir]\tCreates the container. If [dir] is passed, your notebooks will be placed in the corresponding directory (MUST BE ABSOLUTE PATH). ~/notebooks is used by default.
	start\t\tStarts your personal Jupyter container and sends it to the background.
	stop\t\tStops your personal Jupyter container.
	show\t\tBrings your Jupyter container to the foreground (ctrl+p,ctrl+q sends it back).
	list\t\tShows any running containers. Use this to see if anyone else is working.
	url\t\tShows your Jupyter url and token.
	shell\t\tStarts a shell in your running container.
	log\t\tPrints your container's log file.
	destroy\t\tDeletes your container. *This is not the same thing as 'stop'*\n"
 	   		;;
	esac
}	

mkdir -p "$mountdir"
printf "\nUse 'jc help' for list of commands\nRunning instances:\n`docker ps`\n"
