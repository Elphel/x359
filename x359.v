/*!***************************************************************************
*! FILE NAME  : x359.v
*! DESCRIPTION: Top module
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
*!  $Log: x359.v,v $
*!  Revision 1.30  2012/01/12 21:54:03  dzhimiev
*!  1. Added thermometers' individual addresses
*!
*!  Revision 1.29  2010/11/11 21:30:53  dzhimiev
*!  1. corrected hact_regen register - used to handle Value+1 - now just Value
*!
*!  Revision 1.28  2010/08/17 23:44:08  elphel
*!  0359a053 - fixed timing constraints
*!
*!  Revision 1.27  2010/08/13 19:08:35  elphel
*!  8.0.8.42 modified 10359 FPGA code to prevent sensor from (sometimes) locking at 180-degree shifted clock.
*!
*!  Revision 1.26  2010/08/11 22:09:53  elphel
*!  8.0.8.40 - x359 updated
*!
*!  Revision 1.25  2010/08/11 16:47:40  elphel
*!  0359a051 -  replaced sesnor clock output buffers with ODDR2/constant inputs
*!
*!  Revision 1.24  2010/08/10 16:23:14  dzhimiev
*!  1. separated addresses for EEPROMS:
*!  0x5000 - 10359
*!  0x5200 - J2
*!  0x5400 - J3
*!  0x5600 - J4
*!
*!  Revision 1.15  2010/05/19 22:29:24  dzhimiev
*!  1. corrected mem_test
*!  2. some slight changes
*!
*!  Revision 1.13  2010/05/14 18:48:36  dzhimiev
*!  1. added hacts shifts for buffered channels
*!  2. set fixed SDRAM spaces
*!
*!
*/
`timescale 1 ns / 1 ps

module x359(
            RUN,       //low when programmed (switches external AND gate)
// SDRAM interface
            SDCLKE,    // SDRAM clock enable
            SDNCLK_FB, // SDRAM clock feedback inverted
            SDCLK,     // SDRAM clock inverted
            SDNCLK,    // SDRAM clock non-inverted
            SDCLK_FB,  // SDRAM clock feedback non-inverted
            SDLDM,     // SDRAM mask (low  byte)
            SDUDM,     // SDRAM mask (high byte)

            SDWE,      // SDRAM WE
            SDCAS,     // SDRAM CAS
            SDRAS,     // SDRAM RAS

            SDA,       // SDRAM address {BA[1:0],A[12:0]}
            SDD,       // SDRAM data bus D[15:0]
            UDQS,      // SDRAM data strobe - high byte
            LDQS,      // SDRAM data strobe - low byte
// port to host (simulating CMOS 5MPix interface)
            PXD,        // pixel data [11:2] to 10353
            DCLK,       // pixel clock from 10353
            BPF,        // pixel clock to 10353
            HACT,       // line sync   to 10353
            VACT,       // frame sync  to 10353
            MRST,       // sensor reset (from 10353)
            ARO,        // sensor trigger (from 10353)
            ARST,       // sensor standby (from 10353)
            SCL0,       // i2c clock from 10353
            SDA0,       // i2c data  from/to 10353
            CNVSYNC,    // pixel data [0] to 10353 (DC-DC converter sync from 10353)
            CNVCLK,     // pixel data [1] to 10353 (DC-DC converter clock from 10353)

// port 1 to sensor board
            PXD1,       // pixel data [11:2] from sensor
            PX_DCLK1,   // pixel clock to sensor
            PX_BPF1,    // pixel clock from sensor
            PX_HACT1,   // line sync   from sensor
            PX_VACT1,   // frame sync  from sensor
            PX_MRST1,   // sensor reset to sensor
            PX_ARO1,    // sensor trigger to sensor
            PX_ARST1,   // sensor standby to sensor
            PX_SCL1,    // i2c clock to sensor
            PX_SDA1,    // i2c data  to/from sensor
//            PX_CNVSYNC1,// pixel data [0] from sensor (DC-DC converter sync to sensor)
//            PX_CNVCLK1, // pixel data [1] from sensor (DC-DC converter clock to sensor)
            SENSPGM1,   // program attached sensor FPGA 

// port 2 to sensor board
            PXD2,       // pixel data [11:2] from sensor
            PX_DCLK2,   // pixel clock to sensor
            PX_BPF2,    // pixel clock from sensor
            PX_HACT2,   // line sync   from sensor
            PX_VACT2,   // frame sync  from sensor
            PX_MRST2,   // sensor reset to sensor
            PX_ARO2,    // sensor trigger to sensor
            PX_ARST2,   // sensor standby to sensor
            PX_SCL2,    // i2c clock to sensor
            PX_SDA2,    // i2c data  to/from sensor
//            PX_CNVSYNC2,// pixel data [0] from sensor (DC-DC converter sync to sensor)
//            PX_CNVCLK2, // pixel data [1] from sensor (DC-DC converter clock to sensor)
            SENSPGM2,   // program attached sensor FPGA 

// port 3 to sensor board
            PXD3,       // pixel data [11:2] from sensor
            PX_DCLK3,   // pixel clock to sensor
            PX_BPF3,    // pixel clock from sensor
            PX_HACT3,   // line sync   from sensor
            PX_VACT3,   // frame sync  from sensor
            PX_MRST3,   // sensor reset to sensor
            PX_ARO3,    // sensor trigger to sensor
            PX_ARST3,   // sensor standby to sensor
            PX_SCL3,    // i2c clock to sensor
            PX_SDA3,    // i2c data  to/from sensor
//            PX_CNVSYNC3,// pixel data [0] from sensor (DC-DC converter sync to sensor)
//            PX_CNVCLK3, // pixel data [1] from sensor (DC-DC converter clock to sensor)
            SENSPGM3    // program attached sensor FPGA 
            ,ALWAYS0    // pull-down to have 0 that compiler does not n\know is a constant
				,AUXSDA // i2c data bus to EEPROM
				,AUXSCL // i2c data bus to a ClockGenerator
				,CLK2	  // clk2 from the ClockGenerator
				,CLK1   // clk1 from the ClockGenerator
				,CLK0   // clk0 from the ClockGenerator
				);

		parameter MODELREV=32'h0359a054; // taking care of sensors' thermometers
//		parameter MODELREV=32'h0359a053; // timing constraints
//		parameter MODELREV=32'h0359a052; // opposite phase for making MRST*, ARO*, ARST* sync to clock to sensors
//		parameter MODELREV=32'h0359a051; // making MRST*, ARO*, ARST* sync to clock to sensors
//		parameter MODELREV=32'h0359a051; // replaced sensor clock output buffers with ODDR2/constant inputs
//		parameter MODELREV=32'h0359a050;
		
		wire USE5MPIX; // later will add control, currently - compile-time
	 
		output		RUN;

// DDR SDRAM interface 
		output		SDCLKE;
		input			SDNCLK_FB;
		output		SDCLK;
		output		SDNCLK;
		input			SDCLK_FB;
		output		SDLDM;
		output		SDUDM;
		
		output		SDWE;
		output		SDCAS;
		output		SDRAS;
		
		output [14:0]	SDA;
		inout  [15:0]	SDD;
		inout 		UDQS;
		inout 		LDQS;

// port to host (simulating CMOS 5MPix interface)
		output [9:0]  PXD;       // pixel data [11:2] to 10353
		input         DCLK;      // pixel clock from 10353
		output        BPF;       // pixel clock to 10353
		output        HACT;      // line sync   to 10353
		output        VACT;      // frame sync  to 10353
		input         MRST;      // sensor reset (from 10353)
		input         ARO;       // sensor trigger (from 10353)
		input         ARST;      // sensor standby (from 10353)
		inout         SCL0;      // i2c clock from 10353
		inout         SDA0;      // i2c data  from/to 10353
		inout         CNVSYNC;   // pixel data [0] to 10353 (DC-DC converter sync from 10353)
		inout         CNVCLK;    // pixel data [1] to 10353 (DC-DC converter clock from 10353)
		
		inout  [11:0] PXD1;       // pixel data [11:2] from sensor
		output        PX_DCLK1;   // pixel clock to sensor
		input         PX_BPF1;    // pixel clock from sensor
		input         PX_HACT1;   // line sync   from sensor
		input         PX_VACT1;   // frame sync  from sensor
		output        PX_MRST1;   // sensor reset to sensor
		output        PX_ARO1;    // sensor trigger to sensor
		output        PX_ARST1;   // sensor standby to sensor
		inout         PX_SCL1;    // i2c clock to sensor
		inout         PX_SDA1;    // i2c data  to/from sensor
//    inout         PX_CNVSYNC1;// pixel data [0] from sensor (DC-DC converter sync to sensor)
//    inout         PX_CNVCLK1; // pixel data [1] from sensor (DC-DC converter clock to sensor)
		inout         SENSPGM1;   // program attached sensor FPGA 
		
		inout  [11:0] PXD2;       // pixel data [11:2] from sensor
		output        PX_DCLK2;   // pixel clock to sensor
		input         PX_BPF2;    // pixel clock from sensor
		input         PX_HACT2;   // line sync   from sensor
		input         PX_VACT2;   // frame sync  from sensor
		output        PX_MRST2;   // sensor reset to sensor
		output        PX_ARO2;    // sensor trigger to sensor
		output        PX_ARST2;   // sensor standby to sensor
		inout         PX_SCL2;    // i2c clock to sensor
		inout         PX_SDA2;    // i2c data  to/from sensor
//    inout         PX_CNVSYNC2;// pixel data [0] from sensor (DC-DC converter sync to sensor)
//    inout         PX_CNVCLK2; // pixel data [1] from sensor (DC-DC converter clock to sensor)
		inout         SENSPGM2;   // program attached sensor FPGA 
		
		inout  [11:0] PXD3;       // pixel data [11:2] from sensor
		output        PX_DCLK3;   // pixel clock to sensor
		input         PX_BPF3;    // pixel clock from sensor
		input         PX_HACT3;   // line sync   from sensor
		input         PX_VACT3;   // frame sync  from sensor
		output        PX_MRST3;   // sensor reset to sensor
		output        PX_ARO3;    // sensor trigger to sensor
		output        PX_ARST3;   // sensor standby to sensor
		inout         PX_SCL3;    // i2c clock to sensor
		inout         PX_SDA3;    // i2c data  to/from sensor
//    inout         PX_CNVSYNC3;// pixel data [0] from sensor (DC-DC converter sync to sensor)
//    inout         PX_CNVCLK3; // pixel data [1] from sensor (DC-DC converter clock to sensor)
		inout         SENSPGM3;   // program attached sensor FPGA 
	
		inout ALWAYS0;  // will be pulled down to fool the software - it does not know it is always 0.

		inout AUXSDA; // i2c data bus to EEPROM
		inout AUXSCL; // i2c data bus to a ClockGenerator
		input CLK2;	  // clk2 from the ClockGenerator
		input CLK1;   // clk1 from the ClockGenerator
		input CLK0;   // clk0 from the ClockGenerator
	
	wire       nevr;
	wire       sdcl_fb,idclk,imrst,iaro,iarst;
	wire       ipx_bpf1,ipx_hact1,ipx_vact1;
	wire       ipx_bpf2,ipx_hact2,ipx_vact2;
	wire       ipx_bpf3,ipx_hact3,ipx_vact3;
	wire [11:0] ipxd1;
	wire [11:0] ipxd2;
	wire [11:0] ipxd3;
	wire        pclk;
	wire         isdclk=nevr;
	wire         never= nevr & sdcl_fb && idclk && imrst && iaro && iarst;// &&
//							&ipxd1[11:0] && ipx_bpf1 && ipx_hact1 && ipx_vact1 &&
//							&ipxd2[11:0] && ipx_bpf2 && ipx_hact2 && ipx_vact2 &&
//							&ipxd3[11:0] && ipx_bpf3 && ipx_hact3 && ipx_vact3;
                        
	wire       icnvsync, icnvclk;
	wire       ipx_cnvsync1, ipx_cnvclk1;
	wire       ipx_cnvsync2, ipx_cnvclk2;
	wire       ipx_cnvsync3, ipx_cnvclk3;
	wire       ipx_dclk1, ipx_dclk2, ipx_dclk3;

	reg         ivact=0;
	reg         ihact=0;
	reg  [11:0] pxdr=0;
	reg         ibpf=0;

	reg         mrstr,aror,arstr;
	reg         data12bits, data10bits;

	reg [31:0]	sddo_p;	// data out to SDRAM, input to pad FF
	wire [31:0]	sddi_r;	// data from SDRAM  (1 cycle delayed)
	reg  [1:0] 	sddm_p; 	// write mask (sync with data)
	reg [12:0]	sda_p;	// SDRAM address,  input to pad FF
	reg [ 1:0]	sdba_p;	// same as above	
	wire [ 9:0]	sens_a;	// [7:0] channel 0 address (MSB - block #)
	wire [15:0]	sens_d;	// [15:0] channel 0 data in
	wire [15:0]	fpn_d;	
	reg [11:0]  ch1a=0;
	//wire [11:0]	 ch1a;	// SDRAM channel 1 buffer address	 
	wire [15:0]	ch1do;	// SDRAM channel 1 data out
	reg [11:0]  ch3a_buffered=0;
	reg [11:0]  ch3a=0;
	//wire [11:0]	 ch3a;	// SDRAM channel 3 buffer address	 
	wire [15:0]	ch3do;		// SDRAM channel 3 data out
	reg [11:0]  ch5a=0;
	//wire [11:0]	 ch5a;	// SDRAM channel 5 buffer address	 
	wire [15:0]	ch5do;		// SDRAM channel 5 data out
			
	reg trig_aro1=0, trig_aro2=0;
	reg aror1=1,aror2=1,aror3=1;

	wire sclk0;	
		
	wire     ipx_mrst1	= mrstr, 		ipx_mrst2	= mrstr, 		ipx_mrst3	= mrstr;
	
	// aro - trigger signal
	//wire     ipx_aro1		=  aror, 		ipx_aro2	=  aror2, 		ipx_aro3	=  aror3;
	wire     ipx_aro1		=  aror, 		ipx_aro2	=  aror, 		ipx_aro3	=  aror;
	//wire     ipx_aro1		=  trig_aro1, 		ipx_aro2	=  trig_aro2, 		ipx_aro3	=  aror;
	wire     ipx_arst1	= arstr, 		ipx_arst2	= arstr, 		ipx_arst3	= arstr;
			
	assign     ipx_cnvsync1 = icnvsync;
	assign     ipx_cnvclk1  = icnvclk;
	
	assign     ipx_cnvsync2 = icnvsync;
	assign     ipx_cnvclk2  = icnvclk;
	
	assign     ipx_cnvsync3 = icnvsync;
	assign     ipx_cnvclk3  = icnvclk;
	
	PULLDOWN    i_PD_ALWAYS0(.O(ALWAYS0));
	
/***IMPORTANT***/
/*
  RUN should be delayed 2 TCK cycles, otherwise CCLK ("R14") pin would not be enabled
  Just switching "startup options" to output events to (maximal) 6-th cycle (from default 5-th)
  is insufficient, with defualt (5-th) and 2 stage register it is OK
*/
   reg [1:0] irun=2'b00;
   always @ (posedge iaro) begin
     irun[1:0] <= {irun[0],1'b1};
   end
	OBUF i_RUN (.I(!irun[1]),.O(RUN));
	IBUF i_always0 (.I(ALWAYS0),.O(nevr));

	reg SDCLKE_r=1'b0;
	always @ (negedge pclk) begin
		SDCLKE_r <= 1'b1;
	end	  
	
	//clock enable for SDRAM
	OBUF     i_SDCLKE (.I(SDCLKE_r), .O(SDCLKE));	
	IBUFDS   i_sdcl_fb(.O(sdcl_fb),.I(SDNCLK_FB),.IB(SDCLK_FB));

	assign PXD[9:0]=pxdr[11:2];

	OBUF     i_BPF     (.I(ibpf), .O( BPF)); //not used
	OBUF     i_HACT    (.I(ihact),.O(HACT)); // horizontal sync
	OBUF     i_VACT    (.I(ivact),.O(VACT)); // vertical sync
	IBUF     i_DCLK    (.I(DCLK),.O(idclk)); // sensor clk
	IBUF     i_MRST    (.I(MRST),.O(imrst)); // sensor reset
	IBUF     i_ARO     (.I(ARO),  .O(iaro)); // sensor trigger signal
	IBUF     i_ARST    (.I(ARST),.O(iarst)); // sensor reset

	wire new_clk2;
	wire new_clk1;
	wire new_clk0;	

//  IOBUF    i_CNVSYNC (.I(pxdr[ 0]), .T(data10bits), .O(icnvsync), .IO(CNVSYNC));
//  IOBUF    i_CNVCLK  (.I(pxdr[ 1]), .T(data10bits), .O(icnvclk), .IO(CNVCLK));

	assign CNVCLK =pxdr[1];
	assign CNVSYNC=pxdr[0];  

//IOBUF    i_PXD100     (.I(ipx_cnvsync1), .T(data12bits), .IO(PXD1[ 0]), .O(ipxd1[ 0]));
//IOBUF    i_PXD101     (.I(ipx_cnvclk1),  .T(data12bits), .IO(PXD1[ 1]), .O(ipxd1[ 1]));
 
	wire sensor_clock;//pclk;

//	OBUF     i_PX_DCLK1   (.I(sensor_clock),     .O(PX_DCLK1));
//   ODDR2 i_PX_DCLK1(.Q(PX_DCLK1),.C0(sensor_clock), .C1(~sensor_clock), .CE(1'b1),.D0(1'b1),  .D1(1'b0) );
// suspecting sensor sometime getting opposite phase shift between input clock and output, making
// all signals to sensor exactly sync to that clock by adding IOB FFs. Chnage clock polarity to the opposite
// and try again.
// Condition is rather rare, but we got sevaral cameras  taht all had 3-rd sensor phase wrong in >50% times

wire sensor_clk_reg=~sensor_clock; /// may adjust phase (+/-) here
wire sensor_clk_reg0=sensor_clock; /// may adjust phase (+/-) here

wire PX_DCLK1_INT, PX_DCLK2_INT, PX_DCLK3_INT;
wire PX_ARST1_INT, PX_ARST2_INT, PX_ARST3_INT;
wire PX_ARO1_INT,  PX_ARO2_INT,  PX_ARO3_INT;
wire PX_MRST1_INT, PX_MRST2_INT, PX_MRST3_INT;
// THe following layer of registers is needed to ease timing requirements
// (otherwise there is a long routing delay). Outpur registers are locked to the pads
wire PX_ARST1_INT0, PX_ARST2_INT0, PX_ARST3_INT0;
wire PX_ARO1_INT0,  PX_ARO2_INT0,  PX_ARO3_INT0;
wire PX_MRST1_INT0, PX_MRST2_INT0, PX_MRST3_INT0;
   ODDR2 i_PX_DCLK1(.Q(PX_DCLK1_INT),.C0(sensor_clock), .C1(~sensor_clock), .CE(1'b1),.D0(1'b1),  .D1(1'b0) );
	OBUF  i_PX_DCLK1B   (.I(PX_DCLK1_INT),     .O(PX_DCLK1));

/*
	wire     ipx_mrst1	= mrstr, 		ipx_mrst2	= mrstr, 		ipx_mrst3	= mrstr;
	wire     ipx_aro1		=  aror, 		ipx_aro2	=  aror, 	    	ipx_aro3	=  aror;
	wire     ipx_arst1	= arstr, 		ipx_arst2	= arstr, 		ipx_arst3	= arstr;

*/

// PX_*_INT0 should not be duplicated, so all outputs will be guaranteed simultaneous when crossing
/// clock domains

(* KEEP = "TRUE" *)   FD       i_PX_MRST_INT0(.D(mrstr), .Q(PX_MRST_INT0),  .C(sensor_clk_reg0));
(* KEEP = "TRUE" *)   FD       i_PX_ARST_INT0(.D(arstr), .Q(PX_ARST_INT0), .C(sensor_clk_reg0));
(* KEEP = "TRUE" *)   FD       i_PX_ARO_INT0 (.D(aror),  .Q(PX_ARO_INT0),   .C(sensor_clk_reg0));

(* KEEP = "TRUE" *)   FD       i_PX_MRST_INT1(.D(PX_MRST_INT0), .Q(PX_MRST_INT1),  .C(sensor_clk_reg));
(* KEEP = "TRUE" *)   FD       i_PX_ARST_INT1(.D(PX_ARST_INT0), .Q(PX_ARST_INT1), .C(sensor_clk_reg));
(* KEEP = "TRUE" *)   FD       i_PX_ARO_INT1 (.D(PX_ARO_INT0),  .Q(PX_ARO_INT1),   .C(sensor_clk_reg));

  
(* IOB = "FORCE" *)   FD       i_PX_MRST1_INT(.D(PX_MRST_INT1), .Q(PX_MRST1_INT), .C(sensor_clk_reg));
(* IOB = "FORCE" *)   FD       i_PX_MRST2_INT(.D(PX_MRST_INT1), .Q(PX_MRST2_INT), .C(sensor_clk_reg));
(* IOB = "FORCE" *)   FD       i_PX_MRST3_INT(.D(PX_MRST_INT1), .Q(PX_MRST3_INT), .C(sensor_clk_reg));

(* IOB = "FORCE" *)   FD       i_PX_ARST1_INT(.D(PX_ARST_INT1), .Q(PX_ARST1_INT), .C(sensor_clk_reg));
(* IOB = "FORCE" *)   FD       i_PX_ARST2_INT(.D(PX_ARST_INT1), .Q(PX_ARST2_INT), .C(sensor_clk_reg));
(* IOB = "FORCE" *)   FD       i_PX_ARST3_INT(.D(PX_ARST_INT1), .Q(PX_ARST3_INT), .C(sensor_clk_reg));

(* IOB = "FORCE" *)   FD       i_PX_ARO1_INT(.D(PX_ARO_INT1),   .Q(PX_ARO1_INT), .C(sensor_clk_reg));
(* IOB = "FORCE" *)   FD       i_PX_ARO2_INT(.D(PX_ARO_INT1),   .Q(PX_ARO2_INT), .C(sensor_clk_reg));
(* IOB = "FORCE" *)   FD       i_PX_ARO3_INT(.D(PX_ARO_INT1),   .Q(PX_ARO3_INT), .C(sensor_clk_reg));


	IBUFG    i_PX_BPF1    (.I(PX_BPF1),          .O(ipx_bpf1));
	OBUF     i_PX_MRST1   (.I(PX_MRST1_INT),        .O(PX_MRST1));
	OBUF     i_PX_ARO1    (.I(PX_ARO1_INT),         .O(PX_ARO1));
	OBUF     i_PX_ARST1   (.I(PX_ARST1_INT),        .O(PX_ARST1));
	IOBUF    i_SENSPGM1   (.I(1'b0), .T(!never), .O(), .IO(SENSPGM1));

//	OBUF     i_PX_DCLK2   (.I(sensor_clock),     .O(PX_DCLK2));
//   ODDR2 i_PX_DCLK2(.Q(PX_DCLK2),.C0(sensor_clock), .C1(~sensor_clock), .CE(1'b1),.D0(1'b1),  .D1(1'b0) );
   ODDR2 i_PX_DCLK2      (.Q(PX_DCLK2_INT),.C0(sensor_clock), .C1(~sensor_clock), .CE(1'b1),.D0(1'b1),  .D1(1'b0) );
	OBUF  i_PX_DCLK2B     (.I(PX_DCLK2_INT),     .O(PX_DCLK2));
   
	IBUF     i_PX_BPF2    (.I(PX_BPF2),          .O(ipx_bpf2));
	OBUF     i_PX_MRST2   (.I(PX_MRST2_INT),        .O(PX_MRST2));
	OBUF     i_PX_ARO2    (.I(PX_ARO2_INT),         .O(PX_ARO2));
	OBUF     i_PX_ARST2   (.I(PX_ARST2_INT),        .O(PX_ARST2));
	IOBUF    i_SENSPGM2   (.I(1'b0), .T(!never), .O(), .IO(SENSPGM2));

//	OBUF     i_PX_DCLK3   (.I(sensor_clock),     .O(PX_DCLK3));
//   ODDR2 i_PX_DCLK3(.Q(PX_DCLK3),.C0(sensor_clock), .C1(~sensor_clock), .CE(1'b1),.D0(1'b1),  .D1(1'b0) );
   ODDR2 i_PX_DCLK3      (.Q(PX_DCLK3_INT),.C0(sensor_clock), .C1(~sensor_clock), .CE(1'b1),.D0(1'b1),  .D1(1'b0) );
	OBUF  i_PX_DCLK3B     (.I(PX_DCLK3_INT),     .O(PX_DCLK3));

	IBUF     i_PX_BPF3    (.I(PX_BPF3),          .O(ipx_bpf3));
	OBUF     i_PX_MRST3   (.I(PX_MRST3_INT),        .O(PX_MRST3));
	OBUF     i_PX_ARO3    (.I(PX_ARO3_INT),         .O(PX_ARO3));
	OBUF     i_PX_ARST3   (.I(PX_ARST3_INT),        .O(PX_ARST3));
	IOBUF    i_SENSPGM3   (.I(1'b0), .T(!never), .O(), .IO(SENSPGM3));

	IBUFG i_CLK2(.I(CLK2),.O(new_clk2));	// clk2 from the ClockGenerator	
	IBUFG i_CLK1(.I(CLK1),.O(new_clk1));   // clk1 from the ClockGenerator
	IBUFG i_CLK0(.I(CLK0),.O(new_clk0));   // clk0 from the ClockGenerator

	reg [3:0] i2c_cnt=2'b0;
	reg [7:0] i2c_reg_addr=8'b0;	
	wire	[ 7:0]	ia=i2c_reg_addr;		// internal address bus - before latches

	BUFG i_pclk (.I(idclk), .O(pclk)); 
	
	wire pre_sclk0, pre_sclk90, pre_sclk180, pre_sclk270;	
	wire sclk90, sclk180, sclk270;
	 
	reg  [31:0] idi=32'hffffffff;// this is the system bus - filled by i2c
	reg  [15:0] idi_d=0;

	reg select_clk=0; // set to pclk by default

	BUFGMUX BUFGMUX_inst (
	  .O (sensor_clock), // Clock MUX output
	  .I0(pclk),         // Clock0 input
	  .I1(new_clk0),     // Clock1 input
	  .S (select_clk)    // Clock select input
	);

////////////////////////////////////////////////////////////////////////////////////////////////////
// DCM1 - generates sclk0 (system clock)
////////////////////////////////////////////////////////////////////////////////////////////////////
wire da_dcm1;
wire [7:0] dcm1_status;
wire       dcm1_locked;
reg [8:0]  dcm1_reg=0;
reg [1:0]  dcm1_ph90=0;
wire [8:0] dcm1_phase_wire;
wire [1:0] dcm1_phase90_wire;

 dcm_phase #(.NO_SHIFT90(1)) i_dcm_359_1 (
	.cclk(~pclk),    // command clock for shift
	.wcmd(da_dcm1), // decoded address - enables wclk
   .cmd(idi[3:0]), // CPU write data [3:0]
	        	       //  0 - nop, just reset status data
	        	       //  1 - increase phase shift
	        	       //  2 - decrease phase shift
	        	       //  3 - reset phase shift to default (preprogrammed in FPGA configuration)
	        	       //  4 - incr pahse90
	        	       //  8 - decrease phase90											
	        	       //  c - reset phase90
	.iclk(pclk),    // DCM input clock
	.clk_fb(sclk0), // feed back clock
	.clk0(sclk0),   // global output clock, phase 0
	.clk90(sclk90), // global output clock, phase 90
	.clk180(sclk180),// global output clock, phase 180							
	.clk270(sclk270),// global output clock, phase 270
	
	.dcm_phase   (dcm1_phase_wire[8:0]),   // current DCM phase (small steps)
	.dcm_phase_90(dcm1_phase90_wire[1:0]),// current DCM quarter (90 degrees steps)
	.dcm_done(),    // DCM command done
	.dcm_status(dcm1_status[7:0]),  // DCM status (bit 1 - dcm clkin stopped)
	.dcm_locked(dcm1_locked)   // DCM "Locked" pin
);

	always @ (negedge pclk) begin
		dcm1_ph90[1:0] <= dcm1_phase90_wire[1:0];
		dcm1_reg[8:0] <= dcm1_phase_wire[8:0]; //dcm1 phase counter register in clk0 domain
	end

	wire [2:0] fvact;

	reg [13:0] dir_N_fl=1940;
	reg [15:0] dir_N_fp=2596;
	
	reg [2:0] hact_regen=0; // regen for hacts in sensor_phase353 modules

////////////////////////////////////////////////////////////////////////////////////////////////////
// DCM1 - clock for the 1st sensor (channel 0)
////////////////////////////////////////////////////////////////////////////////////////////////////
	wire spx_vact1;
	wire spx_hact1;
	wire [13:0] spxd1;

	wire da_dcm_s1;
	reg dcm_s1_en;
	reg dcm_s1_incdec;
	reg [8:0] dcm_s1_reg=0;
	reg [8:0] dcm_s1_cnt=0;
	reg [7:0] dclk1_cnt=0;
	
	reg [1:0] dcm_s1_ph90=0;	
 
	always @ (negedge pclk) begin
		dcm_s1_en     <= da_dcm_s1 & (idi[1]!=idi[0]);
		dcm_s1_incdec <= da_dcm_s1 & idi[0];
	
		if (da_dcm_s1 & idi[1] & idi[0]) dcm_s1_cnt <= 0;
		else if (dcm_s1_en)
			if (dcm_s1_incdec) dcm_s1_cnt <= dcm_s1_cnt + 1;
			else               dcm_s1_cnt <= dcm_s1_cnt - 1;
			
		if (da_dcm_s1) begin
			if      (idi[2] & idi[3]) dcm_s1_ph90[1:0] <= 2'h0;
			else if (idi[2])          dcm_s1_ph90[1:0] <= dcm_s1_ph90[1:0] +1;
			else if (idi[3])          dcm_s1_ph90[1:0] <= dcm_s1_ph90[1:0] -1;
		end				
			
	end

	always @ (negedge pclk) begin
		dcm_s1_reg[8:0] <= dcm_s1_cnt[8:0];
	end

	wire sp0_clk;
	wire sp0_vact;
	wire sp0_hact;
	wire [11:0] sp0_data;
	
	wire       dclk1_locked;
	wire       dclk1_done;
	wire [7:0] dclk1_status;
	
	sensor_phase353_vact i_sp0(
	  .cclk(~pclk),       // command clock (posedge, invert on input if needed)
	  .wcmd(da_dcm_s1),       // write command
	  .cmd(idi[5:0]),        // CPU write data [5:0]
                 //       0 - nop, just reset status data
                 //       1 - increase phase shift
                 //       2 - decrease phase shift
                 //       3 - reset phase shift to default (preprogrammed in FPGA configuration)
                 //       c - reset phase90
                 //       4 - incr pahse90
                 //       8 - decrease phase90
                 //       10 - increase hact/vact phase
                 //       20 - decrease hact/vact phase
                 //       30 - reset hact/vact phase
	  .HACT(PX_HACT1),       //   sensor HACT I/O pin (input), used to reset FIFO
	  .VACT(PX_VACT1),       //   sensor VACT I/O pin (input)
	  .DI(PXD1),         //   sensor D[11:0] i/o pins (input)
 	  .iclk(sensor_clock),       //   global sensor input clock (posedge) - the clock that goes to all 3 sensors
	  .sclk(sclk0),       //   global FIFO output clock (posedge)
	  .shact(spx_hact1),      //   hact - sync to sclk
	  .svact(spx_vact1),      //   vact - sync to sclk
	  .fvact(fvact[0]),   // vact fall
	  .sdo(spxd1),        //   data output[11:0], sync to sclk
	  
     .debug(0),      // 2-bit debug mode input
     .hact_length(dir_N_fp[13:0]),// [13:0] WOI width-1 (to overwrite sensor HACT duration)
     .hact_regen(hact_regen[0]), // 0 - use hact from sensor, 1 - regenerate using hact_lengh	  
     .mode_12bits(1),// input, 1 -  enable 12/14 bit mode, 0 - 10 bit mode
     .mode_14bits(0),// input, 1 -  enable 14 bit mode, 0 - 12/10 bit mode
     .mode_alt(0),   //   enable alternative vact/hact input (sync to data)
     .sync_alt(0),   //   alternative HACT/VACT input pad (10347) (VACT - 1 clock, HACT >1)	  
	  .clkout(sp0_clk),
	  //.test_clk_out (),
	  //.test_vact_out(),
	  //.test_hact_out(),
	  //.test_data_out(),
	  .dcm_done(dclk1_done),   // DCM command done
	  .status  (dclk1_status), // DDM status (bit 1 - dcm clkin stopped)
	  .locked  (dclk1_locked)  // DCM locked
	);    

	assign     ipx_dclk1 = sclk0;

////////////////////////////////////////////////////////////////////////////////////////////////////
// DCM2 - clock for the 2nd sensor (channel 1)
////////////////////////////////////////////////////////////////////////////////////////////////////
	wire spx_vact2;
	wire spx_hact2;
	wire [13:0] spxd2;	

	wire da_dcm_s2;
	reg dcm_s2_en;
	reg dcm_s2_incdec;
	
	wire       dclk2_locked;
	wire       dclk2_done;
	wire [7:0] dclk2_status;
	
	reg [8:0] dcm_s2_reg=0;
	reg [8:0] dcm_s2_cnt=0;
	reg [7:0] dclk2_cnt=0;

	reg [1:0] dcm_s2_ph90=0;

	always @ (negedge pclk) begin
		dcm_s2_en     <= da_dcm_s2 & (idi[1]!=idi[0]);
		dcm_s2_incdec <= da_dcm_s2 & idi[0];
	
		if (da_dcm_s2 & idi[1] & idi[0])        dcm_s2_cnt <= 0;
		else if (dcm_s2_en)
			if (dcm_s2_incdec) dcm_s2_cnt <= dcm_s2_cnt + 1;
			else               dcm_s2_cnt <= dcm_s2_cnt - 1;
			
		if (da_dcm_s2) begin
			if      (idi[2] & idi[3]) dcm_s2_ph90[1:0] <= 2'h0;
			else if (idi[2])          dcm_s2_ph90[1:0] <= dcm_s2_ph90[1:0] +1;
			else if (idi[3])          dcm_s2_ph90[1:0] <= dcm_s2_ph90[1:0] -1;
		end						
		
	end

	always @ (negedge pclk) begin
		dcm_s2_reg[8:0] <= dcm_s2_cnt[8:0];
	end

	sensor_phase353 i_sp1(
	  .cclk(~pclk),       // command clock (posedge, invert on input if needed)
	  .wcmd(da_dcm_s2),       // write command
	  .cmd(idi[5:0]),        // CPU write data [5:0]
                 //       0 - nop, just reset status data
                 //       1 - increase phase shift
                 //       2 - decrease phase shift
                 //       3 - reset phase shift to default (preprogrammed in FPGA configuration)
                 //       c - reset phase90
                 //       4 - incr pahse90
                 //       8 - decrease phase90
                 //       10 - increase hact/vact phase
                 //       20 - decrease hact/vact phase
                 //       30 - reset hact/vact phase
	  .HACT(PX_HACT2),       //   sensor HACT I/O pin (input), used to reset FIFO
	  .VACT(PX_VACT2),       //   sensor VACT I/O pin (input)
	  .DI(PXD2),         //   sensor D[11:0] i/o pins (input)
 	  .iclk(sensor_clock),       //   global sensor input clock (posedge) - the clock that goes to all 3 sensors
	  .sclk(sclk0),       //   global FIFO output clock (posedge)
	  .shact(spx_hact2),      //   hact - sync to sclk
	  .svact(spx_vact2),      //   vact - sync to sclk
	  .fvact(fvact[1]),   // vact fall
     .debug(0),      // 2-bit debug mode input
     .hact_length(dir_N_fp[13:0]),// [13:0] WOI width-1 (to overwrite sensor HACT duration)
     .hact_regen(hact_regen[1]), // 0 - use hact from sensor, 1 - regenerate using hact_lengh	  	  
     .mode_12bits(1),// input, 1 -  enable 12/14 bit mode, 0 - 10 bit mode
     .mode_14bits(0),// input, 1 -  enable 14 bit mode, 0 - 12/10 bit mode
     .mode_alt(0),   //   enable alternative vact/hact input (sync to data)
     .sync_alt(0),   //   alternative HACT/VACT input pad (10347) (VACT - 1 clock, HACT >1)	  
	  .sdo(spxd2),        //   data output[11:0], sync to sclk
	  .dcm_done(dclk2_done),   // DCM command done
	  .status  (dclk2_status), // DDM status (bit 1 - dcm clkin stopped)
	  .locked  (dclk2_locked)  // DCM locked
	);  

	assign     ipx_dclk2 = sclk0;

////////////////////////////////////////////////////////////////////////////////////////////////////
// DCM3 - clock for the 3rd sensor (channel 2)
////////////////////////////////////////////////////////////////////////////////////////////////////
	wire spx_vact3;
	wire spx_hact3;
	wire [13:0] spxd3;

	wire da_dcm_s3;
	reg dcm_s3_en;
	reg dcm_s3_incdec;
	
	wire       dclk3_locked;
	wire       dclk3_done;
	wire [7:0] dclk3_status;
	
	reg [8:0] dcm_s3_reg=0;
	reg [8:0] dcm_s3_cnt=0;
	reg [7:0] dclk3_cnt=0;
	
	reg [1:0] dcm_s3_ph90=0;	
 
	always @ (negedge pclk) begin
		dcm_s3_en     <= da_dcm_s3 & (idi[1]!=idi[0]);
		dcm_s3_incdec <= da_dcm_s3 & idi[0];
	
		if (da_dcm_s3 & idi[1] & idi[0])       dcm_s3_cnt <= 0;
		else if (dcm_s3_en)
			if (dcm_s3_incdec) dcm_s3_cnt <= dcm_s3_cnt + 1;
			else               dcm_s3_cnt <= dcm_s3_cnt - 1;
			
		if (da_dcm_s3) begin
			if      (idi[2] & idi[3]) dcm_s3_ph90[1:0] <= 2'h0;
			else if (idi[2])          dcm_s3_ph90[1:0] <= dcm_s3_ph90[1:0] +1;
			else if (idi[3])          dcm_s3_ph90[1:0] <= dcm_s3_ph90[1:0] -1;
		end
		
	end

	always @ (negedge pclk) begin
		dcm_s3_reg[8:0] <= dcm_s3_cnt[8:0];
	end
	
	sensor_phase353 i_sp2(
	  .cclk(~pclk),       // command clock (posedge, invert on input if needed)
	  .wcmd(da_dcm_s3),       // write command
	  .cmd(idi[5:0]),        // CPU write data [5:0]
                 //       0 - nop, just reset status data
                 //       1 - increase phase shift
                 //       2 - decrease phase shift
                 //       3 - reset phase shift to default (preprogrammed in FPGA configuration)
                 //       c - reset phase90
                 //       4 - incr pahse90
                 //       8 - decrease phase90
                 //       10 - increase hact/vact phase
                 //       20 - decrease hact/vact phase
                 //       30 - reset hact/vact phase
	  .HACT(PX_HACT3),       //   sensor HACT I/O pin (input), used to reset FIFO
	  .VACT(PX_VACT3),       //   sensor VACT I/O pin (input)
	  .DI(PXD3),         //   sensor D[11:0] i/o pins (input)
 	  .iclk(sensor_clock),       //   global sensor input clock (posedge) - the clock that goes to all 3 sensors
	  .sclk(sclk0),       //   global FIFO output clock (posedge)
	  .shact(spx_hact3),      //   hact - sync to sclk
	  .svact(spx_vact3),      //   vact - sync to sclk
	  .fvact(fvact[2]),   // vact fall	  
	  .sdo(spxd3),        //   data output[11:0], sync to sclk
     .debug(0),      // 2-bit debug mode input
     .hact_length(dir_N_fp[13:0]),// [13:0] WOI width-1 (to overwrite sensor HACT duration)
     .hact_regen(hact_regen[2]), // 0 - use hact from sensor, 1 - regenerate using hact_lengh	    
     .mode_12bits(1),// input, 1 -  enable 12/14 bit mode, 0 - 10 bit mode
     .mode_14bits(0),// input, 1 -  enable 14 bit mode, 0 - 12/10 bit mode
     .mode_alt(0),   //   enable alternative vact/hact input (sync to data)
     .sync_alt(0),   //   alternative HACT/VACT input pad (10347) (VACT - 1 clock, HACT >1)	  
	  
	  .dcm_done(dclk3_done),   // DCM command done
	  .status  (dclk3_status), // DDM status (bit 1 - dcm clkin stopped)
	  .locked  (dclk3_locked)  // DCM locked
	);  

	assign     ipx_dclk3 = sclk0;

////////////////////////////////////////////////////////////////////////////////////////////////////
// DCM333 - for SDRAM
////////////////////////////////////////////////////////////////////////////////////////////////////

	wire [7:0]	dcm2_status;
	wire        dcm2_locked;
	wire [1:0] 	phsel;
	wire dcm_rst;	

  dcm333 i_dcm_359_2(
    .sclk(pclk),       						// in clock pad - 120MHz
	 //.sclk(sclk0),       						// in clock pad - 120MHz
    .SDCLK(SDCLK),   							// out positive clock to SDRAM
    .SDNCLK(SDNCLK),  							// out negative clock to SDRAM
    .sdcl_fb(sdcl_fb),							// in feedback clock
    .xclk(xclk),    								// 60MHz for compressor
    .phsel(phsel[1:0]),   					// additional phase control for SDRAM CLK 
    .dcm_rst(dcm_rst),// || dcm_rst_2), 	// reset DCM phase
    .dcm_incdec(dcm_incdec),  			   // variable phase control to adjust SDCLK so read DQS is aligned with sclk90/sclk270
    .dcm_en(dcm_en),
    .dcm_clk(dcm_clk),//.dcm_clk(dcm_clk),
	 //.dcm_clk(dcm_clk),//.dcm_clk(dcm_clk),
    .dcm_done(dcm2_done),
    .locked(dcm2_locked),  					// dcm locked
    .status(dcm2_status[7:0])   		      // dcm status (bit 1 - dcm clkin stopped)
  );		

////////////////////////////////////////////////////////////////////////////////////////////////////

  always @(negedge pclk) begin
    data12bits <=  USE5MPIX;
    data10bits <= ~USE5MPIX;
  end
		
	reg [2:0] i2c_mux=3'b111;	
	reg [15:0] chn_mux=16'h0039; // 3rd - 11 2nd - 10 direct - 01
	reg [15:0] chn_mux_d=0;
	
	//reg ch1_frame_ready=0, ch1_frame_ready_d=0;
	//reg ch3_frame_ready=0, ch3_frame_ready_d=0;	

	reg [15:0] aror_cnt=0;
	
	reg [31:0] Trig_delay=32'h00000015; // to delay trigger signal for sensors
	reg        trig_delay_en=0;
	reg [31:0] trig_delay_cnt=0;
	reg aror_d;

	always @ (negedge sclk0) begin

    mrstr <= imrst;
		
		if (!aror) aror_cnt[15:0] <= aror_cnt[15:0] + 1;
    arstr <= iarst;
		
		if (trig_delay_cnt==Trig_delay)         trig_delay_en <= 0;
		else if ((!iaro & aror)|(iaro & !aror)) trig_delay_en <= 1;
		
		if ((!iaro & aror)|(iaro & !aror)) aror_d <= iaro;
		
		if (trig_delay_en) trig_delay_cnt <= trig_delay_cnt + 1;
		else 							 trig_delay_cnt <= 0;
		
		//aror  <=  (Trig_delay[31])?(trig_delay_cnt[30:0]==Trig_delay[30:0]?aror_d:aror ):(iaro);
		//aror2 <= (!Trig_delay[31])?(trig_delay_cnt[30:0]==Trig_delay[30:0]?aror_d:aror2):(iaro);
		aror <= iaro;
		if (trig_delay_cnt==Trig_delay) aror2 <= aror_d;
		
  end
	
	wire        i2c_slave_en;   // enable slave bus (may be disabled during fast/non-standard-timing communications with master)
	wire        i2c_scl;        // SCL from master
	wire        i2c_scl_en;     // enable sclk output to external slave device
	wire        i2c_sdami;      // SDA from master input
	wire        i2c_sdamo;      // SDA to master output
	wire        i2c_sdamen;     // SDA to master output enable
	wire        i2c_sdasi;      // SDA from external slave input
	wire        i2c_sdaso;      // SDA to external slave output
	wire        i2c_sdasen;     // SDA to external slave output enable
	wire [15:0] i2c_sr;         // 16-bit shift register output (skipped ACKN)
	wire        i2c_wra_stb;    // single-cycle strobe when sr contains register+slave address to read/write
	wire        i2c_wra_ackn;   // acknowledge address (active high input)
	wire        i2c_wrd_stb;    // single-cycle strobe when sr[7:0] contains byte to write (st[16:9] may have previous/MS byte)
	wire        i2c_wrd_ackn;   // acknowledge for the byte/word written
	wire        i2c_rd_req;     // request read byte (ackn from master), strobe after SCL goes high
	reg   [7:0] i2c_rdat;       // 8-bit data to send to master
	wire        i2c_rd_stb;     // rdat is updated
	wire        i2c_start;      // start strobe (just in case)
	wire        i2c_stop;       // stop strobe (some commands will be triggered now (i.e. connecting/disconnecting bridge to external slave)
	
	wire [31:0] i2c_do_wire;
	//reg [31:0] i2c_do=0;
	wire [31:0] i2c_do=i2c_do_wire;
	
	wire        ext_i2c_disable;
	reg  [10:0] regfila; // register file address (10 bits - address, lsb - byte hi/lo)
	wire [ 7:0] sa_int = 8'h10; // slave addr 10.. 17
	wire [15:0] regfil_do; // output from register file;
	reg  [ 2:0] regfil_ro; // readout strobes for regfil Block RAM

	assign i2c_slave_en=!ext_i2c_disable;
	assign i2c_rd_stb = regfil_ro[2];

	wire          xfpgatdo;    // TDO read from an external FPGA
	wire          xfpgastat;   // Multiplexed read data from xjtag (senspgmin/xfpgadone/xfpgatdo)
	wire	[31:0]  bdo;		// 32-bit data from SDRAM channel3	
	wire	[31:0]  dsdo;		// 32-bit data from SDRAM descriptor memory
	wire 	[11:0]  io_pins;  // status of 12 i/o pins (from J2 connector)
	wire  [19:0]  pio_usec;
	wire  [31:0]  pio_sec;
	wire	[31:0]  dma_d0;
	wire	[31:0]  dma_d1;
	wire  [31:0]  hist_do; // histogram data out, actully only [17:0];	
	wire 	[31:0]  rd_regs; // read 0x10-0x14

	reg [4:0] i2c_brd_address 					=5'b00010; // ability to change board address // wakes up with 0x10xx
	
	parameter [7:0] DA_DCM1_ADDRESS     =8'h01; // a DCM for system clock (can be controlled but used mainly for clk270 for DDR SDRAM io buffers)
	parameter [7:0] DA_DCM2_ADDRESS     =8'h02; // DCM for output SDRAM clock
	parameter [7:0] DA_DCM_S1_ADDRESS   =8'h03; // J2 sensor receiving clock
	parameter [7:0] DA_DCM_S2_ADDRESS   =8'h04; // J3 sensor receiving clock
	parameter [7:0] DA_DCM_S3_ADDRESS   =8'h05; // J4 sensor receiving clock
	parameter [7:0] SET_MUX             =8'h06; // direct sensor data source
	parameter [7:0] SET_I2C_MUX         =8'h07; // i2c mux between sensors' bus and EEPROM & CY22393
	parameter [7:0] DA_CLKSRC           =8'h08; // clock source for sensors

	parameter [7:0] DA_FRAMEN           =8'h09; // mode register

	parameter [7:0] SET_DFSX            =8'h0a; // x size for direct channel
	parameter [7:0] SET_DFSY            =8'h0b; // y size for direct channel

	parameter [7:0] SET_DELAY           =8'h0c; // delay between frames, for instance, in alternation mode.
	parameter [7:0] SET_HACT_DELAY      =8'h0d; // delay between frames, for instance, in alternation mode.
	
	parameter [7:0] HACT_REGEN          =8'h0e; // hact regeneration enable bits [2:0] in input buffers

	parameter [7:0] SET_FS0X            =8'h13; // x size for read channel 1
	parameter [7:0] SET_FS0Y            =8'h14; // y size for read channel 1
	parameter [7:0] SET_FS0IX           =8'h15; // hact inactive time in clocks
	parameter [7:0] SET_FS0BL           =8'h16; // number of blank lines before the 2nd buffered frame
	
	parameter [7:0] SET_FS1X            =8'h23; // x size for read channel 3
	parameter [7:0] SET_FS1Y            =8'h24; // y size for read channel 3
	parameter [7:0] SET_FS1IX           =8'h25; // hact inactive time in clocks	
	parameter [7:0] SET_FS1BL           =8'h26; // number of blank lines before the 1st buffered frame

	parameter [7:0] DA_DSWE_L_ADDRESS     =8'h40;// 40...5f
	parameter [7:0] DA_DSWE_H_ADDRESS     =8'h50;// 40...5f
	
	parameter [7:0] TEST_BRAM           =8'h61;
	
	parameter [7:0] DA_DDR_W            =8'h63;
	parameter [7:0] DA_DDR_R            =8'h64;
	parameter [7:0] DA_DDR_BUF_RW       =8'h70;

	parameter [7:0] WNR_ADDRESS         =8'h31;
	parameter [7:0] DA_MEM_ADDRESS      =8'h33;
	parameter [7:0] DA_CH_MUX	         =8'h34;
	parameter [7:0] SET_SEQ_LEN         =8'h35;
	parameter [7:0] SET_BA              =8'h36;	
	
	parameter [7:0] SET_DFSX1           =8'h39; // for frame errors check, number of pixels
	parameter [7:0] SET_DFSY1           =8'h3a;
	parameter [7:0] SET_DFSX2           =8'h3b;
	parameter [7:0] SET_DFSY2           =8'h3c;
	parameter [7:0] SET_DFSX3           =8'h3d;
	parameter [7:0] SET_DFSY3           =8'h3e;

	wire   i2c_slava_ackn=(i2c_sr[7:3] == 5'b00010);//i2c_brd_address[4:0]); // will ackn. (using 7 MSBs from sr)
	
	assign i2c_wra_ackn   = 1'b1; // may be used no acknowledge only subset of addresses
	assign i2c_wrd_ackn   = 1'b1; // may be used no acknowledge only subset of data values

	reg i2c_wrd_stb_d=0;
	reg i2c_wra_stb_d=0;
	
	always @ (negedge pclk) begin
		i2c_wrd_stb_d <= i2c_wrd_stb;
		i2c_wra_stb_d <= i2c_wra_stb;
	end

	assign da_dcm1=      (i2c_reg_addr[7:0]==DA_DCM1_ADDRESS[7:0]) 		& (i2c_wrd_stb_d & (i2c_cnt[1:0]==2)); //switched to 16-bit
	wire   da_dcm2=      (i2c_reg_addr[7:0]==DA_DCM2_ADDRESS[7:0]) 		& (i2c_wrd_stb_d & (i2c_cnt[1:0]==2)); //switched to 16-bit

	assign da_dcm_s1=		(i2c_reg_addr[7:0]==DA_DCM_S1_ADDRESS[7:0]) 		& (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));
	assign da_dcm_s2=	   (i2c_reg_addr[7:0]==DA_DCM_S2_ADDRESS[7:0])     & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));
	assign da_dcm_s3=	   (i2c_reg_addr[7:0]==DA_DCM_S3_ADDRESS[7:0])     & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));

	wire da_set_mux=	   (i2c_reg_addr[7:0]==SET_MUX[7:0]) 					& (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));
	wire da_i2c_mux=     (i2c_reg_addr[7:0]==SET_I2C_MUX[7:0])           & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));
	wire da_clock_source=(i2c_reg_addr[7:0]==DA_CLKSRC[7:0])             & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));
	wire da_framen=		(i2c_reg_addr[7:0]==DA_FRAMEN[7:0])             & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));
	
	wire da_hact_delay=  (i2c_reg_addr[7:0]==SET_HACT_DELAY[7:0])        & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));
	
	wire da_dswe=			(i2c_reg_addr[7:5]==DA_DSWE_L_ADDRESS[7:5]) 		& (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));
	wire da_dswe_high=	(i2c_reg_addr[7:4]==DA_DSWE_H_ADDRESS[7:4]) 		& (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));	
	
	wire da_set_dfs_x=	   (i2c_reg_addr[7:0]==SET_DFSX[7:0])           & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));
	wire da_set_dfs_y=	   (i2c_reg_addr[7:0]==SET_DFSY[7:0])           & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));	
	
	wire da_hact_regen=	   (i2c_reg_addr[7:0]==HACT_REGEN[7:0])         & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));		
	
	wire da_set_fs0_x=	   (i2c_reg_addr[7:0]==SET_FS0X[7:0])           & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));
	wire da_set_fs0_y=	   (i2c_reg_addr[7:0]==SET_FS0Y[7:0])           & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));
	wire da_set_fs0_nhact=	(i2c_reg_addr[7:0]==SET_FS0IX[7:0])          & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));
	wire da_set_fs0_blank=	(i2c_reg_addr[7:0]==SET_FS0BL[7:0])          & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));
	
	wire da_set_fs1_x=	   (i2c_reg_addr[7:0]==SET_FS1X[7:0])           & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));
	wire da_set_fs1_y=	   (i2c_reg_addr[7:0]==SET_FS1Y[7:0])           & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));
	wire da_set_fs1_nhact=	(i2c_reg_addr[7:0]==SET_FS1IX[7:0])          & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));
	wire da_set_fs1_blank=	(i2c_reg_addr[7:0]==SET_FS1BL[7:0])          & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));

	// not sure if it's used
	wire da_seq_len   =  (i2c_reg_addr[7:0]==SET_SEQ_LEN[7:0])        & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));	

	wire da_ddr_buf_w=  (i2c_reg_addr[7:0]==DA_DDR_BUF_RW[7:0]) & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2)); //62 - incremental write data
	wire da_ddr_page_w= (i2c_reg_addr[7:0]==DA_DDR_W[7:0])      & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2)); //63 - page write
	wire da_ddr_page_r= (i2c_reg_addr[7:0]==DA_DDR_R[7:0])      & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2)); //64 - page read command
	wire da_ddr_buf_r=  (i2c_reg_addr[7:0]==DA_DDR_BUF_RW[7:0]) & ((i2c_rd_req & !i2c_cnt[0]));        //62 - incremental read

	wire da_set_delay=   (i2c_reg_addr[7:0]==SET_DELAY[7:0])             & (i2c_wrd_stb_d & (i2c_cnt[1:0]==2));	

	//////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// not used?!
	wire da_mem=			(i2c_reg_addr[7:0]==DA_MEM_ADDRESS[7:0]) 			& ((i2c_rd_req 	& (i2c_cnt[1:0]==0))); // 32-bit write register	
	wire da_test_bram=    (i2c_reg_addr[7:0]==TEST_BRAM[7:0]);
	
	//wire da_cc_page_r=  (i2c_reg_addr[7:0]==DA_DDR_R[7:0])      & (i2c_wrd_stb_d & (i2c_cnt[1:0]==0));	
	
	wire da_set_ch_mux=	(i2c_reg_addr[7:0]==DA_CH_MUX[7:0])	            & (i2c_wrd_stb_d & (i2c_cnt[1:0]==0));
	//wire da_next_ch3=	   (i2c_reg_addr[7:0]==DA_NEXT_CH3_ADDRESS[7:0])	& (i2c_wrd_stb_d & (i2c_cnt[1:0]==0));
	wire da_wnr=		 	(i2c_reg_addr[7:0]==WNR_ADDRESS[7:0]) 				& (i2c_wrd_stb_d & (i2c_cnt[1:0]==0));	
	//wire da_measure=     (i2c_reg_addr[7:0]==MEASURE[7:0])               & (i2c_wrd_stb_d & (i2c_cnt[1:0]==0));
	//wire da_latch_phase= (i2c_reg_addr[7:0]==LATCH[7:0]) 						& (i2c_wrd_stb_d & (i2c_cnt[1:0]==0));
	//wire da_set_vjump=	(i2c_reg_addr[7:0]==SET_VJUMP[7:0])             & (i2c_wrd_stb_d & (i2c_cnt[1:0]==0));
	wire da_set_ba=		(i2c_reg_addr[7:0]==SET_BA[7:0])                & (i2c_wrd_stb_d & (i2c_cnt[1:0]==0));	
		
	always @ (negedge pclk) begin
		if (da_set_ba) i2c_brd_address[4:0]<=idi[4:0];
	end
			
// i2c things
	always @ (negedge pclk) begin
		if (i2c_wra_stb) i2c_reg_addr <= i2c_sr[7:0];
	end
		
	always @ (negedge pclk) 
	begin				
		if (i2c_wrd_stb & (i2c_cnt[1:0]==1)) idi[31:16] <= i2c_sr;
		//if (i2c_wrd_stb & (i2c_cnt[1:0]==3)) idi[15: 0] <= i2c_sr;
		if (i2c_wrd_stb & i2c_cnt[0]) idi[15: 0] <= i2c_sr; // smart-ass write
		
		if (i2c_start)                       i2c_cnt <= 4'b0;
		else if (i2c_wrd_stb | i2c_rd_stb)   i2c_cnt <= i2c_cnt + 1;

    regfil_ro[2:0] <= {regfil_ro[1:0],i2c_rd_req};
		
    if      (i2c_wra_stb)                regfila[10:0] <= {i2c_sr[10:9], i2c_sr[7:0], 1'b0}; // i2c_sr[8] is direction 1 - read, 2 - write
    else if (i2c_wrd_stb | i2c_rd_stb)   regfila[10:0] <= regfila[10:0] + 1;
  end

	wire [15:0] ch3a_out;
	wire [1:0] dcm_err;
	reg [9:0] sens_a1=0;
	
	reg [15:0] ch0_test_reg=0;	

	// output i2c register
	always @ (negedge pclk) begin
		if (regfil_ro[1]) 
			case (i2c_cnt[1:0])
				2'b00: i2c_rdat <= i2c_do[31:24];
				2'b01: i2c_rdat <= i2c_do[23:16];
				2'b10: i2c_rdat <= i2c_do[15:8];
				2'b11: i2c_rdat <= i2c_do[7:0];
			endcase	
	end

	wire i2c_scls;
		
	wire i2c_j2_block;
	wire i2c_j3_block;
	wire i2c_j4_block;

	wire i2c_aux_block;

	reg i2c_j2_allow=1;
	reg i2c_j3_allow=1;
	reg i2c_j4_allow=1;

	reg i2c_aux_allow=1;
	
  //FDE i_ext_i2c_disable (.Q(ext_i2c_disable),.C(!pclk),.CE(i2c_wrd_stb && (regfila[10:0] == 11'h03)), .D(i2c_sr[0]));
  
  i2csbr i_i2csbr (.clk(!pclk),                 // global clock (30-150MHz?)
                   .slave_en(1),     // enable slave bus (may be disabled while fast/non-standard communications with master)
                   .scl(i2c_scl),               // SCL from master
				   .scls(i2c_scls),
                   .scl_en(i2c_scl_en),         // enable sclk output to external slave device
                   .sdami(i2c_sdami),           // SDA from master input
                   .sdamo(i2c_sdamo),           // SDA to master output
                   .sdamen(i2c_sdamen),         // SDA to master output enable
                   .sdasi(i2c_sdasi),           // SDA from external slave input
                   .sdaso(i2c_sdaso),           // SDA to external slave output
                   .sdasen(i2c_sdasen),         // SDA to external slave output enable
                   .sr(i2c_sr[15:0]),           // 16-bit shift register output (skipped ACKN)
                   .slava_ackn(i2c_slava_ackn), // will ackn. (using 7 MSBs from sr)
                   .wra_stb(i2c_wra_stb),       // single-cycle strobe when sr contains register+slave address to read/write
                   .wra_ackn(i2c_wra_ackn),     // acknowledge address (active high input)
                   .wrd_stb(i2c_wrd_stb),       // single-cycle strobe when sr[7:0] contains byte to write (st[16:9] may have previous/MS byte)
                   .wrd_ackn(i2c_wrd_ackn),     // acknowledge for the byte/word written
                   .rd_req(i2c_rd_req),         // request read byte (ackn from master), strobe after SCL goes high
                   .rdat(i2c_rdat[7:0]),        // 8-bit data to send to master
                   .rd_stb(i2c_rd_stb),         // rdat is updated
                   .start(i2c_start),           // start strobe (just in case)
                   .stop(i2c_stop));            // stop strobe (some commands will be triggered now (i.e. connecting/disconnecting bridge to external slave)

	PULLUP i_sdam_pu (.O(SDA0));
	PULLUP i_sclm_pu (.O(SCL0));
	
	PULLUP i_aux_sda_pu (.O(AUXSDA));
	PULLUP i_aux_scl_pu (.O(AUXSCL));
	
	PULLUP i_sdas_pu1 (.O(PX_SDA1));
	PULLUP i_scls_pu1 (.O(PX_SCL1));
	PULLUP i_sdas_pu2 (.O(PX_SDA2));
	PULLUP i_scls_pu2 (.O(PX_SCL2));
	PULLUP i_sdas_pu3 (.O(PX_SDA3));
	PULLUP i_scls_pu3 (.O(PX_SCL3));	
	
	IOBUF    i_sclm     (.I(1'b0),    	.T(1'b1),        .O(i2c_scl),  .IO(SCL0));
	IOBUF    i_sdam     (.I(i2c_sdamo), .T(~i2c_sdamen), .O(i2c_sdami), .IO(SDA0));	

	reg i2c_aux_en=0;
	
	assign i2c_aux_scl_en = i2c_scl_en;// & i2c_aux_en;
	//assign i2c_aux_sda_en = i2c_sdasen;// & i2c_aux_en;
	assign i2c_aux_sda_en = (i2c_sdasen) | i2c_aux_block | !i2c_aux_allow;
	
	assign i2c_aux_scl = i2c_scl;//!(!i2c_scl & i2c_aux_en);
	assign i2c_aux_sdaso = i2c_sdaso;//i2c_aux_en?i2c_sdaso:1'b1;//i2c_sdaso;//!(!i2c_sdaso & i2c_aux_en);

	IOBUF i_AUXSCL(.I(i2c_aux_scl),.T(~i2c_aux_scl_en),.O(),.IO(AUXSCL)); // i2c data bus to a ClockGenerator
	IOBUF i_AUXSDA(.I((i2c_aux_sdaso & i2c_aux_allow) | i2c_aux_block),.T(~i2c_aux_sda_en),.O(i2c_aux_sdasi),.IO(AUXSDA)); // i2c data bus to EEPROM
	
	wire i2c_scl_en1,i2c_scl_en2,i2c_scl_en3;
	wire i2c_sdasen1,i2c_sdasen2,i2c_sdasen3;
	         
	assign i2c_scl_en1 = i2c_scl_en;
	assign i2c_sdasen1 = (i2c_sdasen) | i2c_j2_block | !i2c_j2_allow;
	
	IOBUF    i_scls1     (.I(i2c_scl), 	.T(~i2c_scl_en1), .O(),        		.IO(PX_SCL1));
	IOBUF    i_sdas1     (.I((i2c_sdaso & i2c_j2_allow) | i2c_j2_block),.T(~i2c_sdasen1), .O(i2c_sdasi1), .IO(PX_SDA1));
	
	assign i2c_scl_en2 = i2c_scl_en;
	assign i2c_sdasen2 = (i2c_sdasen) | i2c_j3_block | !i2c_j3_allow;
	IOBUF    i_scls2     (.I(i2c_scl), 	.T(~i2c_scl_en2), .O(),        		.IO(PX_SCL2));
	IOBUF    i_sdas2     (.I((i2c_sdaso & i2c_j3_allow) | i2c_j3_block),.T(~i2c_sdasen2), .O(i2c_sdasi2), .IO(PX_SDA2));

	assign i2c_scl_en3 = i2c_scl_en;
	assign i2c_sdasen3 = (i2c_sdasen) | i2c_j4_block | !i2c_j4_allow;
	IOBUF    i_scls3     (.I(i2c_scl), 	.T(~i2c_scl_en3), .O(),        		.IO(PX_SCL3));
	IOBUF    i_sdas3     (.I((i2c_sdaso & i2c_j4_allow) | i2c_j4_block),.T(~i2c_sdasen3), .O(i2c_sdasi3), .IO(PX_SDA3));
	
	reg [1:0] i2c_sensor_mux=0;
	reg [1:0] i2c_sensor_eeprom_mux=0;
	
	wire i2c_main_sdasi = i2c_sdasi3 & i2c_sdasi2 & i2c_sdasi1;//i2c_sensor_mux[1]?(i2c_sensor_mux[0]?i2c_sdasi3:i2c_sdasi2):i2c_sdasi1;
//										i2c_mux[0]?
//													i2c_sdasi1     // ch_mux[2:0]=001|011|101|111
//													:
//													(i2c_mux[1]?
//														i2c_sdasi2   // ch_mux[2:0]=010|110
//														:
//														(i2c_mux[2]?
//															i2c_sdasi3 // ch_mux[2:0]=001
//															:
//															1'b0));    // ch_mux[2:0]=000

	assign i2c_sdasi= i2c_aux_sdasi & i2c_main_sdasi;//(i2c_aux_en)?i2c_aux_sdasi:i2c_main_sdasi;

//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////

reg i2c_scls_d=0;

reg i2c_sdaso_d=0;
reg i2c_sdaso_dd=0;

wire scl_fall = !i2c_scls &  i2c_scls_d;
wire scl_rise =  i2c_scls & !i2c_scls_d;

reg [15:0] i2c_addr_ctrl=0;
reg [7:0] i2c_bit_cnt=0;

reg addr_2bits_disable=0;
reg addr_2bits_disable_d=0;
reg addr_2bits_disable_dd=0;

reg addr_2bits_eeprom_disable=0;
reg addr_2bits_eeprom_disable_d=0;
reg addr_2bits_eeprom_disable_dd=0;

always @(negedge pclk) begin
	i2c_scls_d <= i2c_scls;	
	
	i2c_sdaso_d <= i2c_sdaso;
	i2c_sdaso_dd <= i2c_sdaso_d;
		
	if (i2c_start)              i2c_addr_ctrl[15:0] <= 0;
	else if (scl_rise)          i2c_addr_ctrl[15:0] <= {i2c_addr_ctrl[14:0],i2c_sdaso_d};
	
	if (scl_fall) begin
		if      ((i2c_addr_ctrl[15:0]==16'h9) & (i2c_bit_cnt==4)) addr_2bits_disable <= 1; // 0x9 - the first 4 bits of address, next 2 bits will be disabled
		else                                                      addr_2bits_disable <= 0;

		addr_2bits_disable_d <= addr_2bits_disable;
		addr_2bits_disable_dd <= addr_2bits_disable_d;
	end

	if (scl_fall) begin
		if      (((i2c_addr_ctrl[15:0]==16'ha)|(i2c_addr_ctrl[15:0]==16'h3)) & (i2c_bit_cnt==4)) addr_2bits_eeprom_disable <= 1; // 0xa,0x3 - the first 4 bits of eeprom address, next 2 bits will be disabled
		else                                                                                     addr_2bits_eeprom_disable <= 0;
		
		addr_2bits_eeprom_disable_d <= addr_2bits_eeprom_disable;
		addr_2bits_eeprom_disable_dd <= addr_2bits_eeprom_disable_d;
	end
		
	if (i2c_start)                                    
	     i2c_sensor_mux[1:0] <= 0;	
	else if (scl_fall) begin
		if (addr_2bits_disable | addr_2bits_disable_d) 
		  i2c_sensor_mux[1:0] <= {i2c_sensor_mux[0],i2c_sdaso_dd};
	end

	if (i2c_start)                                                   
	     i2c_sensor_eeprom_mux[1:0] <= 0;	
	else if (scl_fall) begin
		if (addr_2bits_eeprom_disable | addr_2bits_eeprom_disable_d) 
		  i2c_sensor_eeprom_mux[1:0] <= {i2c_sensor_eeprom_mux[0],i2c_sdaso_dd};
	end
	
	i2c_j2_allow <= !(addr_2bits_disable | addr_2bits_disable_d) & !(addr_2bits_eeprom_disable | addr_2bits_eeprom_disable_d);
	i2c_j3_allow <= !(addr_2bits_disable | addr_2bits_disable_d) & !(addr_2bits_eeprom_disable | addr_2bits_eeprom_disable_d);
	i2c_j4_allow <= !(addr_2bits_disable | addr_2bits_disable_d) & !(addr_2bits_eeprom_disable | addr_2bits_eeprom_disable_d);	
	i2c_aux_allow <= !(addr_2bits_eeprom_disable | addr_2bits_eeprom_disable_d);
end

	always @(negedge pclk) begin
		
		if (i2c_start)     i2c_bit_cnt <= 8'h00;
		else if (scl_rise) i2c_bit_cnt <= i2c_bit_cnt + 1;
		
	end

wire i2c_j2_block_sensor = addr_2bits_disable_dd & i2c_sensor_mux[1];
wire i2c_j3_block_sensor = addr_2bits_disable_dd & i2c_sensor_mux[0];
wire i2c_j4_block_sensor = addr_2bits_disable_dd & (i2c_sensor_mux[1]!=i2c_sensor_mux[0]);

wire i2c_j2_block_eeprom = addr_2bits_eeprom_disable_dd & !(!i2c_sensor_eeprom_mux[1] &  i2c_sensor_eeprom_mux[0]);
wire i2c_j3_block_eeprom = addr_2bits_eeprom_disable_dd & !( i2c_sensor_eeprom_mux[1] & !i2c_sensor_eeprom_mux[0]);
wire i2c_j4_block_eeprom = addr_2bits_eeprom_disable_dd & !( i2c_sensor_eeprom_mux[1] &  i2c_sensor_eeprom_mux[0]);

assign i2c_j2_block  = i2c_j2_block_sensor | i2c_j2_block_eeprom;
assign i2c_j3_block  = i2c_j3_block_sensor | i2c_j3_block_eeprom;
assign i2c_j4_block  = i2c_j4_block_sensor | i2c_j4_block_eeprom;
assign i2c_aux_block = addr_2bits_eeprom_disable_dd & (i2c_sensor_eeprom_mux[1] | i2c_sensor_eeprom_mux[0]);

//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////

	// check RAM
	reg [9:0] bram_cnt_A=0;
	reg [9:0] bram_cnt_B=0;

	reg [9:0] sdram_cnt_A=0;
	reg [11:0] sdram_cnt_B=0;	
	reg [9:0] sdram_cnt_C=0;
	
	reg i2c_rd_stb_d;
	reg sdram_wpage=0;
	reg da_test_sdram_d=0;
	reg da_test_sdram_rd_d=0;
	reg da_test_sdram_dd=0;
	reg da_test_sdram_rd_dd=0;
	
	always @ (negedge pclk)
	begin    
			i2c_rd_stb_d <= i2c_rd_stb;
			
			if (i2c_cnt[0]) begin
				if (i2c_wrd_stb & da_test_bram)               bram_cnt_A <= bram_cnt_A + 1;				
			  if (i2c_rd_stb & (i2c_reg_addr[7:3]=='b01101)) bram_cnt_B <= bram_cnt_B + 1;							
			end					
	end

reg da_ddr_buf_w_d=0;
reg da_ddr_buf_w_dd=0;

  wire [15:0] ch2dox;
  reg  [10:0] ddr_addr_w=0;
  reg [11:0] ddr_addr_r=0;

	RAMB16_S18_S18  TEST_RAMB16_S18_S18 (
		.DOA(),                            // Port A 16-bit Data Output
		.DOPA(),                           // Port A 2-bit Parity Output
		.ADDRA(ddr_addr_w[9:0]),           // Port A 10-bit Address Input
		.CLKA(!sclk0),                      // Port A Clock
		.DIA(idi_d[15:0]),                // Port A 16-bit Data Input
		.DIPA(2'h0),                       // Port A 2-bit parity Input
		.ENA(1'b1),                        // Port A RAM Enable Input
		.SSRA(1'b0),                       // Port A Synchronous Set/Reset Input
		.WEA(da_ddr_buf_w_d & !da_ddr_buf_w_dd), // Port A Write Enable Input
		.DOB(ch2dox[15:0]),             // Port B 16-bit Data Output
		.DOPB(),                           // Port B 2-bit Parity Output
		.ADDRB(ddr_addr_r[9:0]),           // Port B 10-bit Address Input
		.CLKB(!sclk0),                      // Port B Clock
		.DIB(16'h0),                       // Port B 16-bit Data Input
		.DIPB(2'h0),                       // Port-B 2-bit parity Input
		.ENB(1'b1),                        // Port B RAM Enable Input
		.SSRB(1'b0),                       // Port B Synchronous Set/Reset Input
		.WEB(1'b0)                         // Port B Write Enable Input
	);
	
//  RAMB16_S18_S18  TEST_RAMB16_S18_S18 (
//      .DOA(),                            // Port A 16-bit Data Output
//      .DOPA(),                           // Port A 2-bit Parity Output
//			.ADDRA(bram_cnt_A[9:0]),           // Port A 10-bit Address Input
//      .CLKA(!pclk),                      // Port A Clock
//      .DIA(i2c_sr[15:0]),                // Port A 16-bit Data Input
//      .DIPA(2'h0),                       // Port A 2-bit parity Input
//      .ENA(1'b1),                        // Port A RAM Enable Input
//      .SSRA(1'b0),                       // Port A Synchronous Set/Reset Input
//      .WEA(i2c_wrd_stb & da_test_bram & i2c_cnt[0]), // Port A Write Enable Input
//      .DOB(regfil_do[15:0]),             // Port B 16-bit Data Output
//      .DOPB(),                           // Port B 2-bit Parity Output
//      .ADDRB(bram_cnt_B[9:0]),           // Port B 10-bit Address Input
//      .CLKB(!pclk),                      // Port B Clock
//      .DIB(16'h0),                       // Port B 16-bit Data Input
//      .DIPB(2'h0),                       // Port-B 2-bit parity Input
//      .ENB(1'b1),                        // Port B RAM Enable Input
//      .SSRB(1'b0),                       // Port B Synchronous Set/Reset Input
//      .WEB(1'b0)                         // Port B Write Enable Input
//   );

	reg sdwe_p,sdcas_p,sdras_p;
	wire sddqt_manual;	
	reg  sddqt_manual_1=0;

	always @ (negedge sclk0) begin	
		if      (!sdwe_p & !sdcas_p &  sdras_p) sddqt_manual_1=0; // start of write
		else if (!sdwe_p &  sdcas_p & !sdras_p) sddqt_manual_1=1; // end of write (precharge)
	end

	assign sddqt_manual=(!sdwe_p & !sdcas_p & sdras_p)?1'b0:sddqt_manual_1;

	// IO pads and related FFs
	
	sddrio16 i_SDDd(.c0(sclk0),
									//.c90(sclk90),
									.c270(sclk270),
									.d(sddo_p[31:0]),
									//.d({sddo_p[31:1],1'b1}), // that was for check
									.t(pretrist & sddqt_manual),.q(sddi_r[31:0]),.dq(SDD[15:0]));

	wire [1:0] sddm_pp;
	
	assign sddm_pp[1]= sddm_p[1] & sddqt_manual;
	assign sddm_pp[0]= sddm_p[0] & sddqt_manual;

	sddrdm        i_SDUDM  (.c0(sclk0),/*.c90(sclk90),*/.c270(sclk270),.d(sddm_pp[1:0]),.dq(SDUDM));
	sddrdm        i_SDLDM  (.c0(sclk0),/*.c90(sclk90),*/.c270(sclk270),.d(sddm_pp[1:0]),.dq(SDLDM));
	sdo15_2       i_SDA    (.c(sclk0),.d({sdba_p[1:0],sda_p[12:0]}),.q(SDA[14:0]));		 
	
	sdo1_2        i_SDRAS  (.c(sclk0),.d(sdras_p),.q(SDRAS));
	sdo1_2        i_SDCAS  (.c(sclk0),.d(sdcas_p),.q(SDCAS));
	sdo1_2        i_SDWE   (.c(sclk0),.d(sdwe_p),. q(SDWE ));

	// temporary change behaviour of dqs2 to fix pinout problem - will influence adjustment goal
  dqs2          i_sddqs(.c0(sclk0),/*.c90(sclk90),*/.c270(sclk270),
//     dqs2 i_sddqs(.c0(sclk0),.c0comb(sclk270),.c90(sclk90),.c270(sclk270),
	                      .t       (sddqt && sddqt_manual),       // 1/2 cycle before cmd "write" sent out to the SDRAM, sync to sclk180
	                      .UDQS    (UDQS),         // UDQS I/O pin
	                      .LDQS    (LDQS),         // LDQS I/O pin
	                      .udqsr90 (udqsr90),      // data from SDRAM interface pin UDQS strobed at rising sclk90
	                      .ldqsr90 (ldqsr90),      // data from SDRAM interface pin LDQS strobed at rising sclk90
	                      .udqsr270(udqsr270),     // data from SDRAM interface pin UDQS strobed at rising sclk270
	                      .ldqsr270(ldqsr270)      // data from SDRAM interface pin UDQS strobed at rising sclk270
//       ,.qtmp(qtmp[3:0]) // temporary
	              );
	
	reg dcm2_en;
	reg dcm2_incdec;
	reg [8:0] dcm2_cnt=0;
	reg [8:0] dcm2_reg=0;
 
	always @ (negedge pclk) begin
		dcm2_en     <= da_dcm2 & (idi[1]!=idi[0]); //xor
		dcm2_incdec <= da_dcm2 & idi[0]; 

		if ((da_dcm2 & idi[1] & idi[0]))      dcm2_cnt <= 0;
		else if (dcm2_en)	 
			if (dcm2_incdec) dcm2_cnt <= dcm2_cnt + 1;
			else             dcm2_cnt <= dcm2_cnt - 1;
	end

	always @ (negedge pclk) begin
		dcm2_reg[8:0] <= dcm2_cnt[8:0]; //dcm1 phase counter register in clk0 domain
	end

	reg da_dcm2_d=0;
	reg da_dcm2_dd=0;

	always @ (negedge sclk0) begin
		da_dcm2_d <= da_dcm2;
		da_dcm2_dd <= da_dcm2_d;		
	end

// assumed CL=2.5
 sdram_phase i_sdram_phase(
//***********************  .wclk(cwr),       // global CPU WE pulse
									.clk(pclk),
                           //.pre_wcmd(da_dcm2_d & !da_dcm2_dd),       // decoded address - enables wclk
									.pre_wcmd(da_dcm2),       // decoded address - enables wclk
                           .wd(idi[3:0]),         // CPU write data [3:0]
                                          //       0 - nop, just reset status data
                                          //       1 - increase phase shift
                                          //       2 - decrease phase shift
                                          //       3 - reset phase shift to default (preprogrammed in FPGA configuration)
                           .ph_err(dcm_err[1:0]),     // [1:0] 0 - no data (SDRAM reads) since last change (wclk*wcmd)
                                       //       1 - clock is too late
                                       //       2 - clock is too early
                                       //       3 - OK (some measurements show too late, some - too early)
                           .sclk0(sclk0),      // global clock, phase 0
//                           .sclk90(sclk90),     // global clock, phase 0
                           .sclk270(sclk270),    // global clock, phase 0
                           .enrd180(sd_dqsrd),    // read enable, latency 2 from the command, sync with sclk0 falling edge
                           .udqsr90(udqsr90),    // data from SDRAM interface pin UDQS strobed at rising sclk90
                           .ldqsr90(ldqsr90),    // data from SDRAM interface pin LDQS strobed at rising sclk90
                           .udqsr270(udqsr270),   // data from SDRAM interface pin UDQS strobed at rising sclk270
                           .ldqsr270(ldqsr270),   // data from SDRAM interface pin UDQS strobed at rising sclk270
                           .dcm_rst(dcm_rst),    // set DCM phase to default
                           .dcm_clk(dcm_clk),//.dcm_clk(dcm_clk),    // clock for changing DCM phase (now == sclk0)
                           .dcm_en(dcm_en),     // enable inc/dec of the DCM phase
                           .dcm_incdec(dcm_incdec), // 1 - increment, 0 - decrement DCM phase
                           .phase90sel(phsel[1:0])  // add phase 0 - 0, 1 - 90, 2 - 180, 3 - 270
                     );

	reg     ipx_bpf1_dl=0,   ipx_bpf2_dl=0,   ipx_bpf3_dl=0;

	wire    ipx_vact1_dl,  ipx_vact2_dl,  ipx_vact3_dl;
	wire    ipx_hact1_dl,  ipx_hact2_dl,  ipx_hact3_dl;
	wire [11:0] ipxd1_dl,      ipxd2_dl,      ipxd3_dl;

// Other modules
	reg [15:0] BL0=0; // number of blank lines before the buffered frame (mcontr channels w0 r1)
	reg [15:0] BL1=0; // number of blank lines before the buffered frame (mcontr channels w2 r3)

	reg [15:0] IX0=255; // 256 default // pause between the (blank ones also) lines in a frame (mcontr channels w0 r1)
	reg [15:0] IX1=255; // 256 default // pause between the (blank ones also) lines in a frame (mcontr channels w2 r3)

	wire [9:0] fpn_a;
	reg [15:0] px_d1,px_d1_d, px_d2,px_d2_d;
	reg px_hact1, px_hact1_d, px_hact1_d2, px_hact2, px_hact2_d, px_hact2_d2;
	reg px_vact1, px_vact1_d, px_vact2, px_vact2_d;
	
	reg stch1=0;
	wire ch1weo;
 
	reg stch3=0;
	wire ch3weo;

	//reg stch5=0;
	wire stch5;
	wire ch5weo;

reg [15:0] ch0_hact_cnt=0;
reg ch0_wpage=0;
reg ch0_wpage_last=0;
reg [10:0] ch0a=0; 

reg [15:0] ch2_hact_cnt=0;
reg ch2_wpage=0;
reg ch2_wpage_last=0;
reg [10:0] ch2a=0;

reg ch4_wpage_imt=0;
reg [9:0] ch4a=0;
//wire ch4_wpage_imt;
//wire [9:0] ch4a;

reg stch1_first=0;
reg [15:0] ch1_hact_imt_cnt=0;

reg stch3_first=0;
reg [15:0] ch3_hact_imt_cnt=0;

reg [15:0] px_d2a=0,px_d2a_d=0;

reg [15:0] ch0_N_fl=1940;
reg [15:0] ch0_N_fp=2596;
//reg [15:0] ch0_N_fp=1663;
reg [15:0] ch2_N_fl=1940;
reg [15:0] ch2_N_fp=2596;
//reg [15:0] ch2_N_fp=1663;

reg [15:0] pre_dir_N_fl=1940;
reg [15:0] pre_dir_N_fp=2596;

reg [15:0] pre_ch0_N_fl=1940;
reg [15:0] pre_ch0_N_fp=2596;
//reg [15:0] pre_N_p0=1663;
	
reg [15:0] pre_ch2_N_fl=1940;
reg [15:0] pre_ch2_N_fp=2596;
//reg [15:0] pre_N_p1=1663;

reg [ 3:0] vjump=4'h7;

//reg [31:0] MAX_DELAY=32'h003fffff;
reg [15:0] MAX_DELAY=16'h0;

reg ch1_vact_imt=0;
reg ch1_hact_imt=0;

////
reg npretrist=1'b1;
reg nsddqt=1'b1;
wire [2:0] pre2cmd;
wire [12:0] pre2sda;
wire [1:0] pre2sdb;
wire dmask2;
wire drive_dq2;
wire drive_sd2;
wire [31:0] sddo_p2;
reg  [31:0] sddi_r2=0;

wire [21:0] ch0_a_out;
wire [21:0] ch1_a_out;
wire [21:0] ch2_a_out;
wire [21:0] ch3_a_out;

assign      pretrist=!npretrist;
assign      sddqt=   !nsddqt;

always @ (negedge sclk0) begin
     sdras_p <= pre2cmd[2];
     sdcas_p <= pre2cmd[1];
     sdwe_p  <= pre2cmd[0];
     sda_p[12:0] <= pre2sda[12:0];
     sdba_p[1:0] <= pre2sdb[1:0];
     sddm_p[1:0] <= {dmask2,dmask2};
     npretrist   <= drive_sd2;
     nsddqt      <= drive_dq2;
     sddi_r2[31:0]<=sddi_r[31:0];
     sddo_p[31:0] <= sddo_p2[31:0];
end
////

wire [10:0] ao_wire;

reg ch1_fill_order=0;

reg trig=0, trig_d=0;
reg trig_rst=0;

reg vg_mode=0;
reg framen=0;
reg stereo_enable=1;
//wire rst=(da_set_mux_d)|(trig_rst)|(!framen);

always @ (negedge sclk0) begin
	trig <= aror;
	trig_d <= trig;
	trig_rst <= !trig & trig_d;
end

//wire rst=(trig_rst)|(!framen);

reg rst=0;
reg pre_disable_input=0;
reg pre_disable_output=0;
reg chn_mux_32=0;
reg combine_into_two_frames = 0;
reg test_pattern = 0;
reg select_ipx_spx = 0;

reg ch1_hact_delay = 0;
reg ch3_hact_delay = 0;

wire [2:0] sync_frames;
reg pre_vg_mode=0;

always @ (negedge sclk0) begin
	if (da_framen) rst <= idi[0];
	if (da_framen) pre_disable_output <= idi[1];
	//if (da_framen) pre_disable_input <= idi[2];
	if (da_framen) pre_vg_mode <= idi[2];
	if (da_framen) chn_mux_32 <= idi[3];
	if (da_framen) combine_into_two_frames <= idi[4];
	if (da_framen) test_pattern <= idi[5];
	if (da_clock_source) select_clk <= idi[0];
	if (da_i2c_mux)      i2c_aux_en <= idi[0];	
end

always @ (negedge sclk0) begin
	if (|sync_frames[2:0]) vg_mode <= pre_vg_mode;
end

reg [15:0] idi_stored=0; // a MSB part ofthe mcontr regs

always @ (negedge sclk0) begin
	if (da_dswe_high) idi_stored[15:0] <= idi[15:0];
end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire [8:0] mcontr_init_out;

reg test_page_w=0;

always @ (negedge sclk0) begin
	da_ddr_buf_w_d <= da_ddr_buf_w;
	idi_d[15:0] <= idi[15:0];
	da_ddr_buf_w_dd <= da_ddr_buf_w_d;
	if (mcontr_init_out[4])  ddr_addr_w <= 0;
	else if (test_page_w)    ddr_addr_w <= {ddr_addr_w[10:6]+{4'b0,ddr_addr_w[5]|ddr_addr_w[4]|ddr_addr_w[3]|ddr_addr_w[2]|ddr_addr_w[1]|ddr_addr_w[0]},6'b0};
	else if (da_ddr_buf_w_d & !da_ddr_buf_w_dd) ddr_addr_w <= ddr_addr_w + 1;
end

reg [15:0] ddr_do=0;
reg [15:0] bram_do=0;

reg da_ddr_buf_r_d=0;
reg da_ddr_buf_r_dd=0;
reg da_ddr_buf_r_ddd=0;

always @ (negedge sclk0) begin
//	if (rst) begin
// 	ddr_addr_r    <= 0;
//		ddr_do[15:0]  <= 0;
//		bram_do[15:0] <= 0;
	//end
	//else begin
		//if (test_page_r)     ddr_addr_r <= {ddr_addr_r[9:7]+{2'b0,ddr_addr_r[6]|ddr_addr_r[5]|ddr_addr_r[4]|ddr_addr_r[3]|ddr_addr_r[2]|ddr_addr_r[1]|ddr_addr_r[0]},7'b0};
		//else 
		da_ddr_buf_r_d <= da_ddr_buf_r;
		da_ddr_buf_r_dd <= da_ddr_buf_r_d;
		//da_ddr_buf_r_ddd <= da_ddr_buf_r_dd;		
		
		if (mcontr_init_out[5])                      ddr_addr_r <= 0;
		else if (da_ddr_buf_r_d & !da_ddr_buf_r_dd)  ddr_addr_r <= ddr_addr_r + 1;
			
		if (da_ddr_buf_r_d & !da_ddr_buf_r_dd) ddr_do[15:0]  <= ch5do[15:0];
		if (da_ddr_buf_r_d & !da_ddr_buf_r_dd) bram_do[15:0] <= ch2dox[15:0];
	//end	
	
end

reg ddr_pg_w=0;
reg ddr_pg_w_d=0;

always @ (negedge sclk0) begin
	ddr_pg_w <= da_ddr_page_w;
	ddr_pg_w_d <= ddr_pg_w;
	test_page_w <= ddr_pg_w & !ddr_pg_w_d;
end

reg ddr_pg_r=0;
reg ddr_pg_r_d=0;
reg test_page_r=0;
always @ (negedge sclk0) begin
	ddr_pg_r <= da_ddr_page_r;
	ddr_pg_r_d <= ddr_pg_r;
	test_page_r <= ddr_pg_r & !ddr_pg_r_d;
end

//reg cc_pg_r=0;
//reg cc_pg_r_d=0;
//always @ (negedge sclk0) begin
//	if (da_cc_page_r) cc_pg_r <= idi[1];
//	else              cc_pg_r <= 0;
//	
//	cc_pg_r_d <= cc_pg_r;
//end
//
//assign stch5=cc_pg_r & !cc_pg_r_d;

////////////////////////////////////////////////////////////////////////////////////////////////////
// memory controller
////////////////////////////////////////////////////////////////////////////////////////////////////
reg [7:0]  res_oe_cnt=0;
reg        res_ready=0;
reg [7:0]  res_a_max=0;
reg [17:0] res_do_max=0;

reg corr_finished=0;
reg corr_done=0;

reg ch4_wpage_imt_d=0;

reg EnV1_buf=0;
reg EnV2_buf=0;

reg EnV1_buf_d=0;
reg EnV2_buf_d=0;

reg buf_lock=0;
reg buf_lock_d=0;

//wire mcontr_rst = rst | (pre_vg_mode & !buf_lock & (|sync_frames[2:0]));
wire mcontr_rst = rst | (buf_lock & !buf_lock_d);

mcontr i_mcontr(   
   .rst(mcontr_rst),
	//.rst_addresses(corr_done),
	.clk0(sclk0),        // system clock, mostly negedge (maybe add more clocks for ground bounce reducing?)0
	.mwr(da_dswe),       // @negedge clk0 - write parameters, - valid with ma[2:0] 
	.ma(ia[4:0]),        // [2:0] - specifies register to use:
	                     // 0 - command register, bit19 - ch3 read_block, bit 18 - next block, [17:16] - SDRAM enable/refresh, [15:14] - channel7, ...
											 // 1 - SDRAM manual commands [17:0]
											 // 2 - {ny[9:0], 4'b0, nx[9:0]}
											 // 3 - snb_msbs[9:0], nst[9:0], nsty[4:0], nstx[4:0]
											 // 4 - channel0 start address [11:0]
											 // 5 - channel1 start address [11:0]
											 // 6 - channel2 start address {sync,4'b0,[11:0]}
											 // 7 - channel3 start address {readahead,write,4'b0,[15:0]}
	.piorw(da_mem),      // PIO data (channel 3 R/W)
	.wnr(da_wnr),        // write/not read - used with piorw (channel direction - separately - bit of data)
	.mdi({idi_stored[15:0],idi[15:0]}),     // [31:0] data valid with mwr - CPU data to write parameters (and also - channel3)
	.mdo(bdo[31:0]),     // [31:0] channel 3 data to cpu
	.rq_busy(),          // [8:0] per channel - rq | busy
	.nstx(),             // [4:0] (number of SUPERTILES (128x64 pix) in a row) -1
	.nsty(),             // [4:0] (number of SUPERTILES (128x64 pix) rows in a frame) -1
	.nst (),             // [9:0] (number of SUPERTILES (128x64 pix) in a frame) -1

// interface to SDRAM (through extra registers
	.pre2cmd(pre2cmd[2:0]),          // {ras,cas,we} - should be all ones when not in use (2 cycles ahead of I/O pads)
	.pre2sda(pre2sda[12:0]),         //[12:0] address to SDRAM - 2 cycles ahead of I/O pads
	.pre2sdb(pre2sdb[1:0]),          //[ 1:0] bank to SDRAM - 2 cycles ahead of I/O pads
	.sddo(sddo_p2[31:0]),            //[31:0] - 1 cycle ahead of "write" command on I/O pads
	.sddi(sddi_r2[31:0]),            //[31:0] -
	.drive_sd2(drive_sd2),           // enable data to SDRAM   (2 cycles ahead)
	.drive_dq2(drive_dq2),           //  enable DQ outputs (one extra for FF in output buffer)
	.dmask2(dmask2),                 //  now both the same (even number of words written)
	.dqs_re(sd_dqsrd),               // enable read from DQS i/o-s for phase adjustments  (latency 2 from the SDRAM RD command)

// Channel 0 WriteChannel
	.ch0_ibwe(px_hact1_d),//we
	.ch0_a(ch0a[10:0]),//buffer address
	.ch0_ibdat(px_d1_d[15:0]),// [15:0] input data
	.ch0_next_line(ch0_wpage | ch0_wpage_last), //advance to the next scan line (and next block RAM page if needed)
	.ch0_last_line(ch0_wpage_last),//useless port?
	.ch0_a_out(ch0_a_out),
	.ch0_fill_order(0),
// Channel 1 ReadChannel
	.ch1_obre(1),//ch1_hact_imt),
	.ch1_obdat(ch1do[15:0]),
	.ch1_a(ch1a[11:0]),
	.ch1_next_line(0),//next_line_rd),    // advance to the next scan line (and next block RAM page if needed)
	.ch1_start(stch1_first|stch1), // request sram read
	.ch1_weo(ch1weo),
	.ch1_a_out(ch1_a_out),
	.ch1_fill_order(0),
	
// Channel 2 WriteChannel
	.ch2_ibwe(px_hact2_d),
	.ch2_a(ch2a[10:0]),
	.ch2_ibdat(px_d2_d[15:0]),        // [15:0] input data (1 or 2 pixels)
	//.ch2_ibdat({2'b0,px_d2_d[15:2]}),
	//.ch2_ibdat({4'b0,px_d2_d[15:4]}),
	.ch2_next_line(ch2_wpage | ch2_wpage_last),    // advance to the next scan line (and next block RAM page if needed)
	.ch2_last_line(ch2_wpage_last),
	//.ch2_last_line(0),
	.ch2_a_out(ch2_a_out),
	.ch2_fill_order(0),
// Channel 3 ReadChannel
	.ch3_obre(1),
	.ch3_obdat(ch3do[15:0]), // [15:0] output data
	.ch3_a(ch3a[11:0]),
	.ch3_next_line(0),//next_line_rd),// advance to the next scan line (and next block RAM page if needed)
	.ch3_start(stch3 | stch3_first), // request sdram read
	.ch3_weo(ch3weo),
	.ch3_a_out(ch3_a_out),
	.ch3_fill_order(0),

// Channel 4
	.ch4_ibwe     (da_ddr_buf_w_d & !da_ddr_buf_w_dd),
	.ch4_a        (ddr_addr_w[10:0]),
	.ch4_ibdat    (idi_d[15:0]),
	.ch4_next_line(test_page_w),
	//.ch4_next_line(0),
	.ch4_last_line(0),
	.ch4_a_out(),
	.ch4_fill_order(0),
// Channel 5
	.ch5_obre(1),
	.ch5_obdat(ch5do[15:0]), // [15:0] output data
	.ch5_a(ddr_addr_r[11:0]),    // 12-bit bus
	.ch5_next_line(0),
	.ch5_start(test_page_r),
	.ch5_weo(ch5weo),
	.ch5_a_out(),
	.ch5_fill_order(0),
	
// Others
	.en_refresh(),         // to see if SDRAM controller is programmed
	.tok_frame_num_wr(),  // debug - LSB of last frame written by compressor_one
	.init_out(mcontr_init_out[8:0]),
	.ao(ao_wire)
);

//useless?
reg da_set_mux_d=0;
always @ (negedge sclk0) da_set_mux_d <= da_set_mux;

reg px_hact1_dd=0,  px_hact2_dd=0;
reg px_vact1_dd=0,  px_vact2_dd=0;

reg [31:0] ctrl_reg=1;
reg px_vact_go=0;
reg px_vact_go_d=0;

reg EnV1=0,EnV2=1,EnV3=0;
reg EnV1_d=0;	
reg EnV3_d=0;

reg ipx_vact2_d=0;
reg ipx_vact2_dd=0;
reg ipx_hact2_d=0;
reg [11:0] ipxd2_d=0;

reg EnV2_enable=1;

reg [15:0] ch1weo_cnt=0;
reg [7:0] stch1_cnt=0;
reg ch1_line_ready=0;
//reg [15:0] ch1_vact_imt_cnt=0;
reg ch1_hact_imt_d=0;
reg ch1_vact_imt_d=0;
reg ch1_line_ready_d=0;

reg ch3_vact_imt=0;
reg ch3_hact_imt=0;
reg [15:0] ch3weo_cnt=0;
reg [7:0] stch3_cnt=0;
reg ch3_line_ready=0;
reg ch3_line_ready_d=0;
reg [15:0] ch3_vact_imt_cnt=0;
reg ch3_hact_imt_d=0;
reg ch3_vact_imt_d=0;

//reg [2:0] sphase=3'b111;
reg [27:0] sphase=28'hfff0007;
reg ipx_vact2_en=0;

always @ (negedge sclk0) begin
  if      (rst) 
    ipx_vact2_en <= 0;
  else if (!(chn_mux[8]?ipx_vact2_dl:ipx_vact1_dl))
    ipx_vact2_en <= 1;
	 
  if (ipx_vact2_en & EnV2) begin
	 ipx_vact2_d <= chn_mux[8]?ipx_vact2_dl:ipx_vact1_dl;
	 ipx_vact2_dd <= ipx_vact2_d;
	 ipx_hact2_d <= chn_mux[8]?ipx_hact2_dl:ipx_hact1_dl;
	 ipxd2_d     <= chn_mux[8]?    ipxd2_dl:    ipxd1_dl;
  end
end	
	
reg ipx_vact1_dl_d=0;	
reg ipx_vact2_dl_d=0;
	
reg da_trig_delay=0;
	
always @ (negedge sclk0) begin
	
	ipx_vact1_dl_d <= ipx_vact1_dl;
	ipx_vact2_dl_d <= ipx_vact2_dl;
	
	//if (da_latch_phase) sphase[27:0] <= idi[27:0];
	
	if (da_set_mux)    i2c_mux[2:0] <= idi[2:0];
	//if (da_set_ch_mux) chn_mux[5:0] <= idi[5:0];
	if (da_set_mux) chn_mux[15:0] <= idi[15:0];
	
	if (da_set_ch_mux) ctrl_reg[0] <= idi[8];
	
	if (da_set_ch_mux)                       trig_aro1 <= !idi[7];
	else if (ipx_vact1_dl & !ipx_vact1_dl_d) trig_aro1 <= 1;

	if (da_set_ch_mux)                       trig_aro2 <= !idi[7];
	else if (ipx_vact2_dl & !ipx_vact2_dl_d) trig_aro2 <= 1;
	
	if (da_trig_delay) Trig_delay <= idi[31:0];
	
end	

assign USE5MPIX=  ctrl_reg[0];

reg [1:0] rst_cnt=0;

always @ (negedge sclk0) begin
	if (rst)             rst_cnt <= 0;
	else if (rst_cnt==3) rst_cnt <= rst_cnt;  
	else                 rst_cnt <= rst_cnt + 1;
end

//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////
// sync module - generates "rst" for mcontr channels, enable frames sizes
wire [2:0] chn_enable = {(chn_mux[5]|chn_mux[4]),(chn_mux[3]|chn_mux[2]),(chn_mux[1]|chn_mux[0])};

reg  pre_ipx_vact_direct=0;
wire pre_px_vact1_wire;
wire pre_px_vact2_wire;

sync_frames i_sync_frames(
	.clk(!sclk0),   // @posedge
	.trig(trig_d),  // active low, always low in free running mode
	//.vacts({spx_vact3,spx_vact2,spx_vact1}), // [2:0] vacts (single cycle) from each of 3 channels
	.vacts({pre_px_vact2_wire,pre_px_vact1_wire,pre_ipx_vact_direct}), // [2:0] vacts (single cycle) from each of 3 channels
	.enchn(chn_enable[2:0]), //  [2:0] enabled channels
	.first(), // vacts from the first sesnor (valid in trigger mode only)
	.sync(sync_frames[2:0])
); // single cycle (@posedge clk), one cycle dealy from vacts.



//////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////

reg ch1_read_allow=0;

reg ch0_en=0;
reg ch0_frame_en=0;

//always @ (negedge sclk0) begin
//	if (rst)                                                    ch0_en <= 0;
//	  else if (!ch3_frame_ready & !(chn_mux_d[5] & chn_mux_d[4])) ch0_en <= 1;
//end	

reg [15:0] ch1_vact_imt_cnt=0;

reg ch0_frame_ready=0;
reg ch0_frame_ready_d=0;
reg disable_ch0=0;

always @ (negedge sclk0) begin
	if (rst|disable_ch0) ch0_frame_en <= 0;
	else
	  if (ch0_frame_ready)                          ch0_frame_en <= 0;	
	  //else if (pre_vg_mode & !px_vact1 & !buf_lock) ch0_frame_en <= 1;	
	  else if (buf_lock & !buf_lock_d) ch0_frame_en <= 1;
end

reg ch2_frame_en=0;
reg ch2_frame_ready=0;
reg ch2_frame_ready_d=0;
reg disable_ch2=0;

always @ (negedge sclk0) begin
	if (rst|disable_ch2) begin
		ch2_frame_en <= 0;
	end
	else begin
		if      (ch2_frame_ready)                  	  ch2_frame_en <= 0;
//		else if (pre_vg_mode & !px_vact2  & !buf_lock) ch2_frame_en <= 1;
		else if (buf_lock & !buf_lock_d) ch2_frame_en <= 1;
	end
end

////////////////////////////////////////////////////////////////////////////////////////////////////
//data to channel 0
///////////////////
reg pre_px_vact1=0, pre_px_vact1_d=0;
reg pre_px_hact1=0, pre_px_hact1_d=0;
reg [15:0] pre_px_hact1_cnt=0;
reg [15:0] pre_px_data1=0;

assign      pre_px_vact1_wire = chn_mux_d[3]? (chn_mux_d[2]? ipx_vact3_dl:ipx_vact2_dl):(ipx_vact1_dl);
wire        pre_px_hact1_wire = chn_mux_d[3]? (chn_mux_d[2]? ipx_hact3_dl:ipx_hact2_dl):(ipx_hact1_dl);
wire [15:0] pre_px_data1_wire = chn_mux_d[3]? (chn_mux_d[2]? {4'b0,ipxd3_dl[11:0]}:{4'b0,ipxd2_dl[11:0]}):({4'b0,ipxd1_dl[11:0]});

wire pre_px_hact1_cnt_rst = (pre_px_vact1 & !pre_px_vact1_d) | (pre_px_hact1_cnt[15:0]==ch0_N_fl[15:0]);

always @ (negedge sclk0) begin
	if (pre_px_hact1_cnt==ch0_N_fl)            pre_px_vact1 <= 0;
	//else if (pre_px_vact1_wire & ch0_frame_en) pre_px_vact1 <= 1;
	else if (buf_lock & !buf_lock_d) pre_px_vact1 <= 1;
	
	pre_px_vact1_d <= pre_px_vact1;
	
	pre_px_hact1   <= pre_px_hact1_wire & pre_px_vact1;
	pre_px_hact1_d <= pre_px_hact1;
	
	if (pre_px_hact1_cnt_rst)                        pre_px_hact1_cnt <= 0;
	else if (!pre_px_hact1 & pre_px_hact1_d)         pre_px_hact1_cnt <= pre_px_hact1_cnt + 1;
	
	pre_px_data1[15:0] <= pre_px_data1_wire[15:0];
end

always @ (negedge sclk0) begin
	if (!px_vact1) disable_ch0 <= pre_disable_input;
end

always @ (negedge sclk0) begin
	if (rst) begin
		px_d1[15:0]   <= 0;
		px_d1_d[15:0] <= 0;
		px_hact1      <= 0;
		px_hact1_d    <= 0;
		px_hact1_dd   <= 0;
	end	
	else begin	 
		px_d1[15:0] <= pre_px_data1;//ipxd3_dl;
		px_d1_d[15:0] <= px_d1[15:0]; // delay sensor data by 1 tact to have time to register HACT goes 0

		px_hact1    <= pre_px_hact1 & ch0_frame_en;
		px_hact1_d  <= px_hact1     & ch0_frame_en;	// delay by 1 tact
		px_hact1_dd <= px_hact1_d;		               // delay by 2 tacts
	end	
	
	px_vact1    <= pre_px_vact1;
	px_vact1_d  <= px_vact1  & ch0_frame_en;	// delay by 1 tact
	px_vact1_dd <= px_vact1_d;			         // delay by 2 tacts		
end 

//////////////////////////////////////////////////////////////////////////////////////////////////////
always @ (negedge sclk0) begin
	if (rst) begin
		ch0_hact_cnt <= 0;
		ch0_wpage      <= 0;
		ch0_wpage_last <= 0;
	end
	else begin

		if (px_hact1_d) ch0_hact_cnt <= ch0_hact_cnt + 1;
		else		       ch0_hact_cnt <= 0;
		
		if  (ch0_hact_cnt[6:0]==127) ch0_wpage <= 1;
		else                         ch0_wpage <= 0;
				
		if  (!px_hact1_d & px_hact1_dd) ch0_wpage_last <= 1;
		else 		                       ch0_wpage_last <= 0;
	end				
end

always @ (negedge sclk0) begin
	if (mcontr_rst)
		ch0a[10:0] <= 0;
	else
		if      (ch0_wpage_last) ch0a[10:0] <= {ch0a[10:7]+{3'b0,ch0a[6]|ch0a[5]|ch0a[4]|ch0a[3]|ch0a[2]|ch0a[1]|ch0a[0]},7'b0};
		else if (px_hact1_d)     ch0a[10:0] <= ch0a[10:0] + 1;
end

wire ch0_frame_done;
reg [3:0] ch0_frames_in_sdram=0;

always @ (negedge sclk0) begin
	if (rst) begin
		ch0_frame_ready   <= 0;
		ch0_frame_ready_d <= 0;
	end
	else begin
		//if (ch0_frame_done & (ch0_frames_in_sdram==1))  ch0_frame_ready <= 0;
		if (ch0_frame_done)                             ch0_frame_ready <= 0;
		else if (!px_vact1 & px_vact1_d & ch0_frame_en) ch0_frame_ready <= 1;

		ch0_frame_ready_d <= ch0_frame_ready;
	end
end

always @ (negedge sclk0) begin
	if (rst) begin
		ch0_frames_in_sdram <= 0;
	end
	else begin
		if (!px_vact1 & px_vact1_d & ch0_frame_en) ch0_frames_in_sdram <= ch0_frames_in_sdram + 1;
		else if (ch0_frame_done)                   ch0_frames_in_sdram <= ch0_frames_in_sdram - 1;
	end
end

//////////////////////////////////////////////////////////////////////////////////////////////////////
//data to channel 2
///////////////////
reg pre_px_vact2=0, pre_px_vact2_d=0;
reg pre_px_hact2=0, pre_px_hact2_d=0;
reg [15:0] pre_px_hact2_cnt=0;
reg [15:0] pre_px_data2=0;

assign      pre_px_vact2_wire = chn_mux_d[5]? (chn_mux_d[4]? ipx_vact3_dl:ipx_vact2_dl):(ipx_vact1_dl);
wire        pre_px_hact2_wire = chn_mux_d[5]? (chn_mux_d[4]? ipx_hact3_dl:ipx_hact2_dl):(ipx_hact1_dl);
wire [15:0] pre_px_data2_wire = chn_mux_d[5]? (chn_mux_d[4]? {4'b0,ipxd3_dl[11:0]}:{4'b0,ipxd2_dl[11:0]}):({4'b0,ipxd1_dl[11:0]});

wire pre_px_hact2_cnt_rst = (pre_px_vact2 & !pre_px_vact2_d) | (pre_px_hact2_cnt[15:0]==ch2_N_fl[15:0]);

always @ (negedge sclk0) begin
	if (pre_px_hact2_cnt==ch2_N_fl)            pre_px_vact2 <= 0;
	//else if (pre_px_vact2_wire & ch2_frame_en) pre_px_vact2 <= 1;
	else if (buf_lock & !buf_lock_d) pre_px_vact2 <= 1;
	
	pre_px_vact2_d <= pre_px_vact2;
	
	pre_px_hact2   <= pre_px_hact2_wire & pre_px_vact2;
	pre_px_hact2_d <= pre_px_hact2;
	
	if (pre_px_hact2_cnt_rst)                        pre_px_hact2_cnt <= 0;
	else if (!pre_px_hact2 & pre_px_hact2_d)         pre_px_hact2_cnt <= pre_px_hact2_cnt + 1;
	
	pre_px_data2[15:0] <= pre_px_data2_wire[15:0];
end

always @ (negedge sclk0) begin
	if (!px_vact2) disable_ch2 <= pre_disable_input;
end

always @ (negedge sclk0) begin
	if (rst) begin
		px_d2[15:0]   <= 0;
		px_d2_d[15:0] <= 0;
		px_hact2      <= 0;
		px_hact2_d    <= 0;
		px_hact2_dd   <= 0;
	end	
	else begin	 
		px_d2[15:0]   <= pre_px_data2[15:0];
		px_d2_d[15:0] <= px_d2[15:0];// delay sensor data by 1 tact to have time to catch HACT goes 0

		px_hact2    <= pre_px_hact2 & ch2_frame_en;
		px_hact2_d  <= px_hact2     & ch2_frame_en;// delay by 1 tact
		px_hact2_dd <= px_hact2_d;                 // delay by 2 tacts
	end	
	
	px_vact2    <= pre_px_vact2;
	px_vact2_d  <= px_vact2  & ch2_frame_en;	// delay by 1 tact
	px_vact2_dd <= px_vact2_d;			         // delay by 2 tacts	
	
end 

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////
always @ (negedge sclk0) begin
	if (rst) begin
		ch2_hact_cnt <= 0;
		ch2_wpage <= 0;
		ch2_wpage_last <= 0;
	end
	else begin

		if (px_hact2_d) ch2_hact_cnt <= ch2_hact_cnt + 1;
		else		       ch2_hact_cnt <= 0;
		
		if  (ch2_hact_cnt[6:0]==127) ch2_wpage <= 1;
		else                         ch2_wpage <= 0;
				
		if  (!px_hact2_d & px_hact2_dd) ch2_wpage_last <= 1;
		else 		                       ch2_wpage_last <= 0;
	end				
end

always @ (negedge sclk0) begin
	if (mcontr_rst)
		ch2a[10:0] <= 0;
	else
		if      (ch2_wpage_last) ch2a[10:0] <= {ch2a[10:7]+{3'b0,ch2a[6]|ch2a[5]|ch2a[4]|ch2a[3]|ch2a[2]|ch2a[1]|ch2a[0]},7'b0};
		else if (px_hact2_d)     ch2a[10:0] <= ch2a[10:0] + 1;
end

wire ch2_frame_done;
reg [3:0] ch2_frames_in_sdram=0;

always @ (negedge sclk0) begin
	if (rst) begin
		ch2_frame_ready   <= 0;
		ch2_frame_ready_d <= 0;
	end
	else begin
		//if (ch2_frame_done & (ch2_frames_in_sdram==1))  ch2_frame_ready <= 0;
		if (ch2_frame_done)                             ch2_frame_ready <= 0;
		else if (!px_vact2 & px_vact2_d & ch2_frame_en) ch2_frame_ready <= 1;

		ch2_frame_ready_d <= ch2_frame_ready;
	end
end

always @ (negedge sclk0) begin
	if (rst) begin
		ch2_frames_in_sdram <= 0;
	end
	else begin
		if (!px_vact2 & px_vact2_d & ch2_frame_en) ch2_frames_in_sdram <= ch2_frames_in_sdram + 1;
		else if (ch2_frame_done)                   ch2_frames_in_sdram <= ch2_frames_in_sdram - 1;
	end
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// channel 1 read
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
reg ch1_read_start=0;

reg ch1_frame_done=0;
assign ch0_frame_done=ch1_frame_done;

wire ch1_frame_ready   = ch0_frame_ready;
wire ch1_frame_ready_d = ch0_frame_ready_d;

reg [11:0] ch1_line_cnt=0;
reg ch1_line_done=0;
reg ch1_line_done_d=0;
reg ch1_block_reads=0;

reg ch1_line_pause_cnt_en=0, ch1_line_pause_cnt_en_d=0;
reg [15:0] ch1_line_pause_cnt=0;

always @ (negedge sclk0) begin
	if (rst) begin
		stch1_first <= 0;
		ch1weo_cnt <= 0;
		ch1_line_ready <= 0; 
		ch1_line_ready_d <= 0;			
		stch1 <= 0;
		ch1_block_reads <= 0;
		ch1_line_pause_cnt_en <= 0;
		ch1_line_pause_cnt_en_d <= 0;
		ch1_line_pause_cnt <= 0;		
	end
	else begin	
				
		if (ch1_frame_ready & ch1_line_done_d & !ch1_frame_done)   ch1_line_pause_cnt_en <= 1;
		else if (ch1_read_start)                                   ch1_line_pause_cnt_en <= 1;
		else if (ch1_line_pause_cnt[15:0]==IX0[15:0])              ch1_line_pause_cnt_en <= 0;
		
		ch1_line_pause_cnt_en_d <= ch1_line_pause_cnt_en;
		
		if (ch1_line_pause_cnt_en) ch1_line_pause_cnt <= ch1_line_pause_cnt + 1;
		else                       ch1_line_pause_cnt <= 0;
				
		//if      (ch1_frame_ready & ch1_line_done_d & !ch1_frame_done) stch1_first <= 1; // start of a new line
		if      (ch1_line_pause_cnt_en & !ch1_line_pause_cnt_en_d) stch1_first <= 1; // start of a new line
		//else if (ch1_read_start)                                      stch1_first <= 1;
		//else if (ch1_frame_ready & !ch1_frame_ready_d)                stch1_first <= 1;
		else                                                          stch1_first <= 0;
	
		if      (ch1weo)       ch1weo_cnt <= ch1weo_cnt + 1;
		else if (stch1_first)  ch1weo_cnt <= 0;
		
		if      (ch1_line_done)                                    ch1_line_ready <= 0; // end of line
		//else if (ch1weo_cnt==ch0_N_fp[15:1])              ch1_line_ready <= 1;
		//else if (ch1weo_cnt==32 & !ch1_line_pause_cnt_en)          ch1_line_ready <= 1;
		else if (!ch1_line_pause_cnt_en & ch1_line_pause_cnt_en_d) ch1_line_ready <= 1;
		
		ch1_line_ready_d <= ch1_line_ready;
			
		//if (ch1weo_cnt[5:0]==63 & !ch1_line_ready) stch1 <= 1;
		//if (ch1weo_cnt[5:0]==63 & ch1_hact_imt) stch1 <= 1;
		if (ch1weo_cnt[5:0]==63) stch1 <= !ch1_block_reads;
		else                                    stch1 <= 0;
		
		if      (ch1_line_done)                           ch1_block_reads <= 0; // end of line
		else if (ch1weo_cnt==ch0_N_fp[15:1])              ch1_block_reads <= 1;		
		
	end	
end

wire ch1_blank_lines_start;

always @ (negedge sclk0) begin
	if (mcontr_rst) begin
		ch1_line_cnt <= 0;
		ch1a <= 0;
		ch1_hact_imt <= 0;
		ch1_hact_imt_d <= 0;
		ch1_line_done <= 0;
		ch1_line_done_d <= 0;
		ch1_vact_imt_cnt <= 0;
		ch1_frame_done <= 0;
	end
	else begin
		if (ch1_line_ready & !ch1_line_done) ch1_line_cnt <= ch1_line_cnt + 1;//pixel counter
		else                                 ch1_line_cnt <= 0;
		
		if (ch1_line_cnt==ch0_N_fp[11:0])         ch1a <= {ch1a[11:7]+{4'b0,|(ch1a[6:0])},7'b0};
		else if (ch1_line_ready & !ch1_line_done) ch1a <= ch1a + 1;//buffer address
		
		if       (stch1_first | ch1_blank_lines_start)    ch1_vact_imt <= 1;
		else if  (ch1_frame_done)                         ch1_vact_imt <= 0;
	
		if (ch1_line_cnt==ch0_N_fp[11:0])            ch1_hact_imt <= 0;
		else if (ch1_line_ready & !ch1_line_ready_d) ch1_hact_imt <= 1;
		
		ch1_hact_imt_d <= ch1_hact_imt;
	
		//if (ch1_line_cnt[6:0]==127 & !ch1_hact_imt) ch1_line_done <=1; 
		//if (!ch1_line_pause_cnt_en & ch1_line_pause_cnt_en_d) ch1_line_done <= 1;
		if (ch1_line_cnt==ch0_N_fp[11:0]) ch1_line_done <= 1;
		else                              ch1_line_done <= 0;
				
		ch1_line_done_d <= ch1_line_done;
	
		if      (stch1_first)      ch1_vact_imt_cnt <= ch1_vact_imt_cnt + 1;
		else if (!ch1_frame_ready) ch1_vact_imt_cnt <= 0;
		
		if (ch1_vact_imt_cnt==ch0_N_fl & ch1_line_done) ch1_frame_done <= 1;
		else                                            ch1_frame_done <= 0;	
	end	
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// channel 3 read
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
reg ch3_read_start=0;

reg    ch3_frame_done=0;
assign ch2_frame_done=ch3_frame_done;

wire ch3_frame_ready   = ch2_frame_ready;
wire ch3_frame_ready_d = ch2_frame_ready_d;

reg [11:0] ch3_line_cnt=0;
reg  ch3_line_done=0;
reg  ch3_line_done_d=0;
reg ch3_block_reads=0;

reg ch3_line_pause_cnt_en=0, ch3_line_pause_cnt_en_d=0;
reg [15:0] ch3_line_pause_cnt=0;

always @ (negedge sclk0) begin
	if (rst) begin
		stch3_first <= 0;
		ch3weo_cnt <= 0;
		ch3_line_ready <= 0; 
		ch3_line_ready_d <= 0;			
		stch3 <= 0;
		ch3_block_reads <= 0;
		ch3_line_pause_cnt_en <= 0;
		ch3_line_pause_cnt_en_d <= 0;
		ch3_line_pause_cnt <= 0;		
	end
	else begin	

		if (ch3_frame_ready & ch3_line_done_d & !ch3_frame_done)   ch3_line_pause_cnt_en <= 1;
		else if (ch3_read_start)                                   ch3_line_pause_cnt_en <= 1;
		else if (ch3_line_pause_cnt[15:0]==IX1[15:0])              ch3_line_pause_cnt_en <= 0;
		
		ch3_line_pause_cnt_en_d <= ch3_line_pause_cnt_en;
		
		if (ch3_line_pause_cnt_en) ch3_line_pause_cnt <= ch3_line_pause_cnt + 1;
		else                       ch3_line_pause_cnt <= 0;

		//if      (ch3_frame_ready & ch3_line_done_d & !ch3_frame_done) stch3_first <= 1; // start of a new line
		if      (ch3_line_pause_cnt_en & !ch3_line_pause_cnt_en_d) stch3_first <= 1; // start of a new line
		//else if (ch3_read_start)                                      stch3_first <= 1;
		//else if (ch3_frame_ready & !ch3_frame_ready_d)                stch3_first <= 1;
		else                                                          stch3_first <= 0;
	
		if      (ch3weo)       ch3weo_cnt <= ch3weo_cnt + 1;
		else if (stch3_first)  ch3weo_cnt <= 0;
		
		if      (ch3_line_done)                                    ch3_line_ready <= 0; // end of line
		//else if (ch3weo_cnt==ch0_N_fp[15:1])              ch3_line_ready <= 1;
		//else if (ch3weo_cnt==32 & !ch3_line_pause_cnt_en)          ch3_line_ready <= 1;
		else if (!ch3_line_pause_cnt_en & ch3_line_pause_cnt_en_d) ch3_line_ready <= 1;		
		
		ch3_line_ready_d <= ch3_line_ready;
			
		//if (ch3weo_cnt[5:0]==63 & !ch3_line_ready) stch3 <= 1;
		if (ch3weo_cnt[5:0]==63) stch3 <= !ch3_block_reads;
		else                                    stch3 <= 0;
			
		if      (ch3_line_done)                           ch3_block_reads <= 0; // end of line
		else if (ch3weo_cnt==ch2_N_fp[15:1])              ch3_block_reads <= 1;
			
	end	
end

wire ch3_blank_lines_start;

always @ (negedge sclk0) begin
	if (mcontr_rst) begin
		ch3_line_cnt <= 0;
		ch3a <= 0;
		ch3_hact_imt <= 0;
		ch3_hact_imt_d <= 0;
		ch3_line_done <= 0;
		ch3_line_done_d <= 0;
		ch3_vact_imt_cnt <= 0;
		ch3_frame_done <= 0;
	end
	else begin
		if (ch3_line_ready & !ch3_line_done) ch3_line_cnt <= ch3_line_cnt + 1;//pixel counter
		else                                 ch3_line_cnt <= 0;
		
		if (ch3_line_cnt==ch2_N_fp[11:0])         ch3a <= {ch3a[11:7]+{4'b0,|(ch3a[6:0])},7'b0};
		else if (ch3_line_ready & !ch3_line_done) ch3a <= ch3a + 1;//buffer address

		if       (stch3_first | ch3_blank_lines_start) ch3_vact_imt <= 1;
		else if  (ch3_frame_done)                      ch3_vact_imt <= 0;
	
		if (ch3_line_cnt==ch2_N_fp[11:0])            ch3_hact_imt <= 0;
		else if (ch3_line_ready & !ch3_line_ready_d) ch3_hact_imt <= 1;
		
		ch3_hact_imt_d <= ch3_hact_imt;
	
		//if (ch3_line_cnt[6:0]==127 & !ch3_hact_imt) ch3_line_done <=1;
		//if (!ch3_line_pause_cnt_en & ch3_line_pause_cnt_en_d) ch3_line_done <=1;
		if (ch3_line_cnt==ch2_N_fp[11:0]) ch3_line_done <=1;		
		else                              ch3_line_done <=0;
				
		ch3_line_done_d <= ch3_line_done;
	
		if      (stch3_first)      ch3_vact_imt_cnt <= ch3_vact_imt_cnt + 1;
		else if (!ch3_frame_ready) ch3_vact_imt_cnt <= 0;
		
		if (ch3_vact_imt_cnt==ch2_N_fl & ch3_line_done) ch3_frame_done <= 1;
		else                                            ch3_frame_done <= 0;	
	end	
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// reads managing

reg vact_vglued_d=0;
reg hact_vglued_d=0;
reg [11:0] pixd_vglued_d=0;

reg ipx_vact_buffered_d=0;
reg ipx_hact_buffered_d=0;
reg [11:0] ipxd_buffered_d=0;

reg        buf_cnt_en=0;
reg        buf_cnt_en_d=0;
reg [15:0] buf_cnt=0;

reg        buf_pix_cnt_en=0;
reg [15:0] buf_pix_cnt=0;

reg        buf_cnt_en2=0;
reg        buf_cnt_en2_d=0;
reg [15:0] buf_cnt2=0;

reg        buf_pix_cnt2_en=0;
reg [15:0] buf_pix_cnt2=0;

reg ivd_del=0;

reg vg_mode_direct = 0;
reg vg_mode_buffered = 0;

reg vg_mode_direct_d = 0;
reg vg_mode_buffered_d = 0;

reg vg_mode_buffered_1 = 0;
reg vg_mode_buffered_1_d = 0;

reg vg_mode_ch1_blank_lines = 0, vg_mode_ch1_blank_lines_d = 0;
reg vg_mode_ch3_blank_lines = 0, vg_mode_ch3_blank_lines_d = 0;

reg ch1_blank_lines_done=0;
reg ch3_blank_lines_done=0;

always @ (negedge sclk0) begin
		//if (vg_mode_direct_d & !vg_mode_direct & !combine_into_two_frames & ch1_frame_ready) ch1_read_start <= 1;
		//if ((vg_mode_buffered_1 & !vg_mode_ch1_blank_lines) & ch1_frame_ready & !ch1_frame_ready_d)                       ch1_read_start <= 1;
		if ((vg_mode_buffered & !vg_mode_ch1_blank_lines) & ch1_frame_ready & !ch1_frame_ready_d)                    ch1_read_start <= 1;
		//if (buf_cnt_en2_d & !buf_cnt_en2  & ch1_frame_ready)                                 ch1_read_start <= 1;
		else if (ch1_blank_lines_done)                                                       ch1_read_start <= 1;
		else                                                                            ch1_read_start <= 0;
end

always @ (negedge sclk0) begin
		//if (vg_mode_direct_d & !vg_mode_direct & !combine_into_two_frames & ch3_frame_ready) ch3_read_start <= 1;
		//if ((vg_mode_buffered & !vg_mode_ch3_blank_lines) & ch3_frame_ready & !ch3_frame_ready_d)                    ch3_read_start <= 1;
		if ((vg_mode_buffered_1 & !vg_mode_ch3_blank_lines) & ch3_frame_ready & !ch3_frame_ready_d) ch3_read_start <= 1;
		//else if (buf_cnt_en_d & !buf_cnt_en)                                                 ch3_read_start <= 1;
		else if (ch3_blank_lines_done)                                                       ch3_read_start <= 1;
		else                                                                                 ch3_read_start <= 0;
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ch3 blank header

always @ (negedge sclk0) begin
	vg_mode_ch3_blank_lines_d <= vg_mode_ch3_blank_lines;
end

assign ch3_blank_lines_start = (vg_mode_ch3_blank_lines & !vg_mode_ch3_blank_lines_d & ch3_frame_ready) | (vg_mode_ch3_blank_lines & ch3_frame_ready & !ch3_frame_ready_d);

reg [15:0] ch3_blank_line_cnt = 0;

reg ch3_blank_vact_imt=0;

reg ch3_blank_hact_imt=0;
reg ch3_blank_hact_imt_d=0;
reg ch3_blank_line_done_d=0;

reg       ch3_blank_cnt_en=0;
reg       ch3_blank_cnt_en_d=0;
reg [15:0] ch3_blank_cnt=0;

wire ch3_blank_line_ready=ch3_blank_vact_imt;
reg ch3_blank_line_ready_d=0;

reg [15:0] ch3_blank_vact_imt_cnt=0;

wire ch3_blank_line_done  = !ch3_blank_hact_imt & ch3_blank_hact_imt_d;
wire ch3_blank_line_start = !ch3_blank_cnt_en & ch3_blank_cnt_en_d  & !ch3_blank_lines_done;


always @ (negedge sclk0) begin
	if (rst) begin
		ch3_blank_vact_imt <= 0;	
		ch3_blank_line_cnt <= 0;
		ch3_blank_hact_imt <= 0;
		ch3_blank_hact_imt_d <= 0;
		ch3_blank_cnt_en <= 0;
		ch3_blank_cnt_en_d <= 0;
		ch3_blank_cnt <= 0;
		ch3_blank_line_done_d <= 0;
		ch3_blank_vact_imt_cnt <= 0;
		ch3_blank_lines_done <= 0;
	end
	else begin
		if       (ch3_blank_lines_start) ch3_blank_vact_imt <= 1;
		else if  (ch3_blank_lines_done)  ch3_blank_vact_imt <= 0;	
	
		if (ch3_blank_hact_imt) ch3_blank_line_cnt <= ch3_blank_line_cnt + 1;//pixel counter
		else                    ch3_blank_line_cnt <= 0;
	
		if (ch3_blank_line_cnt[15:0]==ch2_N_fp[15:0]-1)     ch3_blank_hact_imt <= 0;
		else if (ch3_blank_line_start & ch3_blank_vact_imt) ch3_blank_hact_imt <= 1;
	
		ch3_blank_hact_imt_d <= ch3_blank_hact_imt;
		
		if (ch3_blank_line_done | ch3_blank_lines_start)                    ch3_blank_cnt_en <= 1;
		else if ((ch3_blank_cnt[15:0]==IX1[15:0]-1) | ch3_blank_lines_done) ch3_blank_cnt_en <= 0;
		
		ch3_blank_cnt_en_d <= ch3_blank_cnt_en;
		
		if (ch3_blank_cnt_en) ch3_blank_cnt <= ch3_blank_cnt + 1;
		else                  ch3_blank_cnt <= 0;
		
		ch3_blank_line_done_d <= ch3_blank_line_done;
	
		if      (ch3_blank_line_done)   ch3_blank_vact_imt_cnt <= ch3_blank_vact_imt_cnt + 1;
		else if (ch3_blank_lines_done)  ch3_blank_vact_imt_cnt <= 0;
		
		if (ch3_blank_vact_imt_cnt==BL1[15:0] & (ch3_blank_line_done_d | ch3_blank_lines_start)) ch3_blank_lines_done <= 1;
		else                                                                                     ch3_blank_lines_done <= 0;	
		
	end	
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ch1 blank header

always @ (negedge sclk0) begin
	vg_mode_ch1_blank_lines_d <= vg_mode_ch1_blank_lines;
end

assign ch1_blank_lines_start = (vg_mode_ch1_blank_lines & !vg_mode_ch1_blank_lines_d & ch1_frame_ready) | (ch1_frame_ready & !ch1_frame_ready_d & vg_mode_ch1_blank_lines);

reg [15:0] ch1_blank_line_cnt = 0;

reg ch1_blank_vact_imt=0;

reg ch1_blank_hact_imt=0;
reg ch1_blank_hact_imt_d=0;
reg ch1_blank_line_done_d=0;

reg       ch1_blank_cnt_en=0;
reg       ch1_blank_cnt_en_d=0;
reg [15:0] ch1_blank_cnt=0;

wire ch1_blank_line_ready=ch1_blank_vact_imt;
reg ch1_blank_line_ready_d=0;

reg [15:0] ch1_blank_vact_imt_cnt=0;

wire ch1_blank_line_done  = !ch1_blank_hact_imt & ch1_blank_hact_imt_d;
wire ch1_blank_line_start = !ch1_blank_cnt_en & ch1_blank_cnt_en_d & !ch1_blank_lines_done;

always @ (negedge sclk0) begin
	if (rst) begin
		ch1_blank_vact_imt <= 0;	
		ch1_blank_line_cnt <= 0;
		ch1_blank_hact_imt <= 0;
		ch1_blank_hact_imt_d <= 0;
		ch1_blank_cnt_en <= 0;
		ch1_blank_cnt_en_d <= 0;
		ch1_blank_cnt <= 0;
		ch1_blank_line_done_d <= 0;
		ch1_blank_vact_imt_cnt <= 0;
		ch1_blank_lines_done <= 0;
	end
	else begin
		if       (ch1_blank_lines_start) ch1_blank_vact_imt <= 1;
		else if  (ch1_blank_lines_done)  ch1_blank_vact_imt <= 0;	
	
		if (ch1_blank_hact_imt) ch1_blank_line_cnt <= ch1_blank_line_cnt + 1;//pixel counter
		else                    ch1_blank_line_cnt <= 0;
	
		if (ch1_blank_line_cnt[15:0]==ch0_N_fp[15:0]-1)     ch1_blank_hact_imt <= 0;
		else if (ch1_blank_line_start & ch1_blank_vact_imt) ch1_blank_hact_imt <= 1;
	
		ch1_blank_hact_imt_d <= ch1_blank_hact_imt;
		
		if (ch1_blank_line_done | ch1_blank_lines_start)                    ch1_blank_cnt_en <= 1;
		else if ((ch1_blank_cnt[15:0]==IX0[15:0]-1) | ch1_blank_lines_done) ch1_blank_cnt_en <= 0;
		
		ch1_blank_cnt_en_d <= ch1_blank_cnt_en;
		
		if (ch1_blank_cnt_en) ch1_blank_cnt <= ch1_blank_cnt + 1;
		else                  ch1_blank_cnt <= 0;
		
		ch1_blank_line_done_d <= ch1_blank_line_done;
	
		if      (ch1_blank_line_done)   ch1_blank_vact_imt_cnt <= ch1_blank_vact_imt_cnt + 1;
		else if (ch1_blank_lines_done)  ch1_blank_vact_imt_cnt <= 0;
		
		if (ch1_blank_vact_imt_cnt==BL0[15:0] & (ch1_blank_line_done_d | ch1_blank_lines_start)) ch1_blank_lines_done <= 1;
		else                                                                                     ch1_blank_lines_done <= 0;	
		
	end	
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

reg ipx_bpf_direct=0;
reg ipx_vact_direct=0;
reg ipx_hact_direct=0;
reg [11:0] ipxd_direct=0;

always @ (negedge sclk0)
begin

	ivd_del <= ipx_vact_direct;

	if (rst) 
		begin
			vg_mode_direct <= 0;
			vg_mode_buffered <= 0;
			buf_lock <= 0;
			buf_cnt_en <= 0;
			buf_cnt_en2 <= 0;
			buf_cnt <= 0;
			buf_cnt2 <= 0;
		end
	else 
		begin
			if (vg_mode_buffered_1_d & !vg_mode_buffered_1)                   buf_lock <= 0;
			else if (!chn_enable[2] & vg_mode_buffered_d & !vg_mode_buffered) buf_lock <= 0;
			else if (!chn_enable[1] & vg_mode_direct_d   & !vg_mode_direct)   buf_lock <= 0;
			//else if (!ivd_del & ipx_vact_direct & !buf_lock & vg_mode) buf_lock <= 1;
			else if ((|(sync_frames[2:0])) & !buf_lock & pre_vg_mode) buf_lock <= 1; // waiting for the first out of 3
			
			if      (ivd_del & !ipx_vact_direct &  buf_lock)      vg_mode_direct <= 0;
			else if ((|(sync_frames[2:0])) & !buf_lock & pre_vg_mode) vg_mode_direct <= 1;
			
			if (vg_mode_direct_d & !vg_mode_direct & combine_into_two_frames) buf_cnt_en <= 1;
			else if (buf_cnt[15:0]==MAX_DELAY[15:0])                          buf_cnt_en <= 0;
			
			if (buf_pix_cnt==ch0_N_fp-1) buf_pix_cnt <= 0;
			else if (buf_cnt_en)         buf_pix_cnt <= buf_pix_cnt + 1;
			else                         buf_pix_cnt <= 0;
			
			if (buf_cnt[15:0]==MAX_DELAY[15:0]) buf_cnt <= 0;
			else if (buf_pix_cnt==ch0_N_fp-1)   buf_cnt <= buf_cnt + 1;
			//else                         buf_cnt <= 0;
			
			if (ch1_frame_done & buf_lock)                                                          vg_mode_buffered <= 0;
			else if (vg_mode_direct_d & !vg_mode_direct & chn_enable[1] & !combine_into_two_frames) vg_mode_buffered <= 1;
			else if (ch1_blank_lines_done)                                                          vg_mode_buffered <= 1;
			
			if (buf_cnt_en_d & !buf_cnt_en)                                                         vg_mode_ch1_blank_lines <= 1;
			else if (vg_mode_direct_d & !vg_mode_direct & chn_enable[1] & !combine_into_two_frames) vg_mode_ch1_blank_lines <= 1;
			else if (ch1_blank_lines_done)                                                          vg_mode_ch1_blank_lines <= 0;
		
			if (vg_mode_buffered_d & !vg_mode_buffered  & combine_into_two_frames) buf_cnt_en2 <= 1;
			else if (buf_cnt2[15:0]==MAX_DELAY[15:0])                              buf_cnt_en2 <= 0;
			
			if (buf_pix_cnt2==ch2_N_fp-1) buf_pix_cnt2 <= 0;
			else if (buf_cnt_en2)         buf_pix_cnt2 <= buf_pix_cnt2 + 1;
			else                          buf_pix_cnt2 <= 0;
			
			if (buf_cnt2[15:0]==MAX_DELAY[15:0]) buf_cnt2 <= 0;
			else if (buf_pix_cnt2==ch2_N_fp-1)   buf_cnt2 <= buf_cnt2 + 1;
			//else                         buf_cnt2 <= 0;			

			if (buf_cnt_en2_d & !buf_cnt_en2)                                                           vg_mode_ch3_blank_lines <= 1;
			else if (vg_mode_buffered_d & !vg_mode_buffered & chn_enable[2] & !combine_into_two_frames) vg_mode_ch3_blank_lines <= 1;			
			else if (ch3_blank_lines_done)                                                              vg_mode_ch3_blank_lines <= 0;

			if (ch3_frame_done & buf_lock)                                                              vg_mode_buffered_1 <= 0;
			else if (vg_mode_buffered_d & !vg_mode_buffered & chn_enable[2] & !combine_into_two_frames) vg_mode_buffered_1 <= 1;
			else if (ch3_blank_lines_done)                                                              vg_mode_buffered_1 <= 1;			
			
		end
	
	buf_lock_d    <= buf_lock;
	buf_cnt_en_d  <= buf_cnt_en;
	buf_cnt_en2_d <= buf_cnt_en2;
	vg_mode_direct_d   <= vg_mode_direct;
	vg_mode_buffered_d <= vg_mode_buffered;
	vg_mode_buffered_1_d <= vg_mode_buffered_1;
end
	
// Vertical Sync
always @ (negedge sclk0)
begin
	if      (rst | !buf_lock)          vact_vglued_d <= 0;
	else if (!combine_into_two_frames) vact_vglued_d <= buf_lock;
	else if (vg_mode_ch1_blank_lines)  vact_vglued_d <= ch1_vact_imt;//ch1_blank_vact_imt;		
	else if (vg_mode_buffered)         vact_vglued_d <= ch1_vact_imt;	
	else if (vg_mode_ch3_blank_lines)  vact_vglued_d <= ch3_vact_imt;//ch3_blank_vact_imt;	
	else if (vg_mode_buffered_1)       vact_vglued_d <= ch3_vact_imt;
	else if (vg_mode_direct)           vact_vglued_d <= ipx_vact_direct;
	else                               vact_vglued_d <= 0;
end

wire ch1_hact_imt_wire=ch1_hact_delay?ch1_hact_imt_d:ch1_hact_imt;
wire ch3_hact_imt_wire=ch3_hact_delay?ch3_hact_imt_d:ch3_hact_imt;

// Horizontal Sync
always @ (negedge sclk0)
begin
	if (rst)
		begin
			hact_vglued_d   <= 0;
			pixd_vglued_d[11:0] <= 0;			
		end
	else
	if (vg_mode_ch1_blank_lines)
		begin
			hact_vglued_d   <= ch1_blank_hact_imt | ch1_blank_hact_imt_d;
			pixd_vglued_d[11:0] <= 0;
		end			
	else 		
	if (vg_mode_buffered)
		begin
			hact_vglued_d   <= ch1_hact_imt_wire;// | ch1_hact_imt_d;
			pixd_vglued_d[11:0] <= ch1do[11:0];
		end			
	else 	
	if (vg_mode_ch3_blank_lines)
		begin
			hact_vglued_d   <= ch3_blank_hact_imt | ch3_blank_hact_imt_d;
			pixd_vglued_d[11:0] <= 0;
		end			
	else 	
	if (vg_mode_buffered_1)
		begin
			hact_vglued_d   <= ch3_hact_imt_wire;// | ch3_hact_imt_d;
			pixd_vglued_d[11:0] <= ch3do[11:0];
		end			
	else 
	if (vg_mode_direct)
		begin
			hact_vglued_d   <= ipx_hact_direct;
			pixd_vglued_d[11:0] <= ipxd_direct;		
		end
	else
		begin
			hact_vglued_d   <= 0;
			pixd_vglued_d[11:0] <= 0;		
		end
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	reg [2:0] pre_hact_regen=0;
	reg n_lines_reset=0;
	
	reg ch1_n_lines_reset=0;
	reg ch2_n_lines_reset=0;
	reg ch3_n_lines_reset=0;	

	reg pre_ch1_hact_delay=0;
	reg pre_ch3_hact_delay=0;

	reg [15:0] pre_BL0=0;
	reg [15:0] pre_BL1=0;
	reg [15:0] pre_IX0=255;
	reg [15:0] pre_IX1=255;

	always @ (negedge sclk0) begin
			if (da_set_dfs_x) pre_dir_N_fp <= idi[15:0];
			if (da_set_dfs_y) pre_dir_N_fl <= idi[15:0];	
			
			if (da_hact_regen) pre_hact_regen[2:0] <= idi[2:0];	
			
			if (da_hact_regen & idi[4]) ch1_n_lines_reset <= 1;
			else                        ch1_n_lines_reset <= 0;

			if (da_hact_regen & idi[5]) ch2_n_lines_reset <= 1;
			else                        ch2_n_lines_reset <= 0;
			
			if (da_hact_regen & idi[6]) ch3_n_lines_reset <= 1;
			else                        ch3_n_lines_reset <= 0;			
	
			if (da_set_fs0_x) pre_ch0_N_fp <= idi[15:0];
			if (da_set_fs0_y) pre_ch0_N_fl <= idi[15:0];

			if (da_set_fs1_x) pre_ch2_N_fp <= idi[15:0];
			if (da_set_fs1_y) pre_ch2_N_fl <= idi[15:0];
			
			if (da_hact_delay) pre_ch1_hact_delay <= idi[0];
			if (da_hact_delay) pre_ch3_hact_delay <= idi[1];				
			
			if (da_set_fs0_blank) pre_BL0 <= idi[15:0];			
			if (da_set_fs1_blank) pre_BL1 <= idi[15:0];
			
			if (da_set_fs0_nhact) pre_IX0 <= idi[15:0];
			if (da_set_fs1_nhact) pre_IX1 <= idi[15:0];
	end	
			
	always @ (negedge sclk0) begin			
	// changes are applied when nothing works
		if (rst) begin
			dir_N_fl <= pre_dir_N_fl[13:0];
			dir_N_fp <= pre_dir_N_fp;
			hact_regen[2:0] <= pre_hact_regen[2:0];
			ch0_N_fl <= pre_ch0_N_fl;
			ch0_N_fp <= pre_ch0_N_fp;
			ch2_N_fl <= pre_ch2_N_fl; //4
			ch2_N_fp <= pre_ch2_N_fp; //1791
			BL0 <= pre_BL0;
			BL1 <= pre_BL1;
			IX0 <= pre_IX0;
			IX1 <= pre_IX1;			
		end
		else begin
			if (|sync_frames[2:0]) begin
				dir_N_fl <= pre_dir_N_fl[13:0];
				dir_N_fp <= pre_dir_N_fp;		
				hact_regen[2:0] <= pre_hact_regen[2:0];				
				ch0_N_fl <= pre_ch0_N_fl;
				ch0_N_fp <= pre_ch0_N_fp;
				ch2_N_fl <= pre_ch2_N_fl; //4
				ch2_N_fp <= pre_ch2_N_fp; //1791
				ch1_hact_delay <= pre_ch1_hact_delay;
				ch3_hact_delay <= pre_ch3_hact_delay;					
				BL0 <= pre_BL0;
				BL1 <= pre_BL1;
				IX0 <= pre_IX0;
				IX1 <= pre_IX1;				
			end
		end
	
		if (da_set_delay) MAX_DELAY[15:0] <= idi[15:0];
		//if (da_set_delay) MAX_DELAY[31:16] <=idi_stored[15:0];
	end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Command   we  cas  ras
// activate   1   1    0
// precharge  0   1    0
// write      0   0    1
// read       1   0    1
// refresh    1   0    0

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Frames Latching

reg ipx_bpf_direct_d=0;
reg ipx_vact_direct_d=0;
reg ipx_hact_direct_d=0;
reg [11:0] ipxd_direct_d=0;

reg    ipx_vact1_dl1_pos, ipx_vact2_dl1_pos, ipx_vact3_dl1_pos;
reg    ipx_hact1_dl1_pos, ipx_hact2_dl1_pos, ipx_hact3_dl1_pos;

reg    ipx_vact1_dl1_neg, ipx_vact2_dl1_neg, ipx_vact3_dl1_neg;
reg    ipx_hact1_dl1_neg, ipx_hact2_dl1_neg, ipx_hact3_dl1_neg;
reg    ipx_vact1_dl2_neg, ipx_vact2_dl2_neg, ipx_vact3_dl2_neg;
reg    ipx_hact1_dl2_neg, ipx_hact2_dl2_neg, ipx_hact3_dl2_neg;

reg [11:0] ipxd1_dl1_neg, ipxd2_dl1_neg, ipxd3_dl1_neg;
reg [11:0] ipxd1_dl2_neg, ipxd2_dl2_neg, ipxd3_dl2_neg;
reg [11:0] ipxd1_dl3_neg, ipxd2_dl3_neg, ipxd3_dl3_neg;

always @ (negedge ipx_dclk1) begin ipx_vact1_dl1_neg <= spx_vact1; ipx_hact1_dl1_neg <= spx_hact1; end
always @ (negedge ipx_dclk2) begin ipx_vact2_dl1_neg <= spx_vact2; ipx_hact2_dl1_neg <= spx_hact2;	end
always @ (negedge ipx_dclk3) begin ipx_vact3_dl1_neg <= spx_vact3; ipx_hact3_dl1_neg <= spx_hact3;	end

always @ (negedge ipx_dclk1) ipxd1_dl1_neg <= spxd1[13:2];
always @ (negedge ipx_dclk2) ipxd2_dl1_neg <= spxd2[13:2];
always @ (negedge ipx_dclk3) ipxd3_dl1_neg <= spxd3[13:2];

always @ (negedge sclk0)
begin
	ipx_vact1_dl2_neg <= ipx_vact1_dl1_neg;//sphase[0]?ipx_vact1_dl1_neg:ipx_vact1_dl1_pos; 
	ipx_hact1_dl2_neg <= ipx_hact1_dl1_neg;

	ipx_vact2_dl2_neg <= ipx_vact2_dl1_neg;//sphase[1]?ipx_vact2_dl1_neg:ipx_vact2_dl1_pos;
	ipx_hact2_dl2_neg <= ipx_hact2_dl1_neg;

	ipx_vact3_dl2_neg <= ipx_vact3_dl1_neg;//sphase[2]?ipx_vact3_dl1_neg:ipx_vact3_dl1_pos;
	ipx_hact3_dl2_neg <= ipx_hact3_dl1_neg;
	
	ipxd1_dl2_neg <= ipxd1_dl1_neg;
	ipxd2_dl2_neg <= ipxd2_dl1_neg;
	ipxd3_dl2_neg <= ipxd3_dl1_neg;
	
	ipxd1_dl3_neg <= ipxd1_dl2_neg; 
	ipxd2_dl3_neg <= ipxd2_dl2_neg;
	ipxd3_dl3_neg <= ipxd3_dl2_neg;		
end

assign ipx_vact1_dl=ipx_vact1_dl2_neg;
assign ipx_hact1_dl=ipx_hact1_dl2_neg;

assign ipx_vact2_dl=ipx_vact2_dl2_neg;
assign ipx_hact2_dl=ipx_hact2_dl2_neg;

assign ipx_vact3_dl=ipx_vact3_dl2_neg;
assign ipx_hact3_dl=ipx_hact3_dl2_neg;

assign ipxd1_dl= ipxd1_dl2_neg;//sphase[4]?ipxd1_dl1_neg:(sphase[3]?ipxd1_dl3_neg:ipxd1_dl2_neg);
assign ipxd2_dl= ipxd2_dl2_neg;//sphase[6]?ipxd2_dl1_neg:(sphase[5]?ipxd2_dl3_neg:ipxd2_dl2_neg);
assign ipxd3_dl= ipxd3_dl2_neg;//sphase[8]?ipxd3_dl1_neg:(sphase[7]?ipxd3_dl3_neg:ipxd3_dl2_neg);

// channel switching
reg mux_tap=0;
reg [7:0] mux_tap_d=0;

reg pre_ivact=0;
reg pre_ihact=0;
reg [11:0] pre_pxdr=0;

always @ (negedge sclk0)
begin
	if ((chn_mux[6:0]!=chn_mux_d[6:0]) & !pre_ivact) chn_mux_d[6:0] <= chn_mux[6:0];
	
	if ((chn_mux[6:0]!=chn_mux_d[6:0]) & !pre_ivact) mux_tap <= 1;
	else if (!pre_ivact & mux_tap_d[7])              mux_tap <= 0;
	
	mux_tap_d[7:0] <= {mux_tap_d[6:0],mux_tap};
end

reg [11:0] ipxd3_cnt=0;
always @(negedge sclk0) begin
	if (ipx_hact_direct) ipxd3_cnt <= ipxd3_cnt + 1;
	else                 ipxd3_cnt <= 0;
end

//////////////////////////////////////////////////////////////////////////////////////////
// channel multiplexer in normal (direct channel) mode
reg pre_ipx_bpf_direct=0;
//reg pre_ipx_vact_direct=0; needed to be declared earlier
reg pre_ipx_hact_direct=0;
reg fvact_direct=0;
reg [11:0] pre_ipxd_direct=0;

always @ (negedge sclk0) 
begin
		if      (chn_mux_d[1:0]==1) pre_ipx_bpf_direct <= ipx_bpf1_dl;
		else if (chn_mux_d[1:0]==2) pre_ipx_bpf_direct <= ipx_bpf2_dl;
		else if (chn_mux_d[1:0]==3) pre_ipx_bpf_direct <= ipx_bpf3_dl;
		else                        pre_ipx_bpf_direct <= 0;
		
		if      (chn_mux_d[1:0]==1) pre_ipx_vact_direct <= ipx_vact1_dl;
		else if (chn_mux_d[1:0]==2) pre_ipx_vact_direct <= ipx_vact2_dl;
		else if (chn_mux_d[1:0]==3) pre_ipx_vact_direct <= ipx_vact3_dl;
		else                        pre_ipx_vact_direct <= 0;
		
		if      (chn_mux_d[1:0]==1) pre_ipx_hact_direct <= ipx_hact1_dl;
		else if (chn_mux_d[1:0]==2) pre_ipx_hact_direct <= ipx_hact2_dl;
		else if (chn_mux_d[1:0]==3) pre_ipx_hact_direct <= ipx_hact3_dl;		
		else                        pre_ipx_hact_direct <= 0;
	
		if      (chn_mux_d[1:0]==1) pre_ipxd_direct <= ipxd1_dl;
		else if (chn_mux_d[1:0]==2) pre_ipxd_direct <= ipxd2_dl;
		else if (chn_mux_d[1:0]==3) pre_ipxd_direct <= ipxd3_dl;
		//else if (chn_mux_d[2]) ipxd_direct <= ipxd3_cnt;
		else                        pre_ipxd_direct <= 0;
		
		if      (chn_mux_d[1:0]==1) fvact_direct <= fvact[0];
		else if (chn_mux_d[1:0]==2) fvact_direct <= fvact[1];
		else if (chn_mux_d[1:0]==3) fvact_direct <= fvact[2];
		else                        fvact_direct <= 0;
	
end

wire pre_vact_direct_wire = pre_ipx_vact_direct;
wire pre_hact_direct_wire = pre_ipx_hact_direct;
wire [11:0] pre_ipxd_direct_wire = pre_ipxd_direct;

reg pre_hact_direct_d=0;
reg [15:0] pre_hact_direct_cnt=0;
reg pre_ipx_vact_direct_d=0;


wire pre_hact_direct_cnt_rst = !ipx_vact_direct & pre_ipx_vact_direct_d;// | (!buf_lock & buf_lock_d); //fall

always @ (negedge sclk0) begin
	// making long vact from short
	if (pre_vact_direct_wire)                          ipx_vact_direct <= 1;
	else if (fvact_direct)                             ipx_vact_direct <= 0;
	//else if (pre_hact_direct_cnt==dir_N_fl & buf_lock) ipx_vact_direct <= 0;
	//else if (pre_vact_direct_wire)     ipx_vact_direct <= 1;
		
	pre_ipx_vact_direct_d <= ipx_vact_direct;
	
	//ipx_hact_direct   <= pre_hact_direct_wire & ipx_vact_direct;
	ipx_hact_direct   <= pre_hact_direct_wire;
	pre_hact_direct_d <= ipx_hact_direct;
	
	if (pre_hact_direct_cnt_rst)                              pre_hact_direct_cnt <= 0;
	else if (!ipx_hact_direct & pre_hact_direct_d & buf_lock) pre_hact_direct_cnt <= pre_hact_direct_cnt + 1;
	
	ipxd_direct[11:0] <= pre_ipxd_direct_wire[11:0];
	ipx_bpf_direct    <= pre_ipx_bpf_direct;
end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Direct alternation mode

reg EnV2_new=0;
reg EnV1_new=0;

reg ipx_vact1_del=0;
reg ipx_vact3_del=0;

reg let_go=0, let_go_d=0;

reg [15:0] SL=1;
always @(negedge sclk0) begin
	if (da_seq_len) SL <= idi[15:0];
end

reg [15:0] env1_cnt=0;
reg [15:0] env2_cnt=0;

wire vact_direct;
wire hact_direct;
wire [11:0] pxd_direct;

always @ (negedge sclk0) 
begin
	ipx_vact1_del <= ipx_vact1_dl;
	ipx_vact3_del <= vact_direct;

	if (chn_mux_d[7]) 
	begin
	
//		if (ipx_vact1_del & !ipx_vact1_dl) EnV1_new <= !EnV1_new;
//		if (ipx_vact1_del & !ipx_vact1_dl) EnV2_new <= EnV1_new;
		
		if      (ipx_vact1_del & !ipx_vact1_dl & !let_go)                     EnV1_new <= 1;
		else if (ipx_vact1_del & !ipx_vact1_dl & EnV1_new & (env1_cnt==SL-1)) EnV1_new <= 0;
	
		if ((let_go & !let_go_d)|(!let_go & let_go_d))      env1_cnt <= 0;
		else if (ipx_vact1_del & !ipx_vact1_dl &  EnV1_new) env1_cnt <= env1_cnt + 1;
	
		if      (ipx_vact1_del & !ipx_vact1_dl & !let_go)                    let_go <= 1;
		else if (ipx_vact3_del & !vact_direct & EnV2_new & (env2_cnt==SL-1)) let_go <= 0;
				
		if      (ipx_vact3_del & !vact_direct & !EnV1_new & !EnV2_new & let_go) EnV2_new <= 1;
		else if (ipx_vact3_del & !vact_direct & EnV2_new & (env2_cnt==SL-1))    EnV2_new <= 0;
		
		if ((let_go & !let_go_d)|(!let_go & let_go_d))     env2_cnt <= 0;
		else if (ipx_vact3_del & !vact_direct & EnV2_new) env2_cnt <= env2_cnt + 1;		
	end	
	else
	begin
		EnV1_new <= 0;
		env1_cnt  <= 0;
		env2_cnt  <= 0;
		let_go   <= 0;
		EnV2_new <= 0;
	end
	
	let_go_d <= let_go;
	
end

assign vact_direct = chn_mux_d[6]? ipx_vact3_dl   : ipx_vact2_dl;
assign hact_direct = chn_mux_d[6]? ipx_hact3_dl   : ipx_hact2_dl;
assign  pxd_direct = chn_mux_d[6]? ipxd3_dl[11:0] : ipxd2_dl[11:0];

reg [11:0] test_pattern_counter=0;

always @ (negedge sclk0) 
begin
	if (ipx_hact_direct) test_pattern_counter <= test_pattern_counter + 1;
	else                 test_pattern_counter <= 0;
end

always @ (negedge sclk0) 
begin
//	ipx_vact_direct_d   <= ipx_vact_direct;
//	ipx_hact_direct_d   <= ipx_hact_direct;
//	ipxd_direct_d[11:0] <= ipxd_direct;
	
	if (!chn_mux_d[7]) 
		begin
			ipx_vact_direct_d   <= ipx_vact_direct;
			ipx_hact_direct_d   <= ipx_hact_direct;
			ipxd_direct_d[11:0] <= test_pattern?test_pattern_counter[11:0]:ipxd_direct;
		end
	else	
	if (EnV2_new)
		begin
			ipx_vact_direct_d   <= vact_direct;
			ipx_hact_direct_d   <= hact_direct;
			ipxd_direct_d[11:0] <= pxd_direct;
		end			
	else 
	if (EnV1_new)
		begin
			ipx_vact_direct_d   <= ipx_vact1_dl;
			ipx_hact_direct_d   <= ipx_hact1_dl;
			ipxd_direct_d[11:0] <= ipxd1_dl[11:0];							
		end
	else
		begin
			ipx_vact_direct_d   <= 0;
			ipx_hact_direct_d   <= 0;
			ipxd_direct_d[11:0] <= 0;							
		end
end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// output multiplexer 
// chn_mux_d[5:4]==2'b00 - default direct channel mode
// chn_mux_d[5:4]==2'b10 - direct alternating mode
// chn_mux_d[5:4]==2'b01 - alternating-buffered mode / stereo mode

reg pre_vg_mode_mux=0;
reg vg_mode_mux=0;

always @ (negedge sclk0) 
begin
	if (vg_mode)                    pre_vg_mode_mux <= 1;
	else if (!pre_ivact & !vg_mode) pre_vg_mode_mux <= 0;
	
	if (pre_vg_mode_mux)                            vg_mode_mux <= 1;
	else if (!ipx_vact_direct_d & !pre_vg_mode_mux) vg_mode_mux <= 0;
end

always @ (negedge sclk0) 
begin
	if (!chn_mux_d[8] & !vg_mode_mux)
		begin
			pre_ivact <= ipx_vact_direct_d;
			pre_ihact <= ipx_hact_direct_d;
			pre_pxdr  <= ipxd_direct_d;
		end
	else 
	if (vg_mode_mux) 
		begin
			pre_ivact <= vact_vglued_d;
			pre_ihact <= hact_vglued_d;
			pre_pxdr  <= pixd_vglued_d;			
		end
	else
		begin
			pre_ivact <= 0;
			pre_ihact <= 0;
			pre_pxdr  <= 0;	
		end
end		

// the last mux, 'mux_tap' controls that switch to another channel doesn't break the outgoing frame	
reg disable_output=0;

always @ (negedge sclk0) 
begin
	if (!pre_ivact) disable_output <= pre_disable_output;
	pre_disable_input <= disable_output;
end
	
always @ (negedge sclk0) 
begin
	if (!mux_tap & !disable_output) 
		begin
			pxdr[11:0] <= pre_pxdr[11:0];
		end
	else
		begin
			pxdr[11:0] <= 0;	
		end
	ibpf <= 0;
end

//always @ (posedge sclk0) 
always @ (negedge sclk0) 
begin
	if (!mux_tap & !disable_output) 
		begin
			ivact      <= pre_ivact;
			ihact      <= pre_ihact;
		end
	else
		begin
			ivact      <= 0;
			ihact      <= 0;
		end
end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//tests//
//sclk0 test counter, just for check it is 'ticking'
reg [7:0] sclk0_cnt=0;
always @ (negedge sclk0) begin sclk0_cnt <= sclk0_cnt + 1; end

//pclk test counter, for check it is 'ticking'
reg [7:0] pclk_cnt=0;
always @ (negedge pclk) begin pclk_cnt <= pclk_cnt + 1; end



//reset signal
reg [15:0] reset_counter=0;
reg reset_event=0;
always @ (negedge sclk0) begin
	if (reset_event) reset_counter <= 0;
	else             reset_counter <= reset_counter + 1;
	
	if (reset_counter==16'hffff) reset_event <= 1;
	else                         reset_event <= 0;
end


//new_clk2 test counter
reg [15:0] new_clk2_cnt=0;
reg [15:0] new_clk2_cnt_reg=0;
always @ (negedge new_clk2 or posedge reset_event) begin
	if (reset_event) new_clk2_cnt <= 0;
	else             new_clk2_cnt <= new_clk2_cnt + 1; 
end

//new_clk1 test counter
reg [15:0] new_clk1_cnt=0;
reg [15:0] new_clk1_cnt_reg=0;
always @ (negedge new_clk1 or posedge reset_event) begin
	if (reset_event) new_clk1_cnt <= 0;
	else             new_clk1_cnt <= new_clk1_cnt + 1; 
end

//new_clk0 test counter
reg [15:0] new_clk0_cnt=0;
reg [15:0] new_clk0_cnt_reg=0;
always @ (negedge new_clk0 or posedge reset_event) begin
	if (reset_event) new_clk0_cnt <= 0;
	else             new_clk0_cnt <= new_clk0_cnt + 1; 
end

always @ (negedge pclk) begin
	if (reset_counter==16'hffff) begin
		new_clk2_cnt_reg <= new_clk2_cnt;
		new_clk1_cnt_reg <= new_clk1_cnt;
		new_clk0_cnt_reg <= new_clk0_cnt;
	end
end

// counts the number of lines in a frame
reg [11:0] n_lines_cnt=0;
reg [11:0] n_lines_reg=0;
reg pre_ivact_d=0;
reg pre_ihact_d=0;
always @ (negedge sclk0) 
begin
	pre_ivact_d <= pre_ivact;

	if (pre_ihact & !pre_ihact_d)      n_lines_cnt <= n_lines_cnt + 1;
	else if (!pre_ivact & pre_ivact_d) n_lines_cnt <= 0;
	
	if (n_lines_reset)                                            n_lines_reg <= 0;
	else if (!pre_ivact & pre_ivact_d) if (n_lines_cnt!=dir_N_fl) n_lines_reg <= n_lines_cnt;
	
end

// counts the number of pixels in a line
reg [11:0] n_pixels_cnt=0; 
reg [11:0] n_pixels_reg=0;
always @ (negedge sclk0) 
begin
	pre_ihact_d <= pre_ihact;

	if (pre_ihact_d) n_pixels_cnt <= n_pixels_cnt + 1;
	else             n_pixels_cnt <= 0;
	
	if (n_lines_reset)                 n_pixels_reg <= 0;
	else if (!pre_ihact & pre_ihact_d) n_pixels_reg <= n_pixels_cnt;
end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// incoming frames check

//ch1 - J2
reg [11:0] ch1_n_lines_cnt=0; // line counter
reg [11:0] ch1_n_lines_reg=0; // error data (incorrect number of lines)
reg [15:0] ch1_n_lines_err=0; // error counter

always @ (negedge sclk0) 
begin
	// counts hact's rises (number of lines)
	if      ( spx_hact1 & !ipx_hact1_dl1_neg) ch1_n_lines_cnt <= ch1_n_lines_cnt + 1;
	else if (!spx_vact1 &  ipx_vact1_dl1_neg) ch1_n_lines_cnt <= 0;
	
	// if at vact fall number of lines is not correct - store number in reg
	if (ch1_n_lines_reset)                                                   ch1_n_lines_reg <= 0;
	else if (!spx_vact1 &  ipx_vact1_dl1_neg) if (ch1_n_lines_cnt!=dir_N_fl) ch1_n_lines_reg <= ch1_n_lines_cnt;
	
	if (ch1_n_lines_reset)                                                   ch1_n_lines_err <= 0;
	else if (!spx_vact1 &  ipx_vact1_dl1_neg) if (ch1_n_lines_cnt!=dir_N_fl) ch1_n_lines_err <= ch1_n_lines_err + 1;
end

// counts the number of pixels in a line
reg [11:0] ch1_n_pixels_cnt=0; 
reg [11:0] ch1_n_pixels_reg=0;
reg [15:0] ch1_n_pixels_err=0;

always @ (negedge sclk0) 
begin
	if (spx_hact1) ch1_n_pixels_cnt <= ch1_n_pixels_cnt + 1;
	else           ch1_n_pixels_cnt <= 0;
	
	if (ch1_n_lines_reset)                                                   ch1_n_pixels_reg <= 0;
	else if (!spx_hact1 & ipx_hact1_dl1_neg) if (ch1_n_pixels_cnt!=dir_N_fp) ch1_n_pixels_reg <= ch1_n_pixels_cnt;
	
	if (ch1_n_lines_reset)                                                   ch1_n_pixels_err <= 0;
	else if (!spx_hact1 & ipx_hact1_dl1_neg) if (ch1_n_pixels_cnt!=dir_N_fp) ch1_n_pixels_err <= ch1_n_pixels_err + 1;	
end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ch2 - J3
reg [11:0] ch2_n_lines_cnt=0; // line counter
reg [11:0] ch2_n_lines_reg=0; // error data (incorrect number of lines)
reg [15:0] ch2_n_lines_err=0; // error counter

always @ (negedge sclk0) 
begin
	// counts hact's rises (number of lines)
	if      ( spx_hact2 & !ipx_hact2_dl1_neg) ch2_n_lines_cnt <= ch2_n_lines_cnt + 1;
	else if (!spx_vact2 &  ipx_vact2_dl1_neg) ch2_n_lines_cnt <= 0;
	
	// if at vact fall number of lines is not correct - store number in reg
	if (ch2_n_lines_reset)                                                   ch2_n_lines_reg <= 0;
	else if (!spx_vact2 &  ipx_vact2_dl1_neg) if (ch2_n_lines_cnt!=dir_N_fl) ch2_n_lines_reg <= ch2_n_lines_cnt;
	
	if (ch2_n_lines_reset)                                                   ch2_n_lines_err <= 0;
	else if (!spx_vact2 &  ipx_vact2_dl1_neg) if (ch2_n_lines_cnt!=dir_N_fl) ch2_n_lines_err <= ch2_n_lines_err + 1;
end

// counts the number of pixels in a line
reg [11:0] ch2_n_pixels_cnt=0; 
reg [11:0] ch2_n_pixels_reg=0;
reg [15:0] ch2_n_pixels_err=0;

always @ (negedge sclk0) 
begin
	if (spx_hact2) ch2_n_pixels_cnt <= ch2_n_pixels_cnt + 1;
	else           ch2_n_pixels_cnt <= 0;
	
	if (ch2_n_lines_reset)                                                   ch2_n_pixels_reg <= 0;
	else if (!spx_hact2 & ipx_hact2_dl1_neg) if (ch2_n_pixels_cnt!=dir_N_fp) ch2_n_pixels_reg <= ch2_n_pixels_cnt;
	
	if (ch2_n_lines_reset)                                                   ch2_n_pixels_err <= 0;
	else if (!spx_hact2 & ipx_hact2_dl1_neg) if (ch2_n_pixels_cnt!=dir_N_fp) ch2_n_pixels_err <= ch2_n_pixels_err + 1;	
end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//ch3 - J4
reg [11:0] ch3_n_lines_cnt=0; // line counter
reg [11:0] ch3_n_lines_reg=0; // error data (incorrect number of lines)
reg [15:0] ch3_n_lines_err=0; // error counter

always @ (negedge sclk0) 
begin
	// counts hact's rises (number of lines)
	if      ( spx_hact3 & !ipx_hact3_dl1_neg) ch3_n_lines_cnt <= ch3_n_lines_cnt + 1;
	else if (!spx_vact3 &  ipx_vact3_dl1_neg) ch3_n_lines_cnt <= 0;
	
	// if at vact fall number of lines is not correct - store number in reg
	if (ch3_n_lines_reset)                                                   ch3_n_lines_reg <= 0;
	else if (!spx_vact3 &  ipx_vact3_dl1_neg) if (ch3_n_lines_cnt!=dir_N_fl) ch3_n_lines_reg <= ch3_n_lines_cnt;
	
	if (ch3_n_lines_reset)                                                   ch3_n_lines_err <= 0;
	else if (!spx_vact3 &  ipx_vact3_dl1_neg) if (ch3_n_lines_cnt!=dir_N_fl) ch3_n_lines_err <= ch3_n_lines_err + 1;
end

// counts the number of pixels in a line
reg [11:0] ch3_n_pixels_cnt=0; 
reg [11:0] ch3_n_pixels_reg=0;
reg [15:0] ch3_n_pixels_err=0;

always @ (negedge sclk0) 
begin
	if (spx_hact3) ch3_n_pixels_cnt <= ch3_n_pixels_cnt + 1;
	else           ch3_n_pixels_cnt <= 0;
	
	if (ch3_n_lines_reset)                                                   ch3_n_pixels_reg <= 0;
	else if (!spx_hact3 & ipx_hact3_dl1_neg) if (ch3_n_pixels_cnt!=dir_N_fp) ch3_n_pixels_reg <= ch3_n_pixels_cnt;
	
	if (ch3_n_lines_reset)                                                   ch3_n_pixels_err <= 0;
	else if (!spx_hact3 & ipx_hact3_dl1_neg) if (ch3_n_pixels_cnt!=dir_N_fp) ch3_n_pixels_err <= ch3_n_pixels_err + 1;	
end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//stch3_first - registration 
reg [15:0] rreg=0;
always @ (negedge sclk0) begin
	if (stch3_first) rreg <= rreg + 1;
end

// ivact inactivity counter
reg [15:0] ivi_cnt=0, ivi_reg=0;
always @ (negedge sclk0) begin
	if (ivact) ivi_cnt <= ivi_cnt + 1;
	else       ivi_cnt <= 0;
	
	if (!pre_ivact & ivact) ivi_reg <= ivi_cnt;
end

// line counter
reg [15:0] hl_cnt=0, hl_reg=0;
always @ (negedge sclk0) begin
	if (!ivact) hl_cnt <= hl_cnt + 1;
	else        hl_cnt <= 0;
	
	if (pre_ivact & !ivact) hl_reg <= hl_cnt;
end

// line counter
reg [15:0] ch5weo_cnt=0;
always @ (negedge sclk0) begin
	if (rst) ch5weo_cnt <= 0;
	else if (ch5weo) ch5weo_cnt <= ch5weo_cnt + 1;
end

//address check
reg [31:0] addr_check_reg=0;
always @ (negedge sclk0) begin
	if (rst | (EnV2_buf_d & !EnV2_buf)) addr_check_reg <= {5'b0,ch2a[10:0],4'b0,ch3a_buffered[11:0]};
end

always @ (negedge sclk0) begin
	if (rst | (EnV2_buf_d & !EnV2_buf)) addr_check_reg <= {5'b0,ch2a[10:0],4'b0,ch3a_buffered[11:0]};
end

// frame input sum - pixel values are added up to get an analog of MD5
reg [15:0] fisum=0, fisum_reg=0;

//reg sp0_vact_d=0;
//reg sp0_hact_d=0;
//
//reg [15:0] fisum_cnt=0;
//reg [15:0] fisum_cnt_reg=0;
//
//always @(negedge sclk0) begin
//	sp0_vact_d <= ipx_vact_direct;
//	sp0_hact_d <= ipx_hact_direct;
//
//	if (ipx_vact_direct) begin
//		if (ipx_hact_direct) begin
//			if (!sp0_hact_d) fisum_cnt[15:0] <= fisum_cnt[15:0] + 1;
//		end
//	end
//	else begin
//		fisum_cnt[15:0] <= 0;
//	end
//	
//	if (!ipx_vact_direct & sp0_vact_d) fisum_cnt_reg[15:0] <= fisum_cnt[15:0];
//end
//
//always @(negedge sclk0) begin
//	if (ipx_vact_direct) begin
//		if (ipx_hact_direct) begin
//			fisum[15:0] <= fisum[15:0] + {4'b0,ipxd_direct[11:0]};
//		end
//	end
//	else if (ipx_vact_direct & !sp0_vact_d) begin
//		fisum[15:0] <= 0;
//	end
//	
//	if (!ipx_vact_direct & sp0_vact_d) fisum_reg[15:0] <= fisum[15:0];
//end
//
//// frame output sum - pixel values are added up to get an analog of MD5
//
//reg [15:0] fosum_cnt=0;
//reg [15:0] fosum_cnt_reg=0;
//
//always @(negedge sclk0) begin
//	if (pre_ivact) begin
//		if (pre_ihact) begin
//			if (!ihact) fosum_cnt[15:0] <= fosum_cnt[15:0] + 1;
//		end
//	end
//	else begin
//		fosum_cnt[15:0] <= 0;
//	end
//
//	if (ivact & !pre_ivact) fosum_cnt_reg[15:0] <= fosum_cnt[15:0];
//end
//
reg [15:0] fosum=0, fosum_reg=0;

always @(negedge sclk0) begin
	if (pre_ihact) begin
		fosum[15:0] <= fosum[15:0] + {4'b0,pre_pxdr[11:0]};
	end
	else if (!ivact & pre_ivact) begin
		fosum[15:0] <= 0;
	end
	
	if (ivact & !pre_ivact) fosum_reg[15:0] <= fosum[15:0];
end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

reg [15:0] check_counter=0;
always @(negedge sclk0) begin
	if (buf_cnt_en2) check_counter <= check_counter + 1;
end

reg [15:0] output_frame_counter=0;
always @(negedge sclk0) begin
	if (!pre_ivact & ivact) output_frame_counter[15:0] <= output_frame_counter[15:0] + 1;
end

reg [7:0] sp0_clk_cnt=0;
always @(negedge sp0_clk) begin
	sp0_clk_cnt <= sp0_clk_cnt + 1;
end

reg [7:0] sdram_read_cnt=0;
always @(negedge sclk0) begin
	if (test_page_r) sdram_read_cnt <= sdram_read_cnt + 1;
end

reg [7:0] sdram_write_cnt=0;
always @(negedge sclk0) begin
	if (test_page_w) sdram_write_cnt <= sdram_write_cnt + 1;
end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	wire [31:0] r_00 = MODELREV[31:0];
	wire [31:0] r_01 = {25'b0,chn_mux_d[6:0]};
	wire [31:0] r_02 = {fosum_reg[15:0],16'b0};//fisum[15:0]};
	wire [31:0] r_03 = {8'b0,pclk_cnt[7:0],8'b0,sclk0_cnt[7:0]};
	wire [31:0] r_04 = {mux_tap,disable_output,2'b0,1'b0,dclk3_locked,dclk2_locked,dclk1_locked,sp0_clk_cnt[7:0],16'b0};
	wire [31:0] r_05 = {new_clk1_cnt_reg[15:0],new_clk0_cnt_reg[15:0]};//{16'b0,bram_do[15:0]};
	wire [31:0] r_06 = {ivi_reg[15:0],output_frame_counter[15:0]};
	wire [31:0] r_07 = {disable_output, 7'b0,new_clk2_cnt[7:0],new_clk1_cnt[7:0],new_clk0_cnt[7:0]};//{32{vg_mode}};

	wire [31:0] r_08 = {ch1_n_pixels_err[15:0],4'b0,ch1_n_pixels_reg[11:0]};
	wire [31:0] r_09 = {ch2_n_pixels_err[15:0],4'b0,ch2_n_pixels_reg[11:0]};
	wire [31:0] r_0a = {ch3_n_pixels_err[15:0],4'b0,ch3_n_pixels_reg[11:0]};

	wire [31:0] r_0b = 0;
	
	wire [31:0] r_0c = {ch1_n_lines_err[15:0],4'b0,ch1_n_lines_reg[11:0]};
	wire [31:0] r_0d = {ch2_n_lines_err[15:0],4'b0,ch2_n_lines_reg[11:0]};
	wire [31:0] r_0e = {ch3_n_lines_err[15:0],4'b0,ch3_n_lines_reg[11:0]};
	
	wire [31:0] r_0f = {dclk3_status[1],dclk3_locked,dclk3_done,dclk3_status[0],dclk2_status[1],dclk2_locked,dclk2_done,dclk2_status[0],dclk1_status[1],dclk1_locked,dclk1_done,dclk1_status[0],dcm2_status[1],dcm2_locked,dcm2_done,dcm2_status[0],16'b0};
	wire [31:0] r_10 = {bram_do[15:0], 16'b0};
	wire [31:0] r_20 = {ch2_frame_en,ch0_frame_en,ch1_frame_ready,ch3_frame_ready,ch3_line_ready,disable_output,rst,framen,check_counter[15:0],vg_mode_buffered,buf_cnt_en2,ipx_vact3_del,ipx_vact1_del,1'b0,let_go,EnV2_new,EnV1_new};
	wire [31:0] r_40 = {3'b0,dcm2_locked,dcm2_done,dcm2_status[2:0],24'b0};//{fosum_cnt_reg[15:0],fisum_cnt_reg[15:0]};//{aror,15'b0,aror_cnt[15:0]};
	wire [31:0] r_41 = {sdram_read_cnt[7:0],sdram_write_cnt[7:0],16'h0};
	wire [31:0] r_44 = {4'b0,n_pixels_reg,4'b0,n_lines_reg};
	wire [31:0] r_45 = {5'h0,ddr_addr_w[10:0],5'h0,ddr_addr_w[10:0]};
	wire [31:0] r_46 = {4'h0,ddr_addr_r[11:0],4'b0,ddr_addr_r[11:0]};
	wire [31:0] r_47 = {14'b0,dcm1_ph90[1:0],7'b0,dcm1_reg[8:0]};
	wire [31:0] r_60 = {14'b0,phsel[1:0],7'b0,dcm2_reg[8:0]};
	wire [31:0] r_61 = {14'b0,dcm_s1_ph90[1:0],7'b0,dcm_s1_reg[8:0]};
	wire [31:0] r_62 = {14'b0,dcm_s2_ph90[1:0],7'b0,dcm_s2_reg[8:0]};
	wire [31:0] r_63 = {14'b0,dcm_s3_ph90[1:0],7'b0,dcm_s3_reg[8:0]};
	wire [31:0] r_68 = {regfil_do[15:8],regfil_do[7:0],regfil_do[15:8],regfil_do[7:0]};
	wire [31:0] r_70 = {ddr_do[15:0], 16'b0};

	assign i2c_do_wire[31:0] = //32'habcd6789; 
	ia[6]?
	  ia[5]?
			ia[4]? 
			  r_70 // 0x70..0x7f
				:   
				ia[3]?
					r_68 // 0x68..0x6f
					:
					ia[1]? ia[0]?r_63:r_62 : ia[0]?r_61:r_60
			:
			ia[2]?
				ia[1]? ia[0]?r_47:r_46 : ia[0]?r_45:r_44
				:
				ia[0]? r_41:r_40 
		:
		ia[5]?
				r_20
				:
				ia[4]? 
					r_10		
					:
					ia[3]?
						ia[2]?
						   ia[1]? ia[0]?r_0f:r_0e : ia[0]?r_0d:r_0c
							:
							ia[1]? ia[0]?r_0b:r_0a : ia[0]?r_09:r_08
						:
						ia[2]?
							ia[1]? ia[0]?r_07:r_06 : ia[0]?r_05:r_04
							:
							ia[1]? ia[0]?r_03:r_02 : ia[0]?r_01:r_00
  ;	
	
endmodule
