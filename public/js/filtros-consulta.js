(function () {
    'use strict';
    document.querySelectorAll('[data-campo-filtro]').forEach(function (campo) {
        const form = campo.form;
        const input = form.querySelector('[data-valor-filtro]');
        const select = form.querySelector('[data-opcao-filtro]');
        const label = form.querySelector('[data-label-valor]');
        campo.addEventListener('change', function () {
            const opcao = campo.selectedOptions[0];
            const enumerado = opcao.dataset.tipo === 'select';
            input.hidden = input.disabled = enumerado;
            select.hidden = select.disabled = !enumerado;
            input.type = enumerado ? 'text' : opcao.dataset.tipo;
            input.value = '';
            select.replaceChildren(new Option('Todos', ''));
            if (enumerado) opcao.dataset.opcoes.split('|').forEach(function (item) {
                const [valor, texto] = item.split(':'); select.add(new Option(texto, valor));
            });
            label.htmlFor = enumerado ? select.id : input.id;
            (enumerado ? select : input).focus();
        });
    });
}());
