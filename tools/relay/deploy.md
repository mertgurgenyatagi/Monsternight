# Deploying the relay

Wrangler was not logged in when part 42 was built, so the relay is not deployed yet and `Net.PRODUCTION_RELAY` is empty (builds use `ws://127.0.0.1:8787`).

1. In `tools/relay/`: `npx wrangler login`, then `npm run deploy`. It prints `https://monsternight-relay.<account>.workers.dev`.
2. Put `wss://monsternight-relay.<account>.workers.dev` in `Net.PRODUCTION_RELAY` (`src/net/net.gd`). Rebuild the web zip.
3. Put the itch.io page address in `Net.PAGE_URL`, so Copy link gives `https://<user>.itch.io/<game>?room=CODE` instead of the iframe's own address.
4. Measure: `node tools/tests/relay_latency.mjs wss://monsternight-relay.<account>.workers.dev`.

Guards: an empty room wipes its storage after `IDLE_SECONDS` (600, in `wrangler.toml`), and one address may create 10 rooms a minute (best effort, per isolate). Tests: `relay_host_test.mjs`, `relay_guard_test.mjs` (start the relay with `--var IDLE_SECONDS:3`), `relay_latency.mjs`.
