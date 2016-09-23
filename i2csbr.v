/*
** -----------------------------------------------------------------------------**
** i2csbr.v
**
** Slave 2-wire serial device and a passthrough bridge
** 
** Active pullup of SDA line
**
** Copyright (C) 2007 Elphel, Inc.
**
** -----------------------------------------------------------------------------**
**  This file is part of x347
**  X347 is free software - hardware description language (HDL) code.
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
**  $Log: i2csbr.v,v $
**  Revision 1.4  2010/05/14 18:48:35  dzhimiev
**  1. added hacts shifts for buffered channels
**  2. set fixed SDRAM spaces
**
**  Revision 1.1  2009/06/11 17:39:00  dzhimiev
**  new initial version
**  1. simulation and board test availability
**
**  Revision 1.1  2008/12/08 09:07:57  dzhimiev
**  1. set up of the data path for the transform
**  2. 2 read and 2 write channels
**  3. in snapshot mode - 3 frames output sequence -
**    1st - direct
**    2nd - stored 'direct' from the 1st buffer
**    3rd - stored '1st buffer' from the 2nd buffer
**
**  Revision 1.1.1.1  2007/08/17 11:52:28  elphel
**  This is a fresh tree based on elphel353-2.10
**
**  Revision 1.6  2007/08/17 11:52:28  spectr_rain
**  switch to GPL3 license
**
**  Revision 1.5  2007/07/20 09:48:14  spectr_rain
**  *** empty log message ***
**
**  Revision 1.1  2007/04/04 04:21:25  elphel
**  added 10359 fpga files
**
**
*/
`timescale 1 ns / 1 ps

module i2csbr (clk,    // global clock (30-150MHz?)
               slave_en, // enable slave bus (may be disabled while fast/non-standard communications with master)
               scl,    // SCL from master
               scl_en, // enable sclk output to external slave device
               scls,   // SCL to external slave device
               sdami,  // SDA from master input
               sdamo,  // SDA to master output
               sdamen, // SDA to master output enable
               sdasi,  // SDA from external slave input
               sdaso,  // SDA to external slave output
               sdasen, // SDA to external slave output enable
               sr,     // 16-bit shift register output (skipped ACKN)
               slava_ackn, // will ackn. (using 7 MSBs from sr)
               wra_stb,    // single-cycle strobe when sr contains register+slave address to read/write
               wra_ackn,   // acknowledge address (active high input)
               wrd_stb,    // single-cycle strobe when sr[7:0] contains byte to write (st[16:9] may have previous/MS byte)
               wrd_ackn,   // acknowledge for the byte/word written
               rd_req,     // request read byte (ackn from master), strobe after SCL goes high
               rdat,       // 8-bit data to send to master
               rd_stb,     // rdat is updated
               start,      // start strobe (just in case)
               stop);      // stop strobe (some commands will be triggered now (i.e. connecting/disconnecting bridge to external slave)
               
  input         clk;
  input         slave_en, scl,sdami, sdasi;
  output        scl_en, scls, sdamo, sdamen, sdaso, sdasen;
  output [15:0] sr;
  input         slava_ackn;
  output        wra_stb;
  input         wra_ackn;
  output        wrd_stb;
  input         wrd_ackn;
  output        rd_req;
  input  [ 7:0] rdat;
  input         rd_stb;
  output        start;
  output        stop;
  reg    [2:0]  sclr;  // registered scl
  reg    [2:0]  sdamr; // registered sdami
  reg    [2:0]  sdasr; // registered sdasi
  
  reg    sclf;  // filtered scl
  reg    sdamf; // filtered sdami
  reg    sdasf; // filtered sdasi

  reg    sclp;  // previous scl
  reg    sdamp; // previous sdami
  reg    sdasp; // previous sdasi
  reg    start, start_d, stop;
  wire   i2c_active; 
  reg    i2c_active_d; //delayed by 1 clock;
  reg  [15:0] sr;
  reg   [3:0] bcntr;
  reg         this_sa;   // selected this slave
  reg         this_ackn; // acknowledge slave_a/address/write_data
//  reg         wr;  // i2c write mode, register address/data, including trailing ACKN bit
// i2c if active can be reading slave address, wra, wrd or rd
// next registers (state of i2c) change on the rising edge of 9-th SCL
  reg         wrs; // i2c write slave address - including trailing ACKN bit
  reg         wra; // i2c write register address including trailing ACKN bit
  reg         wrd; // i2c write data including trailing ACKN bit
  reg         rd;  // i2c read mode including trailing ACKN bit
// these registers switch on the falling edge of SCL delaying wrs, wra, wrd,rd by the duration of SCL=1  
  reg         wrs_d, wra_d, wrd_d, rd_d, wr_d; // wr_d= wrs_d | wra_d | wrd_d
  reg         acknw; // acknowledge window (from falling SCL to falling SCL)
  reg         wra_stb;
  reg         wrd_stb;
  reg         rd_req;
  wire        rd_stb;
  reg   [7:0] rd_sr;   // shift register for read data


  wire   scl_rise= sclf & ~sclp;
  wire   scl_fall=~sclf &  sclp;
  
  reg         slave_en_sync; //slave_en synchronized to i2c bus activity (will not turn on/off in the middle of the i2c active cycle
//  reg         scl_en;
  wire        sdamo;
  wire        sdamen;
  wire        sdaso;
  wire        sdasen;
  wire        scl_en;
  wire        scls;
  wire        int_slave_do;
  
  wire        from_master; // SDA from master
  wire        from_int;    // SDA - from internal slave
  wire        from_ext;    // SDA - from externa slave
  
//  assign from_master= acknw? rd_d: wr_d;
  assign from_master= acknw? rd_d: ~rd_d;
  assign from_int=    this_sa & (acknw? wr_d: rd_d);
  assign from_ext=    slave_en_sync & ~this_sa & (acknw? wr_d: rd_d);

  assign int_slave_do=acknw ? ~this_ackn : rd_sr[7] ;
  

// can use any of the 2 below (always enable or use sclf)
  assign scls= sclf | ~slave_en_sync;                
  assign scl_en= slave_en_sync;

// let external slave see what internal is sending to the master
  assign  sdaso= from_master ? sdamf : int_slave_do ;
  assign  sdasen=slave_en_sync &
                 ~from_ext &
                 (~sdaso | ~sclp); // active pullup while SCL=0, open-drain when SCL=1 (using sclp so active enabling will not lead the state
                 
  assign  sdamo = from_int ? int_slave_do : (from_ext ? sdasf:1'b1);
  
  assign  sdamen = ~from_master & (~sdamo | ~sclp) ;
                 
  
// using FD instance to make sure it will be reset at startup both in simulation and hardware  
 FD i_i2c_active (.Q(i2c_active),.C(clk),.D(start || (i2c_active && !stop)));
  
  always @ (posedge clk) begin
    sclr[2:0]   <= {scl,sclr[2:1]};
    sdamr[2:0] <= {sdami,sdamr[2:1]};
    sdasr[2:0] <= {sdasi,sdasr[2:1]};
    sclf   <= sclf?  (sclr [1:0] != 2'h0) : (sclr [1:0] == 2'h3);
    sdamf  <= sdamf? (sdamr[1:0] != 2'h0) : (sdamr[1:0] == 2'h3);
    sdasf  <= sdasf? (sdasr[1:0] != 2'h0) : (sdasr[1:0] == 2'h3);
    sclp  <= sclf;
    sdamp <= sdamf;
    sdasp <= sdasf;
    start <= sclp & sclf &  sdamp & ~sdamf; // if sda and scl switch at the same time - no start/stop will be generated
    stop  <= sclp & sclf & ~sdamp &  sdamf;
    start_d <= start;
    
    if   (scl_rise && !bcntr[3])  sr[15:0] <={sr[14:0],sdamf};
    
    if   (!i2c_active || start ) bcntr[3:0] <= 4'h0;
    else if (scl_rise)           bcntr[3:0] <= bcntr[3]? 4'h0 : (bcntr[3:0]+1);

    i2c_active_d <= i2c_active;
    if      (start || start_d)              wrs <= 1'b1;
    else if (!i2c_active ||
             (scl_rise && bcntr[3]))        wrs <= 1'b0;
             
    if      (!i2c_active)                   this_sa <= 1'b0;
    else if (scl_fall && bcntr[3] && wrs)   this_sa <= slava_ackn; 

    if      (!i2c_active || start)          wra <=  1'b0;
    else if (scl_rise && bcntr[3] )         wra <= ~sr[0] & wrs & (this_sa | ~sdasf); // one of the slaves should respond
    
    if      (!i2c_active || start)          rd  <=  1'b0;
    else if (scl_rise && bcntr[3])          rd <=  rd ? (~sdamf): (sr[0] & wrs & (this_sa | ~sdasf)) ;
    

    if      (!i2c_active || start)          wrd <=  1'b0;
    else if (scl_rise && bcntr[3] )         wrd <= this_sa? ((wra | wrd) & this_ackn):(~sdasf & (wra | wrd));
    

    if      (scl_fall)                      this_ackn <=  bcntr[3] & ((wrs & slava_ackn) |
                                                                      (wra & (this_sa & wra_ackn)) |
                                                                      (wrd & (this_sa & wrd_ackn)));
    if      (!i2c_active)   wrs_d <= 1'b0;
    else if (scl_fall)      wrs_d <= wrs; 
     
    if      (!i2c_active)   wra_d <= 1'b0;
    else if (scl_fall)      wra_d <= wra; 

    if      (!i2c_active)   wrd_d <= 1'b0;
    else if (scl_fall)      wrd_d <= wrd; 

    if      (!i2c_active)   wr_d  <= 1'b0;
    else if (scl_fall)      wr_d  <= wrs | wra | wrd; 
    
    if      (!i2c_active)   rd_d  <= 1'b0;
    else if (scl_fall)      rd_d  <= rd; 

    if      (!i2c_active)   acknw  <= 1'b0;
    else if (scl_fall)      acknw  <= bcntr[3]; 


    wra_stb <= this_sa &&  scl_rise && bcntr[3] && wra; // last cycle of wra - beginning of SCL pulse after ACKN
    wrd_stb <= this_sa &&  scl_rise && bcntr[3] && wrd; // last cycle(s) of wrd - beginning of SCL pulse after ACKN
    
    if      (rd_stb)                  rd_sr[7:0] <= rdat[7:0];
    else if (scl_fall && |bcntr[2:0]) rd_sr[7:0] <= {rd_sr[6:0], 1'b0};
    
    rd_req <= this_sa && scl_rise && bcntr[3] && (rd ? (!sdamf): (wrs && sr[0]));
// make sure slave_en_sync does not turn on/off in the middle of i2c activity    
    if (!i2c_active) slave_en_sync <= slave_en;
  end



endmodule
