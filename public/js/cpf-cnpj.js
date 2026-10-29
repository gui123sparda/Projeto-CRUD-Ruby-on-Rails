(function () {
    "use strict";

    const campo = document.getElementById("cpfCnpj");
    if (!campo) {
        return;
    }
    const status = document.getElementById("documento-status");

    function digitoCpf(base) {
        let soma = 0;
        for (let i = 0; i < base.length; i++) {
            soma += Number(base.charAt(i)) * (base.length + 1 - i);
        }
        const resultado = 11 - soma % 11;
        return resultado >= 10 ? 0 : resultado;
    }

    function digitoCnpj(base) {
        let soma = 0;
        for (let i = base.length - 1; i >= 0; i--) {
            soma += (base.charCodeAt(i) - 48) * (2 + (base.length - 1 - i) % 8);
        }
        const resultado = 11 - soma % 11;
        return resultado >= 10 ? 0 : resultado;
    }

    function verificar(completo) {
        const documento = campo.value.replace(/[^A-Z0-9]/g, "");
        let tipo = "";
        let valido = false;

        if (/^\d{11}$/.test(documento)) {
            tipo = "CPF";
            valido = !/^(\d)\1{10}$/.test(documento)
                && Number(documento.charAt(9)) === digitoCpf(documento.slice(0, 9))
                && Number(documento.charAt(10)) === digitoCpf(documento.slice(0, 10));
        } else if (/^[A-Z0-9]{12}\d{2}$/.test(documento)) {
            tipo = "CNPJ";
            valido = !/^(\d)\1{13}$/.test(documento)
                && Number(documento.charAt(12)) === digitoCnpj(documento.slice(0, 12))
                && Number(documento.charAt(13)) === digitoCnpj(documento.slice(0, 13));
        }

        const erro = tipo ? !valido : completo && documento.length > 0;
        const mensagem = tipo
            ? (valido ? tipo + " válido pelos dígitos verificadores." : tipo + " inválido: confira os dígitos verificadores.")
            : (erro ? "Documento incompleto: informe um CPF com 11 dígitos ou CNPJ com 14 caracteres." : "");
        campo.setCustomValidity(erro ? mensagem : "");
        campo.classList.toggle("input-error", erro);
        campo.classList.toggle("input-success", Boolean(tipo && valido));
        if (erro) {
            campo.setAttribute("aria-invalid", "true");
        } else {
            campo.removeAttribute("aria-invalid");
        }
        if (status) {
            status.textContent = mensagem;
        }
    }

    function formatar(valor) {
        const caracteres = valor.toUpperCase().replace(/[^A-Z0-9]/g, "").slice(0, 14);
        if (/^\d{0,11}$/.test(caracteres)) {
            return caracteres
                .replace(/^(\d{3})(\d)/, "$1.$2")
                .replace(/^(\d{3})\.(\d{3})(\d)/, "$1.$2.$3")
                .replace(/^(\d{3})\.(\d{3})\.(\d{3})(\d)/, "$1.$2.$3-$4");
        }
        const base = caracteres.slice(0, 12);
        const finais = caracteres.slice(12).replace(/\D/g, "").slice(0, 2);
        const cnpj = base + finais;
        return cnpj
            .replace(/^(.{2})(.)/, "$1.$2")
            .replace(/^(.{2})\.(.{3})(.)/, "$1.$2.$3")
            .replace(/^(.{2})\.(.{3})\.(.{3})(.)/, "$1.$2.$3/$4")
            .replace(/^(.{2})\.(.{3})\.(.{3})\/(.{4})(.)/, "$1.$2.$3/$4-$5");
    }

    function atualizar() {
        const posicaoOriginal = campo.selectionStart === null ? campo.value.length : campo.selectionStart;
        const caracteresAntesDoCursor = campo.value.slice(0, posicaoOriginal).replace(/[^A-Z0-9]/gi, "").length;
        const valorFormatado = formatar(campo.value);
        campo.value = valorFormatado;

        if (document.activeElement === campo) {
            let posicao = 0;
            let caracteresPercorridos = 0;
            while (posicao < valorFormatado.length && caracteresPercorridos < caracteresAntesDoCursor) {
                if (/[A-Z0-9]/.test(valorFormatado.charAt(posicao))) {
                    caracteresPercorridos++;
                }
                posicao++;
            }
            campo.setSelectionRange(posicao, posicao);
        }
    }

    campo.addEventListener("input", function () {
        atualizar();
        verificar(false);
    });
    campo.addEventListener("blur", function () { verificar(true); });
    campo.form.addEventListener("submit", function (evento) {
        atualizar();
        verificar(true);
        if (!campo.checkValidity()) {
            evento.preventDefault();
            campo.reportValidity();
        }
    });
    atualizar();
    verificar(false);
}());
