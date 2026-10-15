const { DatabaseSync } = require("node:sqlite");
const os = require("os");
const db = new DatabaseSync(os.homedir() + "/.cc-switch/cc-switch.db", { readOnly: true });
const rows = db.prepare("select settings_config,website_url from providers").all();
const set = new Set();
for (const r of rows) {
  const s = r.settings_config || "";
  const m = s.match(/https?:\/\/[a-z0-9.-]+/gi) || [];
  for (const u of m) { try { set.add(new URL(u).hostname); } catch (e) {} }
  if (r.website_url) { try { set.add(new URL(r.website_url).hostname); } catch (e) {} }
}
const PROXY_ONLY = /(google|gstatic|youtube|googleapis|openai|oai\.|x\.ai|anthropic|claude\.ai|gemini|grok|mistral|cohere)/i;
const out = [...set].filter(h => /^[a-z0-9.-]+$/i.test(h) && !/^127\./.test(h) && h !== "localhost" && !PROXY_ONLY.test(h));
console.log(JSON.stringify(out));
