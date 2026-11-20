# Field Notes for a Living Planet

A small edge web service and status page for a wildlife-tracking field journal.
Serves the static site, exposes `/healthz` and `/version`, and keeps a lightweight
reporting agent running for uptime metrics.

## Run

```
npm install   # fetches the core binaries into ./bin
npm start      # serves on $PORT (default 8080)
```
