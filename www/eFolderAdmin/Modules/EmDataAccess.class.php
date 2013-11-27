<?php
class EmDataAccess {
	var $host;
	var $user;
	var $pass;
	var $dbname;
	var $que;

	function EmDataAccess($host, $user, $pass, $dbname, $type=false) {
		$this->db = mysql_connect($host, $user, $pass);
		if ($type) {
			$this->dbname = $this->getUserDb($dbname);
		}
		else {
			$this->dbname = $dbname;
		}
		mysql_select_db($this->dbname, $this->db);
		mysql_query("SET CHARACTER SET 'utf8'", $this->db); 
	}

	/*function __destruct() {
		mysql_close($this->db);
	}*/

	function getConnect() {
		return $this->db;
	}

	function getUserDb($user) {
		//if ( !ereg( "[[:alpha:]]", substr($user,0,1) ) ) {
		if ( !preg_match( "/[[:alpha:]]/", substr($user,0,1) ) ) {
			$User = "etc";
		}
		//else if ( !ereg( "[[:alpha:]]", substr($user,1,1) ) ){
		else if ( !preg_match( "/[[:alpha:]]/", substr($user,1,1) ) ){
			$User = substr($user,0,1)."0";
		}
		else {
			$User = substr($user,0,2);
		}

		$DB_User = "HB".$User;
		return $DB_User;
	}

	function selectDB($dbname) {
		$this->dbname = $dbname;
		mysql_select_db($dbname, $this->db);
	}

	function errorMsg($str) {
		if (preg_match("|Duplicate entry|",$str)) {
			$res = "중복된 정보로 입력에 실패하였습니다.";
		}
		else {
			$res = $str;
		}
		return $res;
	}

	function fetch($sql, $type=false) {
		//$this->que = mysql_unbuffered_query($sql, $this->db) or die (mysql_error());
		//$this->que = mysql_query($sql, $this->db) or die (mysql_error());
		$this->que = mysql_query($sql, $this->db);
		//$this->que = mysql_unbuffered_query($sql, $this->db) or die ($sql);
		//$this->que = mysql_unbuffered_query($sql, $this->db);
		if ($type) {
			return $this->que;
		}
		else {
			if (!$this->que) {
				return $this->errorMsg(mysql_error());
			}
			else {
				return $this->que;
			}
		}
	}

	function getRow() {
		if ($row = mysql_fetch_array($this->que, MYSQL_ASSOC)) {
			return $row;
		}
		else {
			return false;
		}
	}

	function getNumRow() {
		if ($row = mysql_fetch_array($this->que, MYSQL_NUM)) {
			return $row;
		}
		else {
			return false;
		}
	}

	function getAffectedRow() {
		$row = mysql_affected_rows();
		return $row;
	}

	function getLastId() {
		$res = mysql_insert_id();
		return $res;
	}

	function getListTables() {
		$this->que = mysql_list_tables($this->dbname);
		return $this->que;
	}

	function getNumRows() {
		$row = mysql_num_rows($this->que);
		return $row;
	}

	function getTableName($num) {
		$res = mysql_tablename($this->que, $num);
		return $res;
	}
}
?>
