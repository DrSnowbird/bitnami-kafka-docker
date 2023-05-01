#!/bin/bash -x

## -- main -- ##

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $(dirname $DIR)

echo "$PWD"

set -e

SED_MAC_FIX="''"

CP_OPTION="--backup=numbered"

HOST_IP=127.0.0.1
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    # ...
    HOST_IP=`ip route get 1|grep via | awk '{print $7}'`
    SED_MAC_FIX=
    echo ${HOST_IP}
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX
    HOST_IP=`ifconfig | grep "inet " | grep -Fv 127.0.0.1 | grep -Fv 192.168 | awk '{print $2}'`
    CP_OPTION=
    echo ${HOST_IP}
fi

export KAFKA_ADVERTISED_HOST_NAME=${HOST_IP}
export KAFKA_ZOOKEEPER_HOST_NAME=${HOST_IP}

ENV_FILE=".env"

function usage() {
    if [ $# -lt 1 ]; then
        echo "--- Usage: $(basename $0) [<KAFKA_ADVERTISED_HOST_NAME>] [<KAFKA_ZOOKEEPER_HOST_NAME>]"
        echo "   [<KAFKA_ADVERTISED_HOST_NAME>, e.g., 10.128.9.166]"
        echo "        default: ${KAFKA_ADVERTISED_HOST_NAME} will be used!"
        echo "   [<KAFKA_ZOOKEEPER_HOST_NAME>, e.g., 10.128.9.166]"
        echo "        default: ${KAFKA_ZOOKEEPER_HOST_NAME} will be used!"
    fi
}
usage $*

function replaceValueInConfig() {
    FILE=${1}
    KEY=${2}
    VALUE=${3}
    search=`cat $FILE|grep "$KEY"`
    if [ "$search" = "" ]; then
        echo "-- Not found: Append into the file"
        echo "$KEY=$VALUE" >> $FILE
    else
        sed -i ${SED_MAC_FIX} 's/^[[:blank:]]*\('$KEY'[[:blank:]]*=\).*/\1'$VALUE'/g' $FILE
    fi
    echo "results (after replacement) with new value:"    
    cat $FILE |grep $KEY
}

ENV_TEMPLATE=".env.template"

function backupEnv() {
    if [ -s .env ]; then
        if [ ! -d .env.BACKUP ]; then
            mkdir -p .env.BACKUP
        fi
        cp ${CP_OPTION} .env .env.BACKUP/
        echo "... Old .env file is save to: .env.BACKUP/"
    else
        if [ -s .env.template ]; then
            cp .env.template .env
        else
            echo "*** ERROR: Can't find .env.template! Abort now!"
        fi
    fi
}
backupEnv

replaceValueInConfig ".env" "KAFKA_ADVERTISED_HOST_NAME" "${KAFKA_ADVERTISED_HOST_NAME}"
replaceValueInConfig ".env" "KAFKA_ZOOKEEPER_HOST_NAME" "${KAFKA_ZOOKEEPER_HOST_NAME}"
cat .env
