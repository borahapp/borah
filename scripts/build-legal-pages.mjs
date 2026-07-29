#!/usr/bin/env node
// BETA-11B — Gera site/privacidade/index.html e site/termos/index.html a
// partir de docs/legal/privacy_policy.md e terms_of_use.md, respectivamente.
//
// Por que este script existe: o conteúdo jurídico já foi redigido e
// aprovado (BETA-09B1) em docs/legal/*.md — copiar esse texto manualmente
// para HTML criaria duas fontes de verdade que podem divergir com o tempo.
// Este script converte o Markdown já aprovado para HTML no momento do
// build do site, então o site sempre reflete exatamente o conteúdo de
// docs/legal/ sem nenhuma retranscrição manual.
//
// Conversor minimalista, sem dependência externa (nenhum pacote npm) -
// suficiente para o subconjunto de Markdown realmente usado nesses dois
// arquivos: #, ##, **negrito**, tabelas | col | col |, listas "- item" e
// parágrafos simples. Não é um parser de Markdown genérico.
//
// BETA-11D.2 — todos os links de navegação/assets usam caminhos
// RELATIVOS (nunca absolutos "/…"). Motivo: o GitHub Pages de projeto
// serve o site num subcaminho (https://<org>.github.io/<repo>/) até o
// domínio customizado (site/CNAME) entrar no ar — caminhos absolutos
// como "/assets/…" resolvem contra a raiz real do host, quebrando todo
// asset sob esse subcaminho. Caminhos relativos funcionam
// corretamente nos dois cenários (subcaminho do GitHub Pages e raiz do
// domínio customizado), sem precisar de nenhuma configuração. As duas
// páginas geradas por este script vivem sempre em profundidade 1
// (site/privacidade/, site/termos/), por isso o prefixo é sempre
// "../" — ver as mesmas regras aplicadas manualmente nas páginas
// autorais (site/index.html na profundidade 0, demais na
// profundidade 1).

import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, "..");

function escapeHtml(text) {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

function inline(text) {
  let out = escapeHtml(text);
  out = out.replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>");
  return out;
}

function markdownToHtml(markdown) {
  const lines = markdown.split("\n");
  const html = [];
  let i = 0;
  let sawTitle = false;

  while (i < lines.length) {
    const line = lines[i];

    if (line.trim() === "") {
      i++;
      continue;
    }

    // Título principal (única linha "# ...", tratada como <h1>)
    if (!sawTitle && /^#\s+/.test(line)) {
      html.push(`<h1>${inline(line.replace(/^#\s+/, ""))}</h1>`);
      sawTitle = true;
      i++;
      continue;
    }

    // Linha "*Última atualização: ...*" logo após o título
    if (/^\*(.+)\*$/.test(line.trim())) {
      const content = line.trim().replace(/^\*(.+)\*$/, "$1");
      html.push(`<p class="updated-at"><em>${inline(content)}</em></p>`);
      i++;
      continue;
    }

    // Subtítulo "## ..."
    if (/^##\s+/.test(line)) {
      html.push(`<h2>${inline(line.replace(/^##\s+/, ""))}</h2>`);
      i++;
      continue;
    }

    // Tabela: linha começando com "|"
    if (line.trim().startsWith("|")) {
      const tableLines = [];
      while (i < lines.length && lines[i].trim().startsWith("|")) {
        tableLines.push(lines[i].trim());
        i++;
      }
      const isSeparatorRow = (cells) =>
        cells.every((cell) => /^:?-+:?$/.test(cell.trim()));

      const rows = tableLines
        .map((row) =>
          row
            .replace(/^\|/, "")
            .replace(/\|$/, "")
            .split("|")
            .map((cell) => cell.trim()),
        )
        .filter((cells) => !isSeparatorRow(cells));
      const [headerRow, ...bodyRows] = rows;
      html.push("<table>");
      html.push(
        "<thead><tr>" +
          headerRow.map((cell) => `<th>${inline(cell)}</th>`).join("") +
          "</tr></thead>",
      );
      html.push("<tbody>");
      for (const row of bodyRows) {
        html.push(
          "<tr>" + row.map((cell) => `<td>${inline(cell)}</td>`).join("") + "</tr>",
        );
      }
      html.push("</tbody></table>");
      continue;
    }

    // Lista "- item"
    if (/^-\s+/.test(line.trim())) {
      const items = [];
      while (i < lines.length && /^-\s+/.test(lines[i].trim())) {
        items.push(lines[i].trim().replace(/^-\s+/, ""));
        i++;
      }
      html.push(
        "<ul>" + items.map((item) => `<li>${inline(item)}</li>`).join("") + "</ul>",
      );
      continue;
    }

    // Parágrafo simples (junta linhas até a próxima linha em branco)
    const paragraphLines = [line];
    i++;
    while (i < lines.length && lines[i].trim() !== "" && !/^#{1,2}\s+/.test(lines[i]) && !lines[i].trim().startsWith("|") && !/^-\s+/.test(lines[i].trim())) {
      paragraphLines.push(lines[i]);
      i++;
    }
    html.push(`<p>${inline(paragraphLines.join(" "))}</p>`);
  }

  return html.join("\n");
}

function pageTemplate({ title, description, path, bodyHtml }) {
  const nav = renderNav(path);
  return `<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>${title} — BORAH</title>
<meta name="description" content="${description}" />
<link rel="canonical" href="https://www.appborah.com.br${path}" />
<meta property="og:title" content="${title} — BORAH" />
<meta property="og:description" content="${description}" />
<meta property="og:type" content="website" />
<meta property="og:url" content="https://www.appborah.com.br${path}" />
<meta property="og:image" content="https://www.appborah.com.br/assets/img/og-cover.png" />
<meta name="twitter:card" content="summary_large_image" />
<link rel="icon" href="../assets/img/favicon.png" />
<link rel="apple-touch-icon" href="../assets/img/borah_app_icon_1024.png" />
<link rel="stylesheet" href="../assets/css/style.css" />
</head>
<body>
${nav}
<main>
<section>
  <div class="container legal-content">
${bodyHtml}
  </div>
</section>
</main>
${renderFooter()}
<script src="../assets/js/main.js"></script>
</body>
</html>
`;
}

// currentPath usa a forma lógica ("/", "/sobre/", …) só para decidir o
// aria-current; o href real emitido é sempre relativo (profundidade 1
// - ver comentário no topo do arquivo).
function renderNav(currentPath) {
  const links = [
    ["/", "../", "Início"],
    ["/sobre/", "../sobre/", "Sobre"],
    ["/suporte/", "../suporte/", "Suporte"],
    ["/privacidade/", "../privacidade/", "Privacidade"],
    ["/termos/", "../termos/", "Termos"],
    ["/contato/", "../contato/", "Contato"],
  ];
  const items = links
    .map(
      ([logicalPath, href, label]) =>
        `<li><a href="${href}"${logicalPath === currentPath ? ' aria-current="page"' : ""}>${label}</a></li>`,
    )
    .join("");
  return `<header class="site-header">
  <div class="container">
    <a class="brand" href="../"><img src="../assets/img/borah_symbol.svg" alt="" width="32" height="32" /> BORAH</a>
    <button class="nav-toggle" aria-label="Abrir menu" aria-expanded="false" aria-controls="nav-links">
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18M3 12h18M3 18h18"/></svg>
    </button>
    <ul class="nav-links" id="nav-links">${items}</ul>
  </div>
</header>`;
}

function renderFooter() {
  return `<footer class="site-footer">
  <div class="container">
    <div class="footer-grid">
      <div>
        <a class="brand" href="../" style="color:#fff"><img src="../assets/img/borah_symbol.svg" alt="" width="28" height="28" /> BORAH</a>
        <p style="margin-top:12px;max-width:32ch">Todo grupo tem seus rolês. Agora eles têm um ranking.</p>
      </div>
      <div>
        <h4>Produto</h4>
        <ul><li><a href="../">Início</a></li><li><a href="../sobre/">Sobre</a></li></ul>
      </div>
      <div>
        <h4>Legal</h4>
        <ul><li><a href="../privacidade/">Política de Privacidade</a></li><li><a href="../termos/">Termos de Uso</a></li></ul>
      </div>
      <div>
        <h4>Contato</h4>
        <ul><li><a href="../suporte/">Suporte</a></li><li><a href="../contato/">Fale conosco</a></li><li><a href="mailto:Borahh.app@gmail.com">Borahh.app@gmail.com</a></li></ul>
      </div>
    </div>
    <div class="footer-bottom">
      <span>&copy; 2026 BORAH. Todos os direitos reservados.</span>
      <span>Feito com rolês em mente.</span>
    </div>
  </div>
</footer>`;
}

function build(sourceRelPath, outputRelPath, meta) {
  const source = readFileSync(join(ROOT, sourceRelPath), "utf-8");
  const bodyHtml = markdownToHtml(source);
  const html = pageTemplate({ ...meta, bodyHtml });
  const outPath = join(ROOT, outputRelPath);
  mkdirSync(dirname(outPath), { recursive: true });
  writeFileSync(outPath, html, "utf-8");
  console.log(`Gerado: ${outputRelPath} (a partir de ${sourceRelPath})`);
}

build("docs/legal/privacy_policy.md", "site/privacidade/index.html", {
  title: "Política de Privacidade",
  description: "Política de Privacidade oficial do BORAH — quais dados coletamos, por quê, e seus direitos como titular.",
  path: "/privacidade/",
});

build("docs/legal/terms_of_use.md", "site/termos/index.html", {
  title: "Termos de Uso",
  description: "Termos de Uso oficiais do BORAH.",
  path: "/termos/",
});

console.log("Build das páginas jurídicas concluído.");
