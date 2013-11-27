<?php
require_once("./Config/header.php");
require_once("./Config/info.php");

#error_log("SHKIM", 0);

/* Script */
$sc = new EmScriptConfig();
$sc->setJs("main");
$param['sc'] = $sc->getScriptConfig();

/* View */
$param['subPass'] = "Account Management";
$view = new EmViewConfig($param);
$view->setRightPage("Views/main.php");
echo $view->display();
?>
