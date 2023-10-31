#!/bin/bash

wget https://wordpress.org/latest.tar.gz
tar xf latest.tar.gz --strip-components=1
rm latest.tar.gz

ls -la