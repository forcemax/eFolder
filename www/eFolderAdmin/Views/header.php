<link rel="stylesheet" href="Css/jqdialog.css" type="text/css" />
<link rel="stylesheet" href="Css/jquery.alerts.css" type="text/css" />
<link rel="stylesheet" href="Css/default.css" type="text/css" />
<?php
if ($param['sc']['css']) {
        foreach ($param['sc']['css'] as $v) {
?>
<link rel="stylesheet" href="<?=$v?>" type="text/css" />
<?php
        }
}
?>

<script type="text/javascript" src="Js/jquery-1.4.4.min.js"> </script>
<script type="text/javascript" src="Js/jquery.scrollTo-min.js"> </script>
<script type="text/javascript" src="Js/jquery-ui-1.8.10.custom.min.js"> </script>
<script type="text/javascript" src="Js/jquery.alerts.js"> </script>
<script type="text/javascript" src="Js/default.js"> </script>
<?php
if ($param['sc']['js']) {
        foreach ($param['sc']['js'] as $w) {
?>
<script type="text/javascript" src="<?=$w?>"> </script>
<?php
        }
}
?>

