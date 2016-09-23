/*
** -----------------------------------------------------------------------------**
** dcm_phase.v
**
** Copyright (C) 2002 Elphel, Inc
**
** -----------------------------------------------------------------------------**
**  This file is part of X353
**  X333 is free software - hardware description language (HDL) code.
** 
**  This program is free software: you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation, either version 3 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License
**  along with this program.  If not, see <http://www.gnu.org/licenses/>.
** -----------------------------------------------------------------------------**
**
** $Log: dcm_phase.v,v $
** Revision 1.2  2010/05/14 18:48:35  dzhimiev
** 1. added hacts shifts for buffered channels
** 2. set fixed SDRAM spaces
**
*/

`timescale 1 ns / 1 ps

module dcm_phase (
	cclk,   	   // command clock for shift
	wcmd,   	   // decoded address - enables wclk
   cmd,    	   // CPU write data [3:0]
	        	   //  0 - nop, just reset status data
	        	   //  1 - increase phase shift
	        	   //  2 - decrease phase shift
	        	   //  3 - reset phase shift to default (preprogrammed in FPGA configuration)
	        	   //  4 - incr pahse90
	        	   //  8 - decrease phase90											
	        	   //  c - reset phase90
	iclk,   	   // DCM input clock
	clk_fb,     // feed back clock
	clk0,       // global output clock, phase 0
	clk90,      // global output clock, phase 90
	clk180,     // global output clock, phase 180							
	clk270,     // global output clock, phase 270
	
	dcm_phase,   // current DCM phase (small steps)
	dcm_phase_90,// current DCM quarter (90 degrees steps)
	dcm_done,    // DCM command done
	dcm_status,  // DCM status (bit 1 - dcm clkin stopped)
	dcm_locked   // DCM "Locked" pin
);
							
  parameter NO_SHIFT90=0; //wanted to choose between clk0 BUFGs
							
	input         cclk;
   input         wcmd;
   input  [ 3:0] cmd;
   input         iclk;
   input         clk_fb;	
	
	output clk0;
	output clk90;
	output clk180;
	output clk270;	
	
   output [8:0]  dcm_phase;
   output [1:0]  dcm_phase_90;
	output dcm_done;
	output [7:0] dcm_status;
	output dcm_locked;

  reg       dcm_rst=0;
  wire      dcm_rst_cmd;
  reg [2:0] dcm_drst=0;  
  reg [2:0] dcm_reset_done=0;
  wire dcm_done_dcm;
  
  reg dcm_en=0;
  reg dcm_incdec=0;
  reg [8:0] phase_reg=0;
  reg [1:0] phase90_reg=0;
  
  reg dcm_done=0;
  
  assign dcm_phase[8:0] = phase_reg[8:0];
  assign dcm_phase_90[1:0] = NO_SHIFT90? 0 : phase90_reg[1:0];

  FD i_dcm_rst_cmd(.Q(dcm_rst_cmd), .D((wcmd && (cmd[1:0] == 2'b11)) || (dcm_rst_cmd && !dcm_drst[2])), .C(cclk));
  
  // shift commands are synchronous to the command clock
  always @ (posedge cclk) begin
    dcm_reset_done[2:0] <= {dcm_reset_done[1] & ~dcm_reset_done[0], dcm_reset_done[0], dcm_rst}; // sync to cclkl end of dcm reset
    dcm_en     <= wcmd && (cmd[1]!=cmd[0]);
    dcm_incdec <= wcmd && cmd[0]; 

    if (wcmd) begin
      if      (cmd[0] && cmd[1]) phase_reg[8:0] <= 9'h0;
      else if (cmd[0])           phase_reg[8:0] <= phase_reg[8:0] +1;
      else if (cmd[1])           phase_reg[8:0] <= phase_reg[8:0] -1;
    end	 
	 
    if (wcmd) begin
      if      (cmd[2] && cmd[3]) phase90_reg[1:0] <= 2'h0;
      else if (cmd[2])           phase90_reg[1:0] <= phase90_reg[1:0] +1;
      else if (cmd[3])           phase90_reg[1:0] <= phase90_reg[1:0] -1;
    end
  end

  // dcm_rst is synchronous to incoming clock
  always @ (posedge iclk) begin
    dcm_drst[2:0] <= dcm_drst[2]? 3'b0:{dcm_drst[1], dcm_drst[0], dcm_rst_cmd};
    dcm_rst    <= dcm_drst[0]  || dcm_drst[1]   || dcm_drst[2] ;
  end
// make dcm_done behave as dcm_ready
  always @ (posedge cclk)
     if (wcmd && |cmd[2:0])                      dcm_done <= 0;
     else if (dcm_done_dcm || dcm_reset_done[2]) dcm_done <= 1;

/// DCM to compensate sensor delays. Adjustment for data phase - both fine and 90-degrees, hact/vact - 90-degree steps relative to data

  DCM_SP #(
      .CLKIN_DIVIDE_BY_2("FALSE"),     // TRUE/FALSE to enable CLKIN divide by two feature
      .CLKIN_PERIOD(10.0),            //96Hz
      .CLKOUT_PHASE_SHIFT("VARIABLE"),// Specify phase shift of NONE, FIXED or VARIABLE
      .CLK_FEEDBACK("1X"),            // Specify clock feedback of NONE, 1X or 2X
      .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
                                            //   an integer from 0 to 15
      .DLL_FREQUENCY_MODE("LOW"),     // HIGH or LOW frequency mode for DLL
      .DUTY_CYCLE_CORRECTION("TRUE"), // Duty cycle correction, TRUE or FALSE
      .PHASE_SHIFT(0),                // Amount of fixed phase shift from -255 to 255
      .STARTUP_WAIT("FALSE")          // Delay configuration DONE until DCM LOCK, TRUE/FALSE
   ) i_dcm_sensor(
    .CLKIN    (iclk),
    .CLKFB    (clk_fb),
    .RST      (dcm_rst),
    .PSEN     (dcm_en),
    .PSINCDEC (dcm_incdec),
    .PSCLK    (cclk),
    .DSSEN    (1'b0),
    .CLK0     (pre_clk0),
    .CLK90    (pre_clk90),   // adjust tap
    .CLK180   (pre_clk180), // adjust tap
    .CLK270   (pre_clk270),
    .CLKDV    (),
    .CLK2X    (),
    .CLK2X180 (),
    .CLKFX    (),
    .CLKFX180 (),
    .STATUS   (dcm_status[7:0]),
    .LOCKED   (dcm_locked),
    .PSDONE   (dcm_done_dcm)
);

	wire pre_clk = phase90_reg[1]? (phase90_reg[0]? pre_clk270:pre_clk180) : (phase90_reg[0]? pre_clk90:pre_clk0);

	BUFG i_clk0a   (.I(NO_SHIFT90?pre_clk0:pre_clk),   .O(clk0));
//	BUFG i_clk0b   (.I(pre_clk),   .O(clk0));
		
	BUFG i_clk90  (.I(pre_clk90),  .O(clk90));
	BUFG i_clk180 (.I(pre_clk180), .O(clk180));
	BUFG i_clk270 (.I(pre_clk270), .O(clk270));

endmodule
