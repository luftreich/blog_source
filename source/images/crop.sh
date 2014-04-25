#!/bin/bash

for file in `ls *.png`
do
    echo 'cropping '$file
    convert -trim $file $file
done
