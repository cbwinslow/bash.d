const corsHeaders = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET,POST,OPTIONS",
  "access-control-allow-headers": "authorization,content-type",
};

const FREE_MODELS = [
  "meta-llama/llama-3.2-3b-instruct:free",
  "google/gemma-2-9b-it:free",
  "mistralai/mistral-7b-instruct:free",
  "google/gemini-2.0-flash-lite-preview-02-05:free",
];
const DEFAULT_MODEL = FREE_MODELS[0];
const modelList = FREE_MODELS.map((id) => ({
  id,
  object: "model",
  owned_by: "openrouter",
}));

function jsonResponse(data, init = {}) {
  const headers = new Headers(init.headers || {});
  headers.set("content-type", "application/json");
  for (const [key, value] of Object.entries(corsHeaders)) headers.set(key, value);
  return new Response(JSON.stringify(data, null, 2), {
    ...init,
    headers,
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    if (url.pathname === "/v1/models") {
      return jsonResponse({ object: "list", data: modelList });
    }

    if (!url.pathname.startsWith("/v1/")) {
      return new Response("Not found", { status: 404, headers: corsHeaders });
    }

    if (!env.OPENROUTER_API_KEY) {
      return new Response("Missing OPENROUTER_API_KEY", {
        status: 500,
        headers: corsHeaders,
      });
    }

    const upstreamPath = url.pathname.replace("/v1", "/api/v1");
    const upstreamUrl = `https://openrouter.ai${upstreamPath}${url.search}`;

    const headers = new Headers(request.headers);
    headers.set("authorization", `Bearer ${env.OPENROUTER_API_KEY}`);
    headers.set("http-referer", "https://github.com/cbwinslow/bash.d");
    headers.set("x-title", "bash.d openai-compat mirror");
    if (!headers.has("content-type")) {
      headers.set("content-type", "application/json");
    }

    let body =
      request.method === "GET" || request.method === "HEAD"
        ? null
        : await request.text();

    if (body) {
      const contentType = headers.get("content-type") || "";
      if (contentType.includes("application/json")) {
        try {
          const parsed = JSON.parse(body);
          if (parsed && typeof parsed === "object") {
            const model = parsed.model;
            if (!model || !FREE_MODELS.includes(model)) {
              parsed.model = DEFAULT_MODEL;
            }
            body = JSON.stringify(parsed);
          }
        } catch (error) {
          // Non-JSON body; pass through untouched.
        }
      }
    }

    const upstreamResponse = await fetch(upstreamUrl, {
      method: request.method,
      headers,
      body,
    });

    const responseHeaders = new Headers(upstreamResponse.headers);
    for (const [key, value] of Object.entries(corsHeaders)) {
      responseHeaders.set(key, value);
    }

    return new Response(upstreamResponse.body, {
      status: upstreamResponse.status,
      headers: responseHeaders,
    });
  },
};
