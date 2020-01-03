#!/usr/bin/env bash
set -eu

CLIENTS=$(kubectl get pods -l app=iperf-client -o name | cut -d'/' -f2)
SERVER=$(kubectl get pods -l app=iperf-server -o name | cut -d'/' -f2)

for POD in ${CLIENTS}; do
    until $(kubectl get pod ${POD} -o jsonpath='{.status.containerStatuses[0].ready}'); do
        echo "Waiting for ${POD} to start..."
        sleep 5
    done
    HOST=$(kubectl get pod ${POD} -o jsonpath='{.status.hostIP}')
    HOSTIP=$(kubectl describe pods iperf-server|grep IP|head -1|awk '{print $2}')
    kubectl exec -it ${POD} -- iperf -c ${HOSTIP} -P 1 -u -b 1G -l 1024 -t 5 -T "Client on ${HOST}" $@ > /dev/null
    #kubectl exec -it ${POD} -- iperf -c iperf-server -P 3 -T "Client on ${HOST}" $@
    kubectl logs ${SERVER} | tail -n 10
    sleep 10
    echo
done

