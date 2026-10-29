(() => {
    const modalConfirmacao = document.getElementById('modal-confirmar-exclusao');
    const modalCascata = document.getElementById('modal-confirmar-cascata');
    const nome = document.getElementById('exclusao-proprietario-nome');
    const mensagemCascata = document.getElementById('exclusao-cascata-mensagem');
    const continuar = document.getElementById('continuar-exclusao-proprietario');
    const formulario = document.getElementById('form-excluir-proprietario');
    const campoId = document.getElementById('exclusao-proprietario-id');
    const campoCascata = document.getElementById('exclusao-proprietario-cascata');
    const campoTotalConfirmado = document.getElementById('exclusao-proprietario-total-confirmado');
    let proprietarioSelecionado = null;

    document.addEventListener('click', (evento) => {
        const alvo = evento.target;
        const botao = alvo && typeof alvo.closest === 'function'
                ? alvo.closest('[data-excluir-proprietario]') : null;
        if (!botao) return;

        proprietarioSelecionado = {
            id: botao.dataset.id,
            nome: botao.dataset.nome,
            totalVeiculos: Number.parseInt(botao.dataset.totalVeiculos, 10) || 0
        };
        nome.textContent = proprietarioSelecionado.nome;
        modalConfirmacao.showModal();
    });

    continuar.addEventListener('click', () => {
        if (!proprietarioSelecionado) return;

        campoId.value = proprietarioSelecionado.id;
        campoTotalConfirmado.value = String(proprietarioSelecionado.totalVeiculos);
        if (proprietarioSelecionado.totalVeiculos === 0) {
            campoCascata.value = 'false';
            if (typeof formulario.requestSubmit === 'function') {
                formulario.requestSubmit();
            } else {
                formulario.submit();
            }
            return;
        }

        campoCascata.value = 'true';
        mensagemCascata.textContent = 'Este proprietário possui '
                + proprietarioSelecionado.totalVeiculos + ' '
                + (proprietarioSelecionado.totalVeiculos === 1 ? 'veículo' : 'veículos')
                + '. Todos serão inativados e preservados no histórico.';
        modalConfirmacao.close();
        modalCascata.showModal();
    });
})();
