// BETA-11C - Endpoint único para os dois formulários do site
// institucional (lista de espera do Beta e Contato/Suporte).
//
// Recebe o payload do navegador, valida o token do Cloudflare
// Turnstile no servidor (o secret nunca fica no JS do navegador),
// aplica as proteções anti-spam reportadas pelo cliente (honeypot +
// tempo mínimo de preenchimento) e só então insere na tabela correta
// usando o service_role - o papel `anon` não tem nenhum privilégio em
// `beta_waitlist`/`contact_messages` (ver as migrations
// correspondentes). Uma única função com `type` no payload evita
// duplicar a lógica de CORS/Turnstile/honeypot entre dois endpoints.
//
// `verify_jwt = false` para esta função (supabase/config.toml) - a
// chamada é pública por natureza (site sem login); o Turnstile é a
// camada real de proteção contra abuso, não o gateway de JWT do
// Supabase.
//
// ATENÇÃO: escrita e revisada estaticamente, sem execução real via
// `supabase functions serve` (Docker indisponível neste ambiente -
// ver AR-06/EX-01B). Validar com `supabase functions serve` antes do
// primeiro deploy.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ALLOWED_ORIGINS = new Set([
  "https://www.appborah.com.br",
  "https://appborah.com.br",
  "http://localhost:4173",
]);

const DEFAULT_ORIGIN = "https://www.appborah.com.br";

// Bots automatizados costumam enviar em bem menos de 2s; um visitante
// real precisa desse tempo mínimo para ler e preencher o formulário.
const MIN_FILL_TIME_MS = 2000;

function corsHeaders(origin: string | null): HeadersInit {
  const allowOrigin = origin && ALLOWED_ORIGINS.has(origin) ? origin : DEFAULT_ORIGIN;
  return {
    "Access-Control-Allow-Origin": allowOrigin,
    "Access-Control-Allow-Headers": "content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
  };
}

function jsonResponse(body: unknown, status: number, origin: string | null): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders(origin), "Content-Type": "application/json" },
  });
}

async function verifyTurnstile(token: string, remoteIp: string | null): Promise<boolean> {
  const secret = Deno.env.get("TURNSTILE_SECRET_KEY");
  if (!secret) {
    // Sem secret configurado, a função recusa qualquer envio em vez de
    // aceitar sem verificação (falha fechada, não aberta).
    return false;
  }

  const body = new URLSearchParams({ secret, response: token });
  if (remoteIp) body.set("remoteip", remoteIp);

  const result = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", {
    method: "POST",
    body,
  });
  const data = await result.json();
  return data.success === true;
}

function isEmail(value: unknown): value is string {
  return typeof value === "string" && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

function isNonEmptyString(value: unknown): value is string {
  return typeof value === "string" && value.trim() !== "";
}

Deno.serve(async (req) => {
  const origin = req.headers.get("origin");

  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders(origin) });
  }
  if (req.method !== "POST") {
    return jsonResponse({ ok: false, error: "method_not_allowed" }, 405, origin);
  }

  let payload: Record<string, unknown>;
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ ok: false, error: "invalid_json" }, 400, origin);
  }

  const { type, turnstileToken, honeypot, startedAt } = payload;

  // Honeypot: campo que só um bot preencheria (invisível para humanos).
  if (typeof honeypot === "string" && honeypot.trim() !== "") {
    return jsonResponse({ ok: false, error: "rejected" }, 200, origin);
  }

  // Tempo mínimo de preenchimento.
  if (typeof startedAt === "number" && Date.now() - startedAt < MIN_FILL_TIME_MS) {
    return jsonResponse({ ok: false, error: "rejected" }, 200, origin);
  }

  if (!isNonEmptyString(turnstileToken)) {
    return jsonResponse({ ok: false, error: "captcha_required" }, 400, origin);
  }

  const remoteIp = req.headers.get("x-forwarded-for");
  const captchaOk = await verifyTurnstile(turnstileToken, remoteIp);
  if (!captchaOk) {
    return jsonResponse({ ok: false, error: "captcha_failed" }, 400, origin);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  if (type === "waitlist") {
    const email = payload.email;
    const name = payload.name;
    const source = isNonEmptyString(payload.source) ? payload.source : "website";

    if (!isEmail(email)) {
      return jsonResponse({ ok: false, error: "invalid_email" }, 400, origin);
    }

    const { error } = await supabase.from("beta_waitlist").insert({
      email,
      name: isNonEmptyString(name) ? name : null,
      source,
    });

    if (error) {
      if (error.code === "23505") {
        return jsonResponse({ ok: false, error: "duplicate" }, 200, origin);
      }
      console.error("beta_waitlist insert failed", error);
      return jsonResponse({ ok: false, error: "server_error" }, 500, origin);
    }

    return jsonResponse({ ok: true }, 200, origin);
  }

  if (type === "contact") {
    const { email, name, message, subject } = payload;

    if (!isEmail(email)) {
      return jsonResponse({ ok: false, error: "invalid_email" }, 400, origin);
    }
    if (!isNonEmptyString(name)) {
      return jsonResponse({ ok: false, error: "invalid_name" }, 400, origin);
    }
    if (!isNonEmptyString(message)) {
      return jsonResponse({ ok: false, error: "invalid_message" }, 400, origin);
    }

    const { error } = await supabase.from("contact_messages").insert({
      email,
      name,
      message,
      subject: isNonEmptyString(subject) ? subject : null,
    });

    if (error) {
      console.error("contact_messages insert failed", error);
      return jsonResponse({ ok: false, error: "server_error" }, 500, origin);
    }

    return jsonResponse({ ok: true }, 200, origin);
  }

  return jsonResponse({ ok: false, error: "invalid_type" }, 400, origin);
});
