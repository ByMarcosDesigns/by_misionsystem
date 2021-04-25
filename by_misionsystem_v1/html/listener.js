$(function () {
    function display(bool) {
        if (bool) {
            $("#container").show();
            $("#crearmisionesmapa").hide();
            $("#guardarmisionessql").hide();
        } else {
            $("#container").hide();
            $("#crearmisionesmapa").hide();
            $("#guardarmisionessql").hide();
        }
    }

    display(false)

    window.addEventListener("message", function(event) {
        var item = event.data;
        if (item.type === "ui") {
            if (item.status == true) {
                display(true)
            } else {
                display(false)
            }
        }
    })

    document.onkeyup = function (data) {
        if (data.which == 27) {
            $.post("http://by_misionsystem/exit", JSON.stringify({}));
            return
        }
    }

    $("#close").click(function() {
        $.post("http://by_misionsystem/exit", JSON.stringify({}));
        return
    })

    $("#create").click(function() {
        $.post("http://by_misionsystem/create", JSON.stringify({}));
        return
    })

    $("#return1").click(function() {
        $("#crearmisionesmapa").hide();
        $("#guardarmisionessql").hide();
        $("#container").show();
    })
    
    $("#return2").click(function() {
        $("#crearmisionesmapa").hide();
        $("#guardarmisionessql").hide();
        $("#container").show();
    })

    $("#createmission").click(function() {
        $("#container").hide();
        $("#crearmisionesmapa").show();
    })

    $("#savemission").click(function() {
        $("#container").hide();
        $("#guardarmisionessql").show();
    })

    $("#submit").click(function() {
        let inpuValue = $("#input").val()
        let inpuValue2 = $("#input2").val()
        if (inpuValue.length >= 40 || inpuValue2 >= 40) {
            $.post("http://by_misionsystem/error", JSON.stringify({
                error: "El nombre añadido supera las 40 letras"
            }))
            return
        } else if (!inpuValue || !inpuValue2) {
            $.post("http://by_misionsystem/error", JSON.stringify({
                error: "No se ha introducido ningun valor"
            }))
            return
        } else if (inpuValue2 == 'camionero' || inpuValue2 == 'piloto' || inpuValue2 == 'maritimo') {
            $.post("http://by_misionsystem/main", JSON.stringify({
                text: inpuValue,
                text2: inpuValue2
            }))
            return
        }
        $.post("http://by_misionsystem/error", JSON.stringify({
            error: "El tipo de mision introducida no es valida"
        }));
        return;
    })
})