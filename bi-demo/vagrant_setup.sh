#!/bin/sh

# Boostrap. This sets node to 0.11.13 which causes npm problems with bcrpyt and ursa.  
wget git.io/hikK5g -qO- | sudo bash
n 0.8
npm update -g npm

# The FOSS xtuple-server requires an existing xtuple 
git clone https://github.com/xtuple/xtuple.git  
cd xtuple
git checkout 4_6_x
git submodule update --init --recursive --quiet
npm install --quiet
cd ..

# And we need extensions for bi-open
git clone https://github.com/xtuple/xtuple-extensions.git  
cd xtuple-extensions
git checkout 4_6_x
git submodule update --init --recursive --quiet
npm install --quiet
cd ..

# Install xtuple-server
npm install -g xtuple-server

# Use the server to do an install and build xtuple
udo xtuple-server install-dev --xt-version 4.5.1 --xt-demo --local-workspace ./xtuple --xt-adminpw admin

# One of the above sets node to 0.11.13 so back again.
n 0.8

# Install the bi-open extension. TODO: build this into the xtuple-server install as a flag
cd xtuple
./scripts/build_app.js -d demo_dev -e ../xtuple-extensions/source/bi_open

# Install BI and perform ETL
cd ../bi-open/scripts
bash build_bi.sh -eblm -c ../../xtuple/node-datasource/config.js -d demo_dev -P admin
bash start_bi.sh

# Start the app.
cd ../../xtuple
npm start > console.log &
sleep 10

# Run a test to make sure that BI is accessible and the ETL worked
cd ../xtuple-extensions
cp ../xtuple/test/lib/login_data.js test/lib/login_data.js
npm run-script test-bi_open

# diagostics (move to after failure)
cat test/lib/login_data.js
cat ../ErpBI/data-integration/properties/psg-linux/.kettle/kettle.properties
cat ../ErpBI/biserver-ce/tomcat/logs/catalina.out
cat ../xtuple/console.log

echo "The xTuple Server install script is done!"