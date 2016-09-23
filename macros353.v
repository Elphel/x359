/*
** -----------------------------------------------------------------------------**
** macros353.v
**
** I/O pads related circuitry
**
** Copyright (C) 2002 Elphel, Inc
**
** -----------------------------------------------------------------------------**
**  This file is part of X353
**  X353 is free software - hardware description language (HDL) code.
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
*/
// just make more convenient A[3:0] instead of 4 one-bit inputs
`timescale 1 ns / 1 ps

module myRAM_WxD_D(D,WE,clk,AW,AR,QW,QR);
parameter DATA_WIDTH=16;
parameter DATA_DEPTH=4;
parameter DATA_2DEPTH=(1<<DATA_DEPTH)-1;
    input	 [DATA_WIDTH-1:0]	D;
    input				WE,clk;
    input	 [DATA_DEPTH-1:0]	AW;
    input	 [DATA_DEPTH-1:0]	AR;
    output [DATA_WIDTH-1:0]	QW;
    output [DATA_WIDTH-1:0]	QR;
    reg	 [DATA_WIDTH-1:0]	ram [0:DATA_2DEPTH];
    always @ (posedge clk) if (WE) ram[AW] <= D; 
    assign	QW= ram[AW];
    assign	QR= ram[AR];
endmodule

module MSRL16_1 (Q, A, CLK, D);
    output Q;
    input  [3:0] A;
    input  CLK, D;
    SRL16_1 i_q(.Q(Q), .A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .CLK(CLK), .D(D));
endmodule

/*
module MSRLC16E_1 (Q, Q15, A, CLK, CE, D);
    output Q,Q15;
    input  [3:0] A;
    input  CLK,CE, D;
    SRLC16E_1 i_q(.Q(Q),.Q15(Q15), .A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .CLK(CLK), .CE(CE), .D(D));
endmodule
*/

module MSRL16 (Q, A, CLK, D);
    output Q;
    input  [3:0] A;
    input  CLK, D;
    SRL16 i_q(.Q(Q), .A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .CLK(CLK), .D(D));
endmodule

module MSRLC16E (Q, Q15, A, CLK, CE, D);
    output Q,Q15;
    input  [3:0] A;
    input  CLK,CE, D;
    SRLC16E i_q(.Q(Q),.Q15(Q15), .A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .CLK(CLK), .CE(CE), .D(D));
endmodule

module MSRLC16E_1 (Q, Q15, A, CLK, CE, D);
    output Q,Q15;
    input  [3:0] A;
    input  CLK,CE, D;
    SRLC16E_1 i_q(.Q(Q),.Q15(Q15), .A0(A[0]), .A1(A[1]), .A2(A[2]), .A3(A[3]), .CLK(CLK), .CE(CE), .D(D));
endmodule
/*
module RAM32X12D_1 (DPO,SPO,A,D,DPRA,WCLK,WE);
       input   [4:0] A;    // Port A address[4:0] input bit
       input   [4:0] DPRA; // Port B address[4:0] input bit
       input  [11:0] D;    // Port A data input [11:0]
       input         WCLK; // Port A clock (negedge write)
       input         WE;   // Port A write enable input
       output [11:0] DPO;  // Port A 12-bit data output
       output [11:0] SPO;  // Port B 12-bit data output
   RAM32X1D_1 i0 (.DPO(DPO[ 0]),.SPO(SPO[ 0]),.A0(A[0]),.A1(A[1]),.A2(A[2]),.A3(A[3]),.A4(A[4]),.D(D[ 0]),
                  .DPRA0(DPRA[0]),.DPRA1(DPRA[1]),.DPRA2(DPRA[2]),.DPRA3(DPRA[3]),.DPRA4(DPRA[4]),.WCLK(WCLK),.WE(WE));
   RAM32X1D_1 i1 (.DPO(DPO[ 1]),.SPO(SPO[ 1]),.A0(A[0]),.A1(A[1]),.A2(A[2]),.A3(A[3]),.A4(A[4]),.D(D[ 1]),
                  .DPRA0(DPRA[0]),.DPRA1(DPRA[1]),.DPRA2(DPRA[2]),.DPRA3(DPRA[3]),.DPRA4(DPRA[4]),.WCLK(WCLK),.WE(WE));
   RAM32X1D_1 i2 (.DPO(DPO[ 2]),.SPO(SPO[ 2]),.A0(A[0]),.A1(A[1]),.A2(A[2]),.A3(A[3]),.A4(A[4]),.D(D[ 2]),
                  .DPRA0(DPRA[0]),.DPRA1(DPRA[1]),.DPRA2(DPRA[2]),.DPRA3(DPRA[3]),.DPRA4(DPRA[4]),.WCLK(WCLK),.WE(WE));
   RAM32X1D_1 i3 (.DPO(DPO[ 3]),.SPO(SPO[ 3]),.A0(A[0]),.A1(A[1]),.A2(A[2]),.A3(A[3]),.A4(A[4]),.D(D[ 3]),
                  .DPRA0(DPRA[0]),.DPRA1(DPRA[1]),.DPRA2(DPRA[2]),.DPRA3(DPRA[3]),.DPRA4(DPRA[4]),.WCLK(WCLK),.WE(WE));
   RAM32X1D_1 i4 (.DPO(DPO[ 4]),.SPO(SPO[ 4]),.A0(A[0]),.A1(A[1]),.A2(A[2]),.A3(A[3]),.A4(A[4]),.D(D[ 4]),
                  .DPRA0(DPRA[0]),.DPRA1(DPRA[1]),.DPRA2(DPRA[2]),.DPRA3(DPRA[3]),.DPRA4(DPRA[4]),.WCLK(WCLK),.WE(WE));
   RAM32X1D_1 i5 (.DPO(DPO[ 5]),.SPO(SPO[ 5]),.A0(A[0]),.A1(A[1]),.A2(A[2]),.A3(A[3]),.A4(A[4]),.D(D[ 5]),
                  .DPRA0(DPRA[0]),.DPRA1(DPRA[1]),.DPRA2(DPRA[2]),.DPRA3(DPRA[3]),.DPRA4(DPRA[4]),.WCLK(WCLK),.WE(WE));
   RAM32X1D_1 i6 (.DPO(DPO[ 6]),.SPO(SPO[ 6]),.A0(A[0]),.A1(A[1]),.A2(A[2]),.A3(A[3]),.A4(A[4]),.D(D[ 6]),
                  .DPRA0(DPRA[0]),.DPRA1(DPRA[1]),.DPRA2(DPRA[2]),.DPRA3(DPRA[3]),.DPRA4(DPRA[4]),.WCLK(WCLK),.WE(WE));
   RAM32X1D_1 i7 (.DPO(DPO[ 7]),.SPO(SPO[ 7]),.A0(A[0]),.A1(A[1]),.A2(A[2]),.A3(A[3]),.A4(A[4]),.D(D[ 7]),
                  .DPRA0(DPRA[0]),.DPRA1(DPRA[1]),.DPRA2(DPRA[2]),.DPRA3(DPRA[3]),.DPRA4(DPRA[4]),.WCLK(WCLK),.WE(WE));
   RAM32X1D_1 i8 (.DPO(DPO[ 8]),.SPO(SPO[ 8]),.A0(A[0]),.A1(A[1]),.A2(A[2]),.A3(A[3]),.A4(A[4]),.D(D[ 8]),
                  .DPRA0(DPRA[0]),.DPRA1(DPRA[1]),.DPRA2(DPRA[2]),.DPRA3(DPRA[3]),.DPRA4(DPRA[4]),.WCLK(WCLK),.WE(WE));
   RAM32X1D_1 i9 (.DPO(DPO[ 9]),.SPO(SPO[ 9]),.A0(A[0]),.A1(A[1]),.A2(A[2]),.A3(A[3]),.A4(A[4]),.D(D[ 9]),
                  .DPRA0(DPRA[0]),.DPRA1(DPRA[1]),.DPRA2(DPRA[2]),.DPRA3(DPRA[3]),.DPRA4(DPRA[4]),.WCLK(WCLK),.WE(WE));
   RAM32X1D_1 i10(.DPO(DPO[10]),.SPO(SPO[10]),.A0(A[0]),.A1(A[1]),.A2(A[2]),.A3(A[3]),.A4(A[4]),.D(D[10]),
                  .DPRA0(DPRA[0]),.DPRA1(DPRA[1]),.DPRA2(DPRA[2]),.DPRA3(DPRA[3]),.DPRA4(DPRA[4]),.WCLK(WCLK),.WE(WE));
   RAM32X1D_1 i11(.DPO(DPO[11]),.SPO(SPO[11]),.A0(A[0]),.A1(A[1]),.A2(A[2]),.A3(A[3]),.A4(A[4]),.D(D[11]),
                  .DPRA0(DPRA[0]),.DPRA1(DPRA[1]),.DPRA2(DPRA[2]),.DPRA3(DPRA[3]),.DPRA4(DPRA[4]),.WCLK(WCLK),.WE(WE));
endmodule
*/



module RAM16XnnD (D,WE,CLK,AW,AR,QW,QR);
   parameter w=16;
	input	 [w-1:0]	D;
	input				WE,CLK;
	input	 [ 3:0]	AW;
	input	 [ 3:0]	AR;
	output [w-1:0]	QW;
	output [w-1:0]	QR;
 	reg	 [w-1:0]	ram [0:15];
	always @ (posedge CLK) if (WE) ram[AW] <= D; 
	assign	QW= ram[AW];
	assign	QR= ram[AR];
endmodule

module RAM16XnnD_1 (D,WE,CLK,AW,AR,QW,QR);
   parameter w=16;
	input	 [w-1:0]	D;
	input				WE,CLK;
	input	 [ 3:0]	AW;
	input	 [ 3:0]	AR;
	output [w-1:0]	QW;
	output [w-1:0]	QR;
 	reg	 [w-1:0]	ram [0:15];
	always @ (negedge CLK) if (WE) ram[AW] <= D; 
	assign	QW= ram[AW];
	assign	QR= ram[AR];
endmodule

module RAM32XnnD   (D,WE,CLK,AW,AR,QW,QR);
   parameter w=16;
	input	 [w-1:0]	D;
	input				WE,CLK;
	input	 [ 4:0]	AW;
	input	 [ 4:0]	AR;
	output [w-1:0]	QW;
	output [w-1:0]	QR;
 	reg	 [w-1:0]	ram [0:31];
	always @ (posedge CLK) if (WE) ram[AW] <= D; 
	assign	QW= ram[AW];
	assign	QR= ram[AR];
endmodule

module RAM32XnnD_1 (D,WE,CLK,AW,AR,QW,QR);
   parameter w=16;
	input	 [w-1:0]	D;
	input				WE,CLK;
	input	 [ 4:0]	AW;
	input	 [ 4:0]	AR;
	output [w-1:0]	QW;
	output [w-1:0]	QR;
 	reg	 [w-1:0]	ram [0:31];
	always @ (negedge CLK) if (WE) ram[AW] <= D; 
	assign	QW= ram[AW];
	assign	QR= ram[AR];
endmodule


module SRPL	 (D,SDO,SDI,CLK,EN,LD);
   parameter w=16;
	input	 [w-1:0]	D;
	input				EN,CLK, LD, SDI;
	output         SDO;
 	reg	 [w-1:0]	r;
	always @ (posedge CLK)
	  if      (LD) r <= D;
	  else if (EN)	r <= {SDI,r[w-1:1]};
	assign SDO=r[0];
endmodule

module SRPL_1	 (D,SDO,SDI,CLK,EN,LD);
   parameter w=16;
	input	 [w-1:0]	D;
	input				EN,CLK, LD, SDI;
	output         SDO;
 	reg	 [w-1:0]	r;
	always @ (negedge CLK)
	  if      (LD) r <= D;
	  else if (EN)	r <= {SDI,r[w-1:1]};
	assign SDO=r[0];
endmodule
