#!/bin/bash
source ~/.bash_profile
INSTANCE_ID=${2:-0}

if [ -z $JAVA_HOME ]; then
    echo "java home is null, use default path..."
    export JAVA_HOME=/letv/sofwore/jdk1.7.0_80
fi

export CLASSPATH=$JAVA_HOME/lib:$JAVA_HOME/jre/lib
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH:$HOME/bin

#dir config
cd `dirname $0`
BIN_DIR=`pwd`
cd ..
DEPLOY_DIR=`pwd`
CONF_DIR=$DEPLOY_DIR/conf
LIB_DIR=$DEPLOY_DIR/lib
DATA_DIR=$DEPLOY_DIR/data
EXEC_DIR=$DATA_DIR/instance-$INSTANCE_ID
EXEC_LOG_DIR=$EXEC_DIR/logs
EXEC_TMP_DIR=$EXEC_DIR/tmp
EXEC_CONFCENTER_DIR=$EXEC_DIR/conf
mkdir -p $EXEC_LOG_DIR
mkdir -p $EXEC_TMP_DIR
mkdir -p $EXEC_CONFCENTER_DIR
#extra opt
port=$((1901+INSTANCE_ID))
DEBUG_PORT=$((20880+INSTANCE_ID))
GC_LOG=$EXEC_LOG_DIR/gc.log
SERVER_NAME=`hostname`
INSTANCE_PROP="instance.id"

#jvm config
JAVA_BASE_OPTS=" -Djava.awt.headless=true -Dfile.encoding=gbk -D$INSTANCE_PROP=$INSTANCE_ID -Djava.io.tmpdir=$EXEC_TMP_DIR -Ddubbo.protocol.port=$port"

JAVA_MEM_OPTS=" -server -Xms1g -Xmx2g -XX:PermSize=256m -XX:MaxPermSize=256m -Xss256K -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:+UseCMSCompactAtFullCollection -XX:LargePageSizeInBytes=128m -XX:+UseFastAccessorMethods -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=60 "
JAVA_MEM_OPTS_TEST=" -server -Xms256m -Xmx256m -XX:PermSize=128m -XX:MaxPermSize=128m -Xss256K -XX:+DisableExplicitGC -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:+UseCMSCompactAtFullCollection -XX:LargePageSizeInBytes=128m -XX:+UseFastAccessorMethods -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=70 "

JAVA_GC_OPTS=" -verbose:gc -Xloggc:$GC_LOG -XX:+PrintGCDetails -XX:+PrintGCDateStamps " 

JAVA_TEST_OPTS=" -Xdebug -Xnoagent -Xrunjdwp:transport=dt_socket,address=$DEBUG_PORT,server=y,suspend=n $JAVA_MEM_OPTS_TEST "
JAVA_PROD_OPTS=" $JAVA_MEM_OPTS "


LIB_JARS=`ls $LIB_DIR|grep .jar|awk '{print "'$LIB_DIR'/"$0}'|tr "\n" ":"`
JAVA_CP=" -classpath $CONF_DIR:$LIB_JARS "

JAVA_OPTS="$EXTRA_JAVA_OPTS $JAVA_BASE_OPTS $JAVA_GC_OPTS $JAVA_CP" 

RUNJAVA="$JAVA_HOME/bin/java"

EXEC_PID="$EXEC_DIR/instance.pid"

STDOUT_FILE=$EXEC_LOG_DIR/dubbo.out.log

DUBBO_REGISTRY_FILE=$DEPLOY_DIR"/dubbo/dubbo-registry-"$INSTANCE_ID".cache"

case $1 in
start)
    #safe check
    PIDS=`ps  --no-heading -C java -f --width 2000 | grep "$CONF_DIR" | grep "${INSTANCE_PROP}=$INSTANCE_ID" |awk '{print $2}'`
    if [ -n "$PIDS" ]; then
        echo "ERROR: The $SERVER_NAME instance $INSTANCE already started!"
        echo "PID: $PIDS"
        exit 1
    fi
    echo  "Starting $SERVER_NAME instance $INSTANCE_ID ... "
    
    $RUNJAVA $JAVA_PROD_OPTS $JAVA_OPTS -Ddubbo.registry.file=$DUBBO_REGISTRY_FILE com.lecrm.aftersales.acl.container.ContainerBootstrap >> $STDOUT_FILE 2>&1 &
    echo -n $! > $EXEC_PID
    COUNT=0
    while [ $COUNT -lt 1 ]; do    
        echo -e ".\c"
        sleep 1 
        COUNT=`ps  --no-heading -C java -f --width 2000 | grep "$DEPLOY_DIR" | grep "${INSTANCE_PROP}=$INSTANCE_ID" | awk '{print $2}' | wc -l`
    
        if [ $COUNT -gt 0 ]; then
            break
        fi
    done
    echo STARTED
    ;;
stop)
    echo "Stopping $SERVER_NAME instance $INSTANCE_ID ... "
    netstat -nl  2>/dev/null |grep -w "${port}" |grep "LISTEN" &>/dev/null
    if [ $? -ne 0 ];then
            echo "[INFO] The ${port} is CLOSED!"
            echo "[INFO] The service is already STOPPED!"
            exit 0;
    fi
    
    if [ ! -f "$EXEC_PID" ];then
        echo "error: could not find file $EXEC_PID"
        exit 1;
    else
        kill $(cat "$EXEC_PID") > /dev/null 2>&1
        COUNT=`ps  --no-heading -C java -f --width 2000 | grep "$DEPLOY_DIR" | grep "${INSTANCE_PROP}=$INSTANCE_ID" | awk '{print $2}' | wc -l`
        if [ $COUNT -gt 0 ]; then
            sleep 4
            kill -9 $(cat "$EXEC_PID") > /dev/null 2>&1
        fi
        rm $EXEC_PID
        echo STOPPED
    fi
    ;;
test-start)
    #safe check
    PIDS=`ps  --no-heading -C java -f --width 2000 | grep "$CONF_DIR" | grep "${INSTANCE_PROP}=$INSTANCE_ID" |awk '{print $2}'`
    if [ -n "$PIDS" ]; then
        echo "ERROR: The $SERVER_NAME instance $INSTANCE already started!"
        echo "PID: $PIDS"
        exit 1
    fi
    echo  "Starting $SERVER_NAME instance $INSTANCE_ID for debuging... "
    $RUNJAVA $JAVA_TEST_OPTS $JAVA_OPTS -Ddubbo.registry.file=$DUBBO_REGISTRY_FILE com.lecrm.aftersales.acl.container.ContainerBootstrap >> $STDOUT_FILE 2>&1 &
 
   echo -n $! > $EXEC_PID
    COUNT=0
    while [ $COUNT -lt 1 ]; do    
        echo -e ".\c"
        sleep 1 
        COUNT=`ps  --no-heading -C java -f --width 2000 | grep "$DEPLOY_DIR" | grep "${INSTANCE_PROP}=$INSTANCE_ID" | awk '{print $2}' | wc -l`
    
        if [ $COUNT -gt 0 ]; then
            break
        fi
    done
    echo STARTED
    ;;
test-stop)
    echo "Stopping $SERVER_NAME instance $INSTANCE_ID ... "
    if [ ! -f "$EXEC_PID" ];then
        echo "error: could not find file $EXEC_PID"
        exit 1;
    else
        kill $(cat "$EXEC_PID") > /dev/null 2>&1
        COUNT=`ps  --no-heading -C java -f --width 2000 | grep "$DEPLOY_DIR" | grep "${INSTANCE_PROP}=$INSTANCE_ID" | awk '{print $2}' | wc -l`
        if [ $COUNT -gt 0 ]; then
            sleep 4
            kill -9 $(cat "$EXEC_PID") > /dev/null 2>&1
        fi
        rm $EXEC_PID
        echo STOPPED
    fi
    ;;
*)
    echo "Usage: $0 {start|test-start|stop|test-stop} {id}" >&2
    exit 1
esac
