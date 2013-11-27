<div class="roundTop boxTitle" style="width:335px"><a href="#" onClick="closeTeamUserList()">&lt;&lt; Close</a> <?=$param['team']?></div>
<div class="roundBottom boxMain" style="width:335px;height:370px;overflow:auto">
<table cellspacing="0" cellpadding="2">
	<tr>
		<td>
<select name="notusers" id="notusers" style="width:120px;" size="20" multiple>
	<option disabled>Unregistered</option>
	<option disabled>-----------</option>
<?php
foreach ($param['notuserlists'] as $v) {
	echo "<option>".$v."</option>";
}
?>
</select>
		</td>
		<td>
			<input type="button" value="&nbsp;&nbsp;Add&nbsp;&nbsp;&nbsp;&nbsp;>>" style="padding:0;" onClick="addTeamUser('<?=$param['team']?>')" /><br />
			<input type="button" value="<< Remove" style="padding:0;" onClick="deleteTeamUser('<?=$param['team']?>')" />
		</td>
		<td>
<select name="users" id="users" style="width:120px;" size="20" multiple>
	<option value="" disabled>Registered</option>
	<option value="" disabled>-----------</option>
<?php
foreach ($param['userlists'] as $v) {
	echo "<option value='".$v."'>".$v."</option>";
}
?>
</select>
		</td>
	</tr>
</table>
</div>
