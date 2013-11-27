<div class="roundTop boxTitle" style="width:350px">Team List</div>
<div class="roundBottom boxMain list">
<table cellspacing="0" cellpadding="2" style="width:330px">

<?php
if (is_array($param['lists'])) { foreach ($param['lists'] as $v) {
?>
	<tr>
		<td class="tblList" style="padding-left:10px;"><?=$v['teamid_col']?></td>
		<td class="tblList" style="text-align:center;width:60px"><input type="button" onClick="modifyTeam('<?=$v['teamid_col']?>')" value="Modify" /></td>
		<td class="tblList" style="text-align:center;width:60px"><input type="button" onClick="deleteTeam('<?=$v['teamid_col']?>')" value="Delete" /></td>
	</tr>
<?php
} }
?>
</table>
</div>
