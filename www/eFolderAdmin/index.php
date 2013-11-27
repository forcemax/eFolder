<?php
require_once("./Config/header.php");

#error_log("SHKIM", 0);

/* Script */
$sc = new EmScriptConfig();
$sc->setJs("main");
$param['sc'] = $sc->getScriptConfig();

/* View */
$view = new EmViewConfig($param);
$view->setLayoutPage("Views/loginlayout.php");
$view->setRightPage("Views/login.php");
echo $view->display();
?>
