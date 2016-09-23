<?php
/*!***************************************************************************
*! FILE NAME  : sensors_init.php
*! DESCRIPTION: reads parameters from the sensor 1 and writes to other sensors
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
*!  $Log: sensors_init.php,v $
*!  Revision 1.4  2009/02/26 14:02:39  dzhimiev
*!  1. added a pause after channel switching - it appears to be more stable
*!
*!  Revision 1.4  2008/06/23 08:11:58  dzhimiev
*!  1. added more scripts for 10359 board
*!
*!  Revision 1.2  2008/05/22 22:57:54  dzhimiev
*!  + 0x0800 - current channel number register
*!  + DCMs independent phase adjustment
*!  useful scripts
*!
*!  Revision 1.2  2008/05/01 20:32:29  dzhimiev
*!  reads each sensor registers after configuration
*!
*!  Revision 1.1  2008/04/23 01:55:49  dzhimiev
*!  1. added x359 files to src lists
*!  2. x359 read/write DDR
*!  3. x359 3 channels mux directly to out
*!  4. x359 one channel through DDR and another directly frames switching at out
*!
*/

require 'i2c.inc';

function apply_def_settings($pass) {
	$DEF_QUALITY = 96;
	$DEF_WOI_WIDTH = 10000;
	$DEF_WOI_HEIGHT = 10000;
	// sample gamma == 1.0
	$DEF_GAMMA = 6554624;
	$DEF_COLOR = 2;	// color mode - "color, YCbCr 4:2:0, 3x3 pixels"

	// copy predefined settings with autocampars.php
	$conf_xml = simplexml_load_file("/etc/autocampars.xml");
	foreach($conf_xml->paramSets->children() as $paramSet) {
		$numSet = (integer)$paramSet->attributes()->number;
		if($numSet == 0) {
			if($pass == 1 || $pass == 2 || $pass == 0) {
				$paramSet->QUALITY = $DEF_QUALITY;
				$paramSet->WOI_WIDTH = $DEF_WOI_WIDTH;
				$paramSet->WOI_HEIGHT = $DEF_WOI_HEIGHT;
				$paramSet->GTAB_R = $DEF_GTAB_R;
				$paramSet->GTAB_G = $DEF_GTAB_G;
				$paramSet->GTAB_B = $DEF_GTAB_B;
				$paramSet->GTAB_GB = $DEF_GTAB_GB;
				$paramSet->SENSOR_RUN = 2;
				$paramSet->COMPRESSOR_RUN = 2;
				$paramSet->GAINR = 0x20000;
				$paramSet->GAING = 0x20000;
				$paramSet->GAINB = 0x20000;
				$paramSet->GAINGB = 0x20000;
				$paramSet->RSCALE = 0x10000;
				$paramSet->GSCALE = 0x10000;
				$paramSet->BSCALE = 0x10000;
				$paramSet->DGAINR = 32768;
				$paramSet->DGAING = 32768;
				$paramSet->DGAINGB = 32768;
				$paramSet->DGAINB = 32768;
				$paramSet->COLOR = 1;
				$paramSet->AUTOEXP_ON = 0;
				$paramSet->GAIN_MIN = 0x10000;
				$paramSet->GAIN_MAX = 0x10000;
				$paramSet->ANA_GAIN_ENABLE = 0;
				// daemons
				$paramSet->DAEMON_EN = 0;
				$paramSet->DAEMON_EN_AUTOEXPOSURE = 0;
				$paramSet->DAEMON_EN_STREAMER = 0;
				$paramSet->DAEMON_EN_CCAMFTP = 0;
				$paramSet->DAEMON_EN_CAMOGM = 0;
				$paramSet->DAEMON_EN_AUTOCAMPARS = 0;
			}
			if($pass == 0) { // for SDRAM test
		        	$paramSet->SENSOR_RUN = 0;
		        	$paramSet->COMPRESSOR_RUN = 0;
			}
	    }
	}
	$z = $conf_xml->asXml();
	$f = fopen('/tmp/cd359_def.xml', 'w+');
	fwrite($f, $z);
	fclose($f);
	exec('wget http://127.0.0.1/autocampars.php?load=/tmp/cd359_def.xml');
}

function sensor_init($init_pars){
	for ($i=0;$i<256;$i++){
		i2c_send(16,0,0x4800+$i,$init_pars[$i],0);	

		$readout=i2c_receive(16,0,0x4800+$i,0);
		printf("%04x ",$readout);

		if($j==15){
			$j=0; printf("\n");
		}else{
			$j++;
		}
	}
	printf("\n");
}

function dcm_reset(){

	printf("sent 0x%04x \n",0x0810); send_i2c_4(0x0810,0xffffffff);
	printf("sent 0x%04x \n",0x0810); send_i2c_4(0x0810,0x00000000);
	
}

function send_i2c_4($a,$d) {
	$i2c  = fopen('/dev/xi2c16','w');
	fseek ($i2c, 2*$a) ;
	$res=fwrite($i2c, chr (floor($d/(256*256*256))).chr (($d - 256*256*256*floor($d/(256*256*256)))/(256*256)).chr (($d - 256*256*floor($d/(256*256)))/256).chr ($d - 256*floor($d/(256))) );
	fclose($i2c);
	return $res;
} // end of send_i2c()

printf("<pre>\n");

//! Start with reset (normally not needed, just to make sure we have a clean start, not relying on previous programming)
// everything was already set but autocampars.php at boot
// set new parameters

send_i2c_4(0x0835,0x00000001); printf("\nReading parameters from sensor <font size=\"6\">1</font>\n");
exec("fpcf -i2cw16 48a0 0041");
sleep(1);
apply_def_settings(0);
sleep(2);
apply_def_settings(1);
for($i = 0; $i < 6; $i++) exec('wget http://127.0.0.1:8081/noexif/next/wait/img -O /dev/null');
sleep(3);
apply_def_settings(2);
for($i = 0; $i < 6; $i++) exec('wget http://127.0.0.1:8081/noexif/next/wait/img -O /dev/null');

// read sensor parameters
for ($i=0;$i<256;$i++){
	$init_pars3[$i]=i2c_receive(16,0,0x4800+$i,0);
	printf("%04x ",$init_pars3[$i]);	
	if($j==15){
		$j=0; printf("\n");
	}else{
		$j++;
	}	
}

send_i2c_4(0x0835,0x00000002); printf("\nInitializing sensor <font size=\"6\">2</font>\n");
sensor_init($init_pars3);
exec("fpcf -i2cw16 48a0 0041");
sleep(1);
apply_def_settings(0);
sleep(2);
apply_def_settings(1);
for($i = 0; $i < 6; $i++) exec('wget http://127.0.0.1:8081/noexif/next/wait/img -O /dev/null');
sleep(3);
apply_def_settings(2);
for($i = 0; $i < 6; $i++) exec('wget http://127.0.0.1:8081/noexif/next/wait/img -O /dev/null');


send_i2c_4(0x0835,0x00000004); printf("\nInitializing sensor <font size=\"6\">3</font>\n");
sensor_init($init_pars3);
exec("fpcf -i2cw16 48a0 0041");
sleep(1);
apply_def_settings(0);
sleep(2);
apply_def_settings(1);
for($i = 0; $i < 6; $i++) exec('wget http://127.0.0.1:8081/noexif/next/wait/img -O /dev/null');
sleep(3);
apply_def_settings(2);
for($i = 0; $i < 6; $i++) exec('wget http://127.0.0.1:8081/noexif/next/wait/img -O /dev/null');

send_i2c_4(0x0835,0x00000001); printf("\nSwitch back to sensor <font size=\"6\">1</font>\n");

printf("</pre>\n");

?> 
