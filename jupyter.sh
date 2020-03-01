## Author: Rocky Slavin
# This program is for use with a Docker Tensorflow installation following
# the steps at http://github.com/rslavin/tf-jupyter-pycharm
# source this script in your .bashrc file to enable `jc` commands.
##

# The user must be in the 'docker' group to use these commands
contprefix="jupyter"
export JUPYTER_CONT="$contprefix-$USER"
host="somehost.com"
# note that docker automatically modifies iptables so ufw rules won't affect this
hostport=8888
containerport=8888
apiport=2375 # must be set in /lib/systemd/system/docker.service
image=tensorflow/tensorflow:latest-gpu-py3-jupyter
mountdir=$HOME/notebooks # can be overriden with init
tokenfile=$HOME/.jupytertoken

func_name(){
	if [[ -n $BASH_VERSION ]]; then
		echo "${FUNCNAME[1]}"
	else
		echo "${funcstack[@]:1:1}"
	fi
}

jc(){
	case "$1" in
		init) 
			# check if one exists already
			if docker ps | grep $JUPYTER_CONT > /dev/null; then
				echo "Container '$JUPYTER_CONT' already exists. Destroy it? [y|n]"
				read decision
				case "$decision" in
					[yY]) $(func_name) destroy 2> /dev/null;;
					*) return
				esac
			fi

			# check for user-specified directory
			if [[ "$#" > 1 ]]; then
				if [[ "${2:0:1}" != "/" ]]; then
					mountdir=$(pwd)"/$2"
				else
					mountdir="$2"
				fi
			fi
			mkdir -p "$mountdir"

			docker run -d --runtime=nvidia -u $(id -u):$(id -g) -v "$mountdir":/tf -it --name $JUPYTER_CONT -p $hostport:$containerport $image > /dev/null \
				&& echo "Jupyter container '$JUPYTER_CONT' created, mounted directory $mountdir"
			sleep 5
			rm $tokenfile &> /dev/null
			$(func_name) url;;
		stop) 
			docker stop $JUPYTER_CONT > /dev/null && echo "Jupyter container '$JUPYTER_CONT' stopped";;
		show) 
			echo "Use ctrl+p, ctrl+q to exit"
			docker attach $JUPYTER_CONT;;
		list|status) 
			docker ps | sed -nE "/^CONTAINER|$contprefix/p";;
		shell) 
			echo "Use 'exit' to exit"
			docker container exec -u 0 -i $JUPYTER_CONT /bin/bash;;
		url|token) 
			if [[ -f $tokenfile && -s $tokenfile ]] ; then
				echo "http://$host:$hostport/?token=`cat $tokenfile`"
			else
				docker logs --tail 500 $JUPYTER_CONT | grep ' http.*\?token' | tail -1 | sed -E 's/^.+token=//' > $tokenfile && \
					echo "http://$host:$hostport/?token=`cat $tokenfile`"
			fi;;
		start|resume) 
			docker start $JUPYTER_CONT > /dev/null 
			sleep 3
			echo "Jupyter container '$JUPYTER_CONT' resumed" 
			rm $tokenfile &> /dev/null
			$(func_name) url;;
		destroy) 
			$(func_name) stop &> /dev/null
			rm $tokenfile &> /dev/null
		  	if docker rm $JUPYTER_CONT &> /dev/null; then
				echo "Jupyter container '$JUPYTER_CONT' destroyed - notebooks preserved"
			else
				echo "Unable to destroy container. Use '$(func_name) list' to see if one exists" >&2
			fi
			;;
		log) 
			docker logs $JUPYTER_CONT;; 
		*)
			port=$(sed -n '/tcp:\/\// s/^.*\.0://p' /etc/systemd/system/docker.service.d/override.conf)
			printf "usage: $(func_name) <command>\n"
			printf "API daemon running on port $port\n"
			printf "Permissions problems? Make sure you're in the 'docker' group\n"
			printf "For first-time setup, run \`$(func_name) init\`. After that, you can use the following arguments:

	init [dir]\tCreates the container. If [dir] is passed, your notebooks will be placed in the corresponding directory. ~/notebooks is used by default.
	start\t\tStarts your personal Jupyter container and sends it to the background.
	stop\t\tStops your personal Jupyter container.
	show\t\tBrings your Jupyter container to the foreground (ctrl+p,ctrl+q sends it back).
	list\t\tShows any running containers. Use this to see if anyone else is working.
	url\t\tShows your Jupyter url and token.
	shell\t\tStarts a shell in your running container.
	log\t\tPrints your container's log file.
	destroy\t\tDeletes your container. Preserves notebook directory. *This is not the same thing as 'stop'*\n"
 	   		;;
	esac
}	

alias gtop="watch -n0.3 nvidia-smi"

printf "\nUse 'jc help' for list of commands\nRunning instances:\n`docker ps`\n"
