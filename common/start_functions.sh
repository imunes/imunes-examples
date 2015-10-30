#!/bin/sh

os=`uname -s`;

isOSlinux() {
    if test $os = "Linux"; then
	true;
    else
	false;
    fi
}

isOSfreebsd() {
    if test $os = "FreeBSD"; then
	true;
    else
	false;
    fi
}

# Error check
error() {
    echo $*
    exit 2
}

# isEidRunning eid
isEidRunning() {
    err=`himage -l | awk '{print $1}' | grep -x $1` \
	    || error "Cannot find experiment $1. Is simulation started? Try: Experiment->Execute"
}

# isNodeRunning node eid
isNodeRunning() {
    node=$1
    if [ $# -ne 1 ]; then
	isEidRunning $2
    else
	eid=`himage -e $1` \
	    || error "Cannot find node $1. Is simulation started? Try: Experiment->Execute"
	echo "$eid"
    fi
}

# hasPackage node eid pkgName
hasPackage() {
    pkg info > /dev/null 2>&1
    if [ $? -eq 0 ]; then
	himage $1@$2 pkg info | grep "$3" > /dev/null 2>&1
	err=$?
    else
	himage $1@$2 pkg_info | grep "$3" > /dev/null 2>&1
	err=$?
    fi
    if [ $err -ne 0 ]; then
	error "*** Package $3 is not installed on $1@$2"
    fi
}
