#!/bin/bash
startDir=`pwd`
# main work directory, not influenced by start dir
mainWd=$(cd $(dirname $0); pwd)
# GIT install
# common install dir for home | root mode
homeInstDir=~/.usr
rootInstDir=/usr/local
# default is home mode
commInstdir=$homeInstDir
#sudo or empty
execPrefix=""
downloadPath=$mainWd/downloads
pkgPath=$mainWd/packages
runMoreTimeFlag=$mainWd/.MORETIME
ssInitFile=$mainWd/shadowsocks

logo() {
    cat << "_EOF"
                _
 ___  ___   ___| | _____
/ __|/ _ \ / __| |/ / __|
\__ \ (_) | (__|   <\__ \
|___/\___/ \___|_|\_\___/

_EOF
}

usage() {
    exeName=${0##*/}
    cat << _EOF
[NAME]
    $exeName -- deploy shadowsocks on you VPS from c source

[SYNOPSIS]
    sh $exeName [home | root | help]

[EXAMPLE]
    sh $exeName
    sh $exeName root

[NOTE]
    both modes need root privilege, but no sudo prefix

[DESCRIPTION]
    home -- install to $homeInstDir/
    root -- install to $rootInstDir/
_EOF
    logo
}

# compare software version
cmpSoftVersion() {
    set +x
    # usage: cmpSoftVersion TrueVer $BasicVer , format xx.xx(3.10)
    # return '1' if $1 >= $2
    # return '0' else
    leftVal=$1
    rightVal=$2
    if [[ $leftVal == "" || $rightVal == "" ]]; then
        echo Error: syntax not match, please check
        exit 255
    fi

    # with max loop
    for (( i = 0; i < 5; i++ )); do
        if [[ $leftVal == "0" && $rightVal == "0" ]]; then
            break
        fi
        leftPartial=$(echo ${leftVal%%.*})
        rightPartial=$(echo ${rightVal%%.*})
        if [[ $(echo "$leftPartial > $rightPartial" | bc ) -eq 1 ]]; then
            set -x
            return 1
        elif [[ $(echo "$leftPartial < $rightPartial" | bc ) -eq 1 ]]; then
            set -x
            return 0
        fi
        # update leftVal and rightVal for next loop compare
        if [[ ${leftVal#*.} == $leftVal ]]; then
            leftVal='0'
        else
            leftVal=${leftVal#*.}
        fi
        if [[ ${rightVal#*.} == $rightVal ]]; then
            rightVal='0'
        else
            rightVal=${rightVal#*.}
        fi
    done

    set -x
    return 1
}

installAutoConf() {
    cat << "_EOF"
------------------------------------------------------
INSTALLING AUTOCONF
------------------------------------------------------
_EOF
    autoconfPath=`which autoconf 2> /dev/null`
    if [[ "$autoconfPath" != "" ]]; then
        autoconfVersion=`autoconf --version | head -n 1 | cut -d ' ' -f 4`
        cmpSoftVersion $autoconfVersion 2.69
        if [[ $? == 1  ]]; then
            echo [Warning]: Already has autocoonf installed, skip
            return
        fi
    fi

    autoconfInstDir=$commInstdir
    # wgetLink=http://ftp.gnu.org/gnu/autoconf
    tarName=autoconf-2.69.tar.gz
    untarName=autoconf-2.69

    # rename download package
    cd $downloadPath
    if [[ ! -f $untarName ]]; then
        tar -zxv -f $pkgPath/$tarName
    fi

    cd $untarName
    ./configure --prefix=$autoconfInstDir
    make -j
    # check if make returns successfully
    if [[ $? != 0 ]]; then
        echo [Error]: make returns error, quiting now ...
        exit
    fi
    $execPrefix make install
    autoconfPath=$autoconfInstDir/bin/autoconf
}

installShadowSocks() {
    cat << "_EOF"
------------------------------------------------------
INSTALLING SHADOWSOCKS
------------------------------------------------------
_EOF
    # path of ss-server
    ssServerPath=`which ss-server 2> /dev/null`
    if [[ "$ssServerPath" != "" ]]; then
        echo [Warning]: already has ss-server installed, skip
        return
    fi
    ssInstDir=$commInstdir
    $execPrefix mkdir -p $commInstdir
    # comm attribute to get source 'git'
    gitClonePath=https://github.com/shadowsocks/shadowsocks-libev
    clonedName=shadowsocks-libev

    cd $downloadPath
    # check if already has this repository
    if [[ -d $clonedName ]]; then
        echo [Warning]: target $clonedName/ already exists, Omitting now ...
    else
        git clone ${gitClonePath} $clonedName
        # check if git clone returns successfully
        if [[ $? != 0 ]]; then
            echo [Error]: git clone returns error, quiting now ...
            exit
        fi
    fi

    cd $clonedName
    # checkout to latest released tag
    git pull
    latestTag=$(git describe --tags `git rev-list --tags --max-count=1`)
    if [[ "$latestTag" != "" ]]; then
        git checkout $latestTag
    fi

    # checkout
    git checkout $checkoutVersion
    # run make routine
    autoconf
    ./configure --prefix=$ssInstDir
    make -j
    # check if make returns successfully
    if [[ $? != 0 ]]; then
        echo [Error]: make returns error, quiting now ...
        exit
    fi
    $execPrefix make install
    ssServerPath=$ssInstDir/bin/ss-server
}

# add support for /etc/init.d/shadowsocks start
writeInitFile() {
    # _ssJsonFile=$1
    # _ssPidFile=$2
    cat << _EOF > $ssInitFile
#!/bin/bash

start(){
    $ssServerPath -c $ssJsonSysPath -f $ssPidFile -u
}

stop() {
    killall ss-server 2> /dev/null
    rm -rf $ssPidFile
}

_EOF
    cat << "_EOF" >> $ssInitFile
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    'reload')
        stop
        start
        ;;
    *)
        echo "Usage: $0 {start|reload|stop}"
        exit 1
        ;;
esac
_EOF
    chmod +x $ssInitFile
    ls -l $ssInitFile
    if [[ $? != 0 ]]; then
        echo "[Error]: write init file $ssInitFil error, please check"
    fi
    if [[ ! -f /etc/init.d/shadowsocks ]]; then
        sudo cp $ssInitFile /etc/init.d
    fi
}

startService() {
    cat << "_EOF"
------------------------------------------------------
TRY TO START SHADOWSOCKS SERVICE
------------------------------------------------------
_EOF
    # /usr/local/bin/ss-server -c /etc/shadowsocks.json
    #           -f /home/corsair/shadowsocks-libev.pid -u
    ssJsonSysPath=/etc/shadowsocks.json
    ssPidFile=$HOME/.shadowsocks-libev.pid

    # check if old ss-server running
    # oldPid=`cat $ssPidFile`
    # if [[ "$oldPid" != "" ]]; then
    #     kill -15 $oldPid
    # fi
    killall -15 ss-server 2> /dev/null
    # if [[ $? != 0 ]]; then
    #     echo "[Warning]: kill ss-server err, just pay attention"
    # fi

    # template path of shadowsocks.json
    ssJsonTemPath=$mainWd/template/shadowsocks.json
    if [[ ! -f $ssJsonSysPath ]]; then
        set +x
        cat << _EOF

sudo vim $ssJsonSysPath
and re-run this script

_EOF
        sudo cp $ssJsonTemPath $ssJsonSysPath
        exit
    else
        checkIfModified=`grep -i xx. $ssJsonSysPath 2> /dev/null`
        if [[ "$checkIfModified" != "" ]]; then
            set +x
            cat << _EOF

please modify $ssJsonSysPath first
and re-run this script

_EOF
            exit 255
        fi
    fi

    cat << "_EOF"
------------------------------------------------------
BEGIN TO START NEW SHADOWSOCKS SERVICE
------------------------------------------------------
_EOF
    # start new ss service
    $ssServerPath -c $ssJsonSysPath -f $ssPidFile -u
}

# fix dependency for root mode
fixDepends() {
    cat << "_EOF"
------------------------------------------------------
START TO FIX DEPENDENCY ...
------------------------------------------------------
_EOF
    osType=`sed -n '1p' /etc/issue | tr -s " " | cut -d " " -f 1 | \
        grep -i "[ubuntu|centos]"`
    # fix dependency all together.
    # libsodium-dev mbedtls-dev
    case "$osType" in
        'Ubuntu')
            echo "OS is Ubuntu..."
            # sudo apt-get update
            sudo apt-get install build-essential \
                gcc gettext autoconf libtool automake make \
                libghc-regex-pcre-dev asciidoc xmlto libc-ares-dev \
                libev-dev -y
            ;;

        'CentOS' | 'Red')
            echo "OS is CentOS or Red Hat..."
            # sudo yum update
            sudo yum install epel-release \
                gcc gettext autoconf libtool automake make \
                pcre-devel asciidoc xmlto c-ares-devel libev-devel \
                libsodium-devel mbedtls-devel -y
            ;;

        *)
            cat << _EOF
Not Ubuntu or CentOS
not sure whether this script would work
Please check it yourself ...
_EOF
            exit
        ;;
    esac
    cat << "_EOF"
------------------------------------------------------
FIX DEPENDENCY DONE ...
------------------------------------------------------
_EOF
}

install() {
    mkdir -p $downloadPath

    if [[ ! -f "$runMoreTimeFlag" ]]; then
        fixDepends
    fi
    installAutoConf
    installShadowSocks
    startService
    writeInitFile
    installSummary
    echo "Build Done!" > $runMoreTimeFlag
}

installSummary() {
    set +x
    cat << _EOF
------------------------------------------------------
INSTALLATION SUMMARY
------------------------------------------------------
autoconf path = $autoconfPath
ss-server path=$ssServerPath
Use 'service shadowsocks' to start/stop
Put '/etc/init.d/shadowsocks start' under /etc/rc.local
------------------------------------------------------
_EOF
}

case $1 in
    'home')
        set -x
        commInstdir=$homeInstDir
        execPrefix=""
        install
        ;;

    'root')
        set -x
        commInstdir=$rootInstDir
        execPrefix=sudo
        install
        ;;

    *)
        set +x
        usage
        ;;
esac
