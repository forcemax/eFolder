<?php
class EmViewConfig {
	var $layout;
	var $left;
	var $right;
	var $param;

	function EmViewConfig($params) {
		global $cfg;
		$this->param = $params;
		$this->layout = "Views/layout.php";
		$this->top = "Views/top.php";
		$this->footer = "Views/footer.php";
		$this->left = "Views/menu.php";
		$this->rightheader = "Views/rightheader.php";
		$this->header = "Views/header.php";
		$this->popupheader = "Views/popupheader.php";
		$this->browsertitle = $cfg->BrowserTitle;
	}
	function setLayoutPage($layout) {
		$this->layout = $layout;
	}
	function setHeaderPage($header) {
		$this->header = $header;
	}
	function setLeftPage($left) {
		$this->left = $left;
	}
	function setRightHeaderPage($rightheader) {
		$this->rightheader = $rightheader;
	}
	function setRightPage($right) {
		$this->right = $right;
	}
	function setTopPage($top) {
		$this->top = $top;
	}
	function setFooterPage($footer) {
		$this->footer = $footer;
	}

	function display(){
		$top_page = $this->render($this->top);
		$footer_page = $this->render($this->footer);
		$left_page = $this->render($this->left);
		$right_header_page = $this->render($this->rightheader);
		$right_page = $this->render($this->right);
		$header_page = $this->render($this->header);
		$popupheader_page = $this->render($this->popupheader);
		$browser_title = $this->browsertitle;

		ob_start();
		$this->_header();

		include($this->layout);

		$ret =  ob_get_clean();
		return $ret;
	}

	function render($page){
		ob_start();
		$param = $this->param;
		include($page);
		$ret = ob_get_clean();
		return $ret;
	}

	function _header(){
		header( 'Cache-Control: no-store, no-cache, must-revalidate' );
		header( 'Pragma: no-cache' );
		header( 'Content-type: text/html; charset=UTF-8' );
	}
}
?>
