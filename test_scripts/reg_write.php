<?php
/*!***************************************************************************
*! FILE NAME  : reg_write.php
*! DESCRIPTION: writes data to 10359 registers, addresses start with 0x800
*! Copyright (C) 2008 Elphel, Inc
*! -----------------------------------------------------------------------------**
*!
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
*!  $Log: reg_write.php,v $
*!  Revision 1.3  2010/05/13 17:20:18  dzhimiev
*!  1. for 10359 revA, should be compatible with rev0
*!  2. new command system
*!  3. recoded for Eyesis
*!
*!  Revision 1.1  2009/02/13 09:53:10  dzhimiev
*!  1. removed old scripts
*!  2. added new with registers reading and writing, phase shifting and programming other sensors of 10359
*!
*!  Revision 1.1  2008/06/23 08:11:58  dzhimiev
*!  1. added more scripts for 10359 board
*!
*!  Revision 1.2  2008/06/16 07:43:58  dzhimiev
*!  mcontr address range changed from 0x0820-0x082F to 0x0840-0x085F (for making extra channels)
*!
*!  Revision 1.1  2008/04/23 01:55:50  dzhimiev
*!  1. added x359 files to src lists
*!  2. x359 read/write DDR
*!  3. x359 3 channels mux directly to out
*!  4. x359 one channel through DDR and another directly frames switching at out
*!
*/

require 'i2c.inc';

function send_i2c_4($a,$d) {
   $i2c  = fopen('/dev/xi2c16', 'w');
   fseek ($i2c, 2*$a) ;
   if ($w==1)    $res=fwrite($i2c, chr ($d));
   else          $res=fwrite($i2c, chr (floor($d/(256*256*256))).chr (($d - 256*256*256*floor($d/(256*256*256)))/(256*256)).chr (($d - 256*256*floor($d/(256*256)))/256).chr ($d - 256*floor($d/(256))) );
	 
   fclose($i2c);
   return $res;
}

$adr=0x0000;
$data=0x0000;
$width=16;


printf("<pre>");

	foreach($_GET as $key=>$value) {
		switch($key) {
			case "adr"            : $adr=$value+0;        break;
			case "data"           : $data=$value+0;       break;
			case "width"          : $width=$value+0;      break;
		}
	}

if ($width==32) {
  send_i2c_4($adr,$data);
}else{
  i2c_send(16, 0, $adr, $data, 0);
}

switch($adr) {
		case 0x806        : printf("\nSet channel to <font size=\"6\">$data</font>\n"); break;
		default           : printf("Wrote \nAddress: 0x%04x\nData   : 0x%08x\n",$adr,$data);
}

printf("</pre>");

?>
