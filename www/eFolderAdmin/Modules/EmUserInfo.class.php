<?php
require_once("Modules/EmDataAccess.class.php");

class EmUserInfo{
	function EmUserInfo() {
		global $cfg;

		$this->team = "";

		$this->tbl = "eAccountManager.account_tbl";
		$this->tbl_team = "eAccountManager.team_tbl";
		$this->tbl_teammount = "eAccountManager.teammount_tbl";

		$this->dao = new EmDataAccess($cfg->DbHost, $cfg->DbUser, $cfg->DbPass, "eAccountManager");
	}

	function getUsers() {
		$infos = array();
		#$que = sprintf("select * from %s", $this->tbl);
		$que = "select * from ".$this->tbl." where username_col not like 'team-%' order by username_col";
		$this->dao->fetch($que);
		while ($row = $this->dao->getRow()) {
			array_push($infos, $row);
		}
		return $infos;
	}

	function getTeams() {
		$infos = array();
		$que = sprintf("select teamid_col from %s", $this->tbl_team);
		$this->dao->fetch($que);
		while ($row = $this->dao->getRow()) {
			array_push($infos, $row);
		}
		return $infos;
	}

	function getUserInfo($user) {
		$infos = array();
		$que = sprintf("select * from %s where userid_col='%s'", $this->tbl_teammount, $user);
		$this->dao->fetch($que);
		while ($row = $this->dao->getRow()) {
			array_push($infos, $row);
		}
		return $infos;
	}

	function getTeamInfo($team) {
		$infos = array();
		$que = sprintf("select * from %s where userid_col='%s'", $this->tbl_teammount, $team);
		$this->dao->fetch($que);
		while ($row = $this->dao->getRow()) {
			array_push($infos, $row);
		}
		return $infos;
	}

	function getTeamNotUsers($team) {
		$infos = array();
		$users = $this->getUsers();
		foreach ($users as $v) {
			array_push($infos, $v['username_col']);
		}

		$que = sprintf("select * from %s where teamid_col='%s'", $this->tbl_teammount, $team);
		$this->dao->fetch($que);
		while ($row = $this->dao->getRow()) {
			$key = array_search($row['userid_col'], $infos);
			array_splice($infos, $key, 1);
		}
		return $infos;
	}

	function getTeamUsers($team) {
		$infos = array();

		$que = sprintf("select * from %s where teamid_col='%s'", $this->tbl_teammount, $team);
		$this->dao->fetch($que);
		while ($row = $this->dao->getRow()) {
			array_push($infos, $row['userid_col']);
		}
		return $infos;
	}

	function searchUser($search) {
		$infos = array();
		$res = "";
		$users = $this->getUsers();
		foreach ($users as $v) {
			 array_push($infos, $v['username_col']);
		}

		$que = "select username_col from ".$this->tbl." where username_col not like 'team-%' and username_col like '".$search."%' order by username_col";
		error_log("SHKIM ".$que, 0);
		$this->dao->fetch($que);
		while ($row = $this->dao->getRow()) {
			$key = array_keys($infos, $row['username_col']);
			if (is_array($key)) {
				$res .= $key[0]."|";
			}
		}
		if ($res) {
			$res = substr($res, 0, -1);
			return setRetMsg(true, $res);
		}
		return setRetMsg(false, "찾으시는 사용자가 없습니다.");
	}
}
?>
