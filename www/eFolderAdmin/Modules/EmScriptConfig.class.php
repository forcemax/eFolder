<?php
class EmScriptConfig {
	function EmScriptConfig() {
	}

	function setJs($js) {
		$name = $js.".js";
		$this->sc['js'][$js] = "Js/".$name;
	}
	function setCss($css) {
		$name = $css.".css";
		$this->sc['css'][$css] = "Css/".$name;
	}
	function getScriptConfig() {
		return $this->sc;
	}
}
?>
