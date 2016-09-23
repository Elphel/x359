/*
*! -----------------------------------------------------------------------------**
*! FILE NAME  : channel_rd.v
*! DESCRIPTION: channel for read from sdram
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
*! $Log: channel_rd.v,v $
*! Revision 1.4  2010/05/14 18:48:35  dzhimiev
*! 1. added hacts shifts for buffered channels
*! 2. set fixed SDRAM spaces
*!
*! Revision 1.1  2009/06/11 17:39:00  dzhimiev
*! new initial version
*! 1. simulation and board test availability
*!
*! Revision 1.1  2008/12/08 09:09:03  dzhimiev
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

module channel_rd   (
	clk,	 // SDRAM clock (negedge)
	enrq,	    // enable channel requests (does not reset if 0)
   fsa,      // [11:0] frame start address (12 MSBs of SDRAM row address)
   // Using the same values for channels 0..2
	init,     // resets channel
	x_max,
	x_shift,
	nx_max,
	y_max,
	y_shift,
	ny_max,
	fill_order,
	// arbiter interface
	start,
	start2,
	rq,       // request - want at least one access
	rq_urgent,// need 3 or 4 accesses
	sddi,     //[31:0]
	rq_busy,
	//SDRAM controller inteface (mcontr_line_rd)
	predrun,
	sa,       //[16:0]
	len,      // access length
	// external interface (compressor)
	obre,     // output read enable, advance address
	ch1a,
	obdat,    // [15:0] output dtata
	next_line, // advance to the next scan line (and next block RAM page if needed)
	ao
);
						 
  input         clk;
  input         enrq;
  input  [11:0] fsa;
  input         init;
  input  [ 11:0] ch1a;

  input         start;
  input         start2;
  input         rq_busy;
  output        rq;
  output        rq_urgent;

  input [7:0]   x_max;
  input [7:0]   x_shift;
  input [7:0]   nx_max;
  input [13:0]   y_max;
  input [7:0]   y_shift;
  input [7:0]   ny_max;
  input fill_order;

  input  [31:0] sddi;     // data from SDRAM
  input         predrun;
  output [21:0] sa;
  output  [4:0] len;
  input        obre;      // output read enable
  output[15:0] obdat;     // [15:0] output dtata
  input        next_line;
	output [10:0] ao;

  wire         predrun;

	reg         we;
   reg         done;
	reg	[10:0]	a=0;

	reg   [2:0] rq_cnt=0;
   wire        init0;
   reg         init_pclk; 
   wire        page_used0;
   reg         page_used;
	reg         rq;
   reg         rq_urgent;
   reg   [1:0] obpage;
   reg   [7:0] obaddr;
   wire        next_opage;
   reg         cs,cs0;

   reg [21:0] sa=0; 
   reg   [7:0] obre_cnt=0;
   reg   [4:0] len;

//	parameter x_max=7;
//	parameter x_shift=8;
//	parameter nx_max=17;
//	parameter y_max=4;
//	parameter y_shift=4;
//	parameter ny_max=9;

	reg [6:0]  x=0, nx=0;
	reg [12:0] y=0, ny=0;
	reg [7:0] ny_cnt=0;
	reg [7:0] nx_cnt=0;
	reg [1:0] bank=0;

   assign      next_opage=0;//((next_line & (obre_cnt[7:0]!=8'h0)) | ((obre_cnt[7:0]==8'hff) & obre));

	always @ (negedge clk) init_pclk <= init;

	always @ (negedge clk) page_used <= !init_pclk && next_opage;
  
  always @ (negedge clk) begin
    if      (init_pclk | next_opage)  obre_cnt[7:0] <= 0;
    else if (obre)                    obre_cnt[7:0] <= obre_cnt[7:0] + 1;
  end

  //wire switch_order=0;

  always @ (negedge clk) begin
  
   if      (init)              rq_cnt <= 0;
   else if (start2) 
		if (rq_busy)             rq_cnt <= rq_cnt + 1;
		else                     rq_cnt <= rq_cnt;
	else if (!rq_busy & rq_cnt!=0) rq_cnt <= rq_cnt - 1;  
  
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

   rq        <= enrq & (start2 | (rq & !start));
   rq_urgent <= enrq & start2 & (rq_cnt==3);

  end
	
	assign ao[10:0]=a[10:0];
	
	always @ (negedge clk) begin
	  we <= predrun;
	  done <= we & !predrun;

	  if (init)        a[10:0] <= 11'b0;
	  else if (we)     a[10:0] <= a[10:0] + 1;
	  //if (init)        a[9:0] <= 10'b0;
	  //else if (we)     a[9:0] <= a[9:0] + 1;    

		 //if      (init) a[8:7] <= 2'h0;
     //else if (done) a[8:7] <= a[8:7] + 1;
	end	
	
	reg [11:10] ch1a_d=0;
	
	always @ (negedge clk) begin
		ch1a_d[11:10] <= ch1a[11:10];
	end
	
	wire [15:0] obdat_0;
	RAMB16_S18_S36 i_buf_0 (
		.DOA(obdat_0[15:0]),    // Port A 16-bit Data Output   - compressor side
		.ADDRA(ch1a[9:0]),
		.CLKA(!clk),          // Port A Clock
		.DIA(16'b0),          // Port A 16-bit Data Input
		.DIPA(2'b0),          // Port A 2-bit parity Input
		.ENA(obre & !ch1a[11] & !ch1a[10]),           // Port A RAM Enable Input
		.SSRA(1'b0),          // Port A Synchronous Set/Reset Input
		.WEA(1'b0),           // Port A Write Enable Input
	
		.ADDRB(a[8:0]),       // Port B 9-bit Address Input
		.CLKB(!clk),         // Port B Clock
		.DIB(sddi[31:0]),     // Port B 32-bit Data Input
		.DIPB(4'b0),          // Port-B 4-bit parity Input
		.ENB(we & !a[10] & !a[9]),             // PortB RAM Enable Input
		.SSRB(1'b0),          // Port B Synchronous Set/Reset Input
		.WEB(1'b1)            // Port B Write Enable Input
	);

	wire [15:0] obdat_1;
	RAMB16_S18_S36 i_buf_1 (
		.DOA(obdat_1[15:0]),    // Port A 16-bit Data Output   - compressor side
		.ADDRA(ch1a[9:0]),
		.CLKA(!clk),          // Port A Clock
		.DIA(16'b0),          // Port A 16-bit Data Input
		.DIPA(2'b0),          // Port A 2-bit parity Input
		.ENA(obre & !ch1a[11] & ch1a[10]),           // Port A RAM Enable Input
		.SSRA(1'b0),          // Port A Synchronous Set/Reset Input
		.WEA(1'b0),           // Port A Write Enable Input
	
		.ADDRB(a[8:0]),       // Port B 9-bit Address Input
		.CLKB(!clk),         // Port B Clock
		.DIB(sddi[31:0]),     // Port B 32-bit Data Input
		.DIPB(4'b0),          // Port-B 4-bit parity Input
		.ENB(we & !a[10] & a[9]),             // PortB RAM Enable Input
		.SSRB(1'b0),          // Port B Synchronous Set/Reset Input
		.WEB(1'b1)            // Port B Write Enable Input
	);
	
	wire [15:0] obdat_2;
	RAMB16_S18_S36 i_buf_2 (
		.DOA(obdat_2[15:0]),    // Port A 16-bit Data Output   - compressor side
		.ADDRA(ch1a[9:0]),
		.CLKA(!clk),          // Port A Clock
		.DIA(16'b0),          // Port A 16-bit Data Input
		.DIPA(2'b0),          // Port A 2-bit parity Input
		.ENA(obre & ch1a[11] & !ch1a[10]),           // Port A RAM Enable Input
		.SSRA(1'b0),          // Port A Synchronous Set/Reset Input
		.WEA(1'b0),           // Port A Write Enable Input
	
		.ADDRB(a[8:0]),       // Port B 9-bit Address Input
		.CLKB(!clk),         // Port B Clock
		.DIB(sddi[31:0]),     // Port B 32-bit Data Input
		.DIPB(4'b0),          // Port-B 4-bit parity Input
		.ENB(we & a[10] & !a[9]),             // PortB RAM Enable Input
		.SSRB(1'b0),          // Port B Synchronous Set/Reset Input
		.WEB(1'b1)            // Port B Write Enable Input
	);

	wire [15:0] obdat_3;
	RAMB16_S18_S36 i_buf_3 (
		.DOA(obdat_3[15:0]),    // Port A 16-bit Data Output   - compressor side
		.ADDRA(ch1a[9:0]),
		.CLKA(!clk),          // Port A Clock
		.DIA(16'b0),          // Port A 16-bit Data Input
		.DIPA(2'b0),          // Port A 2-bit parity Input
		.ENA(obre & ch1a[11] & ch1a[10]),           // Port A RAM Enable Input
		.SSRA(1'b0),          // Port A Synchronous Set/Reset Input
		.WEA(1'b0),           // Port A Write Enable Input
	
		.ADDRB(a[8:0]),       // Port B 9-bit Address Input
		.CLKB(!clk),         // Port B Clock
		.DIB(sddi[31:0]),     // Port B 32-bit Data Input
		.DIPB(4'b0),          // Port-B 4-bit parity Input
		.ENB(we & a[10] & a[9]),             // PortB RAM Enable Input
		.SSRB(1'b0),          // Port B Synchronous Set/Reset Input
		.WEB(1'b1)            // Port B Write Enable Input
	);	

assign obdat=ch1a_d[11]?(ch1a_d[10]?obdat_3:obdat_2):(ch1a_d[10]?obdat_1:obdat_0);

endmodule

