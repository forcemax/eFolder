<?php
/* 인증 */
$auth = new EmAuth();
$authRes = $auth->isAuth();

if ($authRes == false) header('Location: ./index.php');
?>
