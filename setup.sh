#!/bin/bash
#-----------------------------------------------------------
#
# Purpose: Just run this script to setup a typical working
#          php environment
#
# Build and tested for ubuntu-10.04.4-server-amd64.iso
# wget -q -O - https://raw.github.com/chluehr/roundsman/master/setup.sh | bash
#
#-----------------------------------------------------------

installJavaTask ()
{

    echo "Checking / enabling 'partner' Ubuntu repository"
        grep -q -r '^deb .* partner' /etc/apt/sources.list         ||
        ( echo "Ubuntu 'partner' repository not enabled."
        sudo sed -i -e "s|^# deb (.*) partner.*$|deb \1 partner|" /etc/apt/sources.list
    )

    sudo apt-get update &&
    sudo apt-get --assume-yes install  sun-java6-jdk &&
    sudo update-java-alternatives -s java-6-sun
}

installExtrasTask ()
{
    # typical 3rd party systems (db,cache ..):

    echo "Installing MySQL server, Memcache & Beanstalk daemons"

    export DEBIAN_FRONTEND=noninteractive

    sudo apt-get --assume-yes install     \
        mysql-server                      \
        beanstalkd                        \
        memcached

    # activate beanstalkd:
    sudo echo "START=yes" >> /etc/default/beanstalkd
    sudo /etc/init.d/beanstalkd restart

}

installPhpTask ()
{

    sudo apt-get --assume-yes install    \
         libapache2-mod-php5             \
         php-pear                        \
         php5-mysql                      \
         php5-sqlite                     \
         php5-xdebug                     \
         php5-xcache                     \
         php5-suhosin                    \
         php5-gd                         \
         php5-mcrypt                     \
         php5-xsl                        \
         php5-curl                       \
         php5-memcache

    # update php memory limit

    echo "Raising memory limit in php.ini files"
    sudo sed -i -r 's/^ *memory_limit *= *.*/memory_limit = 512M/' /etc/php5/apache2/php.ini
    sudo sed -i -r 's/^ *memory_limit *= *.*/memory_limit = 512M/' /etc/php5/cli/php.ini
}


upgradeSystemTask ()
{
    echo "Upgrade system"
    sudo apt-get update
    sudo apt-get --assume-yes upgrade
}

#-----------------------------------------------------------

    upgradeSystemTask

    installJavaTask
    installExtrasTask
    installPhpTask
    
#------------------------------------------------------- eof
