#!/bin/bash
###################################################################
##### Multiple concurrent process launch and timeout control  #####
###################################################################
#   A main loop will launch a custom number of processes based    #
#   on the input data.                                            #
#   When they are launched, a timer process is associated to      #
#   each one of them, killing them if they reach a configurable   #
#   timeout.                                                      #
#   Finally, the main process waits for each child and presents   #
#   the results.                                                  #
###################################################################

# Set how much time we will wait for each process
TIMEOUT=3
# EDITABLE - Output file prefix
PREFIX=/tmp/hola

pids=""
errors_found=0

# An example of a long, maybe stuck process
# $1: message to print
# $2: output file to print
function execute_long {
    if [ ! "$2" ]; then
        return 1
    fi
    sleep 100
    echo msg_long: $1 >> $2
}

# An example of a regular process
# $1: message to print
# $2: output file to print
function execute_short {
    if [ ! "$2" ]; then
        return 1
    fi
    sleep 1
    echo msg_short: $1 >> $2
}

# Wait for all PID passed as argument
# [global] errors_found
# return: 0 if no errors were found, 1 otherwise
function wait_all {
    errors_found=0
    result=0
    for job in $@
    do
        wait $job 
        result=$?
        if (( $result != 0 ))
        then
            echo "$job failed with status $result"
            let errors_found+=1
        fi
    done
    if [ ${errors_found} -eq 0 ]; then
        return 0
    fi
    return 1
}

# Timer controller
# $1: PID
# $2: process name
# Wait $TIMEOUT seconds for a process to end or kill it if it didn't
function timeout_control {
    if [ ! $1 ]
    then
        return 1
    fi

    pid=$1
    name=$2

    sleep $TIMEOUT
    proc=$(ps -p $pid)
    alive=$?
    if [ $alive -eq 0 ]
    then
        echo "Killing process $name with pid: $pid" >&2
        kill -PIPE $pid
    fi
}

# Launch a program with a kill timer
#   Adds its PID to the wait list
function launch_program {
    if [ ! $1 ]; then
        return 0
    fi
    $@ &
    pid=$!
    pids="${pids} ${pid}"
    timeout_control $pid "$*" &
}

function print_results {
    for str in $vars
    do
        for typ in short long
        do
            echo "### ${str}-${typ} ###"
            ls ${PREFIX}.$$.$str-$typ >/dev/null 2>&1
            if [ ! -f "${PREFIX}.$$.${str}-${typ}" ]
            then
                echo TIMED OUT!
            else
                txt=$(cat ${PREFIX}.$$.$str-$typ 2>/dev/null)
                if [ "$txt" ]
                then
                    echo $txt
                else
                    echo TIMED OUT!
                fi
            fi
        done
    done
}

################
# MAIN SECTION #
################

# Setup data
# EDITABLE - Example input data
vars="cad1 cad2 cad3 cad4"

# Launch all required programs
# This example illustrate an iterative launch of the same program(s)
#   over a set of data
for str in $vars
do
    launch_program execute_long $str ${PREFIX}.$$.$str-long
    launch_program execute_short $str ${PREFIX}.$$.$str-short
done

wait_all $pids

echo "There were ${errors_found} errors."
echo ""

# Result printing
print_results
