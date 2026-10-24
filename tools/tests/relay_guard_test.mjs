// Run against a relay started with a short idle time: npx wrangler dev --port 8787 --var IDLE_SECONDS:3
// (in tools/relay), then: node tools/tests/relay_guard_test.mjs
// Checks the idle wipe (an emptied room forgets its ids after IDLE_SECONDS) and the rate limit on new rooms.
import WebSocket from "../relay/node_modules/ws/wrapper.mjs";

let fails = 0;
const check = (ok, what) => { console.log((ok ? "ok   " : "FAIL ") + what); if (!ok) fails++; };
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

// Opens a socket; resolves with its hello, or {refused: status} when the upgrade fails.
function open(code, existing) {
  return new Promise((resolve) => {
    const ws = new WebSocket(`ws://127.0.0.1:8787/room/${code}${existing ? "?join=1" : ""}`);
    ws.on("message", (m) => { const o = JSON.parse(m); if (o.t === "hello") resolve({ ws, id: o.id }); });
    ws.on("unexpected-response", (_req, res) => resolve({ refused: res.statusCode }));
    ws.on("error", () => {});
  });
}

const code = "G" + Math.random().toString(36).slice(2, 5).toUpperCase();
const a = await open(code, false);
const b = await open(code, true);
check(a.id === 1 && b.id === 2, "ids count up in a live room");
a.ws.close(); b.ws.close();
await wait(1000);
const early = await open(code, false);
check(early.refused === undefined && early.id === 3, "a room empty for 1 s still remembers its ids");
early.ws.close();
await wait(5500);
const fresh = await open(code, false);
check(fresh.id === 1, "after IDLE_SECONDS empty the room starts again from id 1");
fresh.ws.close();

// The rate limit: 10 new rooms a minute from one address, then 429 (only creating counts; joining is not limited).
let refused = 0, made = 0;
for (let i = 0; i < 14; i++) {
  const r = await open("R" + i + Math.random().toString(36).slice(2, 4).toUpperCase(), false);
  if (r.refused === 429) refused++; else { made++; r.ws.close(); }
}
check(made >= 1 && made <= 10 && refused >= 4, `new rooms are limited (${made} made, ${refused} refused with 429)`);
console.log("FAILS:", fails);
process.exit(fails ? 1 : 0);
