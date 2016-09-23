/*
*! -----------------------------------------------------------------------------**
*! FILE NAME  : channel_wr.v
*! DESCRIPTION: channel for write to sdram
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
*! $Log: channel_wr.v,v $
*! Revision 1.5  2010/05/14 18:48:35  dzhimiev
*! 1. added hacts shifts for buffered channels
*! 2. set fixed SDRAM spaces
*!
*! Revision 1.1  2009/06/11 17:39:00  dzhimiev
*! new initial version
*! 1. simulation and board test availability
*!
*! Revision 1.1  2008/12/08 09:09:35  dzhimiev
*! 0. based on channel0.v (theora)
*! 1. set up of the data path for the transform
*! 2. 2 read and 2 write channels
*! 3. in snapshot mode - 3 frames output sequence -
*!   1st - direct
*!   2nd - stored 'direct' from the 1st buffer
*!   3rd - stored '1st buffer' from the 2nd buffer
*!
*/

`timescale 1 ns / 1 ps

module channel_wr(
  clk,	  // SDRAM clock (negedge)
  enrq,	  // enable channel requests (does not reset if 0)
  fsa,     // [11:0] frame start address (12 MSBs of SDRAM row address)
// Using the same values for channels 0..2?
  init,    // resets channel
  x_max,
  x_shift,
  nx_max,
  y_max,
  y_shift,
  ny_max,	
  fill_order,
// arbiter interface
  start,
  rq,       // request - want at least one access
  rq_urgent,// need 3 or 4 accesses
//SDRAM controller inteface (mcontr_line_wr)
  sddo,     //[31:0]
  predrun,
  sa,       //[16:0]
  len,      // access length
// external interface (compressor)
  ibwe,  // input data write enable, advance address
  ch0a,
  ibdat, // [15:0] input data (1 or 2 pixels)
  next_line // advance to the next scan line (and next block RAM page if needed)
);

  input         clk;
  input         enrq;
  input  [11:0] fsa;
  input         init;

  input         start;
  output        rq;
  output        rq_urgent;

  output [31:0] sddo;     //[31:0] - data to SDRAM
  input         predrun;
  output [21:0] sa;
  output  [4:0] len;

  input        ibwe;
  input [10:0] ch0a;
  input [15:0] ibdat;
  input        next_line;
	
	input [7:0]   x_max;
	input [7:0]   x_shift;
	input [7:0]   nx_max;
	input [13:0]   y_max;
	input [7:0]   y_shift;
	input [7:0]   ny_max;	
	input         fill_order;
  
  wire         next_line;
  wire         predrun;

	reg         re;
   reg         done;
	reg	[9:0]	a;

   reg   [4:0] full_pages_in_buffer;
   wire        init0;
   reg         init_pclk; 
   wire        page_prepared0;
   reg         page_prepared;

   reg         rq=0;
	 //wire         rq;
   reg         rq_urgent;
	
   reg  [21:0] sa=0; 
   reg   [7:0] ibwe_cnt=0;
   reg   [4:0] len;

   wire  [10:0] ch0a;
	
//	parameter x_max=7;
//	parameter x_shift=8;
//	parameter nx_max=17;
//	parameter y_max=4;
//	parameter y_shift=4;
//	parameter ny_max=9;

	reg [ 6:0] x=0, nx=0;
	reg [12:0] y=0, ny=0;
	reg [ 7:0] ny_cnt=0;
	reg [ 7:0] nx_cnt=0;
	reg [1:0] bank=0;
	wire next_ipage;
	
  always @ (posedge clk) 
	if (init) init_pclk <= 1;
	else      init_pclk <= 0;

  always @ (negedge clk) 
		if (!init_pclk & next_ipage) page_prepared <= 1;
		else                         page_prepared <= 0;
  
  always @ (posedge clk) begin
    if      (init_pclk | next_ipage)  ibwe_cnt[7:0] <= 0;
    else if (ibwe)                    ibwe_cnt[7:0] <= ibwe_cnt[7:0] + 1;
  end

  //assign next_ipage=((next_line & (ibwe_cnt[7:0]!=8'h0)) | ((ibwe_cnt[7:0]==8'hff) & ibwe));
	//assign next_ipage=((next_line & (ibwe_cnt[7:0]!=8'h0)) | ((ibwe_cnt[7:0]==8'h7f) & ibwe));
	assign next_ipage=0;//((ibwe_cnt[5:0]==63) & ibwe);

  always @ (negedge clk) begin
   if      (init)       
		full_pages_in_buffer <= 5'h0;
	else if (next_line & start) 
		full_pages_in_buffer[4:0] <= full_pages_in_buffer[4:0];
   else if (next_line)  
		full_pages_in_buffer[4:0] <= full_pages_in_buffer[4:0] +1;
   else if (start)  
	   if (full_pages_in_buffer[4:0]!=0) 
			full_pages_in_buffer[4:0] <= full_pages_in_buffer[4:0] -1;
 
   if (init) begin
     sa[21:0]<= {fsa[11:0],10'b0};
     nx <= 0;
     nx_cnt <= 0;
     ny <= 0;
     ny_cnt <= 0; 
	  {y[11:0],bank[1:0]} <= 0;
   end
	else if (start) 
		begin
		
//				if ({y[11:0],bank[1:0]}==y_max[13:0]) begin
//					{y[11:0],bank[1:0]} <= 0;
//					if (nx_cnt==nx_max) begin
//						nx <= 0;
//						nx_cnt <= 0;
//					end   							
//					else begin
//					  nx <= nx + x_shift;
//					  nx_cnt <= nx_cnt + 1;
//					end  
//				end	
//				else {y[11:0],bank[1:0]} <= {y[11:0],bank[1:0]} + 1;

			if (nx_cnt==nx_max) begin
				nx <= 0;
				nx_cnt <= 0;
				if ({y[11:0],bank[1:0]}==y_max[13:0]) {y[11:0],bank[1:0]} <= 0;
				else                                  {y[11:0],bank[1:0]} <= {y[11:0],bank[1:0]} + 1;	
			end   							
			else begin
				nx <= nx + x_shift;
				nx_cnt <= nx_cnt + 1;
			end
				

			//sa[21:10]<= ny[11:0] + y[11:0];
			sa[21] <= sa[21];
			//sa[20:10]<= ny[10:0] + y[10:0];
			sa[20:10]<= {sa[20],y[9:0]};
			sa[9:2]  <= {1'b0,nx[6:0]};
			sa[1:0]  <= bank[1:0];
			
		end
   len[4:0] <= x_max; 
	 
	 if (!start)
		rq <= ((next_line|rq) & enrq & !init);//|(rq & !start);
	 else
	//	rq <= 0;
		rq <= enrq & (full_pages_in_buffer[4:0] != 1);
	 
   rq_urgent <= enrq & (full_pages_in_buffer[3] | (full_pages_in_buffer[3:0]==7)); //>=3

  end

//assign rq=next_line&enrq&!init;

	always @ (negedge clk) begin
	  re <= predrun;
	  done <= re & !predrun;

	  if (init) a[9:0] <= 10'b0;
	  else if (re)     a[9:0] <= a[9:0] + 1;
     //if      (init) a[8:7] <= 2'h0;
     //else if (done) a[8:7] <= a[8:7] + 1;
	end

   reg a_d=0;

	always @ (negedge clk) begin
	  a_d <= a[9];
	end
	
	wire [31:0] sddo_0;	
    RAMB16_S18_S36 i_buf_0 (
      .DOA(),               // Port A 16-bit Data Output   - compressor side
      .DOPA(),              // Port A 2-bit Parity Output
		.ADDRA(ch0a[9:0]),
      .CLKA(clk),          // Port A Clock
      .DIA(ibdat[15:0]),    // Port A 16-bit Data Input
      .DIPA(2'b0),          // Port A 2-bit parity Input
      .ENA(ibwe & !ch0a[10]),           // Port A RAM Enable Input
      .SSRA(1'b0),          // Port A Synchronous Set/Reset Input
      .WEA(1'b1),           // Port A Write Enable Input

      .DOB(sddo_0[31:0]),     // Port B 32-bit Data Output  - SDRAM side
      .DOPB(),              // Port B 4-bit Parity Output
      .ADDRB(a[8:0]),       // Port B 9-bit Address Input
      .CLKB(!clk),          // Port B Clock
      .DIB(32'h0),          // Port B 32-bit Data Input
      .DIPB(4'b0),          // Port-B 4-bit parity Input
      .ENB(re & !a[9]),             // PortB RAM Enable Input
      .SSRB(1'b0),          // Port B Synchronous Set/Reset Input
      .WEB(1'b0)            // Port B Write Enable Input
   );

	wire [31:0] sddo_1;
    RAMB16_S18_S36 i_buf_1 (
      .DOA(),               // Port A 16-bit Data Output   - compressor side
      .DOPA(),              // Port A 2-bit Parity Output
		.ADDRA(ch0a[9:0]),
      .CLKA(clk),          // Port A Clock
      .DIA(ibdat[15:0]),    // Port A 16-bit Data Input
      .DIPA(2'b0),          // Port A 2-bit parity Input
      .ENA(ibwe & ch0a[10]),           // Port A RAM Enable Input
      .SSRA(1'b0),          // Port A Synchronous Set/Reset Input
      .WEA(1'b1),           // Port A Write Enable Input

      .DOB(sddo_1[31:0]),     // Port B 32-bit Data Output  - SDRAM side
      .DOPB(),              // Port B 4-bit Parity Output
      .ADDRB(a[8:0]),       // Port B 9-bit Address Input
      .CLKB(!clk),          // Port B Clock
      .DIB(32'h0),          // Port B 32-bit Data Input
      .DIPB(4'b0),          // Port-B 4-bit parity Input
      .ENB(re & a[9]),             // PortB RAM Enable Input
      .SSRB(1'b0),          // Port B Synchronous Set/Reset Input
      .WEB(1'b0)            // Port B Write Enable Input
   );

assign sddo[31:0]=a_d?sddo_1[31:0]:sddo_0[31:0];

endmodule

