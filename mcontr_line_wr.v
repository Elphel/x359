/*
*! -----------------------------------------------------------------------------**
*! FILE NAME  : mcontr_line_wr.v
*! DESCRIPTION: write sequence to sdram
*! Copyright (C) 2008 Elphel, Inc.
*! -----------------------------------------------------------------------------**
*!  This program is free software: you can redistribute it and/or modify
*!  it under the terms of the GNU General Public License as published by
*!  the Free Software Foundation, either version 3 of the License, or
*!  (at your option) any later version.
*!
*!  This program is distributed in the hope that it will be useful,
*!  but WITHOUT ANY WARRANTY; without even the implied warranty of
*!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*!  GNU General Public License for more details.
*!
*!  You should have received a copy of the GNU General Public License
*!  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*! -----------------------------------------------------------------------------**
*!
*! $Log: mcontr_line_wr.v,v $
*! Revision 1.4  2010/05/14 18:48:35  dzhimiev
*! 1. added hacts shifts for buffered channels
*! 2. set fixed SDRAM spaces
*!
*! Revision 1.1  2009/06/11 17:39:00  dzhimiev
*! new initial version
*! 1. simulation and board test availability
*!
*! Revision 1.1  2008/12/08 09:11:54  dzhimiev
*! 0. based on theora's mcontr_8chn.v, mcontr_line512_wr.v, mcontr_line512_rd.v
*! 1. set up of the data path for the transform
*! 2. 2 read and 2 write channels
*! 3. in snapshot mode - 3 frames output sequence -
*!   1st - direct
*!   2nd - stored 'direct' from the 1st buffer
*!   3rd - stored '1st buffer' from the 2nd buffer
*!
*/

`timescale 1 ns / 1 ps

// need to take care of banks when switching from plane to plane in the same access.
module mcontr_line_wr   (mclk0,    // system clock, mostly negedge
                            en,
// interface to the output block RAM (x16). Will probably include 12->16 bit conversion here
                            predrun,     // 
// interface to SDRAM arbiter
                            start,    // start atomic writing to SDRAM operation (5 cycles ahead of RAS command on the pads)
                            sa,       // [16:0] - 13 MSBs ->RA, 4 LSBs - row in a chunk 
                            len,      // [ 4:0] - number of 32-byte groups to write, 0 - all 256bytes, for other values - (len*32+8) bytes
                            prenext,  // 8 cycles ahead of possible next start_*?
// interface to SDRAM (through extra registers
                            pre3pre,  // precharge command (3 ahead)
                            pre3wr,   // read command (3 ahead)
                            pre3act,  // activate command (3ahead)
                            pre3sda,  //[12:0] address to SDRAM - 3 cycles ahead of I/O pads
                            pre3sdb,  //[ 1:0] bank to SDRAM - 3 cycles ahead of I/O pads
                            drive_sd3,   // enable data to SDRAM   (2 cycles ahead)
                            drive_dq3,   //  enable DQ outputs (one extra for FF in output buffer)
                            dmask3,      // write mask - 1 bit as even number of words written (32-bit pairs)
                            inuse3    // SDRAM in use by this channel (sync with pre3***
                            );


  input         mclk0;
  input         en;
  output        predrun;
  input         start;
  input  [21:0] sa;
  input  [ 4:0] len;
  output        prenext;
// interface to SDRAM (through extra registers
  output        pre3pre;       // precharge command (3 ahead)
  output        pre3wr;        // write command (3 ahead)
  output        pre3act;       // activate command (3ahead)
  output [12:0] pre3sda;       //[12:0] address to SDRAM - 3 cycles ahead of I/O pads
  output  [1:0] pre3sdb;       //[ 1:0] bank to SDRAM - 3 cycles ahead of I/O pads

  output        drive_sd3;     // enable data to SDRAM   (2 cycles ahead)
  output        drive_dq3;     //  enable DQ outputs (one extra for FF in output buffer)
  output        dmask3;        // write mask - 1 bit as even number of words written (32-bit pairs)

  output        inuse3;        // SDRAm in use by this channel (sync with pre3***


  reg           pre3act;
  reg           pre3pre;
  reg           pre3wr;
  reg    [12:0] pre3sda;
  reg    [ 1:0] pre3sdb;
  reg           inuse3;
  reg           predrun;
  reg           drun;

	wire          predrun_off;
  reg           preprenext;

  reg           drive_sd3;     // enable data to SDRAM   (2 cycles ahead)
  reg           drive_dq3;     // enable DQ outputs (one extra for FF in output buffer)
  reg           dmask3;        // write mask - 1 bit as even number of words written (32-bit pairs)

  wire          drive_sd3_off;
  reg           drive_dq3_off;
  reg           pre4act1;      // before first of 2 activate pulses
  reg           pre5act2;
  reg           pre4act2;
  reg           pre4wr;
  reg           pre4wr1;
  reg           pre4wr_else;
  wire          pre6wr;
  reg           pre5wr;
  reg           pre4pre;
  reg    [ 5:0] left;
  reg           fullpage;
  
  reg pre4pre1,pre4pre2;
	wire prenext;
	assign prenext=predrun_off;

  MSRL16_1 i_pre6wr        (.Q(pre6wr),        .A(4'h1),   .CLK(mclk0), .D(en & pre4wr & (left[5:0]!=0)));
  MSRL16_1 i_predrun_off   (.Q(predrun_off),   .A(4'h2),   .CLK(mclk0), .D(preprenext));
	MSRL16_1 i_drive_sd3_off (.Q(drive_sd3_off), .A(4'h2),   .CLK(mclk0), .D(predrun_off));

  always @ (negedge mclk0) begin
   pre4act1 <= start;
   pre5act2 <= pre4act1;
   pre4act2 <= pre5act2; // not alway will generate "activate" command

	 pre3act  <= pre4act1 | pre4act2;
   pre4wr1  <= pre4act2;
   pre5wr   <= pre6wr;

   if (pre5act2) fullpage <= left[5];

   pre4wr   <= pre4act2 || (pre5wr && (!fullpage || (left[5:0]!=0)));
   pre4wr_else <=          (pre5wr && (!fullpage || (left[5:0]!=0)));

   drive_dq3_off <= fullpage?drive_sd3_off:pre4pre;

   pre4pre  <= drive_sd3_off;
   if      (pre4act1)    pre3sda[12:0] <= sa[21:9];        // row 1
   else if (pre4act2)    pre3sda[12:0] <= pre3sda[12:0]+1; // row 2
   else if (pre4wr1)     pre3sda[12:0] <= {1'b0,sa[8:2],5'h0};
   else if (pre4wr_else) 
		if (left[3:0]==len[4:1]) pre3sda[12:0] <= {1'b0,sa[8:2],5'h0};
		else                        pre3sda[12:0] <= {pre3sda[12:3]+10'b1,3'h0};
   else if (pre4pre2)     pre3sda[12:0] <= {pre3sda[12:11],1'b1,pre3sda[9:0]}; //set A10, others - don't care

   if      (pre4act1)    pre3sdb[0] <= sa[0];

   if      (pre4act1)                                                  pre3sdb[1] <= sa[0] ^ sa[1];
   else if (pre4act2 | pre4wr1 | (pre4wr_else & (left[3:0]==len[4:1]))) pre3sdb[1] <= ~pre3sdb[1];

   if    (pre4act1) left[5:0] <= {~(|len[4:0]), len[4:0]};
   else if (pre4wr) left[5:0] <= left[5:0] - 1;

   predrun   <= en & !predrun_off    & (predrun | pre4act2);
   drive_sd3 <= en & (!drive_sd3_off) & (drive_sd3 | pre4wr1);
   drive_dq3 <= en & (!drive_dq3_off) & (drive_dq3 | pre4wr1); 
   inuse3    <= en & !pre3pre && (inuse3 | pre4act1);

   drun       <= predrun;

   preprenext    <=  (left[5:0]==0) & (fullpage?pre6wr:pre5wr);
   //predrun_off<= prenext;

   dmask3     <=  ~drun;
   pre4pre1   <= pre4pre;
	 pre4pre2   <= pre4pre1;
	 pre3pre    <= pre4pre2;
   pre3wr     <= pre4wr;

  end

endmodule



