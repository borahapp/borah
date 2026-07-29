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

  function showMessage(el, text) {
    if (!el) return;
    el.textContent = text;
    el.classList.add("visible");
  }

  function hideMessage(el) {
    if (!el) return;
    el.classList.remove("visible");
  }

  function errorMessageFor(code) {
    switch (code) {
      case "duplicate":
        return "Você já está na lista de espera do Beta!";
      case "invalid_email":
        return "Verifique se o e-mail digitado está correto.";
      case "invalid_name":
        return "Por favor, preencha seu nome.";
      case "invalid_message":
        return "Por favor, escreva sua mensagem.";
      case "captcha_required":
      case "captcha_failed":
        return "Não foi possível confirmar que você não é um robô. Tente novamente.";
      default:
        return "Não foi possível enviar agora. Tente novamente em instantes.";
    }
  }

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

      if (submitButton) submitButton.disabled = true;

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
          if (result.body && result.body.ok) {
            showMessage(success, successMessageFor(type));
            form.reset();
          } else if (result.body && result.body.error === "duplicate") {
            showMessage(success, errorMessageFor("duplicate"));
            form.reset();
          } else {
            showMessage(errorEl, errorMessageFor(result.body && result.body.error));
          }
        })
        .catch(function () {
          showMessage(errorEl, errorMessageFor());
        })
        .finally(function () {
          if (submitButton) submitButton.disabled = false;
          resetTurnstile(form);
        });
    });
  }

  function successMessageFor(type) {
    return type === "waitlist"
      ? "Você entrou na lista de espera do Beta! Avisaremos por e-mail assim que as vagas abrirem."
      : "Mensagem enviada! Responderemos o quanto antes pelo e-mail informado.";
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
