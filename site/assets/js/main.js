// BETA-11B/BETA-11C — Interações do site institucional do BORAH.
//
// Menu mobile e acordeão de FAQ: sem dependências externas.
//
// Formulários (Beta/Contato): enviados via fetch() para a Edge
// Function pública `website-form-submit` (Supabase), que valida o
// Cloudflare Turnstile no servidor antes de gravar em
// `beta_waitlist`/`contact_messages`. O navegador nunca grava direto
// no banco — só chama a função, protegida por Turnstile + honeypot +
// tempo mínimo de preenchimento (ver
// supabase/functions/website-form-submit/index.ts).
//
// IMPORTANTE: os dois valores abaixo são públicos por natureza (o
// site key do Turnstile e a URL da Edge Function não são segredos),
// mas ainda são placeholders — substituir pelos valores reais do
// projeto Supabase/Cloudflare antes do deploy (ver docs/website/forms.md).
const FUNCTIONS_URL = "https://YOUR-PROJECT-REF.supabase.co/functions/v1/website-form-submit";

(function () {
  "use strict";

  const pageLoadedAt = Date.now();

  function setupNavToggle() {
    var toggle = document.querySelector(".nav-toggle");
    var links = document.getElementById("nav-links");
    if (!toggle || !links) return;
    toggle.addEventListener("click", function () {
      var isOpen = links.classList.toggle("open");
      toggle.setAttribute("aria-expanded", String(isOpen));
    });
  }

  function setupFaqAccordion() {
    var questions = document.querySelectorAll(".faq-question");
    questions.forEach(function (button) {
      button.addEventListener("click", function () {
        var item = button.closest(".faq-item");
        if (!item) return;
        var isOpen = item.classList.toggle("open");
        button.setAttribute("aria-expanded", String(isOpen));
      });
    });
  }

  function showMessage(el, lines) {
    if (!el) return;
    el.innerHTML = "";
    (Array.isArray(lines) ? lines : [lines]).forEach(function (line, index) {
      if (index > 0) el.appendChild(document.createElement("br"));
      el.appendChild(document.createTextNode(line));
    });
    el.classList.add("visible");
  }

  function hideMessage(el) {
    if (!el) return;
    el.classList.remove("visible");
  }

  // Mensagens fixas exigidas para o formulário de Beta (waitlist);
  // as demais respostas do servidor já vêm com `message` pronto para
  // exibição (ver supabase/functions/website-form-submit/index.ts).
  var WAITLIST_SUCCESS = [
    "🎉 Cadastro realizado!",
    "Você entrou para a lista de espera do Beta Fechado.",
    "Avisaremos por e-mail quando novas vagas forem abertas.",
  ];
  var WAITLIST_DUPLICATE = "Este e-mail já está cadastrado na lista de espera.";
  var WAITLIST_GENERIC_ERROR = [
    "Não foi possível concluir seu cadastro.",
    "Tente novamente em alguns instantes.",
  ];

  function getTurnstileToken(form) {
    var widget = form.querySelector(".cf-turnstile");
    if (!widget || typeof window.turnstile === "undefined") return "";
    try {
      return window.turnstile.getResponse(widget) || "";
    } catch (_err) {
      return "";
    }
  }

  function resetTurnstile(form) {
    var widget = form.querySelector(".cf-turnstile");
    if (!widget || typeof window.turnstile === "undefined") return;
    try {
      window.turnstile.reset(widget);
    } catch (_err) {
      // Turnstile pode não ter carregado (ex.: bloqueado por um
      // bloqueador de anúncios) - a submissão seguinte simplesmente
      // falhará na validação do servidor, sem quebrar a página.
    }
  }

  function setupApiForm(formId, successId, errorId, type, buildPayload) {
    var form = document.getElementById(formId);
    if (!form) return;
    var success = document.getElementById(successId);
    var errorEl = document.getElementById(errorId);
    var submitButton = form.querySelector('button[type="submit"]');
    var idleLabel = submitButton ? submitButton.textContent : "";

    function setLoading(isLoading) {
      if (!submitButton) return;
      submitButton.disabled = isLoading;
      submitButton.textContent = isLoading ? "Enviando..." : idleLabel;
    }

    form.addEventListener("submit", function (event) {
      event.preventDefault();
      hideMessage(success);
      hideMessage(errorEl);

      var data = new FormData(form);
      var payload = Object.assign(
        {
          type: type,
          turnstileToken: getTurnstileToken(form),
          honeypot: data.get("hp_field") || "",
          startedAt: pageLoadedAt,
        },
        buildPayload(data),
      );

      setLoading(true);

      fetch(FUNCTIONS_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      })
        .then(function (response) {
          return response.json().then(function (json) {
            return { status: response.status, body: json };
          });
        })
        .then(function (result) {
          var body = result.body || {};
          if (body.success) {
            showMessage(success, type === "waitlist" ? WAITLIST_SUCCESS : body.message);
            form.reset();
          } else if (type === "waitlist" && result.status === 409) {
            showMessage(success, WAITLIST_DUPLICATE);
            form.reset();
          } else if (type === "waitlist" && result.status !== 400) {
            showMessage(errorEl, WAITLIST_GENERIC_ERROR);
          } else {
            showMessage(errorEl, body.message || "Não foi possível enviar agora. Tente novamente em instantes.");
          }
        })
        .catch(function () {
          showMessage(errorEl, type === "waitlist" ? WAITLIST_GENERIC_ERROR : "Não foi possível enviar agora. Tente novamente em instantes.");
        })
        .finally(function () {
          setLoading(false);
          resetTurnstile(form);
        });
    });
  }

  document.addEventListener("DOMContentLoaded", function () {
    setupNavToggle();
    setupFaqAccordion();

    setupApiForm("beta-form", "beta-success", "beta-error", "waitlist", function (data) {
      return {
        email: data.get("email"),
        name: data.get("name"),
        source: "website",
      };
    });

    setupApiForm("contact-form", "contact-success", "contact-error", "contact", function (data) {
      return {
        email: data.get("email"),
        name: data.get("name"),
        message: data.get("message"),
      };
    });
  });
})();
