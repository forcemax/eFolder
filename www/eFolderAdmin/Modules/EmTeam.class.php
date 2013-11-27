<?php
require_once("Modules/EmDataAccess.class.php");

class EmTeam{
	function EmTeam() {
		global $cfg;

		$this->team = "";
		$this->tbl = "eAccountManager.team_tbl";

		$this->dao = new EmDataAccess($cfg->DbHost, $cfg->DbUser, $cfg->DbPass, "eAccountManager");
	}

	function setTeam($team) {
		$this->team = trim($team);
	}

	function addTeam($team) {
		$this->setTeam($team);

		$que = sprintf("insert into %s (teamid_col) values ('%s')", $this->tbl, $this->team);
		$con = $this->dao->fetch($que, "1");
		if (!$con) {
			$res = "Team 등록시 실패하였습니다.";
			error_log("[eFolder-addTeam] "+$que, 0);
		}
		return $res;
	}
	function deleteTeam($team) {
		$this->setTeam($team);

		$que = sprintf("delete from %s where teamid_col='%s'", $this->tbl, $this->team);
		$con = $this->dao->fetch($que, "1");
		if (!$con) {
			$res = "Team 삭제시 실패하였습니다.";
			error_log("[eFolder-deleteTeam] "+$que, 0);
		}
		return $res;
	}
}
?>
