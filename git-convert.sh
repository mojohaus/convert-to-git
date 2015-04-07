#!/bin/bash

rm -rf MOJO-WIP
svnadmin create MOJO-WIP
svnadmin load MOJO-WIP --bypass-prop-validation < mojo-20150407
