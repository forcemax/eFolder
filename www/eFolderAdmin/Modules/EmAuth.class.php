<?php
require_once("Modules/EmSession.class.php");

class EmAuth {
	function EmAuth() {
		global $cfg;

		$this->cfg = $cfg;
		$this->session = "";
		$this->info = "";
		$this->initUser();
	}

	function initUser() {
		$this->session = new EmSession($this->cfg);
		$this->info = $this->session->getSession();
	}

	function isAuth() {
		if ($this->getUserID() == $this->cfg->AdminUser && $this->getUserPW() == $this->cfg->AdminPass) {
			return true;
		}
		return false;
	}

	function login($id, $pw) {
		if ($id == $this->cfg->AdminUser && $pw == $this->cfg->AdminPass) {
			$this->session->createSession($id, $pw);
			return setRetMsg(true, "OK");
		}
		else {
			return setRetMsg(false, "로그인에 실패하였습니다.");
		} 
	}

	function logout() {
		$this->session->destroySession();
		return setRetMsg(true, "OK");
	}

	function getUserID() { return $this->info['id']; }
	function getUserPW() { return $this->info['pw']; }
	function getUserFWD() { return $this->info['fwd']; }
	function getUserBCK() { return $this->info['bck']; }
}
?>
