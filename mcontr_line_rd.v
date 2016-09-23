/*
*! -----------------------------------------------------------------------------**
*! FILE NAME  : mcontr_line_rd.v
*! DESCRIPTION: read sequence to sdram
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
*! $Log: mcontr_line_rd.v,v $
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

/*
will open both pages (if 2 are needed) at once, read as needed and precharge all banks in the end                                                                                                                                     
*/

// need to take care of banks when switching from plane  to plane in the same access.

`timescale 1 ns / 1 ps

module mcontr_line_rd   (mclk0,    // system clock, mostly negedge
                            en,
// interface to the output block RAM (x16). Will probably include 12->16 bit conversion here
                            predrun,     // 
// interface to SDRAM arbiter
                            start,    // start atomic reading from SDRAM operation (5 cycles ahead of RAS command on the pads)
                            sa,       // [16:0] - 13 MSBs ->RA, 4 LSBs - row in a chunk 
                            len,      // [ 4:0] - number of 32-byte groups to read, 0 - all 256bytes, for other values - (len*32+8) bytes
                            //m16,      // 16-bit mode (read 2, not 1 extra 32-bit words for partial blocks)
                            prenext,  // 8 cycles ahead of possible next start_*?
// interface to SDRAM (through extra registers
                            pre3pre,  // precharge command (3 ahead)
                            pre3rd,   // read command (3 ahead)
                            pre3act,  // activate command (3ahead)
                            pre3sda,  //[12:0] address to SDRAM - 3 cycles ahead of I/O pads
                            pre3sdb,  //[ 1:0] bank to SDRAM - 3 cycles ahead of I/O pads
//                            sddi,     //[31:0] - data from SDRAM
                            dqs_re3,  // enable read from DQS i/o-s for phase adjustments  (1 ahead of the final)
                            inuse3    // SDRAm in use by this channel (sync with pre3***
                            );

  input         mclk0;
  input         en;
  output        predrun;
  input         start;
  input  [21:0] sa;
  input  [ 4:0] len;
  //input         m16;
  output        prenext;
// interface to SDRAM (through extra registers
  output        pre3pre;       // precharge command (3 ahead)
  output        pre3rd;        // read command (3 ahead)
  output        pre3act;       // activate command (3ahead)
  output [12:0] pre3sda;       //[12:0] address to SDRAM - 3 cycles ahead of I/O pads
  output  [1:0] pre3sdb;       //[ 1:0] bank to SDRAM - 3 cycles ahead of I/O pads
//  input  [31:0] sddi;          //[31:0] - data from SDRAM
  output        dqs_re3;       // enable read from DQS i/o-s for phase adjustments  (1 ahead of the final)
  output        inuse3;        // SDRAm in use by this channel (sync with pre3***


//
  reg           pre3act;
  reg           pre3pre;
  reg           pre3rd;
  reg    [12:0] pre3sda;
  reg    [ 1:0] pre3sdb;
  reg           inuse3;
  reg           predrun;
  reg           prenext;
  reg           dqs_re3;

  wire          predrun_on;
  wire          predrun_off;
  wire          dqs_re3_on;
  wire          dqs_re3_off;

  reg           pre4act1;   // before first of 2 activate pulses
  reg           pre5act2;
  reg           pre4act2;
  reg           pre4rd;
  reg           pre4rd1;
  reg           pre4rd_else;
  wire          pre6rd;
  reg           pre5rd;
  reg           pre4pre;
  
  reg pre4pre1,pre4pre2,pre4pre3;
  
  reg    [ 5:0] left;
//  reg    [ 3:0] row;
  //reg    [ 1:0] row;
  reg           fullpage;
  //reg           m16_r;
  //reg           pre4pre_no_m16; 
  wire   [ 3:0] next_ca=pre3sda[6:3]+1;

  MSRL16_1 i_pre6rd        (.Q(pre6rd),     .A(4'h1),   .CLK(mclk0), .D(en && pre4rd && (left[5:0]!=0)));

  MSRL16_1 i_predrun_on       (.Q(predrun_on),    .A(4'h7),   .CLK(mclk0), .D(pre4act2));
  MSRL16_1 i_predrun_off      (.Q(predrun_off),   .A(4'h6),   .CLK(mclk0), .D(pre4pre3));

//  MSRL16_1 i_dqs_re3_on    (.Q(dqs_re3_on), .A(4'h5),   .CLK(mclk0), .D(pre4act2));
//  MSRL16_1 i_dqs_re3_off   (.Q(dqs_re3_off),.A(4'h4),   .CLK(mclk0), .D(pre4pre));

  MSRL16_1 i_dqs_re3_on    (.Q(dqs_re3_on), .A(4'h4),   .CLK(mclk0), .D(pre4act2));
  MSRL16_1 i_dqs_re3_off   (.Q(dqs_re3_off),.A(4'h3),   .CLK(mclk0), .D(pre4pre3));

  always @ (negedge mclk0) begin
   pre4act1 <= start;
   pre5act2 <= pre4act1;
   pre4act2 <= pre5act2; // not alway will generate "activate" command

   //pre3act  <= pre4act1 || (pre4act2 && (left[5] || left[4]));
	 pre3act  <= pre4act1 | pre4act2;
	 
   pre4rd1  <= pre4act2;
   pre5rd   <= pre6rd;

//   if (pre4act1) row[3:0]      <=  sa[3:0];
//   if (pre4act1) row[1:0]      <=  sa[1:0];

   if (pre5act2) fullpage <= left[5];
   //if (pre5act2) m16_r    <= m16 && !left[5];

   pre4rd   <= pre4act2 || (pre5rd && (!fullpage || (left[5:0]!=0)));
   pre4rd_else <=          (pre5rd && (!fullpage || (left[5:0]!=0)));
//   pre4pre  <= (left[5:0]==0) && (fullpage?pre5rd:pre4rd); 
   //pre4pre_no_m16 <= (left[5:0]==0) && (fullpage?pre5rd:pre4rd); 
   //pre4pre  <= m16_r? pre4pre_no_m16:((left[5:0]==0) && (fullpage?pre5rd:pre4rd)); // extra delay for 16-bit mode (FPN)
   pre4pre  <= (left[5:0]==0) & (fullpage?pre5rd:pre4rd);
	if      (pre4act1)    pre3sda[12:0] <= sa[21:9];
   else if (pre4act2)    pre3sda[12:0] <= pre3sda[12:0]+1;
   else if (pre4rd1)     pre3sda[12:0] <= {1'b0,sa[8:2],5'h0};
   else if (pre4rd_else) 
		if (left[3:0]==len[4:1]) pre3sda[12:0] <= {1'b0,sa[8:2],5'h0};
		else                        pre3sda[12:0] <= {pre3sda[12:3]+10'b1,3'h0};
   else if (pre4pre)     pre3sda[12:0] <= {pre3sda[12:11],1'b1,pre3sda[9:0]}; //set A10, others - don't care

   if      (pre4act1)    pre3sdb[0] <= sa[0];

   if      (pre4act1)                                                     pre3sdb[1] <= sa[0] ^ sa[1];
   else if (pre4act2 | pre4rd1 | (pre4rd_else & (left[3:0]==len[4:1]))) pre3sdb[1] <= ~pre3sdb[1];

   if    (pre4act1) left[5:0] <= {~(|len[4:0]), len[4:0]};
   else if (pre4rd) left[5:0] <= left[5:0] - 1;

   predrun       <= en && !predrun_off    && (predrun_on    || predrun);
   dqs_re3    <= en && !dqs_re3_off && (dqs_re3_on || dqs_re3);
   inuse3     <= en && !pre3pre && (inuse3 || pre4act1);
//   prenext    <=  (left[5:0]==6'h1) && (fullpage? pre6rd:(pre5rd || pre4act2));
   //prenext    <=  (left[5:0]==6'h0) && (fullpage? pre6rd:(m16_r?(pre4rd || pre4act2):(pre5rd || pre4act2)));
   prenext    <=  (left[5:0]==6'h0) && (fullpage? pre6rd:(pre5rd | pre4act2));
	pre4pre1   <= pre4pre;
	pre4pre2   <= pre4pre1;
	pre4pre3   <= pre4pre2;
	pre3pre    <= pre4pre3;
   pre3rd     <= pre4rd;

  end

endmodule



