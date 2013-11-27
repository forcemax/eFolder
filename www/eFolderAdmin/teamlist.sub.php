<?php
require_once("./Config/header.php");
require_once("./Config/info.php");
require_once("./Modules/EmUserInfo.class.php");

$userinfo = new EmUserInfo();
$param['lists'] = $userinfo->getTeams();

/* Script */

/* View */
$view = new EmViewConfig($param);
$view->setLayoutPage("Views/simplelayout.php");
$view->setRightPage("Views/teamlist.sub.php");
echo $view->display();
?>
