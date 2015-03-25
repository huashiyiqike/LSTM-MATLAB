#!/bin/bash
trap 'kill $PIDS &> /dev/null' EXIT

#Expects: HOST PORT [node_names*];  If no node_names supplied, expects
#$PBS_NODEFILE to be set, and points to new-line delimited file
#containing names of slave nodes.
if [[ $# -lt 2 && $# -ne 0 ]]; then
    echo "Usage: $0 master_host port  [slave_hosts*]"
    echo "or     SLAVERUN_HOST=master_host SLAVERUN_PORT=port $0 "
    exit 1;
fi

if [[ $# -ge 2 ]]; then
    HOST=$1; shift;
    PORT=$1; shift;
elif [[ "$SLAVERUN_HOST" == "" || "$SLAVERUN_PORT" == "" ]]; then
    echo "Must have SLAVERUN_HOST and SLAVERUN_PORT set.";
    exit 2;
else
    HOST=$SLAVERUN_HOST;
    PORT=$SLAVERUN_PORT;
fi


if [[ $# -gt 0 ]]; then
	NODES=$@;
elif [[ "$PBS_NODEFILE" != "" ]]; then
    if [[ -f "$PBS_NODEFILE" ]]; then
        NODES=$(cat $PBS_NODEFILE);
    else
        echo "Couldn't read node file $PBS_NODEFILE"
        exit 1;
    fi
else
    echo "Must either supply node names as arguments, or \$PBS_NODEFILE must be set.";
    exit 1;
fi

NODE_ARRAY=($NODES);
if [[ ${#NODE_ARRAY[@]} -lt 1 ]]; then
    echo  "No node names...?";
    exit 1;
fi

MYPATH="$(dirname "$0")" # relative
MYPATH="$(cd "$MYPATH" && pwd -P)" # absolute and normalized
REMOTEDIR=${PBS_O_WORKDIR:-$(pwd -P)}
if [[ "$CONTINUE_ON_ERROR" != "" ]]; then
    CF=',1';
fi

for i in ${NODE_ARRAY[@]}; do
    if [[ "$i" = "localhost" ]]; then
        matlab -nodesktop -nosplash -r addpath\(\'$MYPATH\'\),slaveRun\(\'$HOST\',$PORT$CF\),quit & SLAVE_PID=$!;
    else
        CMD="matlab -nodesktop -nosplash -r addpath\(\'$MYPATH\'\),slaveRun\(\'$HOST\',$PORT$CF\),quit"
        echo ssh $i "cd $REMOTEDIR && $CMD "
        ssh $i "cd $REMOTEDIR && $CMD " & SLAVE_PID=$! ;
        sleep 1;
    fi
    kill -0 $SLAVE_PID &> /dev/null;
    if [[ $? -ne 0 ]]; then
        echo "Couldn't start job on $i"
        exit 1;
    fi
    PIDS="$PIDS $SLAVE_PID";
done

sleep 10;
for i in $PIDS; do
    if ! kill -0 $i &> /dev/null; then
        echo "One of the processes failed.";
        exit 1;
    fi
done

wait $PIDS ;

