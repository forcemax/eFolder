<?php
class EmEncUtil{
	var $bck;
	var $fwd;

	function EmEncUtil(){
		$this->bck = "";
		$this->fwd = "";
	}

	function setBck($bck){
		$this->bck = base64_decode($bck);
	}
	
	function setFwd($fwd){
		$this->fwd = base64_decode($fwd);
	}

	function getBck(){
		return base64_encode($this->bck);
	}

	function getFwd(){
		return base64_encode($this->fwd);
	}

	function setRandomKey() {
		$this->fwd = $this->getRandomKey();
		$this->bck = $this->getRandomKey();
	}

	function encryptData($str){
		$len = strlen($str);
		
		$crypt_res = "";
        for($i=0;$i<=$len;$i++) {
            $step = substr($str,$i,1);
            $a = "";
            for ($j=0;$j<=$i;$j++) {
                $a .= strtolower(chr(rand(ord('A'), ord('Z'))));
            }
            $crypt_res .= $a.$step;
        }

        $crypt_res = strtr($crypt_res, $this->fwd, $this->bck);
        $crypt_res = base64_encode($crypt_res);

        return $crypt_res;
	}

	function decryptData($str){
		$fwd = $this->fwd;
        $bck = $this->bck;

        $str = base64_decode($str);
        $str = strtr($str, $bck, $fwd);

        $j = 1;
        $len = strlen($str);
        $decrypt_res = "";
        for($i=0;$i<$len;$i=$i+$j) {
            $j = $j+1;
            $step = substr($str,$i,$j);
            $decrypt_res .= substr($step,-1);
        }

        $decrypt_res = substr($decrypt_res,0,-1);

        return $decrypt_res;
	}

	function getRandomKey() {
        $res = array();
        for($i=32; $i<126; $i++) {
            $res[] = chr($i);
        }
        shuffle($res);

        $crypt_key = "";
        foreach($res as $val) {
            $crypt_key .= $val;
        }
        return $crypt_key;
	}
}
?>
