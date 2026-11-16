(function () {
    "use strict";

    const busca = document.getElementById("buscaProprietario");
    const selecao = document.getElementById("idProprietario");
    if (!busca || !selecao) return;

    const opcoes = Array.from(selecao.options);
    const resultado = document.getElementById("resultado-busca-proprietario");
    const normalizar = valor => valor.normalize("NFD").replace(/[\u0300-\u036f]/g, "")
        .toUpperCase().replace(/[^A-Z0-9]/g, "");

    function filtrar() {
        const termo = normalizar(busca.value);
        const selecionado = selecao.value;
        const correspondencias = opcoes.filter(opcao => opcao.value && normalizar(opcao.textContent).includes(termo));
        // Preserve the current owner while searching, including on the edit form.
        selecao.replaceChildren(...opcoes.filter(opcao => !opcao.value || opcao.value === selecionado || correspondencias.includes(opcao)));
        selecao.value = selecionado;
        resultado.textContent = correspondencias.length
            ? `${correspondencias.length} proprietário(s) encontrado(s). Selecione na lista abaixo.`
            : "Nenhum proprietário encontrado.";
    }

    busca.addEventListener("input", filtrar);
    document.getElementById("pesquisa-proprietario").hidden = false;
}());
