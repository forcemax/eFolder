<script>
$(document).ready(function () {
	$('#search_val').keypress(function(event){
		if (event.which == 13) {
			searchUser();
		}
	});
});
</script>
<div class="roundTop boxTitle" style="width:350px">
	Account List&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	<input type="input" name="search_val" id="search_val" />
	<input type="button" value="Search" onClick="searchUser()" />
</div>
<div class="roundBottom boxMain list" id="userListBox">
<table cellspacing="0" cellpadding="2" style="width:330px">

<?php
if (is_array($param['lists'])) { foreach ($param['lists'] as $k=>$v) {
?>
	<tr>
		<td class="tblList" style="padding-left:10px;width:100px" id="p_<?=$k?>"><?=$v['username_col']?></td>
		<td class="tblList" style="text-align:center;width:60px"><input type="button" onClick="updateUser('<?=$v['username_col']?>')" value="Modify" /></td>
		<td class="tblList" style="text-align:center;width:60px"><input type="button" onClick="deleteUser('<?=$v['username_col']?>')" value="Delete" /></td>
	</tr>
<?php
} }
?>
</table>
</div>
