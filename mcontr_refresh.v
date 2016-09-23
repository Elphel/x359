/*
** -----------------------------------------------------------------------------**
** mcontr_refresh.v
**
** SDRAM refresh controller
** average interval (by datasheet) 7.8125usec, 
** maximal interval - 9*7.8125usec (because of future DLL at AR cycles only)
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
module mcontr_refresh (clk0,
                       enrq,
                       init,
                       start,
                       rq,
                       rq_urgent,
                       prenext,
// interface to SDRAM (through extra registers
                       pre3refr,  // precharge command (3 ahead)
                       inuse3    // SDRAm in use by this channel (sync with pre3***
							  );
							  	
   input       clk0;
   input       enrq;
   input       init;
   input       start;
   output      rq;
   output      rq_urgent;
   output      prenext;
   output      pre3refr;
   output      inuse3;

	parameter	REFRESHPERIOD=11'h3d0;

   reg         pre4refr;
   reg         pre3refr;
   reg         prenext;
   wire        inuse3=pre3refr;
	reg	[12:0] nRefrDue;
	reg	[10:0] rcntr;
   reg   [ 2:0] ucntr;
	reg			 rtim;
	reg			 rq;
	reg			 rq_urgent;

   always @ (negedge clk0) begin
     pre4refr <= start;
     pre3refr <= pre4refr;
     prenext  <= pre3refr;

     if      (init)                                 ucntr[2:0] <=4'h0;
     else if ((ucntr[2:0]!=3'h7) && rtim && !start) ucntr[2:0] <= ucntr[2:0]+1;
     else if ((ucntr[2:0]!=3'h0) &&          start) ucntr[2:0] <= ucntr[2:0]-1;

     if      (init)            nRefrDue <= {1'b1,12'b0}; 
	  else if ( start && !rtim) nRefrDue <= nRefrDue - 1;
	  else if (!start &&  rtim) nRefrDue <= nRefrDue + 1;

	  if (init | rtim) rcntr[10:0] <= REFRESHPERIOD;
	  else             rcntr[10:0] <= rcntr[10:0]-1;

	  rtim      <= !nRefrDue[12] && !(|rcntr[10:0]);	// nRefrDue[12] to "saturate" number of refr. cycles due to 4096
     rq        <= !init && enrq && |nRefrDue[12:0];
     rq_urgent <= !init && enrq && (nRefrDue[12] || (ucntr[2:0]==3'h7) || (rq_urgent && (ucntr[2:0]!=3'h0)));
   end

endmodule


