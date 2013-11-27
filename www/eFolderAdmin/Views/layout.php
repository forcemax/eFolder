<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ko" lang="ko">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title><?=$browser_title?></title>
<?=$header_page?>
</head>
<body>
<div id="page">
<table width=100% cellspacing="0" cellpadding="0">
	<tr><td id="page_header" align="center"><?=$top_page?></td></tr>
	<tr>
		<td id="page_body">
			<table border="0" id="body" cellspacing="0" cellpadding="0" align="center">
				<tr>
					<td id="body_left" valign="top"><?=$left_page?></td>
					<td id="body_right" valign="top">
						<?=$right_header_page?>
						<?=$right_page?>
					</td>
				</tr>
			</table>
		</td>
	</tr>
	<tr><td id="page_footer" align="center"><?=$footer_page?></td></tr>
</table>
</div>
<div id="em_active_layer" style="display:none;position:absolute;top:0;left:0;width:100%;height:100%;background:#FFFFFF;z-index:90000;">
            <table width="100%" height="100%"><tr><td align="center"><img src="./Images/ajax-loader.gif" /></td></tr></table>
</div>
</body>
</html>

