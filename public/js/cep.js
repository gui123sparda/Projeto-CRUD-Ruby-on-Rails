(function () {
    "use strict";

    const cep = document.getElementById("cep");
    if (!cep) return;

    const rua = document.getElementById("rua");
    const cidade = document.getElementById("cidade");
    const estado = document.getElementById("estado");
    const complemento = document.getElementById("complemento");
    const status = document.getElementById("cep-status");
    let timer;
    let versao = 0;

    function mostrar(mensagem) {
        status.textContent = mensagem;
    }

    function mascarar(digitos) {
        return digitos.length > 5 ? digitos.slice(0, 5) + "-" + digitos.slice(5) : digitos;
    }

    async function buscar(digitos, consulta) {
        const valoresAnteriores = [rua.value, cidade.value, estado.value];
        try {
            const resposta = await fetch("https://viacep.com.br/ws/" + digitos + "/json/", {
                headers: { "Accept": "application/json" }
            });
            if (!resposta.ok) throw new Error("Falha na consulta");
            const dados = await resposta.json();
            if (consulta !== versao) return;
            if (dados.erro) {
                mostrar("CEP não encontrado. Preencha o endereço manualmente.");
                return;
            }
            if (rua.value === valoresAnteriores[0]) rua.value = (dados.logradouro || "").toLocaleUpperCase("pt-BR");
            if (cidade.value === valoresAnteriores[1]) cidade.value = (dados.localidade || "").toLocaleUpperCase("pt-BR");
            if (estado.value === valoresAnteriores[2]) estado.value = dados.uf || "";
            if (!complemento.value && dados.complemento) complemento.value = dados.complemento.toLocaleUpperCase("pt-BR");
            mostrar("Endereço encontrado. Confira os dados e informe o número.");
        } catch (erro) {
            if (consulta === versao) mostrar("Não foi possível consultar o CEP. Preencha o endereço manualmente.");
        }
    }

    cep.value = mascarar(cep.value.replace(/\D/g, "").slice(0, 8));
    cep.addEventListener("input", function () {
        clearTimeout(timer);
        versao += 1;
        const digitos = cep.value.replace(/\D/g, "").slice(0, 8);
        cep.value = mascarar(digitos);
        if (digitos.length !== 8) {
            mostrar("Informe 8 dígitos para buscar o endereço.");
            return;
        }
        mostrar("Consultando CEP...");
        const consulta = versao;
        timer = setTimeout(function () { buscar(digitos, consulta); }, 300);
    });
}());
