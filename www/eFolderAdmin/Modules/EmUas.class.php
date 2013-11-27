<?php
require_once("Modules/EmDataAccess.class.php");
require_once("Modules/smbHash.class.php");

class EmUas{
	function EmUas() {
		global $cfg;

		$this->user = "";
		$this->passwd = "";
		$this->home = "";
		$this->gid = $cfg->AccountGid;
		$this->shell = $cfg->AccountShell;
		$this->homeroot = $cfg->AccountHome;
		$this->tbl = "UAS.ACT_TBL";

		$this->dao = new EmDataAccess($cfg->DbHost, $cfg->DbUser, $cfg->DbPass, "UAS");
	}

	function setUserId($user) {
		$this->user = trim($user);
	}
	function setPasswd($passwd) {
		$this->passwd = trim($passwd);
	}
	function setGid($gid) {
		$this->gid = $gid;
	}
	function setShell($shell) {
		$this->shell = $shell;
	}
	function setHome($user) {
		$this->home = $this->homeroot."/".trim($user);
	}

	function _isUas($user) {
		$this->setUserId($user);

		# system 계정 확인
#		$system = posix_getpwnam($this->user);
#		if (is_array($system)) {
#			$res = "system에 이미 존재하는 계정입니다.";
#			return $res;
#		}

		# UAS 계정 확인
		$que = sprintf("select * from %s where NAME_COL='%s'", $this->tbl, $this->user);
		$this->dao->fetch($que, "1");
		$row = $this->dao->getNumRows();
		if ($row > 0) {
			$res = "UAS에 이미 존재하는 계정입니다.";
			return $res;
		}

		# home 디렉토리 확인
		$this->setHome($user);
		$chkhome = is_dir($this->home);
		if ($chkhome == true) {
			$res = "home 폴더가 이미 존재하는 계정입니다.";
			return $res;
		}
		return;
	}

	function getPasswd($user) {
		$this->setUserId($user);

		$que = sprintf("select PLPWD_COL from %s where NAME_COL='%s'", $this->tbl, $this->user);
		$con = $this->dao->fetch($que, "1");
		$row = $this->dao->getRow();
		return $row['PLPWD_COL'];
	}

	function addUas($user, $passwd, $flag=false) {
		$this->setUserId($user);
		$this->setPasswd($passwd);
		$this->setHome($user);

		$res = $this->_isUas($this->user);
		if ($res) return $res;

		$shell = $this->shell;
		if ($flag == true) $shell = "/bin/bash";

		if ($this->passwd) {
			$enpwd = $this->getEnPasswd($this->passwd);
			$lmpwd = $this->getLmPassword($this->passwd);
			$ntpwd = $this->getNtPassword($this->passwd);

			$que = sprintf("insert into %s (NAME_COL, NTNAME_COL, FLNAME_COL, ENPWD_COL, LMPWD_COL, NTPWD_COL, PLPWD_COL, GID_COL, HOMEDIR_COL, SHELL_COL) values ('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s')", $this->tbl, $this->user, $this->user, $this->user, $enpwd, $lmpwd, $ntpwd, $this->passwd, $this->gid, $this->home, $shell);
		}
		else {
			$que = sprintf("insert into %s (NAME_COL, NTNAME_COL, FLNAME_COL, GID_COL, HOMEDIR_COL, SHELL_COL, ENPWD_COL, LMPWD_COL, NTPWD_COL, PLPWD_COL) values ('%s','%s','%s','%s','%s','%s','!!','!!','!!','')", $this->tbl, $this->user, $this->user, $this->user, $this->gid, $this->home, $shell);

		}
		$con = $this->dao->fetch($que, "1");
		if (!$con) {
			$res = "1.UAS 등록시 실패하였습니다.";
			error_log("[eFolder-addUas] "+$que, 0);
		}
		else {
			$dir = mkdir($this->home, 0755);
			if ($dir == false) {
				$this->deleteUas($this->user);
				$res = "home 폴더 생성에 실패하였습니다.";
			}
		}
		return $res;
	}

	function deleteUas($user) {
		$this->setUserId($user);
		$que = sprintf("delete from %s where NAME_COL='%s'", $this->tbl, $this->user);
		$con = $this->dao->fetch($que, "1");
		if (!$con) {
			$res = "UAS 삭제에 실패하였습니다.";
			error_log("[eFolder-deleteUas] "+$que, 0);
			return $res;
		}
		return ;
	}

	function updatePasswd($user, $passwd) {
		$this->setUserId($user);
		$this->setPasswd($passwd);
		$enpwd = $this->getEnPasswd($this->passwd);
		$lmpwd = $this->getLmPassword($this->passwd);
		$ntpwd = $this->getNtPassword($this->passwd);

		$que = sprintf("update %s set ENPWD_COL='%s', LMPWD_COL='%s', NTPWD_COL='%s', PLPWD_COL='%s' where NAME_COL='%s'", $this->tbl, $enpwd, $lmpwd, $ntpwd, $this->passwd, $this->user);
		$con = $this->dao->fetch($que, "1");
		if (!$con) {
			$res = "비밀번호 변경에 실패하였습니다.";
			error_log("[eFolder-updatePasswd] "+$que, 0);
		}
		return $res;

	}

	function updateShell($user, $flag=false) {
		$this->setUserId($user);
		$shell = $this->shell;
		if ($flag == true) $shell = "/bin/bash";

		$que = sprintf("update %s set SHELL_COL='%s' where NAME_COL='%s'", $this->tbl, $shell, $this->user);
		$con = $this->dao->fetch($que, "1");
		if (!$con) {
			$res = "AccountShell 변경에 실패하였습니다.";
			error_log("[eFolder-updateShell] "+$que, 0);
		}
		return $res;
	}

	function getNtPassword($passwd) {
		$hash = new smbHash();
		return $hash->nthash($passwd);
	}

	function getLmPassword($passwd) {
		$hash = new smbHash();
		return $hash->lmhash($passwd);
	}

	function getEnPasswd($passwd) {
		$res = crypt($passwd);
		return $res;
	}
}
?>
