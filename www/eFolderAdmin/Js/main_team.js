$(document).ready(function () {
	$('#teamList').load("teamlist.sub.php");
	$('#team').keypress(function(event){
		if (event.which == 13) {
			addTeam();
		}
	});
});
function addTeam() {
	setEmActiveLayer(true);
	if(!checkname($('#team').val())) {
		return;
	}
	$.ajax({
		type: "POST",
		url: "register.action.php",
		data: ({team:$('#team').val(), mode:'ADD_TEAM'}),
		dataType: "json",
		async:false,
		success: function (data) {
			setEmActiveLayer(false);
			if (data.ret == false) {
				jAlert(data.msg, "Alert");
			}
			else {
				$('#teamList').load("teamlist.sub.php");
				addReset();
			}
		},
		error: function() {
			setEmActiveLayer(false);
			jAlert("통신 오류로 등록에 실패 하였습니다.", "Error");
		}
	});
}
function deleteTeam(team) {
	jConfirm(team + "을(를) 삭제하시겠습니까?",
		"Confirmation",
		function(r) {
			if (r==true) {
				deleteTeamAction(team);
			}
		}
        );
}

function deleteTeamAction(teamid) {
	setEmActiveLayer(true);
	$.ajax({
		type: "POST",
		url: "register.action.php",
		data :  ({team:teamid, mode:'DELETE_TEAM'}),
		dataType: "json",
		async:false,
		success: function (data) {
			setEmActiveLayer(false);
			if (data.ret == false) {
				jAlert(data.msg, "Alert");
			}
			else {
				jAlert(teamid + "을(를) 삭제하였습니다.", 
					"Alert",
					function() { $('#teamList').load("teamlist.sub.php"); }
				);
			}
		},
		error: function() {
			setEmActiveLayer(false);
			jAlert("통신 오류로 등록에 실패 하였습니다.", "Error");
		}
	});
}
function addReset() {
	$('#team').val("");
}
function modifyTeam(team) {
	setEmActiveLayer(true);
	var a = $('#teamUserList').html();
	if (a) { 
		$('#teamUserList').hide('slow', function() {
			$('#teamUserList').load("teammember.sub.php?team="+team, function() { setEmActiveLayer(false); });
			$('#teamUserList').show('slow');
		});
	}
	else {
		$('#teamUserList').load("teammember.sub.php?team="+team);
		$('#teamUserList').show('slow', function() { setEmActiveLayer(false); });
	}
}
function addTeamUser(teamid) {
	$("#notusers option:selected").each(function(){
		$(this).appendTo("#users")
	});
	addTeamUserAction(teamid);
}
function deleteTeamUser(teamid) {
	$("#users option:selected").each(function(){
		$(this).appendTo("#notusers")
	});
	addTeamUserAction(teamid);
}
function addTeamUserAction(teamid) {
	var param = "";
	var v = "";
	$("#users option").each(function(){
		if ($(this).val()) {
			v = $(this).val();
			param += "a[]="+v+"&";
		}
	});

	param += "team="+teamid+"&mode=ADD_TEAM_USER";

	setEmActiveLayer(true);
	$.ajax({
		type: "POST",
		url: "register.action.php",
		data: param,
		dataType: "json",
		async: false,
		success: function(data) {
			setEmActiveLayer(false);
			if (data.ret == false) {
				jAlert(data.msg, 
					"Alert",
					function() { modifyTeam(teamid); }
				);
			}
			else { }
		},
		error: function() {
			setEmActiveLayer(false);
			jAlert("통신 오류로 등록에 실패 하였습니다.", "Error");
		}
	});
}
function closeTeamUserList() {
	$("#teamUserList").html("");
}
