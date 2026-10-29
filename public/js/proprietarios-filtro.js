(function () {
    "use strict";

    const form = document.querySelector("[data-live-filter]");
    const resultados = document.getElementById("proprietarios-resultados");
    const status = document.getElementById("busca-status");
    if (!form || !resultados || !status || !window.fetch || !window.AbortController) {
        return;
    }

    const assinatura = () => new URLSearchParams(new FormData(form)).toString();
    let temporizador;
    let requisicao;

    function atualizar() {
        clearTimeout(temporizador);
        if (requisicao) {
            requisicao.abort();
            requisicao = null;
        }

        resultados.setAttribute("aria-busy", "true");
        status.textContent = "Buscando...";
        temporizador = setTimeout(async function () {
            const valorBuscado = assinatura();
            const url = new URL(form.action);
            url.search = valorBuscado;
            const atual = new AbortController();
            requisicao = atual;

            try {
                const resposta = await fetch(url, { signal: atual.signal, credentials: "same-origin" });
                if (!resposta.ok) {
                    throw new Error("Falha na consulta");
                }
                const html = await resposta.text();
                if (atual.signal.aborted || assinatura() !== valorBuscado) {
                    return;
                }
                const pagina = new DOMParser().parseFromString(html, "text/html");
                const novosResultados = pagina.getElementById("proprietarios-resultados");
                if (!novosResultados) {
                    throw new Error("Resposta sem resultados");
                }

                resultados.innerHTML = novosResultados.innerHTML;
                resultados.dataset.total = novosResultados.dataset.total;
                history.replaceState(history.state, "", url.pathname + url.search);
                const total = Number(novosResultados.dataset.total);
                status.textContent = total + (total === 1 ? " registro encontrado." : " registros encontrados.");
            } catch (erro) {
                if (!atual.signal.aborted) {
                    status.textContent = "Não foi possível atualizar a lista. Use o botão Filtrar.";
                }
            } finally {
                if (requisicao === atual) {
                    requisicao = null;
                    resultados.removeAttribute("aria-busy");
                }
            }
        }, 300);
    }

    form.addEventListener("input", function (evento) {
        if (!evento.isComposing) {
            atualizar();
        }
    });
    form.addEventListener("compositionend", atualizar);
    form.addEventListener("change", atualizar);
    form.addEventListener("submit", function () {
        clearTimeout(temporizador);
        if (requisicao) {
            requisicao.abort();
        }
    });
}());
