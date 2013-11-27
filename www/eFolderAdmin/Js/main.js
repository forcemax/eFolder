$(document).ready(function () {
	$('#userList').load("userlist.sub.php");
	$('#passwd').keypress(function(event){
		if (event.which == 13) {
			addUser();
		}
	});
});
function addUser() {
	setEmActiveLayer(true);
        if(!checkname($('#user').val())) {
                return;
        }
	$.ajax({
		type: "POST",
		url: "register.action.php",
		data: ({user:$('#user').val(), passwd:$('#passwd').val(), mode:'ADD'}),
		dataType: "json",
		async:false,
		success: function (data) {
			setEmActiveLayer(false);
			if (data.ret == false) {
				jAlert(data.msg, "Alert");
			}
			else {
				$('#userList').load("userlist.sub.php");
				addReset();
			}
		},
		error: function() {
			setEmActiveLayer(false);
			jAlert("통신 오류로 등록에 실패 하였습니다.", "Error");
		}
	});
}
function deleteUser(userid) {
	jConfirm(userid + "을(를) 삭제하시겠습니까?",
		"Confirmation",
		function(r) {
			if (r==true) {
				deleteUserAction(userid);
			}
		}
	);
}

function deleteUserAction(userid) {
	setEmActiveLayer(true);
	$.ajax({
		type: "POST",
		url: "register.action.php",
		data :  ({user:userid, mode:'DELETE'}),
		dataType: "json",
		async:false,
		success: function (data) {
			setEmActiveLayer(false);
			if (data.ret == false) {
				jAlert(data.msg, "Alert");
			}
			else {
				jAlert(userid + "을(를) 삭제하였습니다.", 
					"Alert",
					function() { $('#userList').load("userlist.sub.php"); }
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
	$('#user').val("");
	$('#passwd').val("");
	$('#user').focus();
}

function updateUser(userid) {
	jPrompt(userid + " - Change Password",
		'',
		'Input',
		function(r) { udpatePassword(userid, r); }
	);
}
function udpatePassword(userid, password) {
	if (userid && password) {
		setEmActiveLayer(true);
		$.ajax({
			type: "POST",
			url: "register.action.php",
			data: ({user:userid, passwd:password, mode:'UPDATE_PASSWD'}),
			dataType: "json",
			async:false,
			success: function (data) {
				setEmActiveLayer(false);
				if (data.ret == false) {
					jAlert(data.msg, "Alert");
				}
				else {
					jAlert(userid + " - Change Password Complete", "Alert");
				}
			},
			error: function() {
				setEmActiveLayer(false);
				jAlert("통신 오류로 등록에 실패 하였습니다.", "Error");
			}
		});
	}
}
function searchUser() {
	setEmActiveLayer(true);
	$(".tblList").css('color', '#000000');
	$.ajax({
		type: "POST",
		url: "register.action.php",
		data: ({search:$('#search_val').val(), mode:'SEARCH'}),
		dataType: "json",
		async: false,
		success: function(data) {
			setEmActiveLayer(false);
			if (data.ret == false) {
				jAlert(data.msg, 
					"Alert",
					function(){ $("#search_val").select(); }
				);
			}
			else {
				gotoUser(data.msg);
			}

		},
		error: function() {
			setEmActiveLayer(false);
			jAlert("통신 오류로 등록에 실패 하였습니다.", "Error");
		}
	});
}
function gotoUser(line) {
	var arr = line.split("|");
	var len = arr.length;
	$('#userListBox').stop().scrollTo( 'tr:eq('+arr[0]+')', 0 );
	$(".tblList").css('color', '#000000');
	for(i=0; i<len; i++) {
		var pid = "p_"+arr[i];
		$("#"+pid).css('color', 'red');
	}
	$("#search_val").select();
}
