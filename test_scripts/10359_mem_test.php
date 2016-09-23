<?php
/*!***************************************************************************
*! FILE NAME  : 10359_mem_test.php
*! DESCRIPTION: tests SDRAM and other memory
*! Copyright (C) 2009 Elphel, Inc
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
*!  $Log: 10359_mem_test.php,v $
*!  Revision 1.1  2009/11/06 20:11:57  dzhimiev
*!  new memory test
*!
*!
*/

require 'i2c.inc';

function receive_i2c_4($a) {
  $i2c  = fopen('/dev/xi2c16','r');
  fseek ($i2c, 4, SEEK_END);
  fseek ($i2c, 2*$a); 
  $data = fread($i2c, 4);
  fclose($i2c);
  if (strlen($data)<4) return -1;
  $v=unpack('N*',$data);
  return $v[1];
}

function send_i2c_4($a,$d) { //$a<0 - use raw read/write
  $i2c=fopen('/dev/xi2c16','w');
  fseek ($i2c,2*$a);
  $res=fwrite($i2c, chr (floor($d/(256*256*256))).chr (($d - 256*256*256*floor($d/(256*256*256)))/(256*256)).chr (($d - 256*256*floor($d/(256*256)))/256).chr ($d - 256*floor($d/(256))) );
  //printf("0x%02x%02x%02x%02x ",(floor($d/(256*256*256))),(($d - 256*256*256*floor($d/(256*256*256)))/(256*256)),(($d - 256*256*floor($d/(256*256)))/256),($d - 256*floor($d/(256))));	 

  fclose($i2c);
  return $res;
}

function ddr_page_write($shift) {
	//fill a buffer
	$j=0;

	for ($i=0;$i<512;$i++) {
	  send_i2c_4(0x0802,0x1234);
	  printf("%04x ",0x1234);	

	  if ($j==31) { $j=0; printf("\n");}
	  else          $j++;
	}

	for ($i=0;$i<512;$i++) {
	  send_i2c_4(0x0802,$i+$shift);
	  printf("%04x ",$i+$shift);	

	  if ($j==31) { $j=0; printf("\n");}
	  else          $j++;
	}

	//write page, data does not matter
	for ($i=0;$i<8;$i++) {
		send_i2c_4(0x0803,0x0001);
	}
	printf("\n");
}

function ddr_page_read($color) {
	$j=0;
	//read page, data does not matter
	for ($i=0;$i<8;$i++) {
		send_i2c_4(0x0804,0x0001);
		//sleep(1);
	}
	printf("<font color=#%06x>",$color);
	$adr=0x0802;
	for ($i=0;$i<1024;$i++) {
	  $data=receive_i2c_4($adr);
	  printf("%04x ",$data);	

	  if ($j==31) { $j=0; printf("\n");}
	  else          $j++;
	}
	printf("\n</font>\n");
}

$adr=0x0860;
$datax=5;
$nopars=false;
$raw=0;

$phase_shift=0;
$channel=2;
$lines1=1940;
$pixes1=2595;
$lines2=1940;
$pixes2=2595;
$delay=0x00ffffff;
$sphase=0x00000007;
$ch1_ch2_delay=115;

printf("<pre><TITLE>SDRAM test</TITLE>");

// initialization
send_i2c_4(0x0841,0x00017fff);
send_i2c_4(0x0841,0x00002002);
send_i2c_4(0x0841,0x00000163);
send_i2c_4(0x0841,0x00008000);
send_i2c_4(0x0841,0x00008000);
send_i2c_4(0x0841,0x00017fff);

send_i2c_4(0x0840,0x00010000);
send_i2c_4(0x0841,0x00005555);
send_i2c_4(0x0841,0x00020000);

send_i2c_4(0x0842,0x0007000f);

send_i2c_4(0x084c,0x000f020f);//send_i2c_4($width,$bus,0x084c,0x0008181f,$raw=0);
send_i2c_4(0x0854,0x1fff10ff);
send_i2c_4(0x084d,0x000f020f);//send_i2c_4($width,$bus,0x084d,0x0008181f,$raw=0);
send_i2c_4(0x0855,0x1fff10ff);

// unknown commands
send_i2c_4(0x0843,0x1c000c21);
send_i2c_4(0x0840,0x00005555);
send_i2c_4(0x0844,0x00000000);
send_i2c_4(0x0845,0x00000000);
send_i2c_4(0x0846,0x00010000);
send_i2c_4(0x0847,0x00010000);
send_i2c_4(0x0840,0x0000aaaa);

printf("SDRAM initialization sequence passed, channels programmed\n\n");

//send_i2c_4(0x0847,0x00000000);
//send_i2c_4(0x0847,0x00000001);

send_i2c_4(0x0805,0x00000001);
send_i2c_4(0x0805,0x00000000);

$adr=0x0800;
$data=receive_i2c_4($adr);
printf("Firmware Version <font size=\"6\">0x%08x</font>\n\n",$data);


printf("Page sent:\n");
for($i=0;$i<1;$i++) {
	ddr_page_write(128*$i); // ddr_page_write writes 1024 words to a buffer and then transfer it with 16 writes to SDRAM
}

printf("Page received:\n");
for($i=0;$i<1;$i++) {
	//sleep(1);
	ddr_page_read(0x00007F+16*$i);
}

printf("</pre>");

?>
