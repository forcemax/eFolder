<?php
require_once("Modules/EmDataAccess.class.php");

class EmAccount{
	function EmAccount() {
		global $cfg;

		$this->user = "";
		$this->tbl = "eAccountManager.account_tbl";
		$this->tbl_team = "eAccountManager.teammount_tbl";

		$this->dao = new EmDataAccess($cfg->DbHost, $cfg->DbUser, $cfg->DbPass, "eAccountManager");
	}

	function setUserId($user) {
		$this->user = trim($user);
	}
	function setTeam($team) {
		$this->team = trim($team);
	}
	function _isAccount($user) {
		$this->setUserId($user);

		$que = sprintf("select * from %s where username_col='%s'", $this->tbl, $this->user);
		$this->dao->fetch($que, "1");
		$row = $this->dao->getNumRows();
		if ($row > 0) {
			$res = "Account에 이미 존재하는 계정입니다.";
			return $res;
		}
		return ;
	}

	function addAccount($user) {
		$this->setUserId($user);

		$res = $this->_isAccount($this->user);
		if ($res) return $res;

		$que = sprintf("insert into %s (username_col) values ('%s')", $this->tbl, $this->user);
		$con = $this->dao->fetch($que, "1");
		if (!$con) {
			$res = "Account 등록시 실패하였습니다.";
			error_log("[eFolder-addAccount] "+$que, 0);
		}
		return $res;
	}
	function deleteAccount($user) {
		$res = $this->_deleteUserAccount($user);
		if ($res) return $res;

		$res = $this->_deleteUserTeammount($user);
		if ($res) {
			$this->addAccount($user);
			return $res;
		}
	}
	function _deleteUserAccount($user) {
		$this->setUserId($user);
		$que = sprintf("delete from %s where username_col='%s'", $this->tbl, $this->user);
		$con = $this->dao->fetch($que, "1");
		if (!$con) {
			$res = "Account 삭제시 실패하였습니다.";
			error_log("[eFolder-_deleteUserAccount] "+$que, 0);
			return $res;
		}
		return ;
	}
	function _deleteUserTeammount($user) {
		$this->setUserId($user);
		$que = sprintf("delete from %s where userid_col='%s'", $this->tbl_team, $this->user);
		$con = $this->dao->fetch($que, "1");
		if (!$con) {
			$res = "Team 정보 삭제시 실패하였습니다.";
			error_log("[eFolder-_deleteUserTeammount] "+$que, 0);
			return $res;
		}
		return ;
	}

	function addTeam($team) {
		$res = $this->addAccount($team);
		return $res;
	}
	function deleteTeam($team) {
		$res = $this->_deleteUserAccount($team);
		if ($res) return $res;

		$res = $this->_deleteTeamTeammount($team);
		if ($res) {
			$this->addTeam($team);
			return $res;
		}
	}
	function _deleteTeamTeammount($team) {
		$this->setTeam($team);
		$que = sprintf("delete from %s where teamid_col='%s'", $this->tbl_team, $this->team);
		$con = $this->dao->fetch($que, "1");
		if (!$con) {
			$res = "Team 구성원 삭제시 실패하였습니다.";
			error_log("[eFolder-_deleteTeamTeammount] "+$que, 0);
		}
		return $res;
	}

	function addTeamUser($team, $users) {
		$this->setTeam($team);
		$res = $this->_deleteTeamTeammount($team);
		if ($res) return $res;

		foreach ($users as $v) {
			$que = sprintf("insert into %s values ('', '%s', '%s')", $this->tbl_team, $v, $this->team);
			$con = $this->dao->fetch($que, "1");
			if (!$con) {
				$res += $v ."은(는) ".$this->tbl_team." 구성원 등록에 실패하였습니다.\n";
				error_log("[eFolder-addTeamUser] "+$que, 0);
			}
		}
		return $res;
	}
}
?>
