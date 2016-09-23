/*
*! -----------------------------------------------------------------------------**
*! FILE NAME  : mcontr359.v
*! DESCRIPTION: memory controller block
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
*! $Log: mcontr359.v,v $
*! Revision 1.8  2010/05/14 18:48:35  dzhimiev
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
To improve timing all SDRAM conrol signals will be generated 2 cycles ahead of the outputs.
will be registered twice - first where the signals from several controllers will come together,
second - in the I/O FFs

mwr will write parameters, initialize running variables. These variables will be also updated after
being used.

There will be 3 types of write operations:
1 - intensity - write two 32-bit words (for each index) into the same page (open page once)
2 - intensity - write two 32-bit words (for each index) into different pages - different banks, make overlap
3 - color. Write two 32-bit words - each in it's own page

Two types of read operations (may be truncated between planes/frames)
1 - intensity
2 - color
*/

`timescale 1 ns / 1 ps

module mcontr(       clk0,           // system clock, mostly negedge (maybe add more clocks for ground bounce reducing?)
                     rst,
							mwr,            // @negedge clk0 - write parameters, - valid with ma[2:0] 
                     ma,             // [2:0] - specifies register to use:
                                     // 0 - command register, bit19 - ch3 read_block, bit 18 - next block, [17:16] - SDRAM enable/refresh, [15:14] - channel7, ...
                                     // 1 - SDRAM manual commands [17:0]
                                     // 2 - {ny[9:0], 6'b0, nx[9:0]}
                                     // 3 - snb_msbs[9:0], nst[9:0], nsty[4:0], nstx[4:0]
                                     // 4 - channel0 start address [11:0]
                                     // 5 - channel1 start address [11:0]
                                     // 6 - channel2 start address {sync,[11:0]}
                                     // 7 - channel3 start address {write,4'b0,[15:0]}
                     piorw,          // PIO data (channel 3 R/W)
                     wnr,            // write/not read - used with piorw (channel direction - separately - bit of data)
                     mdi,            // [31:0] data valid with mwr - CPU data to write parameters (and also - channel3)
                     mdo,            // [31:0] channel 3 data to cpu
                     rq_busy,        // [8:0] per channel - rq | busy
                     nstx,           // [4:0] (number of SUPERTILES (128x64 pix) in a row) -1
                     nsty,           // [4:0] (number of SUPERTILES (128x64 pix) rows in a frame) -1
                     nst,            // [9:0] (number of SUPERTILES (128x64 pix) in a frame) -1

// interface to SDRAM (through extra registers
                     pre2cmd,        // {ras,cas,we} - should be all ones when not in use (2 cycles ahead of I/O pads)
                     pre2sda,        //[12:0] address to SDRAM - 2 cycles ahead of I/O pads
                     pre2sdb,        //[ 1:0] bank to SDRAM - 2 cycles ahead of I/O pads
                     sddo,           //[31:0] - 1 cycle ahead of "write" command on I/O pads
                     sddi,           //[31:0] -
                     drive_sd2,      // enable data to SDRAM   (2 cycles ahead)
                     drive_dq2,      //  enable DQ outputs (one extra for FF in output buffer)
                     dmask2,         //  now both the same (even number of words written)
                     dqs_re,         // enable read from DQS i/o-s for phase adjustments  (latency 2 from the SDRAM RD command)

// Channel 0 :       read/write of SDRAM data
                     ch0_a,
                     ch0_ibwe,       // input data write enable, advance address
                     ch0_ibdat,      // [15:0] input data (1 or 2 pixels)
                     ch0_next_line,  // advance to the next scan line (and next block RAM page if needed)
                     ch0_last_line,
							ch0_a_out,
							ch0_fill_order,
// Channel 1 :       read/write of SDRAM data
							ch1_a,
                     ch1_obre,       // output read enable, advance address
                     ch1_obdat,      // [15:0] output dtata
                     ch1_next_line,  // advance to the next scan line (and next block RAM page if needed)
							ch1_weo,
							ch1_start,
                     ch1_a_out,  
							ch1_fill_order,
// Channel 2 :       read/write of SDRAM data
                     ch2_a,
                     ch2_ibwe,       // input data write enable, advance address
                     ch2_ibdat,      // [15:0] input data (1 or 2 pixels)
                     ch2_next_line,  // advance to the next scan line (and next block RAM page if needed)
                     ch2_last_line,
							ch2_a_out,
							ch2_fill_order,
// Channel 3 :       read/write of SDRAM data
							ch3_a,
                     ch3_obre,       // output read enable, advance address
                     ch3_obdat,      // [15:0] output dtata
                     ch3_next_line,  // advance to the next scan line (and next block RAM page if needed)
							ch3_weo,
							ch3_start,
                     ch3_a_out,  
							ch3_fill_order,							
// Channel 4 :       read/write of SDRAM data
                     ch4_a,
                     ch4_ibwe,       // input data write enable, advance address
                     ch4_ibdat,      // [15:0] input data (1 or 2 pixels)
                     ch4_next_line,  // advance to the next scan line (and next block RAM page if needed)
                     ch4_last_line,
							ch4_a_out,
							ch4_fill_order,
// Channel 5 :       read/write of SDRAM data
							ch5_a,
                     ch5_obre,       // output read enable, advance address
                     ch5_obdat,      // [15:0] output dtata
                     ch5_next_line,  // advance to the next scan line (and next block RAM page if needed)
							ch5_weo,
							ch5_start,
                     ch5_a_out,  
							ch5_fill_order,							
// Others :
                     en_refresh,      // to see if SDRAM controller is programmed
                     tok_frame_num_wr,// debug - LSB of last frame written by compressor_one
							init_out,
                     ao
										 );
  input         clk0;
  input         rst;
  input         mwr;            // @negedge clk0 - write parameters, - valid with ma[2:0] 
  input  [ 4:0] ma;             // [2:0] - specifies register to use:
                                     // 0 - command register, bit19 - ch3 read_block, bit 18 - next block, [17:16] - SDRAM enable/refresh, [15:14] - channel7, ...
                                     // 1 - SDRAM manual commands [17:0]
                                     // 2 - ny[9:0], nx[9:0]
                                     // 3 - snb_msbs[9:0], nst[9:0], nsty[4:0], nstx[4:0]
                                     // 4 - channel0 start address [11:0]
                                     // 5 - channel1 start address [11:0]
                                     // 6 - channel2 start address {sync,[11:0]}
                                     // 7 - channel3 start address {read_ahead,write,[15:0]}
  input         piorw;          // PIO data (channel 3 R/W)
  input         wnr;            // write/not read - used with piorw (channel direction - separately - bit of data)
  input  [31:0] mdi;            // [31:0] data valid with mwr - CPU data to write parameters (and also - channel3)
  output [31:0] mdo;            // [31:0] channel 3 data to cpu 
  output  [8:0] rq_busy;        // request or busy - per channel
  output [ 4:0] nstx;
  output [ 4:0] nsty;
  output [ 9:0] nst;

// interface to SDRAM (through extra registers
  output [ 2:0] pre2cmd;        // {ras,cas,we} - should be all ones when not in use (2 cycles ahead of I/O pads)
  output [12:0] pre2sda;        //[12:0] address to SDRAM - 2 cycles ahead of I/O pads
  output [ 1:0] pre2sdb;        //[ 1:0] bank to SDRAM - 2 cycles ahead of I/O pads
  output [31:0] sddo;           //[31:0] - 1 cycle ahead of "write" command on I/O pads
  input  [31:0] sddi;           //[31:0] -
  output        drive_sd2;      // enable data to SDRAM   (2 cycles ahead)
  output        drive_dq2;      //  enable DQ outputs (one extra for FF in output buffer)
  output        dmask2;         // [1:0] - now both the same (even number of words written)
  output        dqs_re;         // enable read from DQS i/o-s for phase adjustments  (latency 2 from the SDRAM RD command)
//  output        inuse2;         // SDRAM is used by this module (sync to pre2cmd, etc)
// Channel 0
  input	[10:0]	 ch0_a;
  input         ch0_ibwe;       // input data write enable, advance address
  input  [15:0] ch0_ibdat;      // [15:0] input data (1 or 2 pixels)
  input         ch0_next_line;  // advance to the next scan line (and next block RAM page if needed)
  input         ch0_last_line;
  output [21:0] ch0_a_out;
  input         ch0_fill_order;
// Channel 1
  input	[11:0] ch1_a;
  input         ch1_obre;       // output read enable, advance address
  output [15:0] ch1_obdat;      // [15:0] output dtata
  input         ch1_next_line;  // advance to the next scan line (and next block RAM page if needed)
  output        ch1_weo;
  input         ch1_start;
  output [21:0] ch1_a_out;
  input         ch1_fill_order;
// Channel 2
  input	[10:0]	 ch2_a;
  input         ch2_ibwe;       // input data write enable, advance address
  input  [15:0] ch2_ibdat;      // [15:0] input data (1 or 2 pixels)
  input         ch2_next_line;  // advance to the next scan line (and next block RAM page if needed)
  input         ch2_last_line;
  output [21:0] ch2_a_out;
  input         ch2_fill_order;
// Channel 3
  input	[11:0] ch3_a;
  input         ch3_obre;       // output read enable, advance address
  output [15:0] ch3_obdat;      // [15:0] output dtata
  input         ch3_next_line;  // advance to the next scan line (and next block RAM page if needed)
  output        ch3_weo;
  input         ch3_start;
  output [21:0] ch3_a_out;
  input         ch3_fill_order;
// Channel 4
  input	[10:0]	 ch4_a;
  input         ch4_ibwe;       // input data write enable, advance address
  input  [15:0] ch4_ibdat;      // [15:0] input data (1 or 2 pixels)
  input         ch4_next_line;  // advance to the next scan line (and next block RAM page if needed)
  input         ch4_last_line;
  output [21:0] ch4_a_out;
  input         ch4_fill_order;
// Channel 5
  input	[11:0] ch5_a;
  input         ch5_obre;       // output read enable, advance address
  output [15:0] ch5_obdat;      // [15:0] output dtata
  input         ch5_next_line;  // advance to the next scan line (and next block RAM page if needed)
  output        ch5_weo;
  input         ch5_start;
  output [21:0] ch5_a_out;
  input         ch5_fill_order;
  
  output        en_refresh;
  output        tok_frame_num_wr;
  output [10:0] ao;
  output [8:0] init_out;

  wire ch0_next_line;
  wire ch0_next_line_clone=ch0_next_line;
  wire   [ 8:0] init_chn;
  wire   [ 8:0] enrq_chn;
  wire          en_refresh;
  wire          ch3_next_block;
  wire          ch3_read_block;
  wire   [ 9:0] snb_msbs;
  wire   [ 4:0] nstx;
  wire   [ 4:0] nsty;
  wire   [ 9:0] nst;
  wire   [ 9:0] ntile_x;
  wire   [ 9:0] ntile_y;
  wire   [11:0] ch0_sa;
  wire   [11:0] ch1_sa;
  wire   [11:0] ch2_sa;
  wire   [15:0] ch3_sa;
  wire          ch2_sync;
  wire          ch3_wnr;

	
  wire 	[10:0] ch0_a;
  wire	[11:0] ch1_a;
  wire   [14:0] ch0_line_number;
  wire   [ 8:0] start_chn;
  wire   [ 8:0] channel;       // 1-hot current channel (may switch before drun?) 
  wire   [ 8:0] rq_chn;        // not all bits used
  wire   [ 8:0] rq_urgent_chn; // not all bits used
  
  assign rq_urgent_chn[7:6]=0;

  wire   [21:0] chn0_sa;
  wire   [ 4:0] chn0_len;
  wire   [21:0] chn1_sa;
  wire   [ 4:0] chn1_len;
  wire   [21:0] chn2_sa;
  wire   [ 4:0] chn2_len;
  wire   [21:0] chn3_sa;  
  wire   [ 4:0] chn3_len;
  wire   [21:0] chn4_sa;
  wire   [ 4:0] chn4_len;
  wire   [21:0] chn5_sa;  
  wire   [ 4:0] chn5_len;

  wire          ch3_wnr_current;
  wire          ch3_read_ahead;
  wire          start_lnwr, start_lnrd;
  wire          pre3refr;

  wire          predrun_lnwr, predrun_lnrd, predrun_t20x20;// predrun_wpf, predrun_rpf, predrun_tw, predrun_tr;
  wire          prenext_lnwr, prenext_lnrd, prenext_t20x20, prenext_wpf, prenext_rpf, prenext_tw, prenext_tr, prenext_refr;
  wire          prenext;
  wire          pre3act_lnwr, pre3act_lnrd, pre3act_t20x20, pre3act_wpf, pre3act_rpf, pre3act_tw, pre3act_tr;
  wire          pre3pre_lnwr, pre3pre_lnrd, pre3pre_t20x20, pre3pre_wpf, pre3pre_rpf, pre3pre_tw, pre3pre_tr;
  wire          pre3wr_lnwr,    pre3wr_wpf,     pre3wr_tw;
  wire          drive_sd3_lnwr, drive_sd3_wpf,  drive_sd3_tw;
  wire          drive_dq3_lnwr, drive_dq3_wpf,  drive_dq3_tw;
  wire          dmask3_lnwr,    dmask3_wpf,     dmask3_tw;
  wire          pre3rd_lnrd,    pre3rd_t20x20,  pre3rd_rpf,  pre3rd_tr;
  wire          dqs_re3_lnrd,   dqs_re3_t20x20, dqs_re3_rpf, dqs_re3_tr;
  wire          inuse3_lnwr,  inuse3_lnrd,  inuse3_t20x20,  inuse3_wpf,  inuse3_rpf,  inuse3_tw,  inuse3_tr, inuse3_refr;

  wire   [12:0] pre3sda_lnwr;
  wire   [12:0] pre3sda_lnrd;
  wire   [12:0] pre3sda_t20x20;
  wire   [12:0] pre3sda_wpf;
  wire   [12:0] pre3sda_rpf;
  wire   [12:0] pre3sda_tw;

  wire   [12:0] pre3sda_tr;

  wire   [ 1:0] pre3sdb_lnwr;
  wire   [ 1:0] pre3sdb_lnrd;
  wire   [ 1:0] pre3sdb_t20x20;
  wire   [ 1:0] pre3sdb_wpf;
  wire   [ 1:0] pre3sdb_rpf;
  wire   [ 1:0] pre3sdb_tw;

  
  wire   [ 1:0] pre3sdb_tr;

  wire   [31:0] sddo_chn0;
  wire   [31:0] sddo_chn2;
  wire   [31:0] sddo_chn4;
  wire   [31:0] sddo_wpf;
  wire   [31:0] sddo_tw;
  wire          used_4_sb; // used group of 4 superblocks from Block RAM buffer (may be overwritten)

  wire          tok_rd_dav;

  wire  [ 9:0]  obadr;
  wire  [15:0]  obdat;
  wire          obre;

  wire  [10:0]  ibadr;
  wire  [ 7:0]  ibdat;
  wire          ibwe;

  wire  [15:0]  compr_tk_data;
  wire          compr_tk_data_we;

  wire          pre3act;
  wire          pre3rd;
  wire          pre3wr;
  wire          pre3pre;

  reg           next;
//reg           inuse2;
  reg   [12:0]  pre2sda;
  reg   [ 1:0]  pre2sdb;
  reg   [31:0]  sddo;
  reg           drive_sd2;
  reg           drive_dq2;
  reg           dmask2;
  reg           dqs_re;
  wire  [ 2:0]  pre2cmd;
  wire  [17:0]  mancmd;
  wire  [ 5:0]  sddo_sel;
  wire          init_lnwr;
  wire          init_lnrd;
  wire          tok_frame_written;
  assign en_refresh=enrq_chn[8];

  reg           tok_frame_num_wr;
  wire          tok_frame_writtens;
 
	wire [7:0] ch0_x_max;
	wire [7:0] ch0_x_shift;
	wire [7:0] ch0_nx_max;
	wire [13:0] ch0_y_max;
	wire [7:0] ch0_y_shift;
	wire [7:0] ch0_ny_max;
	
	wire [7:0] ch1_x_max;
	wire [7:0] ch1_x_shift;
	wire [7:0] ch1_nx_max;
	wire [13:0] ch1_y_max;
	wire [7:0] ch1_y_shift;
	wire [7:0] ch1_ny_max;	

	wire [21:0] ch0_a_out=chn0_sa;
	wire [21:0] ch1_a_out=chn1_sa;
	wire [21:0] ch2_a_out=chn2_sa;
	wire [21:0] ch3_a_out=chn3_sa;

  reg sddo_chn0_block=0;  
  always @ (negedge clk0) begin
    if      (ch0_last_line) sddo_chn0_block <= 0;//1;
	 else if (ch0_next_line) sddo_chn0_block <= 0;
  end

  reg sddo_chn2_block=0;  
  always @ (negedge clk0) begin
    if      (ch2_last_line) sddo_chn2_block <= 0;//1;
	 else if (ch2_next_line) sddo_chn2_block <= 0;
  end
  
   always @ (negedge clk0) begin
    if      (init_chn[6])       tok_frame_num_wr <= 1'h0; 
    else if (tok_frame_written) tok_frame_num_wr <= tok_frame_num_wr + 1;        
   end

  assign init_lnwr= (init_chn[0] & init_chn[2] & init_chn[4])|(init_chn[0] & channel[0])|(init_chn[2] & channel[2])|(init_chn[4] & channel[4]);
  assign init_lnrd= (init_chn[1] & init_chn[3] & init_chn[5])|(init_chn[1] & channel[1])|(init_chn[3] & channel[3])|(init_chn[5] & channel[5]);

  assign   prenext = (!init_lnwr  && prenext_lnwr) || (!init_lnrd && prenext_lnrd)  || 
                      prenext_refr;

  assign   pre3act = pre3act_lnwr | pre3act_lnrd;
  assign   pre3rd  = pre3rd_lnrd;
  assign   pre3wr  = pre3wr_lnwr;
  assign   pre3pre = pre3pre_lnwr | pre3pre_lnrd;
	
  //assign   rq_chn[2]= 1'b0;
  //assign   rq_chn[3]= 1'b0;
  //assign   rq_chn[4]= 1'b0;
  //assign   rq_chn[5]= 1'b0;
  assign   rq_chn[6]= 1'b0;
  assign   rq_chn[7]= 1'b0;
  //assign   rq_urgent_chn[3]= 1'b0;
  //assign   rq_urgent_chn[2]= 1'b0;

  
  always @ (negedge clk0) begin
   next <= prenext;

    pre2sda[12:0] <=  ({13{~inuse3_lnwr  }} | pre3sda_lnwr[12:0]) &
                      ({13{~inuse3_lnrd  }} | pre3sda_lnrd[12:0]) & mancmd[12:0];

    pre2sdb[1:0]  <=  ({ 2{~inuse3_lnwr  }} | pre3sdb_lnwr [1:0] ) &
                      ({ 2{~inuse3_lnrd  }} | pre3sdb_lnrd [1:0] ) & mancmd[14:13];

    case (sddo_sel)
      6'h01: sddo[31:0]  <= (sddo_chn0_block)?32'hffffffff:sddo_chn0[31:0];
      6'h02: sddo[31:0]  <= (sddo_chn0_block)?32'hffffffff:sddo_chn0[31:0];
      6'h03: sddo[31:0]  <= (sddo_chn2_block)?32'hffffffff:sddo_chn2[31:0];
      6'h04: sddo[31:0]  <= (sddo_chn2_block)?32'hffffffff:sddo_chn2[31:0]; //token write
      6'h10: sddo[31:0]  <= (sddo_chn2_block)?32'hffffffff:sddo_chn4[31:0];
      6'h20: sddo[31:0]  <= (sddo_chn2_block)?32'hffffffff:sddo_chn4[31:0]; //token write		
    endcase
    drive_sd2     <= (inuse3_lnwr && drive_sd3_lnwr);
    drive_dq2     <= (inuse3_lnwr && drive_dq3_lnwr);
    dmask2        <= (inuse3_lnwr && dmask3_lnwr);
// inuse is too early for dqs_re (3 cycles?)
//    dqs_re        <= (inuse3_lnrd && dqs_re3_lnrd)   || (inuse3_tr && dqs_re3_tr)   || (inuse3_rpf && dqs_re3_rpf) || (inuse3_rpf && dqs_re3_t20x20);
    dqs_re        <= dqs_re3_lnrd;

  end

                                         
// Use FF for cas, ras, we for correct simulation

  FD_1 i_pre2cmd_0	(.D( ~(pre3wr  | pre3pre )  &          mancmd[15]), .C(clk0),.Q(pre2cmd[0]));	//WE
  FD_1 i_pre2cmd_1	(.D( ~(pre3rd  | pre3wr  | pre3refr) & mancmd[16]), .C(clk0),.Q(pre2cmd[1]));	//CAS
  FD_1 i_pre2cmd_2	(.D( ~(pre3act | pre3pre | pre3refr) & mancmd[17]), .C(clk0),.Q(pre2cmd[2]));	//RAS
//synthesis translate_off
 defparam i_pre2cmd_0.INIT = 1'b1;
 defparam i_pre2cmd_1.INIT = 1'b1;
 defparam i_pre2cmd_2.INIT = 1'b1;
//synthesis translate_on
//synthesis attribute INIT of i_pre2cmd_0  is "1" 
//synthesis attribute INIT of i_pre2cmd_1  is "1" 
//synthesis attribute INIT of i_pre2cmd_2  is "1" 


mcontr_cmd i_mcontr_cmd(.clk0(clk0),                     // system clock, mostly negedge (maybe add more clocks for ground bounce reducing?)0
                        .mwr(mwr),                       // @negedge clk0 - write parameters, single-cycle - valid with ma[2:0] - early , mdi valid at mwr and next cycle 
                        .ma(ma[4:0]),                    // [2:0] - specifies register to use:
                                                         // 0 - command register, bit19 - ch3 read_block, bit 18 - next block, [17:16] - refresh, [15:14] - channel7, ...
                                                         // 1 - SDRAM manual commands [17:0]
                                                         // 2 - ny[9:0] (d[25:16], nx[9:0] (d[9:0])
                                                         // 3 - snb_msbs[9:0], nst[9:0], nsty[4:0], nstx[4:0]
                                                         // 4 - channel0 start address [11:0]
                                                         // 5 - channel1 start address [11:0]
                                                         // 6 - channel2 start address {sync,4'b0,[11:0]}
                                                         // 7 - channel3 start address {readahead,write,[15:0]}
                        .mdi(mdi[31:0]),                 // [31:0] data valid with mwr - CPU data to write parameters (and also - channel3)
                        .init_chn(init_chn[8:0]),        // [8:0] init channels
                        .enrq_chn(enrq_chn[8:0]),        // [8:0] enable channels to access SDRAM ( 0 - pause, will not abort SDRAM r/w in progress) 
                        .ch3_next_block(ch3_next_block),           
                        .ch3_read_block(ch3_read_block),
                        .ch3_read_ahead(ch3_read_ahead), // if set, ch3 in read mode will try to read 4 pages ahead without additional requests
                        .snb_msbs(snb_msbs[9:0]),        // 10 MSBs of the start block address of the SDRAM dedicated to the token buffer
                        //.nstx(nstx[4:0]),                // (number of SUPERTILES (128x64 pix) block in a row) -1
                        //.nsty(nsty[4:0]),                // (number of SUPERTILES (128x64 pix) rows in a frame) -1
                        //.nst(nst[9:0]),                  // (number of SUPERTILES (128x64 pix) in a frame) -1
                        //.ntile_x(ntile_x[9:0]),          // [9:0] (number of overlapping 20x20 tiles in a scan line) - 1
                        //.ntile_y(ntile_y[9:0]),          // [9:0] (number of overlapping 20x20 tiles in a column) - 1
												.ch0_x_max(ch0_x_max),
												.ch0_x_shift(ch0_x_shift),
												.ch0_nx_max(ch0_nx_max),
												.ch0_y_max(ch0_y_max),
												.ch0_y_shift(ch0_y_shift),
												.ch0_ny_max(ch0_ny_max),
												.ch1_x_max(ch1_x_max),
												.ch1_x_shift(ch1_x_shift),
												.ch1_nx_max(ch1_nx_max),
												.ch1_y_max(ch1_y_max),
												.ch1_y_shift(ch1_y_shift),
												.ch1_ny_max(ch1_ny_max),
                        .ch0_sa(ch0_sa[11:0]),           // [11:0] 12 MSBs of the channel0 start address
                        .ch1_sa(ch1_sa[11:0]),           // [11:0] 12 MSBs of the channel0 start address
                        .ch2_sa(ch2_sa[11:0]),           // [11:0] 12 MSBs of the channel0 start address
                        .ch3_sa(ch3_sa[15:0]),           // [15:0] 16 MSBs of the channel0 start address
                        .ch2_sync(ch2_sync),             // If "1" - channel 2 will wait for data from channel 0, "0" - run independently
                        .ch3_wnr(ch3_wnr),                // channel3 (CPU PIO) write/not read mode
                        .mancmd(mancmd)         // [17:0]

                       );

wire [8:0] init_out=init_chn[8:0];

mcontr_arbiter i_mcontr_arbiter(.clk0(clk0),                    // system clock, mostly negedge (maybe add more clocks for ground bounce reducing?)
                                .ch3_wnr(0),      // channel3 mode: 1 - write, 0 - read
                                .init_chn(init_chn[8:0]),       // [8:0] - reset busy for selected channels
                                .rq(rq_chn[8:0]),               // [8:0] - low priority request from channels (0..5), 8 - refresh
                                .rq_urgent(rq_urgent_chn[8:0]), // [7:0] - high priority request from channels (0..2, 4..7)
                                .next(next),                    //  - 7 cycles ahead of the next start (8- refresh)
                                .start(start_chn[8:0]),         // [8:0] - one-hot start channels
                                .start_lnwr(start_lnwr),        // start writing line (ch0 and possibly ch3)
                                .start_lnrd(start_lnrd),        // start reading line (ch1 and possibly ch3)
                                .channel(channel[8:0]),         // [8:0] - one-hot channel select - starts 1 cycle ahead of start (drun can last longer)
                                .sddo_sel(sddo_sel[5:0]),       // [1:0] - 0 - chn0, 1 - chn3, 2 - chn4, 3 - chn6
                                .rq_busy(rq_busy[8:0])          // [8:0] per channel - rq | busy
                                );

mcontr_refresh i_mcontr_refresh(.clk0(clk0),
                                .enrq(enrq_chn[8]),
                                .init(init_chn[8]),
                                .start(start_chn[8]),
                                .rq(rq_chn[8]),
                                .rq_urgent(rq_urgent_chn[8]),
                                .prenext(prenext_refr),
// interface to SDRAM (through extra registers
                                .pre3refr(pre3refr),  // precharge command (3 ahead)
                                .inuse3(inuse3_refr)    // SDRAm in use by this channel (sync with pre3***
							           );

reg [5:0] sddo_sel_d=0;
reg [5:0] sddo_sel_dd=0;	
	
always @(negedge clk0)
begin
  sddo_sel_d[5:0]  <= sddo_sel[5:0];
  sddo_sel_dd[5:0] <= sddo_sel_d[5:0];
end
										  
channel_wr i_channel0    (.clk(clk0),                  // SDRAM clock (negedge)
					         .enrq(enrq_chn[0]),            // enable channel requests (does not reset if 0)
                        //.fsa(ch0_sa[11:0]),            // [11:0] frame start address (12 MSBs of SDRAM row address)
                        .fsa(12'h000),
// Using the same values for channels 0..2
					         .init(init_chn[0]|rst),            // resets channel
								
//								.x_max(ch0_x_max),
//								.x_shift(ch0_x_shift),
//								.nx_max(ch0_nx_max),
//								.y_max(ch0_y_max),
//								.y_shift(ch0_y_shift),
//								.ny_max(ch0_ny_max),

								.x_max  (8'h0f),
								.x_shift(8'h02),
								.nx_max (8'h0f),
								.y_max  (16'h1fff),
								.y_shift(8'h10),
								.ny_max (8'hff ),
								
								.fill_order(ch0_fill_order),
// arbiter interface
                        .start(start_chn[0]),
                        .rq(rq_chn[0]),                // request - want at least one access
                        .rq_urgent(rq_urgent_chn[0]),  // need 3 or 4 accesses
//SDRAM controller inteface (mcontr_line512_wr)
                        .sddo(sddo_chn0[31:0]),             //[31:0]
                        .predrun(predrun_lnwr & sddo_sel[0]),
                        .sa(chn0_sa[21:0]),            //[16:0]
                        .len(chn0_len[4:0]),           // access length (0 - full block, 1 - 10x16 bits, 2 - 18*16 bits,... (m16 bit will be 0 for this channel)
// external interface (compressor)
                        .ibwe(ch0_ibwe),               // input data write enable, advance address
								.ch0a(ch0_a[10:0]),
                        .ibdat(ch0_ibdat[15:0]),       // [15:0] input data (1 or 2 pixels)
                        //.next_line(0)
								.next_line(ch0_next_line)
								);
								
channel_rd i_channel1    (.clk(clk0),                  // SDRAM clock (negedge)
					         .enrq(enrq_chn[1]),            // enable channel requests (does not reset if 0)
                        //.fsa(ch1_sa[11:0]),            // [11:0] frame start address (12 MSBs of SDRAM row address)
                        .fsa(12'h000),
								.start2(ch1_start), 
// Using the same values for channels 0..2
					         .init(init_chn[1]|rst),            // resets channel
								
//								.x_max(ch0_x_max),
//								.x_shift(ch0_x_shift),
//								.nx_max(ch0_nx_max),
//								.y_max(ch0_y_max),
//								.y_shift(ch0_y_shift),
//								.ny_max(ch0_ny_max),

								.x_max  (8'h0f),
								.x_shift(8'h02),
								.nx_max (8'h0f),
								.y_max  (16'h1fff),
								.y_shift(8'h10),
								.ny_max (8'hff ),
								
								.fill_order(ch1_fill_order),
// arbiter interface
                        .start(start_chn[1] & !init_chn[1]),
                        .rq(rq_chn[1]),                // request - want at least one access
                        .rq_urgent(rq_urgent_chn[1]),  // need 3 or 4 accesses
                        .sddi(sddi[31:0]),             //[31:0]
								.rq_busy(rq_busy[1]),
//SDRAM controller inteface (mcontr_line512_rd)
                        .predrun(predrun_lnrd & sddo_sel_dd[1]),// & sddo_sel[1]),
                        .sa(chn1_sa[21:0]),            //[16:0]
                        .len(chn1_len[4:0]),           // access length (0 - full block, 1 - 12x16 bits, 2 - 20*16 bits,... (m16 bit will be set for this channel)
// external interface (compressor)
                        .obre(ch1_obre),               // output read enable, advance address
								.ch1a(ch1_a[11:0]),
                        .obdat(ch1_obdat[15:0]),       // [15:0] output dtata
                        .next_line(ch1_next_line),      // advance to the next scan line (and next block RAM page if needed)
                        .ao(ao)
								);
								
assign ch1_weo=predrun_lnrd & sddo_sel_dd[1];								

/////////////
/////////////

channel_wr i_channel2    (.clk(clk0),                  // SDRAM clock (negedge)
					         .enrq(enrq_chn[2]),            // enable channel requests (does not reset if 0)
                        //.fsa(ch0_sa[11:0]),            // [11:0] frame start address (12 MSBs of SDRAM row address)
                        .fsa(12'h400),
// Using the same values for channels 0..2
					         .init(init_chn[2]|rst),            // resets channel
//								.x_max(ch0_x_max),
//								.x_shift(ch0_x_shift),
//								.nx_max(ch0_nx_max),
//								.y_max(ch0_y_max),
//								.y_shift(ch0_y_shift),
//								.ny_max(ch0_ny_max),

								.x_max  (8'h0f),
								.x_shift(8'h02),
								.nx_max (8'h0f),
								.y_max  (16'h1fff),
								.y_shift(8'h10),
								.ny_max (8'hff ),
								
								.fill_order(ch2_fill_order),
// arbiter interface
                        .start(start_chn[2]),
                        .rq(rq_chn[2]),                // request - want at least one access
                        .rq_urgent(rq_urgent_chn[2]),  // need 3 or 4 accesses
//SDRAM controller inteface (mcontr_line512_wr)
                        .sddo(sddo_chn2[31:0]),             //[31:0]
                        .predrun(predrun_lnwr & sddo_sel[2]),
                        .sa(chn2_sa[21:0]),            //[16:0]
                        .len(chn2_len[4:0]),           // access length (0 - full block, 1 - 10x16 bits, 2 - 18*16 bits,... (m16 bit will be 0 for this channel)
// external interface (compressor)
                        .ibwe(ch2_ibwe),               // input data write enable, advance address
								.ch0a(ch2_a[10:0]),
                        .ibdat(ch2_ibdat[15:0]),       // [15:0] input data (1 or 2 pixels)
                        //.next_line(0)
								.next_line(ch2_next_line)
								);
/////////////
/////////////
	
channel_rd i_channel3    (.clk(clk0),                  // SDRAM clock (negedge)
					         .enrq(enrq_chn[3]),            // enable channel requests (does not reset if 0)
                        //.fsa(ch3_sa[11:0]),            // [11:0] frame start address (12 MSBs of SDRAM row address)
                        .fsa(12'h400),
								//.fsa(12'h000), //for testing equal frames
								.start2(ch3_start), 
// Using the same values for channels 0..2
					         .init(init_chn[3]|rst),            // resets channel
								
//								.x_max(ch0_x_max),
//								.x_shift(ch0_x_shift),
//								.nx_max(ch0_nx_max),
//								.y_max(ch0_y_max),
//								.y_shift(ch0_y_shift),
//								.ny_max(ch0_ny_max),

								.x_max  (8'h0f),
								.x_shift(8'h02),
								.nx_max (8'h0f),
								.y_max  (16'h1fff),
								.y_shift(8'h10),
								.ny_max (8'hff ),
								
								.fill_order(ch3_fill_order),
// arbiter interface
                        .start(start_chn[3] & !init_chn[3]),
                        .rq(rq_chn[3]),                // request - want at least one access
                        .rq_urgent(rq_urgent_chn[3]),  // need 3 or 4 accesses
                        .sddi(sddi[31:0]),             //[31:0]
								.rq_busy(rq_busy[3]),
//SDRAM controller inteface (mcontr_line512_rd)
                        .predrun(predrun_lnrd  & sddo_sel_dd[3]),
                        .sa(chn3_sa[21:0]),            //[16:0]
                        .len(chn3_len[4:0]),           // access length (0 - full block, 1 - 12x16 bits, 2 - 20*16 bits,... (m16 bit will be set for this channel)
// external interface (compressor)
                        .obre(ch3_obre),               // output read enable, advance address
								.ch1a(ch3_a[11:0]),
                        .obdat(ch3_obdat[15:0]),       // [15:0] output dtata
                        .next_line(ch3_next_line),      // advance to the next scan line (and next block RAM page if needed)
                        .ao()
								);

assign ch3_weo=predrun_lnrd & sddo_sel_dd[3];

/////////////
/////////////

channel_wr i_channel4    (.clk(clk0),                  // SDRAM clock (negedge)
					         .enrq(enrq_chn[4]),            // enable channel requests (does not reset if 0)
                        //.fsa(ch0_sa[11:0]),            // [11:0] frame start address (12 MSBs of SDRAM row address)
                        .fsa(12'h000),
// Using the same values for channels 0..2
					         .init(init_chn[4]|rst),            // resets channel

//								.x_max(ch0_x_max),
//								.x_shift(ch0_x_shift),
//								.nx_max(ch0_nx_max),
//								.y_max(ch0_y_max),
//								.y_shift(ch0_y_shift),
//								.ny_max(ch0_ny_max),

								.x_max  (8'h0f),
								.x_shift(8'h02),
								.nx_max (8'h0f),
								.y_max  (16'h1fff),
								.y_shift(8'h10),
								.ny_max (8'hff ),
								
								.fill_order(ch4_fill_order),
// arbiter interface
                        .start(start_chn[4]),
                        .rq(rq_chn[4]),                // request - want at least one access
                        .rq_urgent(rq_urgent_chn[4]),  // need 3 or 4 accesses
//SDRAM controller inteface (mcontr_line512_wr)
                        .sddo(sddo_chn4[31:0]),             //[31:0]
                        .predrun(predrun_lnwr & sddo_sel[4]),
                        .sa(chn4_sa[21:0]),            //[16:0]
                        .len(chn4_len[4:0]),           // access length (0 - full block, 1 - 10x16 bits, 2 - 18*16 bits,... (m16 bit will be 0 for this channel)
// external interface (compressor)
                        .ibwe(ch4_ibwe),               // input data write enable, advance address
								.ch0a(ch4_a[10:0]),
                        .ibdat(ch4_ibdat[15:0]),       // [15:0] input data (1 or 2 pixels)
                        //.next_line(0)
								.next_line(ch4_next_line)
								);
/////////////
/////////////
	
channel_rd_short i_channel5    (.clk(clk0),                  // SDRAM clock (negedge)
					         .enrq(enrq_chn[5]),            // enable channel requests (does not reset if 0)
                        //.fsa(ch3_sa[11:0]),            // [11:0] frame start address (12 MSBs of SDRAM row address)
                        .fsa(12'h000),
								//.fsa(12'h000), //for testing equal frames
								.start2(ch5_start), 
// Using the same values for channels 0..2
					         .init(init_chn[5]|rst),            // resets channel

//								.x_max(ch0_x_max),
//								.x_shift(ch0_x_shift),
//								.nx_max(ch0_nx_max),
//								.y_max(ch0_y_max),
//								.y_shift(ch0_y_shift),
//								.ny_max(ch0_ny_max),

								.x_max  (8'h0f),
								.x_shift(8'h02),
								.nx_max (8'h0f),
								.y_max  (16'h1fff),
								.y_shift(8'h10),
								.ny_max (8'hff ),
								
								.fill_order(ch5_fill_order),
// arbiter interface
                        .start(start_chn[5] & !init_chn[5]),
                        .rq(rq_chn[5]),                // request - want at least one access
                        .rq_urgent(rq_urgent_chn[5]),  // need 3 or 4 accesses
                        .sddi(sddi[31:0]),             //[31:0]
								.rq_busy(rq_busy[5]),
//SDRAM controller inteface (mcontr_line512_rd)
                        .predrun(predrun_lnrd  & sddo_sel_dd[5]),
                        .sa(chn5_sa[21:0]),            //[16:0]
                        .len(chn5_len[4:0]),           // access length (0 - full block, 1 - 12x16 bits, 2 - 20*16 bits,... (m16 bit will be set for this channel)
// external interface (compressor)
                        .obre(ch5_obre),               // output read enable, advance address
								.ch1a(ch5_a[11:0]),
                        .obdat(ch5_obdat[15:0]),       // [15:0] output dtata
                        .next_line(ch5_next_line),      // advance to the next scan line (and next block RAM page if needed)
                        .ao()
								);

assign ch5_weo=predrun_lnrd & sddo_sel_dd[5];

								
mcontr_line_wr i_mcontr_line_wr (.mclk0(clk0),                 // system clock, mostly negedge
//                                       .en(!(init_chn[0] && init_chn[3])), // need to reset both channels to reset this module
                                       .en(!init_lnwr),              // need to reset both channels to reset this module
// interface to the output block RAM (x16). Will probably include 12->16 bit conversion here
                                       .predrun(predrun_lnwr),             // 
// interface to SDRAM arbiter
                                       .start(start_lnwr),           // start atomic writing to SDRAM operation (5 cycles ahead of RAS command on the pads)
                                       .sa(channel[4]?chn4_sa[21:0]:(channel[2]?chn2_sa[21:0]:chn0_sa[21:0])),             // [16:0] - 13 MSBs ->RA, 4 LSBs - row in a chunk 
                                       .len(chn0_len[4:0]),            // [ 4:0] - number of 32-byte groups to write, 0 - all 256bytes, for other values - (len*32+8) bytes
                                       .prenext(prenext_lnwr),       // 8 cycles ahead of possible next start_*?
// interface to SDRAM (through extra registers
                                       .pre3pre(pre3pre_lnwr),       // precharge command (3 ahead)
                                       .pre3wr(pre3wr_lnwr),         // read command (3 ahead)
                                       .pre3act(pre3act_lnwr),       // activate command (3ahead)
                                       .pre3sda(pre3sda_lnwr[12:0]), //[12:0] address to SDRAM - 3 cycles ahead of I/O pads
                                       .pre3sdb(pre3sdb_lnwr[1:0]),  //[ 1:0] bank to SDRAM - 3 cycles ahead of I/O pads
                                       .drive_sd3(drive_sd3_lnwr),   // enable data to SDRAM   (2 cycles ahead)
                                       .drive_dq3(drive_dq3_lnwr),   //  enable DQ outputs (one extra for FF in output buffer)
                                       .dmask3(dmask3_lnwr),         // write mask - 1 bit as even number of words written (32-bit pairs)
                                       .inuse3(inuse3_lnwr)          // SDRAm in use by this channel (sync with pre3***
                                       );

mcontr_line_rd i_mcontr_line_rd  (.mclk0(clk0),                // system clock, mostly negedge
//                                        .en(!(init_chn[1] && init_chn[3])),
                                        .en(!init_lnrd),
// interface to the output block RAM (x16). Will probably include 12->16 bit conversion here
                                        .predrun(predrun_lnrd),            // 
// interface to SDRAM arbiter
                                        .start(start_lnrd),          // start atomic reading from SDRAM operation (5 cycles ahead of RAS command on the pads)
                                        .sa(channel[5]?chn5_sa[21:0]:(channel[3]?chn3_sa[21:0]:chn1_sa[21:0])),            // [16:0] - 13 MSBs ->RA, 4 LSBs - row in a chunk 
                                        .len(chn1_len[4:0]),           // [ 4:0] - number of 32-byte groups to read, 0 - all 256bytes, for other values - (len*32+8) bytes
                                        //.m16(channel[3]),      // 16-bit mode (read 2, not 1 extra 32-bit words for partial blocks)

                                        .prenext(prenext_lnrd),      // 8 cycles ahead of possible next start_*?
// interface to SDRAM (through extra registers
                                        .pre3pre(pre3pre_lnrd),      // precharge command (3 ahead)
                                        .pre3rd(pre3rd_lnrd),        // read command (3 ahead)
                                        .pre3act(pre3act_lnrd),      // activate command (3ahead)
                                        .pre3sda(pre3sda_lnrd[12:0]), //[12:0] address to SDRAM - 3 cycles ahead of I/O pads
                                        .pre3sdb(pre3sdb_lnrd[1:0]), //[ 1:0] bank to SDRAM - 3 cycles ahead of I/O pads
                                        .dqs_re3(dqs_re3_lnrd),      // enable read from DQS i/o-s for phase adjustments  (1 ahead of the final)
                                        .inuse3(inuse3_lnrd)         // SDRAm in use by this channel (sync with pre3***
                                        );

endmodule



