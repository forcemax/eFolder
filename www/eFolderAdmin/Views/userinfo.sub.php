<table>
	<tr>
		<td colspan="3" style="font-weight:bold;"><?=$param['user']?></td>
	</tr>
	<tr>
		<td>비밀번호</td>
		<td><input type="password" name="new_passwd" id="new_passwd" /></td>
		<td><input type="button" value="수정" onClick="updatePassword('<?=$param['user']?>')" /></td>
	</tr>
</table>
