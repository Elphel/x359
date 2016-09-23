`timescale 1ns/1ps
/*
 *  It is just a placeholder for a real testbench. Made from 333, not everything updated
 */
module testbench();
   parameter CCLK_PER = 6.25;//	160MHz
   parameter ICLK_PER = 10.45;// 96MHz
   parameter SCLK_PER_SLOW= 10.0;//	 96+MHz
   parameter SCLK_PER_FAST= 10.9;//	 96-MHz
   parameter SKIP_CYCLES=3;
   parameter SENSOR_D_DLY=3;
   parameter SENSOR_H_DLY=8;
   parameter DCM_STEP=5; // number of DCM phase shifts per line

reg         CCLK;
reg         WCMD;
reg   [5:0] CMD;
reg         preHACT;
reg         preVACT;
reg  [11:0] preDI;
reg         ICLK;
reg         SCLK;
wire        SHACT;
wire        SVACT;
wire [11:0] SDO;
wire        DCM_DONE;
wire  [7:0] STATUS;
wire        LOCKED;
wire    ICLKD;
wire        HACT;
wire        VACT;
wire [11:0] DI;
assign #(SENSOR_H_DLY) HACT=     preHACT;
assign #(SENSOR_H_DLY) VACT=     preVACT;
assign #(SENSOR_D_DLY) DI[11:0]= preHACT?preDI[11:0]:12'bx;

wire       CLOCK_SEL;
reg  [5:0] FRAME;
integer   pix, line;
parameter npix=100;
parameter nlines=10;
parameter vb=4;
parameter hb0=10;
parameter hb1=10;
assign    CLOCK_SEL=FRAME[5];

sensor_phase359 i_sensor_phase359(
                        .cclk(CCLK),       // command clock (posedge, invert on input if needed)
                        .wcmd(WCMD),       // write command
                        .cmd(CMD[5:0]),        // CPU write data [5:0]
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
                        .HACT(HACT),       //   sensor HACT I/O pin (input), used to reset FIFO
                        .VACT(VACT),       //   sensor VACT I/O pin (input)
                        .DI(DI[11:0]),         //   sensor D[11:0] i/o pins (input)
                        .iclk(ICLK),       //   global sensor input clock (posedge) - the clock that goes to all 3 sensors
                        .sclk(SCLK),       //   global FIFO output clock (posedge)
                        .shact(SHACT),      //   hact - sync to sclk
                        .svact(SVACT),      //   vact - sync to sclk
                        .sdo(SDO[11:0]),        //   data output[11:0], sync to sclk
                        .dcm_done(DCM_DONE),   //   DCM command done
                        .status(STATUS[7:0]),     // dcm status (bit 1 - dcm clkin stopped)
                        .locked(LOCKED));    //   DCM locked
//reg  [3:0] fifo_data_in_addr;
//reg  [3:0] fifo_hact_in_addr;
//reg  [3:0] fifo_out_addr;

wire [3:0] fifo_d_diff=i_sensor_phase359.fifo_data_in_addr[3:0]-i_sensor_phase359.fifo_out_addr[3:0];
wire [3:0] fifo_h_diff=i_sensor_phase359.fifo_hact_in_addr[3:0]-i_sensor_phase359.fifo_out_addr[3:0];

    initial begin

      $dumpfile("sensor_phase359.lxt");
      $dumpvars(0,testbench);


      CCLK<=0;
      ICLK<=0;
      SCLK<=0;
      wait (~glbl.GSR);

//      sclk<=1;
      $display ("reset done at %t",$time);

      write_cmd(6'h3f);

      #1200000;

    $finish;
    end

//  always #(CLK_PER/2) if (~glbl.GSR) sclk <=   ~sclk;
initial begin
  FRAME=0;
  forever begin
    wait (VACT);
    wait (!VACT);
//    write_cmd(6'h8);
    write_cmd(6'hb); // rotate clock phases by 90 degrees, reset DCM phase
    if (FRAME[1:0]==0) write_cmd(6'h20); // shift clock phase hact,vact vs data by 90 degrees
    #10;
    FRAME=FRAME+1;
  end
end

always @ (posedge HACT) begin /// hoping task at VACT end is already over - could be conflicts - combine in the same thread?
 repeat (DCM_STEP) begin
   write_cmd(FRAME[0]?6'h1:6'h2);
 end
end
//DCM_STEP

initial begin
  SCLK <=   1'b0;
  forever begin
      #((CLOCK_SEL?SCLK_PER_SLOW:SCLK_PER_FAST)/2);
      SCLK <=   1'b1;
      #((CLOCK_SEL?SCLK_PER_SLOW:SCLK_PER_FAST)/2);
      SCLK <=   1'b0;
  end

end
  always #(CCLK_PER/2) CCLK <=   ~CCLK;
  always #(ICLK_PER/2) ICLK <=   ~ICLK;
//  always #(SCLK_PER/2) SCLK <=   ~SCLK;

/*
always @ (negedge VACT) begin
       write_cmd(6'h20);

end
*/
initial begin
 line=0;
 pix=0;
 preDI=0;
 forever begin
   for (line=0; line < (nlines+vb); line=line+1) begin
     preVACT<=(line>=vb)?1'b1:1'b0;
     for (pix=0;pix<(npix+hb0+hb1); pix=pix+1) begin
       if ((line>=vb) && (pix>=hb0) && (pix<(hb0+npix))) begin
         preHACT<=1'b1;
         preDI<=preDI+1;
       end else begin
         preHACT<=1'b0;
       end
       wait (~ICLK);wait (ICLK);
     end
   end
 end
end

  task write_cmd;
    input [5:0] d;
    integer i;
    begin
      wait(~CCLK);wait(CCLK);
      #1;
      CMD=d;
      WCMD=1;
      wait(~CCLK);wait(CCLK);
      #1;
      CMD='bx;
      WCMD=0;
      wait (DCM_DONE);
      for (i=0; i<SKIP_CYCLES;i=i+1) begin
        wait(~CCLK);wait(CCLK);
      end
    end
  endtask

endmodule

