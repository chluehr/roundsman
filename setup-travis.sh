#!/bin/bash
#-----------------------------------------------------------
#
# Purpose: Just run this script to setup a typical working
#          php environment for travis-ci
#
# Target system: travis-ci
# wget -q -O - https://raw.github.com/chluehr/roundsman/master/setup-travis.sh | bash
# (do not execute this line blindly)
#-----------------------------------------------------------

installPearTask ()
{
    echo -e "\nAuto-discover pear channels and upgrade ..."
    pear config-set auto_discover 1
    pear -qq channel-update pear.php.net
    pear -qq upgrade
    echo "... OK"

    echo -e "\nInstalling / upgrading phing ... "
    which phing >/dev/null                      &&
        pear upgrade pear.phing.info/phing ||
        pear install pear.phing.info/phing

    # update paths
    phpenv rehash

    echo "DEBUG which phing:"
    echo $PATH
    phpenv which phing
    ls -lr /home/vagrant/.phpenv/bin
    echo "------------------"


    # re-test for phing:
    phing -v 2>&1 >/dev/null    &&
        echo "... OK"           ||
        return 1
}


#-----------------------------------------------------------

    installPearTask &&
        echo -e "\nSUCCESS - PHP ENVIRONMENT READY." ||
        ( echo "=== FAILED."; exit 1 )

#------------------------------------------------------- eof
