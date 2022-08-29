#!/usr/bin/env bash
#########################################################################
# File Name: flush.sh
# Author: Mode
# mail: 13692247896@163.com
# Created Time: 一  8/29 19:47:14 2022
# Describe: 
#########################################################################

cd "$(dirname "${BASH_SOURCE[0]}")"
echo 'Removing dir out'
rm -rf out
echo 'Creating output structure'
mkdir out
cd out
mkdir newcerts
touch index.txt
echo "unique_subject = no" > index.txt.attr
echo 1000 > serial
echo 'Done'
