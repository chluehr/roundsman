roundsman
=========

[![Build Status](https://secure.travis-ci.org/chluehr/roundsman.png)](http://travis-ci.org/chluehr/roundsman)

Roundsman contains a couple of (bash) shell scripts which
are designed to prepare a linux system for development.

setup.sh
--------
Simple bash script to bring a ubuntu system up to speed regarding the newest development tools.

travis-phing.sh
---------------
Add this to your .travis.yml config in order to use phing on travis-ci.
Sample:

    language: php
    php:
      - 5.3
      - 5.4
    before_script: wget -q -O - https://raw.github.com/chluehr/roundsman/master/travis-phing.sh
    script: ./travis-phing.sh


build.xml
---------
Dummy, just for testing the travis setup.


