#!/bin/bash
rm or1300TrippleCore.*
yosys -D GECKO5Education -s ../scripts/yosysOr1300.script 
nextpnr-ecp5 --threads 12 --timing-allow-fail --85k --package CABGA381 --json or1300TrippleCore.json --lpf ../scripts/gecko5.lpf --textcfg or1300TrippleCore.config
ecppack --compress --freq 62.0 --input or1300TrippleCore.config --bit or1300TrippleCore.bit
openFPGALoader or1300TrippleCore.bit
