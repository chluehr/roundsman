#!/bin/bash
#-----------------------------------------------------------
#
# Purpose: Just run this script to setup a typical working
#          php environment - better use puppet or chef for
#          real servers!
#
# Build and tested for ubuntu-10.04.4-server-amd64.iso
# wget -q -O - https://raw.github.com/chluehr/roundsman/master/setup.sh | bash
# (do not execute that line blindly)
#-----------------------------------------------------------

installToolsTask ()
{
    echo -n "Installing misc. tool packages ... "

    sudo apt-get -qq --assume-yes install   \
        vim                                 \
        git-core                            \
        imagemagick                         \
        rsync                               \
        screen                              &&
        echo "OK"                           ||
        ( echo "FAILED";  exit 1 )
}


installExtrasTask ()
{
    # typical 3rd party systems (db,cache ..):

    echo -n "Installing MySQL server, Memcache & Beanstalk daemons ... "

    sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes install     \
        mysql-server                        \
        beanstalkd                          \
        memcached                           &&
        echo "OK"                           ||
        ( echo "FAILED";  exit 1 )

    # activate beanstalkd:
    sudo sed -i -e "s|^#START=yes.*$|START=yes|" /etc/default/beanstalkd
    sudo /etc/init.d/beanstalkd restart

    # mysql innodb file per table settings:
    grep -q -r '^innodb_file_per_table' /etc/mysql/my.cnf         ||
    (
        sudo sed -i -e "s|^\[mysqld\]$|[mysqld]\ninnodb_file_per_table\n|" /etc/mysql/my.cnf
        sudo restart mysql
    )

}

installPhpTask ()
{

    echo -n "Installing PHP related packages ... "
    sudo apt-get --assume-yes install   \
        libapache2-mod-php5             \
        php5-mysql                      \
        php5-sqlite                     \
        php5-xdebug                     \
        php5-xcache                     \
        php5-suhosin                    \
        php5-gd                         \
        php5-mcrypt                     \
        php5-xsl                        \
        php5-curl                       \
        php5-memcache                   &&
        echo "OK"                       ||
        ( echo "FAILED";  exit 1 )


    # update php memory limit

    echo "Raising memory limit in php.ini files"
    sudo sed -i -r 's/^ *memory_limit *= *.*/memory_limit = 512M/' /etc/php5/apache2/php.ini
    sudo sed -i -r 's/^ *memory_limit *= *.*/memory_limit = 512M/' /etc/php5/cli/php.ini

    echo "Fixing annoying notice regarding wrong comment in mcrypt ini file"
    sudo sed -i -r -e 's/^#(.*)$/;\1/' /etc/php5/cli/conf.d/mcrypt.ini
}

installPearTask ()
{
    echo -n "Installing pear ... "

    sudo apt-get -qq --assume-yes install php-pear  &&
    echo "OK"                                       ||
    ( echo "FAILED";  exit 1 )

    echo "Installing phing"
    sudo pear -qq channel-update pear.php.net
    sudo pear -qq upgrade
    sudo pear -qq channel-discover pear.phing.info
    sudo pear -qq install phing/phing
}

upgradeSystemTask ()
{
    echo -n "Upgrading system ... "

    sudo apt-get -qq update                 &&
    sudo apt-get -qq --assume-yes upgrade   &&
    echo "OK"                               ||
    ( echo "FAILED";  exit 1 )
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
    installPearTask
    installApacheTask

#------------------------------------------------------- eof
