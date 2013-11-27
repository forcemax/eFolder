<?php
require_once("./Config/header.php");
require_once("./Config/info.php");
require_once("./Modules/EmUserInfo.class.php");

$userinfo = new EmUserInfo();
$param['team'] = $_GET['team'];
$param['notuserlists'] = $userinfo->getTeamNotUsers($_GET['team']);
$param['userlists'] = $userinfo->getTeamUsers($_GET['team']);

/* Script */

/* View */
$view = new EmViewConfig($param);
$view->setLayoutPage("Views/simplelayout.php");
$view->setRightPage("Views/teammember.sub.php");
echo $view->display();
?>
