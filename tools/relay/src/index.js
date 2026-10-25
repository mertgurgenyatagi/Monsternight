// The relay: /room/<code> upgrades to a WebSocket held by that room's Durable Object.
// Messages are JSON. Client to relay: {to: <peer id>, data: ...}, with to 0 meaning everyone else.
// Relay to client: {t: "hello", id, host, peers: [ids]} on joining (host is true for the first
// socket into an empty room), {t: "join", id}, {t: "leave", id}, and {t: "msg", from, data}. The
// relay never looks inside data. When the host leaves, the lowest id left gets the room and everyone is
// told {t: "host", id} right after the {t: "leave"}. It also closes a socket right after telling it why:
// {t: "full"} for a ninth player, {t: "missing"} for /room/<code>?join=1 when nobody is in the room.
// What a message means is the clients' business; the relay only forwards it.
//
// Two guards keep it inside Cloudflare's free plan: a room that has been empty for IDLE_SECONDS
// (default 600, `vars` in wrangler.toml) wipes its storage, and one address can only make
// CREATES_PER_MINUTE new rooms a minute (best effort: the count lives in the Worker's isolate).

const MAX_PEERS = 8;
const DEFAULT_IDLE_SECONDS = 600;
const CREATES_PER_MINUTE = 10;
const creates = new Map(); // address -> start times of the rooms it made in the last minute

// True when `address` may make another room now.
function mayCreate(address, now) {
  const recent = (creates.get(address) ?? []).filter((t) => now - t < 60000);
  if (recent.length >= CREATES_PER_MINUTE) {
    creates.set(address, recent);
    return false;
  }
  recent.push(now);
  creates.set(address, recent);
  if (creates.size > 5000) for (const [k, v] of creates) if (v.every((t) => now - t >= 60000)) creates.delete(k);
  return true;
}

export class Room {
  constructor(ctx, env) {
    this.ctx = ctx;
    this.idleMs = 1000 * (Number(env?.IDLE_SECONDS) || DEFAULT_IDLE_SECONDS);
  }

  async fetch(request) {
    if (request.headers.get("Upgrade") !== "websocket") {
      return new Response("expected a WebSocket", { status: 426 });
    }
    const pair = new WebSocketPair();
    const server = pair[1];
    const present = this.peers(null).length;
    const wantsExisting = new URL(request.url).searchParams.has("join");
    const refusal = present >= MAX_PEERS ? "full" : present === 0 && wantsExisting ? "missing" : null;
    if (refusal) {
      this.ctx.acceptWebSocket(server);
      server.serializeAttachment({ id: 0 });
      server.send(JSON.stringify({ t: refusal }));
      server.close(1000, refusal);
      return new Response(null, { status: 101, webSocket: pair[0] });
    }
    await this.ctx.storage.deleteAlarm();
    const id = ((await this.ctx.storage.get("last")) ?? 0) + 1;
    await this.ctx.storage.put("last", id);
    this.ctx.acceptWebSocket(server);
    server.serializeAttachment({ id });
    const others = this.peers(server);
    if (others.length === 0) await this.ctx.storage.put("host", id);
    server.send(JSON.stringify({ t: "hello", id, host: others.length === 0, peers: others.map((p) => p.id) }));
    for (const p of others) p.ws.send(JSON.stringify({ t: "join", id }));
    return new Response(null, { status: 101, webSocket: pair[0] });
  }

  peers(except) {
    return this.ctx
      .getWebSockets()
      .filter((ws) => ws !== except && ws.deserializeAttachment().id > 0)
      .map((ws) => ({ ws, id: ws.deserializeAttachment().id }));
  }

  webSocketMessage(ws, message) {
    let msg;
    try {
      msg = JSON.parse(message);
    } catch {
      return;
    }
    const from = ws.deserializeAttachment().id;
    const out = JSON.stringify({ t: "msg", from, data: msg.data });
    for (const p of this.peers(ws)) {
      if (!msg.to || msg.to === p.id) p.ws.send(out);
    }
  }

  webSocketClose(ws) {
    this.gone(ws);
  }

  webSocketError(ws) {
    this.gone(ws);
  }

  async gone(ws) {
    const id = ws.deserializeAttachment().id;
    if (id === 0) return;
    const rest = this.peers(ws);
    if (rest.length === 0) await this.ctx.storage.setAlarm(Date.now() + this.idleMs);
    for (const p of rest) p.ws.send(JSON.stringify({ t: "leave", id }));
    // The host left: the longest-connected socket left (the lowest id, since ids only grow) holds the room now.
    if (rest.length > 0 && (await this.ctx.storage.get("host")) === id) {
      const next = Math.min(...rest.map((p) => p.id));
      await this.ctx.storage.put("host", next);
      for (const p of rest) p.ws.send(JSON.stringify({ t: "host", id: next }));
    }
  }

  // Nobody came back: forget the room, so its storage is freed and its ids start again.
  async alarm() {
    if (this.peers(null).length === 0) await this.ctx.storage.deleteAll();
  }
}

export default {
  async fetch(request, env) {
    const match = new URL(request.url).pathname.match(/^\/room\/([A-Za-z0-9]{1,16})$/);
    if (!match) return new Response("not found", { status: 404 });
    const joining = new URL(request.url).searchParams.has("join");
    const address = request.headers.get("CF-Connecting-IP") ?? "local";
    if (!joining && request.headers.get("Upgrade") === "websocket" && !mayCreate(address, Date.now())) {
      return new Response("too many rooms", { status: 429 });
    }
    const stub = env.ROOMS.get(env.ROOMS.idFromName(match[1].toUpperCase()));
    return stub.fetch(request);
  },
};
