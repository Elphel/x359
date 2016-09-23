<?php
/*!***************************************************************************
*! FILE NAME  : phases_adjust.php
*! DESCRIPTION: phase shifting for 10359 DCMs
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
*!  $Log: phases_adjust.php,v $
*!  Revision 1.4  2010/05/13 17:20:18  dzhimiev
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
*!  Revision 1.2  2008/02/13 00:30:01  elphel
*!  Added system time synchronization  with "CMOS" clock
*!
*!  Revision 1.1  2008/02/12 21:53:20  elphel
*!  Modified I2c to support multiple buses, added raw access (no address registers) and per-slave protection bitmasks
*!
*!
*/

require 'i2c.inc';

function receive_i2c_4($width,$bus,$a,$raw=0) {
   $w=($width==16)?2:1;
   $i2c_fn='/dev/xi2c'.($raw?'raw':(($w==2)?'16':'8')).(($bus==0)?'':'_aux');
   $i2c  = fopen($i2c_fn, 'r');
	 fseek ($i2c, 4, SEEK_END);
   fseek ($i2c, $w*$a);
	 
   $data = fread($i2c, 2*$w);
   fclose($i2c);
   if (strlen($data)<2*$w) return -1;
   $v=unpack(($w==1)?'C*':'N*',$data);
	 //print_r($v);
	 //printf("0x%x\n",$v[1]);
	 return $v[1];
} // end of receive_i2c()

function send_i2c_4($width,$bus,$a,$d,$raw=0) { //$a<0 - use raw read/write
   $w=($width==16)?2:1;
   $i2c_fn='/dev/xi2c'.($raw?'raw':(($w==2)?'16':'8')).(($bus==0)?'':'_aux');
   $i2c  = fopen($i2c_fn, 'w');
   fseek ($i2c, $w*$a) ;
   if ($w==1)    $res=fwrite($i2c, chr ($d));
   else          $res=fwrite($i2c, chr (floor($d/(256*256*256))).chr (($d - 256*256*256*floor($d/(256*256*256)))/(256*256)).chr (($d - 256*256*floor($d/(256*256)))/256).chr ($d - 256*floor($d/(256))) );

	 //printf("Sending passage ");
	 //printf("0x%02x%02x%02x%02x ",(floor($d/(256*256*256))),(($d - 256*256*256*floor($d/(256*256*256)))/(256*256)),(($d - 256*256*floor($d/(256*256)))/256),($d - 256*floor($d/(256))));	 
	 //printf("\n");

   fclose($i2c);
   return $res;
} // end of send_i2c()

function dcm_reset($width,$bus,$raw=0){
	printf("<font size=\"4\">Resetting DCMs</font>\n");
	printf("sent 0x%04x ",0x0810); send_i2c_4($width,$bus,0x0810,0xffffffff,$raw=0);
	printf("\nsent 0x%04x ",0x0810); send_i2c_4($width,$bus,0x0810,0x00000000,$raw=0);
	printf("\n\n");
}

  $width=16;
  $bus=0;
  $raw=0;

	$phase_shift=0;
	$dcm_addr=0;
	$n=1;

	$sphase=0x7;

	printf("<pre><title>Phases adjust</title>");

	foreach($_GET as $key=>$value) {
		switch($key) {
			case "rst"            : $dcm_rst=$value+0;        break;
			case "dcm"            : $dcm_addr=$value+0;       break;
			case "phase_shift"    : $phase_shift=$value+0;    break;
			case "n"              : $n=$value+0;              break;
			case "sphase"         : $sphase=$value+0;         break;
		}
	}

if ($dcm_rst==1) {
dcm_reset($width,$bus,$raw=0);
}

switch($dcm_addr) {
	case 0  : $adr=0x0801; break; // sclk0
	case 4  : $adr=0x0802; break; // SDRAM
	case 1  : $adr=0x0803; break; // sensor1 
	case 2  : $adr=0x0804; break; // sensor2
	case 3  : $adr=0x0805; break; // sensor3
	default : $adr=5;
}

if ($dcm_addr<>5){
	for($i=0;$i<$n;$i++){
		//send_i2c_4($width,$bus,$adr,$phase_shift,$raw=0);
		i2c_send(16, 0, $adr, $phase_shift, 0);
		usleep(1);
	}
	printf("DCM %d, number of shifts applied: <font size=\"6\">%d</font>\n",$dcm_addr,$n);
}

	//$adr=0x083a;
	//send_i2c_4($width,$bus,$adr,$sphase,$raw=0);

	if (($sphase & 0x1)==0x1) printf("S1. Vact/Hact - sclk0 FALLING edge, PXD - sclk0 FALLING edge\n");
	else                      printf("S1. Vact/Hact - sclk0  RISING edge, PXD - sclk0 FALLING edge\n"); 

	if (($sphase & 0x2)==0x2) printf("S2. Vact/Hact - sclk0 FALLING edge, PXD - sclk0 FALLING edge\n");
	else                      printf("S2. Vact/Hact - sclk0  RISING edge, PXD - sclk0 FALLING edge\n");

	if (($sphase & 0x4)==0x4) printf("S3. Vact/Hact - sclk0 FALLING edge, PXD - sclk0 FALLING edge\n");
	else                      printf("S3. Vact/Hact - sclk0  RISING edge, PXD - sclk0 FALLING edge\n");

	$adr=0x0861;
	$data=receive_i2c_4($width,$bus,$adr,$raw=0);
	printf("read 0x%04x : DCM1 phase step number is <font size=\"6\">0x%08x</font>\n",$adr,$data);
	
	$adr=0x0862;
	$data=receive_i2c_4($width,$bus,$adr,$raw=0);
	printf("read 0x%04x : DCM_S2 phase step number is <font size=\"6\">0x%08x</font>\n",$adr,$data);

	$adr=0x0863;
	$data=receive_i2c_4($width,$bus,$adr,$raw=0);
	printf("read 0x%04x : DCM_S3 phase step number is <font size=\"6\">0x%08x</font>\n",$adr,$data);

printf("</pre>");

?>
