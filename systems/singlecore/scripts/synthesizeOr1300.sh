rm or1300SingleCore.*
yosys -D GECKO5Education -s ../scripts/yosysOr1300.script 
nextpnr-ecp5 --threads 12 --timing-allow-fail --85k --package CABGA381 --json or1300SingleCore.json --lpf ../scripts/gecko5.lpf --textcfg or1300SingleCore.config
ecppack --compress --freq 62.0 --input or1300SingleCore.config --bit or1300SingleCore.bit
openFPGALoader or1300SingleCore.bit
