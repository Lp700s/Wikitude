#!/bin/bash

# Make sure the Android libs folder exists
mkdir -p android/libs

# Make a temp directory and move into it
mkdir temp
cd temp

# Get the android .aar and put it into the proper location
wget --quiet https://s3.amazonaws.com/mbt-public/8.1.0-js/wikitudesdk.aar
mv wikitudesdk.aar ../android/libs/

# Get the iOS Framework and put it in the proper location
wget --quiet https://s3.amazonaws.com/mbt-public/8.1.0-js/WikitudeSDK.framework.zip
unzip -q WikitudeSDK.framework.zip
mv WikitudeSDK.framework ../ios/

# Remove the temporary folder
cd ../
rm -rf temp
