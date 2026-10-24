// The relay: /room/<code> upgrades to a WebSocket held by that room's Durable Object.
// Messages are JSON. Client to relay: {to: <peer id>, data: ...}, with to 0 meaning everyone else.
// Relay to client: {t: "hello", id, peers: [ids]} on joining, {t: "join", id}, {t: "leave", id},
// and {t: "msg", from, data}. The relay never looks inside data.

export class Room {
  constructor(ctx) {
    this.ctx = ctx;
  }

  async fetch(request) {
    if (request.headers.get("Upgrade") !== "websocket") {
      return new Response("expected a WebSocket", { status: 426 });
    }
    const id = ((await this.ctx.storage.get("last")) ?? 0) + 1;
    await this.ctx.storage.put("last", id);
    const pair = new WebSocketPair();
    const server = pair[1];
    this.ctx.acceptWebSocket(server);
    server.serializeAttachment({ id });
    const others = this.peers(server);
    server.send(JSON.stringify({ t: "hello", id, peers: others.map((p) => p.id) }));
    for (const p of others) p.ws.send(JSON.stringify({ t: "join", id }));
    return new Response(null, { status: 101, webSocket: pair[0] });
  }

  peers(except) {
    return this.ctx
      .getWebSockets()
      .filter((ws) => ws !== except)
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
