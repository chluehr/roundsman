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

installToolsTask ()
{
    echo "Installing misc. tool packages"

    sudo apt-get --assume-yes install       \
        vim                                 \
        git-core                            \
        imagemagick                         \
        rsync                               \
        screen
}


installExtrasTask ()
{
    # typical 3rd party systems (db,cache ..):

    echo "Installing MySQL server, Memcache & Beanstalk daemons"

    sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes install     \
        mysql-server                      \
        beanstalkd                        \
        memcached

    # activate beanstalkd:
    sudo echo "START=yes" >> /etc/default/beanstalkd
    sudo /etc/init.d/beanstalkd restart

    # mysql innodb file per table settings:
    grep -q -r '^innodb_file_per_table' /etc/mysql/my.cnf         ||
    (
        sudo sed -i -e "s|^\[mysqld\]$|[mysqld]\ninnodb_file_per_table\n|" /etc/mysql/my.cnf
    )

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

installApacheTask ()
{
    echo "Enabling Apache mod_rewrite & restarting Apache"

    sudo a2enmod rewrite
    sudo apache2ctl graceful
}

#-----------------------------------------------------------

    upgradeSystemTask

    installToolsTask
    installExtrasTask
    installPhpTask
    installApacheTask

#------------------------------------------------------- eof
