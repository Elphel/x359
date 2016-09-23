#!/bin/sh
UNISIMS="../unisims"
rm -vf motors.lxt
echo "Using UNISIM library $UNISIMS"
time iverilog -Dlegacy_model -gno-specify -v -o sensor_phase359_test -sglbl -stestbench \
-y$UNISIMS \
sensor_phase359_tb.v \
sensor_phase359.v \
glbl.v  \
|| { echo "iverilog failed"; exit 1; } 

time vvp -v  sensor_phase359_test -lxt2  || { echo "vvp failed"; exit 1; } 

gtkwave sensor_phase359.lxt sensor_phase359.sav &


exit 0 


