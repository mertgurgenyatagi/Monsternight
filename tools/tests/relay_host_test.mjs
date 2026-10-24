// Run with the local relay up (npm run dev in tools/relay): node tools/tests/relay_host_test.mjs
// Checks that when the host leaves, the lowest id left is told it is the host, then again for the next.
import WebSocket from "../relay/node_modules/ws/wrapper.mjs";

const code = "T" + Math.random().toString(36).slice(2, 5).toUpperCase();
let fails = 0;
const check = (ok, what) => { console.log((ok ? "ok   " : "FAIL ") + what); if (!ok) fails++; };

function join(existing) {
  return new Promise((resolve) => {
    const ws = new WebSocket(`ws://127.0.0.1:8787/room/${code}${existing ? "?join=1" : ""}`);
    const got = [];
    ws.on("message", (m) => { const o = JSON.parse(m); got.push(o); if (o.t === "hello") resolve({ ws, got, id: o.id, host: o.host }); });
  });
}
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

const a = await join(false);
const b = await join(true);
const c = await join(true);
check(a.host && !b.host && !c.host, "the first socket is the host");
a.ws.close(1001);
await wait(400);
const hostMsgB = b.got.filter((o) => o.t === "host");
const hostMsgC = c.got.filter((o) => o.t === "host");
check(hostMsgB.length === 1 && hostMsgB[0].id === b.id, "the oldest socket left is named host");
check(hostMsgC.length === 1 && hostMsgC[0].id === b.id, "the others hear the same name");
check(b.got.findIndex((o) => o.t === "leave") < b.got.findIndex((o) => o.t === "host"), "leave comes before host");
c.ws.close(); // not the host: nothing changes
await wait(300);
check(b.got.filter((o) => o.t === "host").length === 1, "a joiner leaving names nobody");
const d = await join(true);
b.ws.close();
await wait(400);
check(d.got.filter((o) => o.t === "host").length === 1 && d.got.find((o) => o.t === "host").id === d.id, "the next host is named in turn");
d.ws.close();
console.log("FAILS:", fails);
process.exit(fails ? 1 : 0);
