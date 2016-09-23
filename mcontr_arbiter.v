/*
** -----------------------------------------------------------------------------**
** mcontr_arbiter.v
**
** Performs arbitration of SDRAM accesses between 8 channels and refresh.
** some channels have 2 levels of request priority (rq and rq_urgent)
**
** Copyright 2002-2004 Andrey Filippov
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
module mcontr_arbiter(clk0,          // system clock, mostly negedge (maybe add more clocks for ground bounce reducing?)
                      ch3_wnr,       // channel3 mode: 1 - write, 0 - read
                      init_chn,      // [8:0] - reset busy for selected channels
                      rq,            // [8:0] - low priority request from channels (0..5), 8 - refresh
                      rq_urgent,     // [8:0] - high priority request from channels (0..2, 4..7)
//                      prenext,       //  - 8 cycles ahead of the next start (8- refresh)
                      next,          //  - 7 cycles ahead of the next start (8- refresh)
                      start,         // [8:0] - one-hot start channels
                      start_lnwr,    // start writing line (ch0 and possibly ch3)
                      start_lnrd,    // start reading line (ch1 and possibly ch3)
                      channel,       // [8:0] - one-hot channel select - starts 1 cycle ahead of start (drun can last longer)
                      sddo_sel,      // [1:0] - 0 - chn0, 1 - chn3, 2 - chn4, 3 - chn6
                      rq_busy        // [8:0] per channel - rq | busy
                     );
  input         clk0;
  input         ch3_wnr;
  input   [8:0] init_chn;
  input   [8:0] rq;
  input   [8:0] rq_urgent;
//  input         prenext;
  input         next;
  output  [8:0] start;
  output        start_lnwr;
  output        start_lnrd;
  output  [8:0] channel;
  output  [5:0] sddo_sel;
  output  [8:0] rq_busy;

  reg     [8:0] start=0;
  reg     [8:0] channel=0;

  wire    [8:0] prechannel;
  reg           prestart=0;
  reg           pre2start=0;
  reg     [8:0] busy=0;
  reg     [2:0] cntr=0;
//  wire          want=|(rq[8:0] & (~init_chn[8:0])) || |(rq_urgent[8:0]& (~init_chn[8:0]));
  reg           want=0;
  wire          can= (busy[8:0] == 9'h0);
  reg    [17:0] frosen_rq=0;
  reg           start_lnwr=0;
  reg           start_lnrd=0;
  reg    [5:0]  sddo_sel=0;
  wire          sddo_sel_stb;
  assign        rq_busy[8:0] = rq[8:0] | busy[8:0];

  wire          no_urgent=(frosen_rq[8:0]==9'h0);
  assign prechannel[0] = no_urgent?(frosen_rq[ 9  ] == 1'h1  ):(frosen_rq[ 0  ] == 1'h1 );
  assign prechannel[1] = no_urgent?(frosen_rq[10:9] == 2'h2  ):(frosen_rq[ 1:0] == 2'h2 );
  assign prechannel[2] = no_urgent?(frosen_rq[11:9] == 3'h4  ):(frosen_rq[ 2:0] == 3'h4 );
  assign prechannel[3] = no_urgent?(frosen_rq[12:9] == 4'h8  ):(frosen_rq[ 3:0] == 4'h8 );
  assign prechannel[4] = no_urgent?(frosen_rq[13:9] == 5'h10 ):(frosen_rq[ 4:0] == 5'h10);
  assign prechannel[5] = no_urgent?(frosen_rq[14:9] == 6'h20 ):(frosen_rq[ 5:0] == 6'h20);
  assign prechannel[6] = no_urgent?(frosen_rq[15:9] == 7'h40 ):(frosen_rq[ 6:0] == 7'h40);
  assign prechannel[7] = no_urgent?(frosen_rq[16:9] == 8'h80 ):(frosen_rq[ 7:0] == 8'h80);
  assign prechannel[8] = no_urgent?(frosen_rq[17:9] == 9'h100):(frosen_rq[ 8:0] == 9'h100);
  MSRL16_1 i_sddo_sel_stb (.Q(sddo_sel_stb),   .A(4'h2), .CLK(clk0), .D(prestart));

  always @ (negedge clk0) begin
//   busy[8:0] <= ~init_chn[8:0] & (prestart?prechannel[8:0]:(prenext? 9'h0 : busy[8:0]));
   busy[8:0] <= ~init_chn[8:0] & (prestart?prechannel[8:0]:(next? 9'h0 : busy[8:0]));
   want<=|(rq[8:0] & (~init_chn[8:0])) || |(rq_urgent[8:0]& (~init_chn[8:0]));

   if (pre2start) channel[8:0] <= prechannel[8:0];
   start[8:0] <= prestart?prechannel[8:0]:9'h0;
   start_lnwr <= prestart && (prechannel[0] | prechannel[2] | prechannel[4] | (prechannel[3] &&  ch3_wnr));
   start_lnrd <= prestart && (prechannel[1] | prechannel[5] | (prechannel[3] && !ch3_wnr));

//   if       (!(want && can))  cntr[2:0] <= 3'h3;
   if       (!(want && can))  cntr[2:0] <= 3'h2;
   else  if (cntr[2:0]!=3'h7) cntr[2:0] <= cntr[2:0] -1;

   pre2start <= (cntr[2:0] == 3'h0);
   prestart  <=  pre2start;

   if (!(want && can)) frosen_rq[17:0] <= {(rq[8:0] & (~init_chn[8:0])), (rq_urgent[8:0] & (~init_chn[8:0]))}; 

   if (sddo_sel_stb) sddo_sel[5:0] <= channel[5:0];
  end





  endmodule



