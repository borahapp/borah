// BETA-11B — Interações do site institucional do BORAH.
// Sem dependências externas: toggle do menu mobile, acordeão de FAQ e
// envio dos formulários de Beta/Contato via mailto (nenhum dado é
// armazenado ou enviado a um backend neste site).

(function () {
  "use strict";

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

  function buildMailtoUrl(to, subject, bodyLines) {
    var params = new URLSearchParams({
      subject: subject,
      body: bodyLines.join("\n"),
    });
    return "mailto:" + to + "?" + params.toString().replace(/\+/g, "%20");
  }

  function setupMailtoForm(formId, successId, subject, buildBody) {
    var form = document.getElementById(formId);
    if (!form) return;
    var success = document.getElementById(successId);
    form.addEventListener("submit", function (event) {
      event.preventDefault();
      var data = new FormData(form);
      var url = buildMailtoUrl("Borahh.app@gmail.com", subject, buildBody(data));
      window.location.href = url;
      if (success) success.classList.add("visible");
    });
  }

  document.addEventListener("DOMContentLoaded", function () {
    setupNavToggle();
    setupFaqAccordion();

    setupMailtoForm("beta-form", "beta-success", "Quero participar do Beta - BORAH", function (data) {
      return [
        "Nome: " + data.get("name"),
        "E-mail: " + data.get("email"),
        "",
        "Quero participar do Beta Fechado do BORAH.",
      ];
    });

    setupMailtoForm("contact-form", "contact-success", "Contato pelo site - BORAH", function (data) {
      return [
        "Nome: " + data.get("name"),
        "E-mail: " + data.get("email"),
        "",
        String(data.get("message") || ""),
      ];
    });
  });
})();
