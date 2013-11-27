<?php
require_once("./Config/header.php");
require_once("./Config/info.php");

#$user = new EmUser();
#$param['lists'] = $user->getUsers();

/* Script */
$sc = new EmScriptConfig();
$sc->setJs("main_team");
$param['sc'] = $sc->getScriptConfig();

/* View */
$param['subPass'] = "Team Management";
$view = new EmViewConfig($param);
$view->setRightPage("Views/main_team.php");
echo $view->display();
?>
