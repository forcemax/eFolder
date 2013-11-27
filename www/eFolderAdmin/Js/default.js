function setEmActiveLayer(flag) {
        if (flag == true) {
                $("#em_active_layer").height($("#wrap").height());
                $("#em_active_layer").css("opacity","0.5");
                $("#em_active_layer").css("display", "block");
        }
        else {
                $("#em_active_layer").css("display", "none");
        }
}

function authenticate(flag) {
        setEmActiveLayer(true);
        $.ajax({
                type: "POST",
                url: "login.action.php",
                data: ({id:$('#id').val(), pwd:$('#pwd').val(), mode: flag}),
                dataType: "json",
                async:false,
                success: function (data) {
                        setEmActiveLayer(false);
                        if (data.ret == false) {
                                jAlert(data.msg, "확인");
                                //alert(data.msg);
                        }
                        else {
				if (flag == "LOGIN") {
                                	window.location.href = "./main.php";
				}
				else {
                                	window.location.href = "./index.php";
				}
                        }
                },
                error: function() {
                        setEmActiveLayer(false);
                        jAlert("통신 오류로 등록에 실패 하였습니다.","오류");
                        //alert("통신 오류로 등록에 실패 하였습니다.");
                }
        });
}

function checkname(str) {
	if (/\W/.test(str)) {
		setEmActiveLayer(false);
		jAlert("The name or ID does not consist of all letters or digits.", "Error");
		return false;
	}

	if (str.toLowerCase() != str) {
		setEmActiveLayer(false);
		jAlert("The name or ID does not consist of all lowercase letters.", "Error");
		return false;
	}

	return true;
}
