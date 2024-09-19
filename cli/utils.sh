#!/bin/bash

set() {
    graph indexer rules set $1 decisionBasis always parallelAllocations 1 allocationAmount $2
}

start() {
    graph indexer rules start $1
}

get(){
    if [ -z "$1" ]
    then
        graph indexer rules get all
    else
        graph indexer rules get $1
    fi
}

stop() {
    graph indexer rules stop $1
}

delete() {
    graph indexer rules delete $1
}

cost(){
    if [ -z "$1" ]
    then
        graph indexer cost get all
    else
        graph indexer cost get $1
    fi
}