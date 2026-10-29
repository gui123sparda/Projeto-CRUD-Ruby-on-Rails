(function (root) {
    'use strict';
    const inteiro = n => Math.floor(Math.random() * n);
    const escolher = s => s[inteiro(s.length)];
    const digitos = n => Array.from({length:n}, () => inteiro(10)).join('');
    function documento(empresa) {
        const base = empresa ? digitos(8) + '0001' : digitos(9);
        function dv(s) {
            const pesos = s.length === 9 ? [10,9,8,7,6,5,4,3,2] : s.length === 10 ? [11,10,9,8,7,6,5,4,3,2] : s.length === 12 ? [5,4,3,2,9,8,7,6,5,4,3,2] : [6,5,4,3,2,9,8,7,6,5,4,3,2];
            const resto = [...s].reduce((v,c,i) => v + Number(c)*pesos[i], 0) % 11;
            return resto < 2 ? '0' : String(11-resto);
        }
        const parcial = base + dv(base); return parcial + dv(parcial);
    }
    function proprietario(empresa) {
        return {cpfCnpj:documento(empresa), nome:empresa ? 'EMPRESA FICTÍCIA ' + digitos(6) + ' LTDA' : escolher(['ANA','JOÃO','MARIA','PAULO','LÚCIA']) + ' ' + escolher(['SILVA','COSTA','SANTOS','ALMEIDA']) + ' (FICTÍCIO)', rua:'RUA DE DEMONSTRAÇÃO', numero:String(1+inteiro(999)), cep:'60000-000', cidade:'FORTALEZA', estado:'CE', complemento:'DADOS FICTÍCIOS PARA TESTE'};
    }
    function veiculo() {
        const letras='ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        const chassi='ABCDEFGHJKLMNPRSTUVWXYZ0123456789';
        let renavam=digitos(10), soma=0;
        [...renavam].reverse().forEach((c,i) => { soma += Number(c)*([2,3,4,5,6,7,8,9][i%8]); });
        const dv=11-soma%11;
        return {placa:Array.from({length:3},()=>escolher(letras)).join('')+inteiro(10)+(inteiro(2) ? escolher(letras) : inteiro(10))+digitos(2), renavam:renavam+(dv>=10?0:dv), chassi:Array.from({length:17},()=>escolher(chassi)).join(''), anoFabricacao:String(new Date().getFullYear()-inteiro(20))};
    }
    const api={documento,proprietario,veiculo};
    if (typeof module !== 'undefined') module.exports=api;
    if (!root.document) return;
    const doc=root.document;
    function uppercase(el) {
        if (!(el instanceof HTMLInputElement || el instanceof HTMLTextAreaElement) || !['text','search','textarea'].includes(el.type) || el.readOnly) return;
        const inicio=el.selectionStart, fim=el.selectionEnd;
        el.value=el.value.toLocaleUpperCase('pt-BR');
        if (inicio !== null) el.setSelectionRange(inicio,fim);
    }
    doc.addEventListener('input',e=>{if(!e.isComposing) uppercase(e.target);},true);
    doc.addEventListener('compositionend',e=>uppercase(e.target),true);
    doc.addEventListener('submit',e=>e.target.querySelectorAll('input,textarea').forEach(uppercase),true);
    function iniciar() {
        doc.querySelectorAll('input,textarea').forEach(uppercase);
        const dono=doc.getElementById('idProprietario'), campos=doc.getElementById('dados-veiculo');
        if(dono && campos) {
            const atualizar=()=>{campos.hidden=!dono.value; campos.disabled=!dono.value;};
            dono.addEventListener('change',atualizar); atualizar();
        }
        doc.querySelectorAll('[data-gerar-ficticios]').forEach(botao=>botao.addEventListener('click',()=>{
            const form=botao.closest('form');
            const valores=botao.dataset.gerarFicticios==='veiculo' ? veiculo() : proprietario(form.elements.tipoPessoa && form.elements.tipoPessoa.value==='PJ');
            Object.entries(valores).forEach(([nome,valor])=>{const campo=form.elements.namedItem(nome); if(campo && !campo.readOnly){campo.value=valor; if(nome!=='cep') campo.dispatchEvent(new Event('input',{bubbles:true}));}});
            const aviso=form.querySelector('[data-aviso-ficticios]'); if(aviso) aviso.textContent='Dados fictícios preenchidos. Revise antes de salvar. Não correspondem a uma identidade verificada.';
        }));
    }
    if(doc.readyState==='loading') doc.addEventListener('DOMContentLoaded',iniciar); else iniciar();
}(typeof window !== 'undefined' ? window : globalThis));
