<?php
$i = posix_getpwnam("mail11");
if (is_array($i)) {
	echo "aa";
}
else {
	echo "no";
}
?>
