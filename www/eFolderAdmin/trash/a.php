<?php
require_once("./Modules/smbHash.class.php");

function ntPassword($password) {
    $hash = new smbHash();
    return $hash->nthash($password);
}
function lmPassword($password) {
    $hash = new smbHash();
    return $hash->lmhash($password);
}


$str = "aaa";
//$res = crypt($str, CRYPT_MD5);
$res = crypt($str);
$res1 = lmPassword($str);
$res2 = ntPassword($str);
echo $res."\n";
echo $res1."\n";
echo $res2."\n";

?>
