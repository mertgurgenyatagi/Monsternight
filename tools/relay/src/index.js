// The relay: /room/<code> upgrades to a WebSocket held by that room's Durable Object.
// Messages are JSON. Client to relay: {to: <peer id>, data: ...}, with to 0 meaning everyone else.
// Relay to client: {t: "hello", id, host, peers: [ids]} on joining (host is true for the first
// socket into an empty room), {t: "join", id}, {t: "leave", id}, and {t: "msg", from, data}. The
// relay never looks inside data. It also closes a socket right after telling it why:
// {t: "full"} for a ninth player, {t: "missing"} for /room/<code>?join=1 when nobody is in the room.
// What a message means is the clients' business; the relay only forwards it.

const MAX_PEERS = 8;

export class Room {
  constructor(ctx) {
    this.ctx = ctx;
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
    const id = ((await this.ctx.storage.get("last")) ?? 0) + 1;
    await this.ctx.storage.put("last", id);
    this.ctx.acceptWebSocket(server);
    server.serializeAttachment({ id });
    const others = this.peers(server);
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

  gone(ws) {
    const id = ws.deserializeAttachment().id;
    if (id === 0) return;
    for (const p of this.peers(ws)) p.ws.send(JSON.stringify({ t: "leave", id }));
  }
}

export default {
  async fetch(request, env) {
    const match = new URL(request.url).pathname.match(/^\/room\/([A-Za-z0-9]{1,16})$/);
    if (!match) return new Response("not found", { status: 404 });
    const stub = env.ROOMS.get(env.ROOMS.idFromName(match[1].toUpperCase()));
    return stub.fetch(request);
  },
};
