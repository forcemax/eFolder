<?php
require_once("Modules/EmDataAccess.class.php");

class EmMember{
	function EmMember() {
		global $cfg;

		$this->user = "";
		$this->adult = "1";
		$this->tbl = "eFolder.member";

		$this->dao = new EmDataAccess($cfg->DbHost, $cfg->DbUser, $cfg->DbPass, "eFolder");
	}

	function setUserId($user) {
		$this->user = trim($user);
	}
	function setAdult($adult) {
		$this->adult = trim($adult);
	}
	function _isMember($user) {
		$this->setUserId($user);

		$que = sprintf("select * from %s where id='%s'", $this->tbl, $this->user);
		$this->dao->fetch($que, "1");
		$row = $this->dao->getNumRows();
		if ($row > 0) {
			$res = "Member에 이미 존재하는 계정입니다.";
			return $res;
		}
		return ;
	}

	function addMember($user) {
		$this->setUserId($user);

		$res = $this->_isMember($this->user);
		if ($res) return $res;

		$mdate = time();

		$que = sprintf("insert into %s (id, adult, mdate) values ('%s', '%s', '%s')", $this->tbl, $this->user, $this->adult, $mdate);
		$con = $this->dao->fetch($que, "1");
		if (!$con) {
			$res = "Member-user 등록시 실패하였습니다.";
			error_log("[eFolder-addMember] "+$que, 0);
		}
		return $res;
	}
	function deleteMember($user) {
		$this->setUserId($user);

		$que = sprintf("delete from %s where id='%s'", $this->tbl, $this->user);
		$con = $this->dao->fetch($que, "1");
		if (!$con) {
			$res = "Member-user 삭제시 실패하였습니다.";
			error_log("[eFolder-deleteMember] "+$que, 0);
			return $res;
		}
		return ;
	}
	function addTeam($team) {
		$res = $this->addMember($team);
		if ($res) { $res = "Member-team 등록시 실패하였습니다."; }
		return $res;
	}
	function deleteTeam($team) {
		$res = $this->deleteMember($team);
		if ($res) { $res = "Member-team 삭제시 실패하였습니다."; }
		return $res;
	}
}
?>
