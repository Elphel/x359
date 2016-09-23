/*
** -----------------------------------------------------------------------------**
** mcontr_cmd.v
**
** decodes CPU writes to mcontr registers

** Copyright 2004 Elphel, Inc.
**
** -----------------------------------------------------------------------------**
**  This file is part of X333
** 
**  X333 is free software - hardware description language (HDL) code; you can
**  redistribute it and/or modify it under the terms of the GNU General Public License
**  as published by the Free Software Foundation; either version 2 of the License, or
**  (at your option) any later version.
** 
**  X333 is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
** 
**  You should have received a copy of the GNU General Public License
**  along with X333; if not, write to the Free Software
**  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
** -----------------------------------------------------------------------------**
**
*/

`timescale 1 ns / 1 ps

// add some status outputs
module mcontr_cmd(   clk0,           // system clock, mostly negedge (maybe add more clocks for ground bounce reducing?)0
                     mwr,            // @negedge clk0 - write parameters, single-cycle - valid with ma[2:0] - early , mdi valid at mwr and next cycle 
                     ma,             // [2:0] - specifies register to use:
                                     // 0 - command register, bit19 - ch3 read_block, bit 18 - next block, [17:16] - refresh, [15:14] - channel7, ...
                                     // 1 - SDRAM manual commands [17:0]
                                     // 2 - ny[9:0] (d[25:16], nx[9:0] (d[9:0])
                                     // 3 - snb_msbs[9:0], nst[9:0], nsty[4:0], nstx[4:0]
                                     // 4 - channel0 start address [11:0]
                                     // 5 - channel1 start address [11:0]
                                     // 6 - channel2 start address {sync,4'b0,[11:0]}
                                     // 7 - channel3 start address {readahead,write,[15:0]}
                     mdi,            // [31:0] data valid with mwr - CPU data to write parameters (and also - channel3)
// 
                     init_chn,       // [8:0] init channels (8 - refresh)
                     enrq_chn,       // [8:0] enable channels to access SDRAM ( 0 - pause, will not abort SDRAM r/w in progress) 
//                     en_refresh,
                     ch3_next_block,           
                     ch3_read_block,
                     ch3_read_ahead, // if set, ch3 in read mode will try to read 4 pages ahead without additional requests

                     snb_msbs,       // 10 MSBs of the start block address of the SDRAM dedicated to the token buffer
                     //nstx,           // (number of SUPERTILES (128x64 pix) block in a row) -1
                     //nsty,           // (number of SUPERTILES (128x64 pix) rows in a frame) -1
                     nst,            // (number of SUPERTILES (128x64 pix) in a frame) -1
                     //ntile_x,        // [9:0] (number of overlapping 20x20 tiles in a scan line) - 1
                     //ntile_y,        // [9:0] (number of overlapping 20x20 tiles in a column) - 1
										 ch0_x_max,
										 ch0_x_shift,
										 ch0_nx_max,
										 ch0_y_max,
										 ch0_y_shift,
										 ch0_ny_max,
										 ch1_x_max,
										 ch1_x_shift,
										 ch1_nx_max,
										 ch1_y_max,
										 ch1_y_shift,
										 ch1_ny_max,										 
                     ch0_sa,         // [11:0] 12 MSBs of the channel0 start address
                     ch1_sa,         // [11:0] 12 MSBs of the channel0 start address
                     ch2_sa,         // [11:0] 12 MSBs of the channel0 start address
                     ch3_sa,         // [15:0] 16 MSBs of the channel0 start address
                     ch2_sync,       // If "1" - channel 2 will wait for data from channel 0, "0" - run independently
                     ch3_wnr,        // channel3 (CPU PIO) write/not read mode
                     mancmd          // [17:0]

                     );
  input         clk0;
  input         mwr;
  input   [4:0] ma;
  input  [31:0] mdi;
  output  [8:0] init_chn;
  output  [8:0] enrq_chn;
//  output        en_refresh;
  output        ch3_next_block;
  output        ch3_read_block;
  output        ch3_read_ahead;
  output  [9:0] snb_msbs;   // 10 MSBs of the start block address of the SDRAM dedicated to the token buffer
  //output  [4:0] nstx;       // (number of SUPERTILES (128x64 pix) block in a row) -1
  //output  [4:0] nsty;       // (number of SUPERTILES (128x64 pix) rows in a frame) -1
  output  [9:0] nst;        // (number of SUPERTILES (128x64 pix) in a frame) -1

  //output  [9:0] ntile_x;        // [9:0] (number of overlapping 20x20 tiles in a scan line) - 1
  //output  [9:0] ntile_y;        // [9:0] (number of overlapping 20x20 tiles in a column) - 1
  output [11:0] ch0_sa;         // [11:0] 12 MSBs of the channel0 start address
  output [11:0] ch1_sa;         // [11:0] 12 MSBs of the channel0 start address
  output [11:0] ch2_sa;         // [11:0] 12 MSBs of the channel0 start address
  output [15:0] ch3_sa;         // [15:0] 16 MSBs of the channel0 start address
  output        ch2_sync;       // If "1" - channel 2 will wait for data from channel 0, "0" - run independently
  output        ch3_wnr;        // channel3 (CPU PIO) write/not read mode
  output [17:0] mancmd;

	output [7:0] ch0_x_max;
	output [7:0] ch0_x_shift;
	output [7:0] ch0_nx_max;
	output [13:0] ch0_y_max;
	output [7:0] ch0_y_shift;
	output [7:0] ch0_ny_max;
	
	output [7:0] ch1_x_max;
	output [7:0] ch1_x_shift;
	output [7:0] ch1_nx_max;
	output [13:0] ch1_y_max;
	output [7:0] ch1_y_shift;
	output [7:0] ch1_ny_max;

//   reg          en_refresh;
   reg          ch3_next_block;           
   reg          ch3_read_block;
   reg    [9:0] snb_msbs;   // 10 MSBs of the start block address of the SDRAM dedicated to the token buffer
   //reg    [4:0] nstx;       // (number of SUPERTILES (128x64 pix) block in a row) -1
   //reg    [4:0] nsty;       // (number of SUPERTILES (128x64 pix) rows in a frame) -1
   reg    [9:0] nst;        // (number of SUPERTILES (128x64 pix) in a frame) -1
   //reg    [9:0] ntile_x;        // [9:0] (number of overlapping 20x20 tiles in a scan line) - 1
   //reg    [9:0] ntile_y;        // [9:0] (number of overlapping 20x20 tiles in a column) - 1
   reg   [11:0] ch0_sa;         // [11:0] 12 MSBs of the channel0 start address
   reg   [11:0] ch1_sa;         // [11:0] 12 MSBs of the channel0 start address
   reg   [11:0] ch2_sa;         // [11:0] 12 MSBs of the channel0 start address
   reg   [15:0] ch3_sa;         // [15:0] 16 MSBs of the channel0 start address
   reg          ch2_sync;       // If "1" - channel 2 will wait for data from channel 0, "0" - run independently
   reg          ch3_wnr;        // channel3 (CPU PIO) write/not read mode
   reg   [17:0] mancmd;
   reg    [8:0] ninit_chn;
   reg          ch3_read_ahead;
   wire   [8:0] init_chn=~ninit_chn[8:0]; // so will be initialized to all "1"-s on POR
   reg    [8:0] enrq_chn;
/**/
   reg          mwr_cmd;
   reg          mancmd_stb;
   reg          mwr_nxny;
   reg          mwr_tkpars;
   reg          mwr_ch0;
   reg          mwr_ch1;
   reg          mwr_ch2;
   reg          mwr_ch3;
	 
	 reg mwr_ch0x, mwr_ch0y;
	 reg mwr_ch1x, mwr_ch1y;
	 
	reg [7:0] ch0_x_max=7;
	reg [7:0] ch0_x_shift=1; //was8
	reg [7:0] ch0_nx_max=15;  //was3
	reg [13:0] ch0_y_max=3;
	reg [7:0] ch0_y_shift=4;
	reg [7:0] ch0_ny_max=9;
	
	reg [7:0] ch1_x_max=7;
	reg [7:0] ch1_x_shift=1; //was8
	reg [7:0] ch1_nx_max=15;  //was3
	reg [13:0] ch1_y_max=3;
	reg [7:0] ch1_y_shift=4;
	reg [7:0] ch1_ny_max=9;	 
	 
/**/
/*
   wire          mwr_cmd;
   wire         mancmd_stb;
   wire         mwr_nxny;
   wire         mwr_tkpars;
   wire         mwr_ch0;
   wire         mwr_ch1;
   wire         mwr_ch2;
   wire         mwr_ch3;

 assign mwr_cmd    = mwr && (ma[2:0]==3'h0);
 assign mancmd_stb = mwr && (ma[2:0]==3'h1);
 assign mwr_nxny   = mwr && (ma[2:0]==3'h2);
 assign mwr_tkpars = mwr && (ma[2:0]==3'h3);
 assign mwr_ch0    = mwr && (ma[2:0]==3'h4);
 assign mwr_ch1    = mwr && (ma[2:0]==3'h5);
 assign mwr_ch2    = mwr && (ma[2:0]==3'h6);
 assign mwr_ch3    = mwr && (ma[2:0]==3'h7);
*/


   always @ (negedge clk0) begin
/**/
    mwr_cmd    <= mwr && (ma[4:0]==5'h0);
    mancmd_stb <= mwr && (ma[4:0]==5'h1);
    mwr_nxny   <= mwr && (ma[4:0]==5'h2);
    mwr_tkpars <= mwr && (ma[4:0]==5'h3);
    mwr_ch0    <= mwr && (ma[4:0]==5'h4);
    mwr_ch1    <= mwr && (ma[4:0]==5'h5);
    mwr_ch2    <= mwr && (ma[4:0]==5'h6);
    mwr_ch3    <= mwr && (ma[4:0]==5'h7);
		
		mwr_ch0x  <= mwr & (ma[4:0]==5'h0c);
		mwr_ch1x  <= mwr & (ma[4:0]==5'h0d);		
		mwr_ch0y  <= mwr & (ma[4:0]==5'h0e);
		mwr_ch1y  <= mwr & (ma[4:0]==5'h0f);
		
/**/
    mancmd[17:0] <= mancmd_stb?mdi[17:0]:18'h3ffff;
    if (mwr_cmd) begin
     ninit_chn[8:0]<={(mdi[17] | ~mdi[16]),
                      (mdi[15] | ~mdi[14]),(mdi[13] | ~mdi[12]),(mdi[11] | ~mdi[10]),(mdi[ 9] | ~mdi[ 8]),
                      (mdi[ 7] | ~mdi[ 6]),(mdi[ 5] | ~mdi[ 4]),(mdi[ 3] | ~mdi[ 2]),(mdi[ 1] | ~mdi[ 0])} & (ninit_chn[8:0] |
                      {mdi[17],mdi[15],mdi[13],mdi[11],mdi[9],mdi[7],mdi[5],mdi[3],mdi[1]} );
     enrq_chn[8:0] <= (~{mdi[16],mdi[14],mdi[12],mdi[10],mdi[8],mdi[6],mdi[4],mdi[2],mdi[0]}) & 
                       ({mdi[17],mdi[15],mdi[13],mdi[11],mdi[9],mdi[7],mdi[5],mdi[3],mdi[1]} | enrq_chn[8:0]);

    end

     ch3_next_block <= mwr_cmd && mdi[18];           
     ch3_read_block <= mwr_cmd && mdi[19];

//    if (mwr_nxny) begin
//     ntile_x[9:0]  <= mdi[9:0];
//     ntile_y[9:0]  <= mdi[25:16];
//    end
    if (mwr_tkpars) begin
     snb_msbs[9:0]<= mdi[29:20];
     nst[9:0]     <= mdi[19:10];
     //nsty[4:0]    <= mdi[9:5];
     //nstx[4:0]    <= mdi[4:0];
    end
    if (mwr_ch0)  ch0_sa[11:0] <= mdi[11:0];
    if (mwr_ch1)  ch1_sa[11:0] <= mdi[11:0];
    if (mwr_ch2) begin
      ch2_sa[11:0] <= mdi[11:0];
      ch2_sync     <= mdi[16];
    end    
    if (mwr_ch3) begin
      ch3_sa[15:0]   <= mdi[15:0];
      ch3_wnr        <= mdi[16];
      ch3_read_ahead <= mdi[17];
    end    

		if (mwr_ch0x) begin
			ch0_x_max   <= mdi[7:0];
			ch0_x_shift <= mdi[15:8];
			ch0_nx_max  <= mdi[23:16];
		end

		if (mwr_ch0y) begin
			ch0_y_max   <= mdi[29:16];
			ch0_y_shift <= mdi[15:8];
			ch0_ny_max  <= mdi[7:0];
		end
		
		if (mwr_ch1x) begin
			ch1_x_max   <= mdi[7:0];
			ch1_x_shift <= mdi[15:8];
			ch1_nx_max  <= mdi[23:16];
		end		

		if (mwr_ch1y) begin
			ch1_y_max   <= mdi[29:16];
			ch1_y_shift <= mdi[15:8];
			ch1_ny_max  <= mdi[7:0];
		end
		
   end
endmodule



