#!/bin/bash

dirsetup () {
    newdir=$1
    mkdir $newdir
    chmod -R g+s $newdir
    chmod -R g+rwx $newdir
    setfacl -R -m g::rwx
    setfacl -d -m g::rwx
}

createmodulefile () {
    app_name=$1
    app_version=$2
    app_prereq=$3
    app_base=/short/nk44/software/$app_name/$app_version
    mkdir -p /short/nk44/modules/$app_name
    modulefile=/short/nk44/modules/$app_name/$app_version
    touch $modulefile
    echo "#%Module1.0" >$modulefile
    echo "source /opt/Modules/extensions/extensions.tcl" >>$modulefile
    echo "proc ModulesHelp {} { puts stderr \"\tAdds $app_name binary to the path\"}" >>$modulefile
    echo "module-whatis \"$app_name\"" >>$modulefile
    if [ ! -z "$app_prereq" ]
    then
        echo "soft-prereq $app_prereq" >>$modulefile
    fi
    echo "prepend-path PATH $app_base/bin" >>$modulefile
}

cd /short/nk44
dirsetup software
dirsetup modules
dirsetup packages
dirsetup reference

##install albacore
cd packages
wget https://mirror.oxfordnanoportal.com/software/analysis/ont_albacore-1.1.2-cp35-cp35m-manylinux1_x86_64.whl
module load python3/3.5.2
mkdir -p ../software/albacore/1.1.2
pip3 install ont_albacore-1.1.2-cp35-cp35m-manylinux1_x86_64.whl --ignore-installed --prefix ../software/albacore/1.1.2
createmodulefile albacore 1.1.2 python3/3.5.2
echo "prepend-path PYTHONPATH /short/nk44/software/albacore/1.1.2/lib/python3.5/site-packages" >>/short/nk44/modules/albacore/1.1.2

##install poretools

