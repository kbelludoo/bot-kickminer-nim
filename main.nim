import std/[asyncdispatch, os, strutils, tables]
import config, telemetry, manager, chatter, daily, server

proc tickerLoop(state: TelemetryState) {.async.} =
  while true:
    await sleepAsync(5000)
    let tel = state.buildTelemetry()
    var totalPts: int64 = 0
    var watchingList: seq[string] = @[]

    for _, acc in tel.accounts.pairs():
      totalPts += acc.totalPoints
      for sm, st in acc.streamers.pairs():
        if st.watching: watchingList.add(sm)

    let watchStr = if watchingList.len > 0: watchingList.join(", ") else: "Nenhum canal ao vivo"
    echo "[Ticker] RAM: ", formatFloat(tel.ramMb, ffDecimal, 2), " MB | Uptime: ", tel.uptime, " | Streams: ", tel.totalStreams, " | Pontos: ", totalPts, " | Assistindo: [", watchStr, "]"

proc main() {.async.} =
  echo "================================================================================"
  echo "       ⚡ KICK MINER NATIVE NIM BOT (ARC/ORC ZERO-GC & ALTA PERFORMANCE) ⚡"
  echo "================================================================================"

  let configPath = "config.json"
  var content = ""
  if fileExists(configPath):
    content = readFile(configPath)
  else:
    echo "⚠️ Arquivo config.json não encontrado. Criando template padrão..."
    writeFile(configPath, DefaultConfigExample)
    content = DefaultConfigExample

  let cfg = parseConfig(content)
  let state = newTelemetryState()

  # Iniciar Chatter se habilitado
  for acc in cfg.accounts:
    if cfg.chatter.enabled:
      for sm in cfg.chatter.streamers:
        asyncCheck runChatter(acc.bearerToken, acc.username, sm, cfg.chatter)

  # Iniciar Daily Claims se habilitado
  asyncCheck runDailyClaims(cfg)

  # Iniciar Manager de Streams
  asyncCheck startManager(cfg, state)

  # Iniciar Servidor Web / Dashboard
  let port = if cfg.settings.webDashboardPort > 0: cfg.settings.webDashboardPort else: 3009
  let webServer = newWebServer(port, state)
  asyncCheck webServer.start()

  # Iniciar Console Ticker
  asyncCheck tickerLoop(state)

  echo "Bot operacional na porta ", port, ". Pressione Ctrl+C para encerrar."
  runForever()

waitFor main()
