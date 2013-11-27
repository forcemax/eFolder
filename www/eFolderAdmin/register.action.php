<?php
require_once("./Config/header.php");
require_once("./Config/info.php");
require_once("./Modules/EmUser.class.php");
require_once("./Modules/EmUserInfo.class.php");

$user = new EmUser();

if ($_POST['mode'] == "ADD") {
	$res = $user->addUser($_POST['user'], $_POST['passwd']);
}
else if ($_POST['mode'] == "DELETE") {
	$res = $user->deleteUser($_POST['user']);
}
else if ($_POST['mode'] == "UPDATE_PASSWD") {
	$res = $user->updateUserPasswd($_POST['user'], $_POST['passwd']);
}
else if ($_POST['mode'] == "ADD_TEAM") {
	$team = "team-".$_POST['team'];
	$res = $user->addTeam($team);
}
else if ($_POST['mode'] == "DELETE_TEAM") {
	$res = $user->deleteTeam($_POST['team']);
}
else if ($_POST['mode'] == "ADD_TEAM_USER") {
	$res = $user->addTeamUser($_POST['team'], $_POST['a']);
}
else if ($_POST['mode'] == "SEARCH") {
	$user = new EmUserInfo();
	$res = $user->searchUser($_POST['search']);
}
else {
	$res = setRetMsg(false, "잘못된 접근입니다.");
}
echo json_encode($res);
?>
