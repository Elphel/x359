<?php
/*!***************************************************************************
*! FILE NAME  : reg_read.php
*! DESCRIPTION: reads some control and test registers of 10359 board
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
*!  $Log: reg_read.php,v $
*!  Revision 1.4  2010/05/13 17:20:18  dzhimiev
*!  1. for 10359 revA, should be compatible with rev0
*!  2. new command system
*!  3. recoded for Eyesis
*!
*!  Revision 1.2  2009/08/24 19:07:09  dzhimiev
*!  1. correct xml output
*!
*!  Revision 1.1  2009/02/13 09:53:10  dzhimiev
*!  1. removed old scripts
*!  2. added new with registers reading and writing, phase shifting and programming other sensors of 10359
*!
*!  Revision 1.1  2008/04/23 01:55:50  dzhimiev
*!  1. added x359 files to src lists
*!  2. x359 read/write DDR
*!  3. x359 3 channels mux directly to out
*!  4. x359 one channel through DDR and another directly frames switching at out
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
	 printf("0x%02x%02x%02x%02x ",(floor($d/(256*256*256))),(($d - 256*256*256*floor($d/(256*256*256)))/(256*256)),(($d - 256*256*floor($d/(256*256)))/256),($d - 256*floor($d/(256))));	 
	 //printf("\n");

   fclose($i2c);
   return $res;
} // end of send_i2c()

$res_xml = "<?xml version='1.0' standalone='yes'?>\n<registers_read>\n";
//$res_xml = "<Registers_read>\n";

$adr=0x0800;
$data=receive_i2c_4(16,0,$adr,0);
$res_xml .= "<reg_00>".dechex($data)."</reg_00>\n";//firmware version

$adr=0x0801;
$data=receive_i2c_4(16,0,$adr,0);
$res_xml .= "<reg_01>".dechex($data)."</reg_01>\n";//correlation status

$adr=0x0802;
$data=receive_i2c_4(16,0,$adr,0);
$res_xml .= "<reg_02>".dechex($data)."</reg_02>\n";

$adr=0x0803;
$data_l=receive_i2c_4(16,0,$adr,0);
$data_h=i2c_receive(16,0,$adr,0);
$res_xml .= "<reg_03_h>".dechex($data_h)."</reg_03_h>\n";
$res_xml .= "<reg_03_l>".dechex($data_l-0x10000*(floor($data_l/0x10000)))."</reg_03_l>\n";

$adr=0x0805;
$data=receive_i2c_4(16,0,$adr,0);
$res_xml .= "<reg_05>".dechex($data)."</reg_05>\n";

$adr=0x0806;
$data=receive_i2c_4(16,0,$adr,0);
$res_xml .= "<reg_06>".dechex($data)."</reg_06>\n";

$adr=0x0807;
$data=receive_i2c_4(16,0,$adr,0);
$res_xml .= "<reg_07>".dechex($data)."</reg_07>\n";

$adr=0x0820;
$data=receive_i2c_4(16,0,$adr,0);
$res_xml .= "<reg_20>".dechex($data)."</reg_20>\n";

$adr=0x0844;
$data=receive_i2c_4(16,0,$adr,0);
$res_xml .= "<reg_44>".dechex($data)."</reg_44>\n";

$adr=0x0845;
$data=receive_i2c_4(16,0,$adr,0);
$res_xml .= "<reg_45>".dechex($data)."</reg_45>\n";

$adr=0x0846;
$data=receive_i2c_4(16,0,$adr,0);
$res_xml .= "<reg_46>".dechex($data)."</reg_46>\n";

//sclk0
$adr=0x0847;
$data=receive_i2c_4(16,0,$adr,0);
$res_xml .= "<reg_47>".dechex($data)."</reg_47>\n";

//ch0 clk
$adr=0x0860;
$data=receive_i2c_4(16,0,$adr,0);
$res_xml .= "<reg_60>".dechex($data)."</reg_60>\n";

// ch1 clk
$adr=0x0861;
$data=receive_i2c_4(16,0,$adr,0);
$res_xml .= "<reg_61>".dechex($data)."</reg_61>\n";

// ch2 clk
$adr=0x0862;
$data=receive_i2c_4(16,0,$adr,0);
$res_xml .= "<reg_62>".dechex($data)."</reg_62>\n";
	
$adr=0x0863;
$data=receive_i2c_4(16,0,$adr,0);
$res_xml .= "<reg_63>".dechex($data)."</reg_63>\n";

$res_xml .= "</registers_read>\n";

header("Content-Type: text/xml");
header("Content-Length: ".strlen($res_xml)."\n");
header("Pragma: no-cache\n");
printf("%s", $res_xml);
flush();

?>
