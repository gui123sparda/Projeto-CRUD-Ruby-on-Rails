(function () {
    "use strict";
    const raiz = document.documentElement;
    const botao = document.getElementById("theme-toggle");
    if (!botao) return;
    let salvo = null;
    try { salvo = localStorage.getItem("tema-detran"); } catch (_) { /* armazenamento indisponível */ }
    const inicial = salvo === "dark" || salvo === "light"
        ? salvo : (window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
    function aplicar(tema) {
        raiz.setAttribute("data-theme", tema);
        botao.textContent = tema === "dark" ? "Modo escuro" : "Modo claro";
        botao.setAttribute("aria-label", "Ativar " + (tema === "dark" ? "modo escuro" : "modo claro"));
        botao.setAttribute("aria-pressed", String(tema === "dark"));
    }
    aplicar(inicial);
    botao.addEventListener("click", function () {
        const novo = raiz.getAttribute("data-theme") === "dark" ? "light" : "dark";
        aplicar(novo);
        try { localStorage.setItem("tema-detran", novo); } catch (_) { /* armazenamento indisponível */ }
    });
}());
