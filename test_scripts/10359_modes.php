<?php
/*!***************************************************************************
*! FILE NAME  : 10359_modes.php
*! DESCRIPTION: switches between modes
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
*!  $Log: 10359_modes.php,v $
*!  Revision 1.6  2010/05/13 17:20:18  dzhimiev
*!  1. for 10359 revA, should be compatible with rev0
*!  2. new command system
*!  3. recoded for Eyesis
*!
*!  Revision 1.4  2010/01/04 05:32:27  dzhimiev
*!  1. added scale factor - for combined mode mostly, scale factor is set avoiding camvc
*!
*!  Revision 1.3  2009/12/04 03:40:15  dzhimiev
*!  1. removed frame size setting - replaced with getting it from the sensor
*!
*!  Revision 1.2  2009/12/02 04:45:10  dzhimiev
*!  1. added combining into one frame for alternating channels
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

   fclose($i2c);
   return $res;
} // end of send_i2c()

function res_update($name, $result, $description) {
	global $res_rpt;

	if($result != "")
		$res_rpt.="<${name} result=\"${result}\">".$description."</${name}>\n";
	else
		$res_rpt.="<${name}>".$description."</${name}>\n";
}

function _finish($res) {
	global $res_rpt;

	res_update("finish", $res, "");

	$res_rpt.="</script>\n";

	$res_xml=$res_rpt;
	header("Content-Type: text/xml");
	header("Content-Length: ".strlen($res_xml)."\n");
	header("Pragma: no-cache\n");
	printf("%s", $res_xml);
	flush();
	exit(0);
}


$width=16;
$bus=0;
$raw=0;

$pixes=2592;
$lines=1940;
$second_channel=2;
$mode=0;
$mode_start=true;
$combined=false;
$scale_factor=1;

$res_rpt="<?xml version='1.0' standalone='yes'?>\n<script name=\"modes control\">\n";

foreach($_GET as $key=>$value) {
	switch($key) {
		case "x"            : $camvc_pixes = $value+0; break;
		case "y"            : $camvc_lines = $value+0; break;
		case "mode"         : $mode=$value+0;           break;
		case "channel"      : $second_channel=$value+0; break;
		case "start"        : $mode_start=true; break;
		case "stop"         : $mode_start=false; break;
		case "combined"     : $combined=true; break;
		case "scale_factor" : $scale_factor=$value+0; break;
	}
}

// alternation mode with buffering
if ($mode==0) {

	// switch to broadcast channel to program all the sensors at once
	$adr=0x0806;
	//printf("<h3>Set channel to broadcast</h3>");
	res_update("step_01", "ok", "set channel to broadcast");
	//send_i2c_4($width,$bus,$adr,0x7,$raw=0);
	i2c_send(16, 0, $adr, 0x7, 0);
//	sleep(1);

	$some_x=i2c_receive(16,0,0x4804,0);
	res_update("step_01a", "ok", "got x-size from the sensor:${some_x}");
	$some_y=i2c_receive(16,0,0x4803,0);
	res_update("step_01b", "ok", "got y-size from the sensor:${some_y}");

	if ($mode_start) {

		$camvc_pixes=$some_x-3;
		$camvc_lines=$some_y-3;

		//disable all
		//printf("<h3>disable 10359 input/output</h3>");
		res_update("step_02", "ok", "disable 10359 input/output");
		$adr=0x808;
		//send_i2c_4($width,$bus,$adr,0x2,$raw=0);
		i2c_send(16, 0, $adr, 0x2, 0);
		//sleep(1);

		// reset regs
		//printf("<h3>regs reset</h3>");
		res_update("step_03", "ok", "regs reset");
		$adr=0x0808;
		//send_i2c_4($width,$bus,$adr,0x3,$raw=0);
		//send_i2c_4($width,$bus,$adr,0x2,$raw=0);
		i2c_send(16, 0, $adr, 0x3, 0);
		i2c_send(16, 0, $adr, 0x2, 0);

		if ($combined) {
			$pixes_to_10359=$camvc_pixes+4;
			$lines_to_10359=$camvc_lines/2+2;
			$pixes_to_sensor=$scale_factor*$camvc_pixes+4*$scale_factor;
			$lines_to_sensor=$scale_factor*$camvc_lines/2+2*$scale_factor;
		} else {
			$pixes_to_10359=$camvc_pixes+4;
			$lines_to_10359=$camvc_lines+4;
			$pixes_to_sensor=$camvc_pixes+4;
			$lines_to_sensor=$camvc_lines+4;
		}

		//program mcontr
		$adr=0x0837; //to_change
		send_i2c_4($width,$bus,$adr,(0x10000*$lines_to_10359)+$pixes_to_10359,$raw=0); 
		//printf("\nSet ch0 frame resolution to <font size=\"6\">$camvc_pixes"."x$camvc_lines</font>\n");	
		res_update("step_04", "ok", "Set ch0 frame resolution to ".$pixes_to_10359."x".$lines_to_10359);

		$adr=0x083c; //to_change
		send_i2c_4($width,$bus,$adr,(0x10000*$lines_to_10359)+$pixes_to_10359,$raw=0); 
		//printf("\nSet ch1 frame resolution to <font size=\"6\">$camvc_pixes"."x$camvc_lines</font>\n");
		res_update("step_05", "ok", "Set ch1 frame resolution to ".$pixes_to_10359."x".$lines_to_10359);

		send_i2c_4($width,$bus,0x0840,0x00015555,$raw=0);

		send_i2c_4($width,$bus,0x0841,0x00017fff,$raw=0);
		send_i2c_4($width,$bus,0x0841,0x00002002,$raw=0);
		send_i2c_4($width,$bus,0x0841,0x00000163,$raw=0);
		send_i2c_4($width,$bus,0x0841,0x00008000,$raw=0);
		send_i2c_4($width,$bus,0x0841,0x00008000,$raw=0);
		send_i2c_4($width,$bus,0x0841,0x00017fff,$raw=0);

		send_i2c_4($width,$bus,0x0840,0x00010000,$raw=0);
		send_i2c_4($width,$bus,0x0841,0x00005555,$raw=0);
		send_i2c_4($width,$bus,0x0841,0x00020000,$raw=0);

		send_i2c_4($width,$bus,0x0842,0x0007000f,$raw=0);

		send_i2c_4($width,$bus,0x084c,0x000f020f,$raw=0);//send_i2c_4($width,$bus,0x084c,0x0008181f,$raw=0);
		send_i2c_4($width,$bus,0x0854,0x1fff10ff,$raw=0);
		send_i2c_4($width,$bus,0x084d,0x000f020f,$raw=0);//send_i2c_4($width,$bus,0x084d,0x0008181f,$raw=0);
		send_i2c_4($width,$bus,0x0855,0x1fff10ff,$raw=0);

		send_i2c_4($width,$bus,0x0843,0x1c000c21,$raw=0);
		send_i2c_4($width,$bus,0x0840,0x00005555,$raw=0);
		send_i2c_4($width,$bus,0x0844,0x00000000,$raw=0);
		send_i2c_4($width,$bus,0x0845,0x00000000,$raw=0);

		send_i2c_4($width,$bus,0x0846,0x00010000,$raw=0);
		send_i2c_4($width,$bus,0x0847,0x00010000,$raw=0);
		send_i2c_4($width,$bus,0x0840,0x0000aaaa,$raw=0);

		// reset to regs
		$adr=0x0808;
		//printf("<h3>control reset</h3>");
		res_update("step_06", "ok", "control reset");
		//send_i2c_4($width,$bus,$adr,0x3,$raw=0);
		//send_i2c_4($width,$bus,$adr,0x2,$raw=0);
		i2c_send(16, 0, $adr, 0x3, 0);
		i2c_send(16, 0, $adr, 0x2, 0);
//		sleep(2);

		// program sensors
		$pixes_hex=dechex($pixes_to_sensor-1);
		exec("fpcf -i2cw16 4804 ${pixes_hex}");
		//printf("<h3>Sensors programmed Reg: 0x4803 Data: 0x${lines_hex}</h3>");
		res_update("step_07", "ok", "Sensors programmed Reg: 0x4804 Data: ${pixes_to_sensor}");

		$lines_hex=dechex($lines_to_sensor-1);
		exec("fpcf -i2cw16 4803 ${lines_hex}");
		//printf("<h3>Sensors programmed Reg: 0x4803 Data: 0x${lines_hex}</h3>");
		res_update("step_07", "ok", "Sensors programmed Reg: 0x4803 Data: ${lines_to_sensor}");

		$sf=$scale_factor-1;

		exec("fpcf -i2cw16 4802 c");
		exec("fpcf -i2cw16 4823 ${sf}");
		exec("fpcf -i2cw16 4822 ${sf}");

		// some useless commands
		send_i2c_4($width,$bus,0x0847,0x00000000,$raw=0);
		send_i2c_4($width,$bus,0x0847,0x00000001,$raw=0);

		// combine mode on
		//printf("<h3>Go</h3>");
		res_update("step_08", "ok", "mode started");
		$adr=0x0808;

		//send_i2c_4($width,$bus,$adr,0x00,$raw=0);
		i2c_send(16, 0, $adr, 0x00, 0);

		if ($second_channel==4) {
			if ($combined) send_i2c_4($width,$bus,$adr,0x0c,$raw=0);
			else           send_i2c_4($width,$bus,$adr,0x1c,$raw=0);
		}else{
			if ($combined) send_i2c_4($width,$bus,$adr,0x04,$raw=0);
			else           send_i2c_4($width,$bus,$adr,0x14,$raw=0);
		}

	} else {

		$camvc_pixes=$some_x;
		$camvc_lines=$some_y;

		res_update("step_03", "ok", "disable output");
		$adr=0x0808;
		//send_i2c_4($width,$bus,$adr,0x06,$raw=0);
		i2c_send(16, 0, $adr, 0x6, 0);
		sleep(1);

		res_update("step_04", "ok", "keep disable + reset");
		$adr=0x0808;
		//send_i2c_4($width,$bus,$adr,0x03,$raw=0);
		i2c_send(16, 0, $adr, 0x3, 0);

		if ($combined) {
			$pixes=($camvc_pixes+1)/$scale_factor;
			$lines=2*($camvc_lines+1)/$scale_factor;
			//reprogram sensor
			$pixes_hex=dechex($pixes-1);
			exec("fpcf -i2cw16 4804 ${pixes_hex}");

			$lines_hex=dechex($lines-1);
			exec("fpcf -i2cw16 4803 ${lines_hex}");

			exec("fpcf -i2cw16 4823 0");
			exec("fpcf -i2cw16 4822 0");

			//printf("<h3>Sensors vertical resolution is reprogrammed back - Reg: 0x4803 Data: 0x${lines_hex}</h3>");
			res_update("step_05", "ok", "sensors vertical resolution is set back - Reg: 0x4803 Data: 0x${lines_hex}");
			sleep(1);
		}

		res_update("step_06", "ok", "enable 10359 input/output");
		$adr=0x0808;
		//send_i2c_4($width,$bus,$adr,0x0,$raw=0);
		i2c_send(16, 0, $adr, 0x0, 0);

	}
}

_finish("ok");
//printf("</pre>");

?>
