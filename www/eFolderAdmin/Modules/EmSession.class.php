<?php
require_once("Modules/EmEncUtil.class.php");

class EmSession{
    var $objEmEncUtil;
    var $rootUrl;
    var $cookieDomain;
    var $secure;
    var $cookieTime;

    function EmSession(&$cfg){
        $this->objEmEncUtil = new EmEncUtil();
        $this->rootUrl = "/";
        $this->cookieDomain = $cfg->CookieDomain;
        $this->secure = "";
        //$this->cookieTime = time()+3600*24;
        $this->cookieTime = "0";
    }

    function _setCookie($name, $val) {
        setcookie($name, '', "0", $this->rootUrl, $this->cookieDomain, $this->secure);
        setcookie($name, $val, $this->cookieTime, $this->rootUrl, $this->cookieDomain, $this->secure);
    }

    function createSession($id, $pw){
	$this->objEmEncUtil->setRandomKey();

        $user = $this->objEmEncUtil->encryptData($id);
        $this->_setCookie("YAMAILuser", $user);

        $pass = $this->objEmEncUtil->encryptData($pw);
        $this->_setCookie("YAMAILpass", $pass);

        $fwd = $this->objEmEncUtil->getFwd();
        $this->_setCookie("YAMAILfwd", $fwd);

        $bck = $this->objEmEncUtil->getBck();
        $this->_setCookie("YAMAILbck", $bck);
    }

    function destroySession(){
        $this->_setCookie("YAMAILuser","");
        $this->_setCookie("YAMAILpass","");
        $this->_setCookie("YAMAILfwd","");
        $this->_setCookie("YAMAILbck","");
    }

    function getSession(){
        $this->objEmEncUtil->setFwd($_COOKIE['YAMAILfwd']);
        $this->objEmEncUtil->setBck($_COOKIE['YAMAILbck']);

        $arrData = array();
        $arrData['id'] = $this->objEmEncUtil->decryptData($_COOKIE['YAMAILuser']);
        $arrData['pw'] = $this->objEmEncUtil->decryptData($_COOKIE['YAMAILpass']);
        $arrData['fwd'] = $this->objEmEncUtil->decryptData($_COOKIE['YAMAILfwd']);
        $arrData['bck'] = $this->objEmEncUtil->decryptData($_COOKIE['YAMAILbck']);

        return $arrData;
    }
}
?>
