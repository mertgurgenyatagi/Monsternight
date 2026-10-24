// Measures the relay's round trip: node tools/tests/relay_latency.mjs [wss://relay.example] [samples]
// Two sockets in a throwaway room; A sends, B echoes, A times it. Prints min / median / p95 in ms.
import WebSocket from "../relay/node_modules/ws/wrapper.mjs";

const base = process.argv[2] ?? "ws://127.0.0.1:8787";
const samples = Number(process.argv[3] ?? 200);
const code = "L" + Math.random().toString(36).slice(2, 5).toUpperCase();
const open = (existing) => new Promise((resolve) => {
  const ws = new WebSocket(`${base}/room/${code}${existing ? "?join=1" : ""}`);
  ws.on("message", (m) => { const o = JSON.parse(m); if (o.t === "hello") resolve({ ws, id: o.id }); });
});
const a = await open(false);
const b = await open(true);
b.ws.on("message", (m) => { const o = JSON.parse(m); if (o.t === "msg" && o.data.k === "ping") b.ws.send(JSON.stringify({ to: a.id, data: { k: "pong", p: o.data.p } })); });
const times = [];
for (let i = 0; i < samples; i++) {
  const t = performance.now();
  await new Promise((resolve) => {
    a.ws.once("message", () => { times.push(performance.now() - t); resolve(); });
    a.ws.send(JSON.stringify({ to: b.id, data: { k: "ping", p: { i } } }));
  });
  await new Promise((r) => setTimeout(r, 10));
}
times.sort((x, y) => x - y);
const at = (q) => times[Math.min(times.length - 1, Math.floor(times.length * q))].toFixed(1);
console.log(`round trip over ${samples} samples: min ${times[0].toFixed(1)} ms, median ${at(0.5)} ms, p95 ${at(0.95)} ms`);
a.ws.close(); b.ws.close();
process.exit(0);
