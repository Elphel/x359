/*
** -----------------------------------------------------------------------------**
** sync_frames.v
**
** Copyright (C) 2002-2010 Elphel, Inc.
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
module sync_frames(clk,   /// @posedge
                   trig,  /// active low, always low in free running mode
                   vacts, /// [2:0] vacts (single cycle) from each of 3 channels
                   enchn, ///  [2:0] enabled channels
                   first, /// vacts from the first sesnor (valid in trigger mode only)
                   sync); /// single cycle (@posedge clk), one cycle dealy from vacts.

input         clk;
input         trig;
input  [2:0]  vacts;
input  [2:0]  enchn;
output        first;
output [2:0]  sync;

reg trig_d, trigs;
reg    [2:0]  wait_vacts=0;
reg           wait_first=0,wait_first_d=0;
reg    [2:0]  sync=0;
assign first= wait_first_d & ~wait_first;
always @ (posedge clk) begin
   trig_d <=trig;
   trigs  <= trig_d && !trig;
//   wait_vacts[2:0] <= trigs?3'b111:(wait_vacts[2:0] & ~vacts[2:0] & enchn[2:0]);
   wait_vacts[2:0] <= {3{trigs}} | (wait_vacts[2:0] & ~vacts[2:0] & enchn[2:0]);
//   wait_first      <= trigs?1'b1:  (wait_first & ~|(vacts[2:0] & enchn[2:0]));
   wait_first      <= trigs | (wait_first & ~|(vacts[2:0] & enchn[2:0]));
   wait_first_d    <= wait_first;
   sync[2:0] <= enchn[2:0] & ({3{first}} | (vacts[2:0] & ~wait_vacts[2:0]));
end
endmodule
