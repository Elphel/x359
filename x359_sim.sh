#!/bin/bash
#XILINX=/home/andrey/Xilinx91i
#modified version
#XILINX=/home/andrey/xil91
#echo "$XILINX/verilog/src/unisims"



#echo iverilog -v -o x359.vvp -Dlegacy_model -s x359_tf -s glbl \
#-y $XILINX/verilog/src/unisims \
#x359_1.tf \
#x359.v \
#i2csbr.v \
#glbl.v

UNISIMS="../unisims"
rm -vf x359_sim.lxt
rm -vf x359.vvp

iverilog -v -o x359.vvp -Dlegacy_model -s x359_tf -s glbl \
-y $UNISIMS \
x359.tf \
x359.v \
i2csbr.v \
ddr.v \
clkios353.v \
sdram_phase.v \
dcm_phase.v \
ioports353.v \
sync_frames.v \
mcontr359.v \
mcontr_cmd.v \
mcontr_arbiter.v \
mcontr_refresh.v \
mcontr_line_wr.v \
mcontr_line_rd.v \
channel_wr.v \
channel_rd.v \
sensor_phase359.v \
sensor_phase359_vact.v \
channel_rd_short.v \
macros353.v \
sensor12bits.v \
glbl.v

vvp -v  x359.vvp -lxt2 || { echo "vvp failed"; exit 1; } 

#
gtkwave x359_sim.lxt x359.sav


#-y$XILINX/verilog/src/simprims 
#-y$XILINX/verilog/src/unisims

exit 0 
