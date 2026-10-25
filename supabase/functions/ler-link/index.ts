// Prep.pro · ler-link: recebe um link de produto (ou de afiliado) e devolve loja, nome, foto e preço.
// Só o admin pode usar. Só segue links das lojas parceiras (evita virar um "proxy" aberto).
import { createClient } from "npm:@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b: unknown, s = 200) => new Response(JSON.stringify(b), { status: s, headers: { ...CORS, "Content-Type": "application/json" } });

const LOJAS: [RegExp, string][] = [
  [/(^|\.)mercadoli(vre|bre)\.com(\.br)?$|(^|\.)mlstatic\.com$|(^|\.)meli\.la$/, "mercado_livre"],
  [/(^|\.)shopee\.com\.br$|(^|\.)shp\.ee$|(^|\.)shopee\.com$/, "shopee"],
  [/(^|\.)aliexpress\.(com|us)$|(^|\.)aliexpress\.com\.br$|(^|\.)s\.click\.aliexpress\.com$/, "aliexpress"],
  [/(^|\.)amazon\.com(\.br)?$|(^|\.)amzn\.to$|(^|\.)a\.co$/, "amazon"],
];
const lojaDe = (host: string) => (LOJAS.find(([re]) => re.test(host)) || [null, null])[1];

const UA = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1";

function decode(s: string) {
  return s.replace(/&amp;/g, "&").replace(/&quot;/g, '"').replace(/&#39;|&#x27;/g, "'").replace(/&lt;/g, "<").replace(/&gt;/g, ">")
    .replace(/&#(\d+);/g, (_, n) => String.fromCharCode(+n)).replace(/\s+/g, " ").trim();
}
function meta(html: string, keys: string[]) {
  for (const k of keys) {
    const re1 = new RegExp(`<meta[^>]+(?:property|name|itemprop)=["']${k}["'][^>]*content=["']([^"']+)["']`, "i");
    const re2 = new RegExp(`<meta[^>]+content=["']([^"']+)["'][^>]*(?:property|name|itemprop)=["']${k}["']`, "i");
    const m = html.match(re1) || html.match(re2);
    if (m) return decode(m[1]);
  }
  return null;
}
function jsonLd(html: string) {
  const out: any[] = [];
  for (const m of html.matchAll(/<script[^>]+application\/ld\+json[^>]*>([\s\S]*?)<\/script>/gi)) {
    try { const j = JSON.parse(m[1]); (Array.isArray(j) ? j : (j["@graph"] || [j])).forEach((x: any) => out.push(x)); } catch { /* ignora */ }
  }
  return out.find((x) => /product/i.test(String(x["@type"]))) || null;
}
function preco(v: unknown): number | null {
  if (v === null || v === undefined) return null;
  let s = String(v).replace(/[^\d.,]/g, "");
  if (!s) return null;
  if (s.includes(",") && s.lastIndexOf(",") > s.lastIndexOf(".")) s = s.replace(/\./g, "").replace(",", ".");
  else s = s.replace(/,/g, "");
  const n = parseFloat(s);
  return isFinite(n) && n > 0 ? Math.round(n * 100) / 100 : null;
}
export function extrair(html: string) {
  const p = jsonLd(html);
  const offer = p ? (Array.isArray(p.offers) ? p.offers[0] : p.offers) : null;
  const img = p && p.image ? (Array.isArray(p.image) ? p.image[0] : (p.image.url || p.image)) : null;
  let nome = (p && p.name) || meta(html, ["og:title", "twitter:title"]) || (html.match(/<title[^>]*>([^<]+)<\/title>/i) || [])[1] || null;
  if (nome) nome = decode(String(nome)).replace(/\s*[|\-–]\s*(Mercado Livre|MercadoLivre|Shopee Brasil|AliExpress|Amazon\.com\.br).*$/i, "").trim();
  return {
    nome,
    imagem: (typeof img === "string" ? img : null) || meta(html, ["og:image", "og:image:secure_url", "twitter:image"]),
    preco: preco(offer && (offer.price ?? offer.lowPrice)) ?? preco(meta(html, ["product:price:amount", "og:price:amount", "price"])),
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  try {
    const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: req.headers.get("Authorization") || "" } },
    });
    const { data: admin } = await sb.rpc("is_admin");
    if (!admin) return json({ erro: "Só o administrador pode usar." });

    const { url } = await req.json();
    let atual = new URL(String(url || "").trim());
    if (atual.protocol !== "https:" && atual.protocol !== "http:") return json({ erro: "Link inválido." });
    if (!lojaDe(atual.hostname)) return json({ erro: "Por enquanto: Mercado Livre, Shopee, AliExpress e Amazon." });

    let res: Response | null = null;
    for (let i = 0; i < 8; i++) {
      res = await fetch(atual, { redirect: "manual", headers: { "User-Agent": UA, "Accept-Language": "pt-BR,pt;q=0.9" } });
      const loc = res.headers.get("location");
      if (res.status >= 300 && res.status < 400 && loc) {
        const prox = new URL(loc, atual);
        if (!lojaDe(prox.hostname)) return json({ erro: "O link redirecionou para fora da loja." });
        atual = prox; continue;
      }
      break;
    }
    const loja = lojaDe(atual.hostname);
    let dados = { nome: null as string | null, imagem: null as string | null, preco: null as number | null };
    if (res && res.ok) {
      const html = (await res.text()).slice(0, 2_000_000);
      dados = extrair(html);
      // Alguns links de afiliado abrem uma página intermediária que aponta para o produto
      if (!dados.nome || /mercado livre$/i.test(dados.nome)) {
        const alvo = html.match(/https:\/\/(?:produto|www)\.mercadoli(?:vre|bre)\.com\.br\/[^"'\s<>]+MLB-?\d+[^"'\s<>]*/i);
        if (alvo) {
          const r2 = await fetch(alvo[0], { headers: { "User-Agent": UA, "Accept-Language": "pt-BR" } });
          if (r2.ok) dados = extrair((await r2.text()).slice(0, 2_000_000));
        }
      }
    }
    return json({ loja, url_final: atual.toString(), ...dados, ok: !!dados.nome });
  } catch (e) {
    return json({ erro: "Não consegui ler esse link.", detalhe: String(e) }, 200);
  }
});
