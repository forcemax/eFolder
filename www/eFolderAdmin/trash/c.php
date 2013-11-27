<?php
$a = array("a","b","c","d");

$key = array_search("b", $a);
echo $key."\n";

array_splice($a, $key, 1);

foreach ($a as $v) {
	echo $v."\n";
}

?>
