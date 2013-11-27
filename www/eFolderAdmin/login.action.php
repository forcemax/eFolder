<?php
require_once("./Config/header.php");

$auth = new EmAuth;

if ($_POST['mode'] == "LOGIN") {
	$res = $auth->login($_POST['id'], $_POST['pwd']);
}
else {
	$res = $auth->logout();
}

echo json_encode($res);
?>
