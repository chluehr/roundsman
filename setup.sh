#!/bin/bash
#-----------------------------------------------------------
#
# Purpose: Just run this script to setup a typical working
#          php environment - better use puppet or chef for
#          real servers!
#
# Target system: ubuntu-12.04-server-amd64.iso
# wget -q -O - https://raw.github.com/chluehr/roundsman/master/setup.sh | bash
# (do not execute this line blindly)
#-----------------------------------------------------------

upgradeSystemTask ()
{

    # ask once for sudo password ..
    sudo true

    echo -e "\nUpgrading system ..."

    sudo apt-get install --fix-broken
    sudo apt-get autoclean
    sudo apt-get autoremove

    sudo apt-get -qq update                 &&
    sudo apt-get -qq --assume-yes upgrade   &&
    echo "... OK"                           ||
    return 1
}

installToolsTask ()
{
    echo -e "\nInstalling misc. tool packages ..."

    sudo apt-get --assume-yes install   \
        vim                                 \
        git-core                            \
        imagemagick                         \
        rsync                               \
        screen                              &&
        echo "... OK"                       ||
        return 1
}


installExtrasTask ()
{
    # typical 3rd party systems (db,cache ..):

    echo -e "\nInstalling MySQL server, Memcache & Beanstalk daemons ..."

    sudo DEBIAN_FRONTEND=noninteractive apt-get -qq --assume-yes install     \
        mysql-server                        \
        beanstalkd                          \
        memcached                           &&
        echo "... OK"                       ||
        return 1

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

    echo -e "\nInstalling PHP related packages ..."
    sudo apt-get -qq --assume-yes install   \
        libapache2-mod-php5             \
        php5-cli                        \
        php5-mysqlnd                    \
        php5-sqlite                     \
        php5-xdebug                     \
        php5-xcache                     \
        php5-suhosin                    \
        php5-gd                         \
        php5-mcrypt                     \
        php5-xsl                        \
        php5-curl                       \
        php5-intl                       \
        php5-memcache                   &&
        echo "... OK"                   ||
        return 1


    # update php memory limit

    echo -e -n "\nRaising memory limit in php.ini files ... "
    sudo sed -i -r 's/^ *memory_limit *= *.*/memory_limit = 512M/' /etc/php5/apache2/php.ini    &&
        sudo sed -i -r 's/^ *memory_limit *= *.*/memory_limit = 512M/' /etc/php5/cli/php.ini    &&
        echo "OK"   ||
        return 1

    echo -e -n "\nFixing annoying notice regarding wrong comment in mcrypt ini file ... "
    sudo sed -i -r -e 's/^#(.*)$/;\1/' /etc/php5/cli/conf.d/mcrypt.ini  &&
        echo "OK" ||
        return 1

    echo -e -n "\nAdding extra php ini file /etc/php... "
    read -r -d '' VAR <<-'EOF'
	;allow phar execution even with suhosin patch (for composer):
	suhosin.executor.include.whitelist="phar"
	;enable the next line for symfony2 projects ...
	;short_open_tag = off
	[Date]
	date.timezone = Europe/Berlin
	EOF
    echo "$VAR" |sudo tee /etc/php5/conf.d/zzz-roundsman.ini >/dev/null
    echo "OK"
}

installPearTask ()
{
    echo -e "\nInstalling pear ..."

    sudo apt-get -qq --assume-yes install php-pear  &&
    echo "... OK"                                   ||
    return 1

    echo -e "\nAuto-discover pear channels and upgrade ..."
    sudo pear config-set auto_discover 1
    sudo pear -qq channel-update pear.php.net
    sudo pear -qq upgrade
    echo "... OK"

    echo -e "\nInstalling / upgrading phing ... "
    which phing >/dev/null                      &&
        sudo pear upgrade pear.phing.info/phing ||
        sudo pear install pear.phing.info/phing
    # re-test for phing:
    phing -v 2>&1 >/dev/null    &&
        echo "... OK"           ||
        return 1

    echo -e "\nInstalling / upgrading phpcpd ... "
    which phpcpd >/dev/null                      &&
        sudo pear upgrade pear.phpunit.de/phpcpd ||
        sudo pear install pear.phpunit.de/phpcpd
    # re-test for phpcpd:
    phpcpd -v 2>&1 >/dev/null   &&
        echo "... OK"           ||
        return 1


    echo -e "\nInstalling / upgrading phpcs ... "
    which phpcs >/dev/null                             &&
        sudo pear upgrade pear.php.net/PHP_CodeSniffer ||
        sudo pear install pear.php.net/PHP_CodeSniffer
    # re-test for phpcs:
    phpcs --version 2>&1 >/dev/null   &&
        echo "... OK"           ||
        return 1

    echo -e "\nInstalling / upgrading phpcs Symfony2 coding standard... "
    cd /usr/share/php/PHP/CodeSniffer/Standards
    if test -d Symfony2
    then
	cd Symfony2
        sudo git pull
    else
        sudo git clone git://github.com/opensky/Symfony2-coding-standard.git Symfony2
    fi
    sudo phpcs --config-set default_standard Symfony2
    echo "... OK"


    echo -e "\nInstalling / upgrading phpunit ... "
    which phpunit >/dev/null                        &&
        sudo pear upgrade pear.phpunit.de/phpunit ||
        sudo pear install pear.phpunit.de/phpunit
    # re-test for phpunit:
    phpunit --version 2>&1 >/dev/null  &&
        echo "... OK"           ||
        return 1

    echo -e "\nInstalling / upgrading pdepend ... "
    which pdepend >/dev/null                       &&
        sudo pear upgrade pear.pdepend.org/PHP_Depend ||
        sudo pear install pear.pdepend.org/PHP_Depend
    # re-test for pdepend:
    pdepend --version 2>&1 >/dev/null  &&
        echo "... OK"           ||
        return 1

    echo -e "\nInstalling / upgrading phpmd ... "
    which phpmd >/dev/null                       &&
        sudo pear upgrade pear.phpmd.org/PHP_PMD ||
        sudo pear install --alldeps pear.phpmd.org/PHP_PMD
    # re-test for phpmd:
    phpmd --version 2>&1 >/dev/null  &&
        echo "... OK"           ||
        return 1

    echo -e "\nInstalling / upgrading phpdoc ... "
    which phpdoc >/dev/null                       &&
        sudo pear upgrade pear.phpdoc.org/phpDocumentor-alpha ||
        sudo pear install pear.phpdoc.org/phpDocumentor-alpha
    # re-test for phpmd:
    phpdoc --version 2>&1 >/dev/null  &&
        echo "... OK"           ||
        return 1
}

installApacheTask ()
{
    echo -e "\nEnabling Apache mod_rewrite & restarting Apache ..."

    sudo a2enmod rewrite
    sudo apache2ctl graceful
    echo "... OK"
}

#-----------------------------------------------------------

    upgradeSystemTask   &&
    installToolsTask    &&
    installExtrasTask   &&
    installPhpTask      &&
    installPearTask     &&
    installApacheTask	&&
        echo -e "\nSUCCESS - PHP ENVIRONMENT READY." ||
        ( echo "=== FAILED."; exit 1 )

#------------------------------------------------------- eof
