<?php
require_once("./Config/header.php");
require_once("./Config/info.php");
require_once("./Modules/EmUserInfo.class.php");

$userinfo = new EmUserInfo();
$param['user'] = $_GET['user'];
$param['lists'] = $userinfo->getUserInfo($_GET['user']);

/* Script */

/* View */
$view = new EmViewConfig($param);
$view->setLayoutPage("Views/simplelayout.php");
$view->setRightPage("Views/userinfo.sub.php");
echo $view->display();
?>
