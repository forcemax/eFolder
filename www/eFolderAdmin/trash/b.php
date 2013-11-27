<?php
$user_input = "aaa";
$password = '$1$gzg7B6DJ$a1eDYBJxbmBdjS4eMPPDw/';

if (crypt($user_input, $password) == $password) {
	echo "Password verified!";
}
else {
	echo "NO";
}
echo "\n";

?>
