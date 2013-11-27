<?php
require_once("Modules/EmDataAccess.class.php");
require_once("Modules/EmUas.class.php");
require_once("Modules/EmAccount.class.php");
require_once("Modules/EmMember.class.php");
require_once("Modules/EmTeam.class.php");

class EmUser{
	function EmUser() {
		global $cfg;

		$this->team = "";

		$this->tbl = "eAccountManager.account_tbl";
		$this->tbl_team = "eAccountManager.team_tbl";
		$this->tbl_teammount = "eAccountManager.teammount_tbl";

		$this->dao = new EmDataAccess($cfg->DbHost, $cfg->DbUser, $cfg->DbPass, "eAccountManager");
	}

	function _checkUserVal($user, $passwd) {
		$user = trim($user);
		$passwd = trim($passwd);

		if (empty($user)) return "아이디값이 없습니다.";
		if (empty($passwd)) return "비밀번호값이 없습니다.";


		$pattern = '/^team-/i';
		if (preg_match($pattern, $user)) {
			return "아이디는 team- 으로 시작할 수 없습니다.";
		}
		return;
	}

	function addUser($user, $passwd) {
		$res = $this->_checkUserVal($user, $passwd);
		if ($res) return setRetMsg(false, $res);

		# UAS
		$uas = new EmUas();
		$res = $uas->addUas($user, $passwd);
		if ($res) return setRetMsg(false, $res); 

		# Account
		$account = new EmAccount();
		$res = $account->addAccount($user);
		if ($res) {
			$uas->deleteUas($user);
			return setRetMsg(false, $res); 
		}

		# Member
		$member = new EmMember();
		$res = $member->addMember($user);
		if ($res) {
			$uas->deleteUas($user);
			$account->deleteAccount($user);
			return setRetMsg(false, $res);
		}
		return setRetMsg(true, "OK");
	}

	function deleteUser($user) {
		# UAS
		$uas = new EmUas();
		$passwd = $uas->getPasswd($user);
		$res = $uas->deleteUas($user);
		if ($res) return setRetMsg(false, $res);

		# Account
		$account = new EmAccount();
		$res = $account->deleteAccount($user);
		if ($res) {
			$uas->addUas($user, $passwd);
			return setRetMsg(false, $res);
		}

		# Member
		$member = new EmMember();
		$res = $member->deleteMember($user);
		if ($res) {
			$uas->addUas($user, $passwd);
			$account->addAccount($user);
			return setRetMsg(false, $res);
		}
		return setRetMsg(true, "OK");
	}

	function updateUserPasswd($user, $passwd) {
		$uas = new EmUas();
		$res = $uas->updatePasswd($user, $passwd);
		if ($res) {
			return setRetMsg(false, $res);
		}
		return setRetMsg(true, "OK");
	}

	function _checkTeamVal($team) {
		$team = trim($team);
		if (empty($team)) return "팀값이 없습니다.";
		return;
	}

	function addTeam($team) {
		$res = $this->_checkTeamVal($team);
		if ($res) return setRetMsg(false, $res);

		# UAS
		$uas = new EmUas();
		$res = $uas->addUas($team, "");
		if ($res) return setRetMsg(false, $res);

		# Account
		$account = new EmAccount();
		$res = $account->addTeam($team);
		if ($res) {
			$uas->deleteUas($team);
			return setRetMsg(false, $res);
		}

		# Member
		$member = new EmMember();
		$res = $member->addTeam($team);
		if ($res) {
			$uas->deleteUas($team);
			$account->deleteTeam($team);
			return setRetMsg(false, $res);
		}

		# Team
		$teamobj = new EmTeam();
		$res = $teamobj->addTeam($team);
		if ($res) {
			$uas->deleteUas($team);
			$account->deleteTeam($team);
			$member->deleteMember($team);
			return setRetMsg(false, $res);
		}
		return setRetMsg(true, "OK");
	}

	function deleteTeam($team) {
		$res = $this->_checkTeamVal($team);
		if ($res) return setRetMsg(false, $res);

		# UAS
		$uas = new EmUas();
		$res = $uas->deleteUas($team);
		if ($res) return setRetMsg(false, $res);

		# Account
		$account = new EmAccount();
		$res = $account->deleteTeam($team);
		if ($res) {
			$uas->addUas($team, "");
			return setRetMsg(false, $res);
		}

		# Member
		$member = new EmMember();
		$res = $member->deleteTeam($team);
		if ($res) {
			$uas->addUas($team, "");
			$account->addTeam($team);
			return setRetMsg(false, $res);
		}

		# Team
		$teamobj = new EmTeam();
		$res = $teamobj->deleteTeam($team);
		if ($res) {
			$uas->addUas($team, "");
			$account->addTeam($team);
			$member->addMember($team);
			return setRetMsg(false, $res);
		}
		return setRetMsg(true, "OK");
	}

	function addTeamUser($team, $users) {
		$account = new EmAccount();
		$res = $account->addTeamUser($team, $users);
		if ($res) return setRetMsg(false, $res);

		return setRetMsg(true, "OK");
	}
}
?>
