/*!***************************************************************************
*! FILE NAME  : x359.tf
*! DESCRIPTION: testbench
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
*!  $Log: x359.tf,v $
*!  Revision 1.3  2010/05/13 03:34:46  elphel
*!  10359 updates for composite frames
*!
*!  Revision 1.1  2009/06/11 17:39:00  dzhimiev
*!  new initial version
*!  1. simulation and board test availability
*!
*!  Revision 1.1  2008/12/08 09:07:57  dzhimiev
*!  1. set up of the data path for the transform
*!  2. 2 read and 2 write channels
*!  3. in snapshot mode - 3 frames output sequence -
*!    1st - direct
*!    2nd - stored 'direct' from the 1st buffer
*!    3rd - stored '1st buffer' from the 2nd buffer
*!
*!  Revision 1.2  2008/04/24 17:45:55  dzhimiev
*!  did't close the header comment
*!
*!  Revision 1.1  2008/04/23 01:55:49  dzhimiev
*!  1. added x359 files to src lists
*!  2. x359 read/write DDR
*!  3. x359 3 channels mux directly to out
*!  4. x359 one channel through DDR and another directly frames switching at out
*!
*/

`timescale 1 ns / 1 ps

module x359_tf;
   parameter DCLK_PER = 50;	//20MHz
	parameter I2C_PER = 1000;
	
	parameter PIXELS_IN_LINE = 1296;
	parameter LINES_IN_FRAME = 4; 

	// Inputs
	reg SDNCLK_FB;
	reg SDCLK_FB;
	reg DCLK;
	reg MRST;
	reg ARO;
	reg ARST;
	wire PX_BPF1;
	wire PX_HACT1;
	wire PX_VACT1;
	wire PX_BPF2;
	wire PX_HACT2;
	wire PX_VACT2;
	wire PX_BPF3;
	wire PX_HACT3;
	wire PX_VACT3;

	// Outputs
	wire RUN;
	wire SDCLKE;
	wire SDCLK;
	wire SDNCLK;
	wire SDLDM;
	wire SDUDM;
	wire SDWE;
	wire SDCAS;
	wire SDRAS;
	wire [14:0] SDA;
	wire [9:0] PXD;
	wire BPF;
	wire HACT;
	wire VACT;
	wire PX_DCLK1;
	wire PX_MRST1;
	wire PX_ARO1;
	wire PX_ARST1;
	wire PX_DCLK2;
	wire PX_MRST2;
	wire PX_ARO2;
	wire PX_ARST2;
	wire PX_DCLK3;
	wire PX_MRST3;
	wire PX_ARO3;
	wire PX_ARST3;

	// Bidirs
	wire [15:0] SDD;
	wire UDQS;
	wire LDQS;
	wire SCL0;
	wire SDA0;
	wire CNVSYNC;
	wire CNVCLK;
	wire [11:0] PXD1;
	wire PX_SCL1;
	wire PX_SDA1;
	wire SENSPGM1;
	wire [11:0] PXD2;
	wire PX_SCL2;
	wire PX_SDA2;
	wire SENSPGM2;
	wire [11:0] PXD3;
	wire PX_SCL3;
	wire PX_SDA3;
	wire SENSPGM3;
	wire ALWAYS0;
   
// test registers/wires
   reg I2C_CLK;
   reg HOST_SDA;   
   reg HOST_SCL;   
   reg HOST_SDA_EN;   
   reg HOST_SCL_EN;   
   
   assign SDA0= HOST_SDA_EN ? HOST_SDA : 'bz;  
   assign SCL0= HOST_SCL_EN ? HOST_SCL : 'bz;  

	// param
	//defparam i_x359.i_dcm_359_2.i_dcm2.PHASE_SHIFT=7;
	// Instantiate the Unit Under Test (UUT)
	x359 i_x359 (
		.RUN(RUN), 
		.SDCLKE(SDCLKE), 
		.SDNCLK_FB(SDNCLK_FB), 
		.SDCLK(SDCLK), 
		.SDNCLK(SDNCLK), 
		.SDCLK_FB(SDCLK_FB), 
		.SDLDM(SDLDM), 
		.SDUDM(SDUDM), 
		.SDWE(SDWE), 
		.SDCAS(SDCAS), 
		.SDRAS(SDRAS), 
		.SDA(SDA), 
		.SDD(SDD), 
		.UDQS(UDQS), 
		.LDQS(LDQS), 
		.PXD(PXD), 
		.DCLK(DCLK), 
		.BPF(BPF), 
		.HACT(HACT), 
		.VACT(VACT), 
		.MRST(MRST), 
		.ARO(ARO), 
		.ARST(ARST), 
		.SCL0(SCL0), 
		.SDA0(SDA0), 
		.CNVSYNC(CNVSYNC), 
		.CNVCLK(CNVCLK), 
		.PXD1(PXD1),
		//.PXD1({5'b0,PXD1[6:0]}),
		.PX_DCLK1(PX_DCLK1), 
		.PX_BPF1(PX_BPF1), 
		.PX_HACT1(PX_HACT1), 
		.PX_VACT1(PX_VACT1), 
		.PX_MRST1(PX_MRST1), 
		.PX_ARO1(PX_ARO1), 
		.PX_ARST1(PX_ARST1), 
		.PX_SCL1(PX_SCL1), 
		.PX_SDA1(PX_SDA1), 
		.SENSPGM1(SENSPGM1), 
		.PXD2(PXD2), 
		//.PXD2({5'b0,PXD2[6:0]}),
		.PX_DCLK2(PX_DCLK2), 
		.PX_BPF2(PX_BPF2), 
		.PX_HACT2(PX_HACT2), 
		.PX_VACT2(PX_VACT2), 
		.PX_MRST2(PX_MRST2), 
		.PX_ARO2(PX_ARO2), 
		.PX_ARST2(PX_ARST2), 
		.PX_SCL2(PX_SCL2), 
		.PX_SDA2(PX_SDA2), 
		.SENSPGM2(SENSPGM2),
		.PXD3(PXD3),
		//.PXD3(),
		.PX_DCLK3(PX_DCLK3), 
		.PX_BPF3(PX_BPF3), 
		.PX_HACT3(PX_HACT3), 
		.PX_VACT3(PX_VACT3), 
		.PX_MRST3(PX_MRST3), 
		.PX_ARO3(PX_ARO3), 
		.PX_ARST3(PX_ARST3), 
		.PX_SCL3(PX_SCL3), 
		.PX_SDA3(PX_SDA3), 
		.SENSPGM3(SENSPGM3), 
		.ALWAYS0(ALWAYS0)
	);

reg a;
reg [2:0] fib=0;

initial begin
 fib=0; a=(fib[2] || & fib[1:0]); #100;
 fib=1; a=(fib[2] || & fib[1:0]); #100;
 fib=2; a=(fib[2] || & fib[1:0]); #100;
 fib=3; a=(fib[2] || & fib[1:0]); #100;
 fib=4; a=(fib[2] || & fib[1:0]); #100;
 fib=5; a=(fib[2] || & fib[1:0]); #100;
 fib=6; a=(fib[2] || & fib[1:0]); #100;
 fib=7; a=(fib[2] || & fib[1:0]); #100;
end

// Instance of Micron MT48LC8M16LFFF8
// cheating - no such actual signal :-(
reg SDCKE;
initial begin
  SDCKE=0;
  #1000;
  SDCKE=1;
end
wire SDCLK_D;
wire SDNCLK_D;
assign #(2) SDCLK_D=SDCLK;
assign #(2) SDNCLK_D=SDNCLK;

integer k=0;
integer s0=0;
integer s1=0;

reg [7:0] corr_status=0;
//`define sg5B;

	ddr i_mt46v16m16fg (.Dq(SDD[15:0]),
                    .Dqs({UDQS,LDQS}),
                    .Addr(SDA[12:0]),
                    .Ba(SDA[14:13]),
                    .Clk(SDCLK_D),
                    .Clk_n(SDNCLK_D),
//                  .Cke(1'b1),
//                  .Cke(SDCKE),
                    .Cke(SDCLKE),
                    .Cs_n(1'b0),
                    .Ras_n(SDRAS),
                    .Cas_n(SDCAS),
                    .We_n(SDWE),
                    .Dm({SDUDM,SDLDM})
										);

	initial begin
		// Initialize Inputs
		SDNCLK_FB = 0;
		SDCLK_FB = 0;
		DCLK = 0;
		MRST = 0;
		ARO = 0;
		ARST = 0;
		//PX_BPF1 = 0;
		//PX_HACT1 = 0;
		//PX_VACT1 = 0;
		//PX_BPF2 = 0;
		//PX_HACT2 = 0;
		//PX_VACT2 = 0;
		//PX_BPF3 = 0;
		//PX_HACT3 = 0;
		//PX_VACT3 = 0;

		// Wait 100 ns for global reset to finish
		#100;

		MRST = 1;
		ARO = 1;
		ARST = 1;        
		// Add stimulus here

	end
      
      
   always #(DCLK_PER/2)	DCLK =	   ~DCLK;
   always #(I2C_PER/2)	I2C_CLK =	~I2C_CLK;

//   parameter DCLK_PER = 50	//20MHz
//   parameter I2C_PER = 1000;
    	initial begin
    $dumpfile("x359_sim.lxt");
    $dumpvars(0,x359_tf);
      DCLK = 0;
      I2C_CLK = 0;
// test registers/wires
      I2C_CLK =0;
      HOST_SDA=1;   
      HOST_SCL=1;   
      HOST_SDA_EN=0;
      HOST_SCL_EN=0;   
      
//#1000;
// global set/reset for simulation
		glbl.GSR_int = 1'b1;
		glbl.GTS_int = 1'b1;
		#2000;
		glbl.GSR_int = 1'b0;
		#20;
		glbl.GTS_int = 1'b0;
		#50;

#10000;

i2c_start; i2c_send_2_bytes('hbaa0); i2c_send_4_bytes('h00410000); i2c_stop; #10000;

// direct frame sizes
i2c_start; i2c_send_2_bytes('h100a); i2c_send_2_bytes(PIXELS_IN_LINE); i2c_stop; #10000;
i2c_start; i2c_send_2_bytes('h100b); i2c_send_2_bytes(LINES_IN_FRAME); i2c_stop; #10000;

// frequency rotate 90 for ddr correct work
 i2c_start; i2c_send_2_bytes('h1002); i2c_send_2_bytes('h0004); i2c_stop; #10000;

 //i2c_start; i2c_send_2_bytes('h1009); i2c_send_2_bytes('h0003); i2c_stop; #10000; // rst
 //i2c_start; i2c_send_2_bytes('h1009); i2c_send_2_bytes('h0002); i2c_stop; #10000; // disable output

 i2c_start; i2c_send_2_bytes('h9001); i2c_send_2_bytes('h0002); i2c_stop; #10000;
 i2c_start; i2c_send_2_bytes('h9402); i2c_send_2_bytes('h0003); i2c_stop; #10000;
 
 i2c_start; i2c_send_2_bytes('h1001); i2c_send_2_bytes('h0001); i2c_stop; #10000;
 
 i2c_start; i2c_send_2_bytes('h9803); i2c_send_2_bytes('h0004); i2c_stop; #10000;
 i2c_start; i2c_send_2_bytes('h9c04); i2c_send_2_bytes('h0005); i2c_stop; #10000; 

#10000;

i2c_start;
i2c_sendbyte ('h10);
i2c_sendbyte ('h02);
i2c_restart;      
i2c_sendbyte ('h11);
 
i2c_readbyte (1);
i2c_readbyte (1);
i2c_readbyte (1);
i2c_readbyte (0);	 
i2c_stop;

#100000;

i2c_start;
i2c_sendbyte ('h90);
i2c_sendbyte ('h00);
i2c_restart;      
i2c_sendbyte ('h00);
 
i2c_readbyte (1);
i2c_readbyte (1);
i2c_readbyte (1);
i2c_readbyte (0);	 
i2c_stop;

#100000;

i2c_start;
i2c_sendbyte ('h94);
i2c_sendbyte ('h00);
i2c_restart;      
i2c_sendbyte ('h00);
 
i2c_readbyte (1);
i2c_readbyte (1);
i2c_readbyte (1);
i2c_readbyte (0);	 
i2c_stop;

// ch0_N frame dimensions
//i2c_start; i2c_send_2_bytes('h1037); i2c_send_4_bytes(LINES_IN_FRAME*32'h10000+PIXELS_IN_LINE); i2c_stop; #10000;	

i2c_start; i2c_send_2_bytes('h1013); i2c_send_2_bytes(PIXELS_IN_LINE); i2c_stop; #10000;
i2c_start; i2c_send_2_bytes('h1014); i2c_send_2_bytes(LINES_IN_FRAME); i2c_stop; #10000;
// ch2_N frame dimensions
//i2c_start; i2c_send_2_bytes('h103c); i2c_send_4_bytes(LINES_IN_FRAME*32'h10000+PIXELS_IN_LINE); i2c_stop; #10000;	

i2c_start; i2c_send_2_bytes('h1023); i2c_send_2_bytes(PIXELS_IN_LINE); i2c_stop; #10000;
i2c_start; i2c_send_2_bytes('h1024); i2c_send_2_bytes(LINES_IN_FRAME); i2c_stop; #10000;

//	i2c_start; i2c_send_2_bytes('h103b); i2c_send_4_bytes('h00000001); i2c_stop; #10000;
	
// set little delay for simulation
	i2c_start; i2c_send_2_bytes('h1038); i2c_send_4_bytes('h00000000); i2c_stop; #10000;	  
// switch channel to 0x21
	i2c_start; i2c_send_2_bytes('h1006); i2c_send_4_bytes('h00390039); i2c_stop; #10000;	  
  		
 // DDR initialization sequence
   // init all the channels?
	i2c_start; i2c_send_2_bytes('h1050); i2c_send_2_bytes('h0001); i2c_stop;
	i2c_start; i2c_send_2_bytes('h1040); i2c_send_2_bytes('h5555); i2c_stop;	
#10000;
  // DDR initialization sequence
   //PRE : Addr[10] = 1, Bank = 11
	i2c_start; i2c_send_2_bytes('h1051); i2c_send_2_bytes('h0001); i2c_stop;
	i2c_start; i2c_send_2_bytes('h1041); i2c_send_2_bytes('h7fff); i2c_stop;
	//Extended mode register - Enable DLL
	i2c_start; i2c_send_2_bytes('h1051); i2c_send_2_bytes('h0000); i2c_stop;
	i2c_start; i2c_send_2_bytes('h1041); i2c_send_2_bytes('h2002); i2c_stop;
	//Load Mode Register - Burst Length - 8, CAS latency - 2.5
	i2c_start; i2c_send_2_bytes('h1051); i2c_send_2_bytes('h0000); i2c_stop;
	i2c_start; i2c_send_2_bytes('h1041); i2c_send_2_bytes('h0163); i2c_stop;
	//Refresh
	i2c_start; i2c_send_2_bytes('h1051); i2c_send_2_bytes('h0000); i2c_stop;
	i2c_start; i2c_send_2_bytes('h1041); i2c_send_2_bytes('h8000); i2c_stop;
	//Refresh
	i2c_start; i2c_send_2_bytes('h1051); i2c_send_2_bytes('h0000); i2c_stop;
	i2c_start; i2c_send_2_bytes('h1041); i2c_send_2_bytes('h8000); i2c_stop;
	//PRE : Addr[10] = 1, Bank = 11
	i2c_start; i2c_send_2_bytes('h1051); i2c_send_2_bytes('h0001); i2c_stop;
	i2c_start; i2c_send_2_bytes('h1041); i2c_send_2_bytes('h7fff); i2c_stop;
#10000;

//	i2c_start; i2c_send_2_bytes('h1050); i2c_send_2_bytes('h0001); i2c_stop;
//	i2c_start; i2c_send_2_bytes('h1040); i2c_send_2_bytes('h0000); i2c_stop;
//	
//	i2c_start; i2c_send_2_bytes('h1050); i2c_send_2_bytes('h0000); i2c_stop;	
//	i2c_start; i2c_send_2_bytes('h1040); i2c_send_2_bytes('h5555); i2c_stop;
	
	// unappply init and enable all the 6 channels
	i2c_start; i2c_send_2_bytes('h1050); i2c_send_2_bytes('h0002); i2c_stop;
	i2c_start; i2c_send_2_bytes('h1040); i2c_send_2_bytes('haaaa); i2c_stop;
	

#10000;
////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// ddr test
//repeat(8) begin
//i2c_start; i2c_send_2_bytes('h1070); i2c_send_2_bytes('h2211); i2c_stop; #10000;
//i2c_start; i2c_send_2_bytes('h1070); i2c_send_2_bytes('h4433); i2c_stop; #10000;
//i2c_start; i2c_send_2_bytes('h1070); i2c_send_2_bytes('h6655); i2c_stop; #10000;
//i2c_start; i2c_send_2_bytes('h1070); i2c_send_2_bytes('h8877); i2c_stop; #10000;
//i2c_start; i2c_send_2_bytes('h1070); i2c_send_2_bytes('haa99); i2c_stop; #10000;
//i2c_start; i2c_send_2_bytes('h1070); i2c_send_2_bytes('hccbb); i2c_stop; #10000;
//i2c_start; i2c_send_2_bytes('h1070); i2c_send_2_bytes('heedd); i2c_stop; #10000;
//i2c_start; i2c_send_2_bytes('h1070); i2c_send_2_bytes('h00ff); i2c_stop; #10000;
//end
//
//i2c_start; i2c_send_2_bytes('h1063); i2c_send_2_bytes('h0001); i2c_stop; #10000; // write page to SDRAM
//
//i2c_start; i2c_send_2_bytes('h1064); i2c_send_2_bytes('h0001); i2c_stop; #10000; // read page from SDRAM
//
//repeat(10) begin
//i2c_start;
//i2c_sendbyte ('h10);
//i2c_sendbyte ('h70);
//i2c_restart;      
//i2c_sendbyte ('h11);
//i2c_readbyte (1);
//i2c_readbyte (0);	 
//i2c_stop;
//#10000;
//
//i2c_start;
//i2c_sendbyte ('h10);
//i2c_sendbyte ('h10);
//i2c_restart;      
//i2c_sendbyte ('h11);
//i2c_readbyte (1);
//i2c_readbyte (0);	 
//i2c_stop;
//#10000;
//
//end
//#10000;
//
//	i2c_start; i2c_send_2_bytes('h1050); i2c_send_2_bytes('h0001); i2c_stop;	
//	i2c_start; i2c_send_2_bytes('h1040); i2c_send_2_bytes('h5555); i2c_stop;
//	
//	i2c_start; i2c_send_2_bytes('h1050); i2c_send_2_bytes('h0002); i2c_stop;
//	i2c_start; i2c_send_2_bytes('h1040); i2c_send_2_bytes('h0a00); i2c_stop;
//
//#100000;
//
//$finish;
////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////

	i2c_start; i2c_send_2_bytes('h1052); i2c_send_2_bytes('h0007); i2c_stop; #10000;
	i2c_start; i2c_send_2_bytes('h1042); i2c_send_2_bytes('h000f); i2c_stop; #10000;
	
////	i2c_start; i2c_send_2_bytes('h104c); i2c_send_4_bytes('h00010107); i2c_stop; #10000;
////	i2c_start; i2c_send_2_bytes('h1054); i2c_send_4_bytes('h0019100c); i2c_stop; #10000;
////	i2c_start; i2c_send_2_bytes('h104d); i2c_send_4_bytes('h00010107); i2c_stop; #10000;
////	i2c_start; i2c_send_2_bytes('h1055); i2c_send_4_bytes('h0019100c); i2c_stop; #10000;

	i2c_start; i2c_send_2_bytes('h105c); i2c_send_2_bytes('h000f); i2c_stop; #10000; //was 'h001f0107
	i2c_start; i2c_send_2_bytes('h104c); i2c_send_2_bytes('h020f); i2c_stop; #10000; //was 'h001f0107
	
	i2c_start; i2c_send_2_bytes('h105e); i2c_send_2_bytes('h1fff); i2c_stop; #10000;	
	i2c_start; i2c_send_2_bytes('h104e); i2c_send_2_bytes('h10ff); i2c_stop; #10000;
	
	i2c_start; i2c_send_2_bytes('h105d); i2c_send_2_bytes('h000f); i2c_stop; #10000; //was 'h001f0107
	i2c_start; i2c_send_2_bytes('h104d); i2c_send_2_bytes('h020f); i2c_stop; #10000; //was 'h001f0107
	
	i2c_start; i2c_send_2_bytes('h105f); i2c_send_2_bytes('h1fff); i2c_stop; #10000;
	i2c_start; i2c_send_2_bytes('h104f); i2c_send_2_bytes('h10ff); i2c_stop; #10000;

	i2c_start; i2c_send_2_bytes('h1053); i2c_send_2_bytes('h1c00); i2c_stop; #10000;
	i2c_start; i2c_send_2_bytes('h1043); i2c_send_2_bytes('h0c21); i2c_stop; #10000;
	
	i2c_start; i2c_send_2_bytes('h1050); i2c_send_2_bytes('h0000); i2c_stop; #10000;
	i2c_start; i2c_send_2_bytes('h1040); i2c_send_2_bytes('h5555); i2c_stop; #10000;
	
	i2c_start; i2c_send_2_bytes('h1054); i2c_send_2_bytes('h0000); i2c_stop; #10000;
	i2c_start; i2c_send_2_bytes('h1044); i2c_send_2_bytes('h0000); i2c_stop; #10000;
	
	i2c_start; i2c_send_2_bytes('h1055); i2c_send_2_bytes('h0000); i2c_stop; #10000;
	i2c_start; i2c_send_2_bytes('h1045); i2c_send_2_bytes('h0000); i2c_stop; #10000;

	i2c_start; i2c_send_2_bytes('h1056); i2c_send_2_bytes('h0001); i2c_stop; #10000;
	i2c_start; i2c_send_2_bytes('h1046); i2c_send_2_bytes('h0000); i2c_stop; #10000;
	
	i2c_start; i2c_send_2_bytes('h1057); i2c_send_2_bytes('h0001); i2c_stop; #10000;
	i2c_start; i2c_send_2_bytes('h1047); i2c_send_2_bytes('h0000); i2c_stop; #10000;
	
	i2c_start; i2c_send_2_bytes('h1050); i2c_send_2_bytes('h0002); i2c_stop; #10000;
	i2c_start; i2c_send_2_bytes('h1040); i2c_send_2_bytes('haaaa); i2c_stop; #10000;
	
	i2c_start; i2c_send_2_bytes('h1009); i2c_send_2_bytes('h0003); i2c_stop; #10000;
	i2c_start; i2c_send_2_bytes('h1009); i2c_send_2_bytes('h0002); i2c_stop; #10000;

	// switch to alternation mode with buffering
	//i2c_start; i2c_send_2_bytes('h1035); i2c_send_4_bytes('h00000007); i2c_stop; #100000;

	i2c_start; i2c_send_2_bytes('h1015); i2c_send_2_bytes('h0100); i2c_stop; #10000;
   i2c_start; i2c_send_2_bytes('h1016); i2c_send_2_bytes('h0001); i2c_stop; #10000;
	
   i2c_start; i2c_send_2_bytes('h1025); i2c_send_2_bytes('h0080); i2c_stop; #10000;
   i2c_start; i2c_send_2_bytes('h1026); i2c_send_2_bytes('h0001); i2c_stop; #10000;

	i2c_start; i2c_send_2_bytes('h1009); i2c_send_2_bytes('h0004); i2c_stop; #10000;
	//frame enable
	//i2c_start; i2c_send_2_bytes('h1005); i2c_send_4_bytes('h00000001); i2c_stop; #10000;

#8000000;
$finish;
	
// test!!!
//	i2c_start; i2c_send_2_bytes('h1047); i2c_send_4_bytes('h00000000); i2c_stop; #10000;
//	i2c_start; i2c_send_2_bytes('h1047); i2c_send_4_bytes('h00000001); i2c_stop; #10000;

i2c_start; i2c_send_2_bytes('h1003); i2c_send_4_bytes('h00000001); i2c_stop; #10000;

// ddr shit
repeat(1) begin
i2c_start; i2c_send_2_bytes('h1002); i2c_send_4_bytes('h00002222); i2c_stop; #10000;
end

i2c_start; i2c_send_2_bytes('h1003); i2c_send_4_bytes('h00000001); i2c_stop; #10000;


// now read what was written from channel 0
i2c_start; i2c_send_2_bytes('h1004); i2c_send_4_bytes('h00000001); i2c_stop; #10000;

// now read what was written from channel 0
i2c_start; i2c_send_2_bytes('h1004); i2c_send_4_bytes('h00000001); i2c_stop; #10000;

i2c_start;
i2c_sendbyte ('h10);
i2c_sendbyte ('h02);
i2c_restart;      
i2c_sendbyte ('h11);
	 
repeat(14) begin
	i2c_readbyte (1);
	i2c_readbyte (1);
	i2c_readbyte (1);
	i2c_readbyte (1);
end
 	 
i2c_readbyte (1);
i2c_readbyte (1);
i2c_readbyte (1);
i2c_readbyte (0);	 
i2c_stop;

#10000;

i2c_start;
i2c_sendbyte ('h10);
i2c_sendbyte ('h02);
i2c_restart;      
i2c_sendbyte ('h11);
	 
repeat(14) begin
	i2c_readbyte (1);
	i2c_readbyte (1);
	i2c_readbyte (1);
	i2c_readbyte (1);
end
 	 
i2c_readbyte (1);
i2c_readbyte (1);
i2c_readbyte (1);
i2c_readbyte (0);	 
i2c_stop;

#10000;

$finish;
end  

reg PX_MRST1_D=0;
reg PX_ARST1_D=0;

initial begin
#100000;
PX_MRST1_D = PX_MRST1;
PX_ARST1_D = PX_ARST1;
end	

  sensor12bits #(.ncols(PIXELS_IN_LINE),.nrows(LINES_IN_FRAME),.t_afterHACT(100),.nVLO(7000)) 
i_sensor12bits1(.MCLK(PX_DCLK1),	// Master clock
								//.MRST(PX_MRST1_D),	// Master Reset - active low
								.MRST(PX_MRST1),	// Master Reset - active low
								.ARO (PX_ARO1),	  // Array read Out.
								//.ARST(PX_ARST1_D),	// Array Reset. Active low
								.ARST(PX_ARST1),	// Array Reset. Active low
								.OE  (1'b0),      // output enable active low
								.SCL (PX_SCL1),   // I2C clock
								.SDA (PX_SDA1),	  // I2C data
								.OFST(1'b1),      // I2C address ofset by 2: for simulation 0 - still mode, 1 - video mode.
								.D   (PXD1[11:0]),// [9:0] data output
								.DCLK(),          // Data output clock
								.BPF (PX_BPF1),   // Black Pixel Flag
								.HACT(PX_HACT1),  // Horizontal Active
								.VACT(PX_VACT1)   // Vertical Active		
                );

  sensor12bits #(.ncols(PIXELS_IN_LINE),.nrows(LINES_IN_FRAME),.t_afterHACT(100),.nVLO(7000)) 
i_sensor12bits2(.MCLK(PX_DCLK2),	// Master clock
								.MRST(PX_MRST2),	// Master Reset - active low
								.ARO (PX_ARO2),	  // Array read Out.
								.ARST(PX_ARST2),	// Array Reset. Active low
								.OE  (1'b0),      // output enable active low
								.SCL (PX_SCL2),   // I2C clock
								.SDA (PX_SDA2),	  // I2C data
								.OFST(1'b1),      // I2C address ofset by 2: for simulation 0 - still mode, 1 - video mode.
								.D   (PXD2[11:0]),// [9:0] data output
								.DCLK(),          // Data output clock
								.BPF (PX_BPF2),   // Black Pixel Flag
								.HACT(PX_HACT2),  // Horizontal Active
								.VACT(PX_VACT2)   // Vertical Active		
                );
 
  sensor12bits #(.ncols(PIXELS_IN_LINE),.nrows(LINES_IN_FRAME),.t_afterHACT(100),.nVLO(7000)) 
i_sensor12bits3(.MCLK(PX_DCLK3),	// Master clock
								.MRST(PX_MRST3),	// Master Reset - active low
								.ARO (PX_ARO3),	  // Array read Out.
								.ARST(PX_ARST3),	// Array Reset. Active low
								.OE  (1'b0),      // output enable active low
								.SCL (PX_SCL3),   // I2C clock
								.SDA (PX_SDA3),	  // I2C data
								.OFST(1'b1),      // I2C address ofset by 2: for simulation 0 - still mode, 1 - video mode.
								.D   (PXD3[11:0]),// [9:0] data output
								.DCLK(),          // Data output clock
								.BPF (PX_BPF3),   // Black Pixel Flag
								.HACT(PX_HACT3),  // Horizontal Active
								.VACT(PX_VACT3)   // Vertical Active		
                );
								
parameter I2CDLY = 10;

   task i2c_start;  // SCL is supposed to be 1, SDA - released
     begin
       $display ("i2c START at %t", $time);
       HOST_SDA=1;
       HOST_SCL=1;
       HOST_SDA_EN=0;
       HOST_SCL_EN=1;
       wait (~I2C_CLK);wait (I2C_CLK);
       HOST_SDA_EN=1;
       HOST_SDA=0;
       wait (~I2C_CLK);wait (I2C_CLK);
       HOST_SCL=0;
     end
   endtask   

   task i2c_stop;  // SCL is supposed to be 0, SDA - any
     begin
       $display ("i2c STOP at %t", $time);
       HOST_SCL=0;
       HOST_SCL_EN=1;
       wait (~I2C_CLK);wait (I2C_CLK); // wait for bus turnover (it was likely reading ACKN)
       HOST_SDA=0;
       HOST_SDA_EN=1;
       wait (~I2C_CLK);wait (I2C_CLK);
       HOST_SCL=1;
       wait (~I2C_CLK);wait (I2C_CLK);
       HOST_SDA=1;
       wait (~I2C_CLK);wait (I2C_CLK);
       HOST_SDA_EN=0;
     end
   endtask
   
   task i2c_restart;  // SCL is supposed to be 0, SDA - any
     begin
       $display ("i2c RESTART at %t", $time);
       HOST_SCL=0;
       HOST_SCL_EN=1;
       wait (~I2C_CLK);wait (I2C_CLK); // wait for bus turnover (it was likely reading ACKN)
       HOST_SDA=1;
       HOST_SDA_EN=1;
       wait (~I2C_CLK);wait (I2C_CLK);
       HOST_SCL=1;
       HOST_SDA_EN=0;
       wait (~I2C_CLK);wait (I2C_CLK);
       HOST_SDA=0;
       HOST_SDA_EN=1;
       wait (~I2C_CLK);wait (I2C_CLK);
       HOST_SCL=0;
     end
   endtask

   task i2c_sendbyte;  // SCL is supposed to be 0, SDA - any
     input [7:0] b;
     reg ackn;
     integer i;
     begin
       $display ("i2c send (%x) at %t", b,$time);
       HOST_SCL=0;
       HOST_SCL_EN=1;
       wait (~I2C_CLK);wait (I2C_CLK); // wait for bus turnover (it was reading ACKN)
       for (i=7;i>=0;i=i-1) begin
//         # (I2CDLY);
         HOST_SDA=b[i];
         HOST_SDA_EN=1;
         wait (~I2C_CLK);wait (I2C_CLK);
         HOST_SCL=1;
         if (HOST_SDA) begin
           HOST_SDA_EN=0;
         end
         wait (~I2C_CLK);wait (I2C_CLK);
         HOST_SCL=0;
       end
       HOST_SDA_EN=0; // float for acknowledge
       wait (~I2C_CLK);wait (I2C_CLK);
       ackn=SDA0;
       #1;
       $display ("i2c acknowledge (%x)", ackn);
       HOST_SCL=1;
       wait (~I2C_CLK);wait (I2C_CLK);
       HOST_SCL=0;
     end
   endtask   

   task i2c_readbyte;  // SCL is supposed to be 0, SDA - any (more)
     input more;
     reg [7:0] d;
     integer i;
     begin
       $display ("i2c read (more=%x) at %t", more, $time);
       HOST_SCL=0;
       HOST_SCL_EN=1;
       HOST_SDA_EN=0;
       for (i=7;i>=0;i=i-1) begin
         wait (~I2C_CLK);wait (I2C_CLK);
         d[i]=SDA0;
         #1;
         HOST_SCL=1;
         wait (~I2C_CLK);wait (I2C_CLK);
         HOST_SCL=0;
       end
//       # (I2CDLY);
       wait (~I2C_CLK);wait (I2C_CLK); // wait for bus turnover (it was reading)
       HOST_SDA=~more;
       HOST_SDA_EN=1; 
       wait (~I2C_CLK);wait (I2C_CLK);
       HOST_SCL=1;
       if (HOST_SDA) begin
         HOST_SDA_EN=0;
       end
       wait (~I2C_CLK);wait (I2C_CLK);
       HOST_SCL=0;
       $display ("i2c read returned %x", d);
     end
   endtask   

   task i2c_readbyte2;  // SCL is supposed to be 0, SDA - any (more)
     input more;
	  output [7:0] d;
     reg [7:0] d;
     integer i;
     begin
       $display ("i2c read (more=%x) at %t", more, $time);
       HOST_SCL=0;
       HOST_SCL_EN=1;
       HOST_SDA_EN=0;
       for (i=7;i>=0;i=i-1) begin
         wait (~I2C_CLK);wait (I2C_CLK);
         d[i]=SDA0;
         #1;
         HOST_SCL=1;
         wait (~I2C_CLK);wait (I2C_CLK);
         HOST_SCL=0;
       end
//       # (I2CDLY);
       wait (~I2C_CLK);wait (I2C_CLK); // wait for bus turnover (it was reading)
       HOST_SDA=~more;
       HOST_SDA_EN=1; 
       wait (~I2C_CLK);wait (I2C_CLK);
       HOST_SCL=1;
       if (HOST_SDA) begin
         HOST_SDA_EN=0;
       end
       wait (~I2C_CLK);wait (I2C_CLK);
       HOST_SCL=0;
       $display ("i2c read returned %x", d);
     end
   endtask 

		task i2c_send_4_bytes;
			input [31:0] di;
			begin
				i2c_sendbyte(di[31:24]);
				i2c_sendbyte(di[23:16]);
				i2c_sendbyte(di[15:8]);
				i2c_sendbyte(di[7:0]);
			end	
		endtask
		
		task i2c_send_2_bytes;
			input [15:0] di;
			begin
				i2c_sendbyte(di[15:8]);
				i2c_sendbyte(di[7:0]);
			end	
		endtask

endmodule

