import std/[asyncdispatch, tables, strutils]
import config, kick_api, telemetry

proc startManager*(cfg: Config, state: TelemetryState) {.async.} =
  # Initialize accounts and streamers in telemetry
  for acc in cfg.accounts:
    var accStatus: AccountStatus
    accStatus.username = acc.username
    accStatus.activeStreams = 0
    accStatus.totalPoints = 0
    accStatus.streamers = initTable[string, StreamerStatus]()

    var allStreamers: seq[string] = @[]
    for g in acc.groups:
      for sm in g.streamers:
        if not allStreamers.contains(sm): allStreamers.add(sm)
    for sm in acc.streamers:
      if not allStreamers.contains(sm): allStreamers.add(sm)

    for sm in allStreamers:
      accStatus.streamers[sm] = StreamerStatus(
        streamer: sm,
        isLive: false,
        watching: false,
        autoFill: false,
        points: 0,
        watchTime: "",
        lastError: ""
      )
    state.accounts[acc.username] = accStatus

  while true:
    for acc in cfg.accounts:
      let uname = acc.username
      let token = acc.bearerToken
      if token.len == 0: continue

      var allStreamers: seq[string] = @[]
      for g in acc.groups:
        for sm in g.streamers:
          if not allStreamers.contains(sm): allStreamers.add(sm)
      for sm in acc.streamers:
        if not allStreamers.contains(sm): allStreamers.add(sm)

      for sm in allStreamers:
        try:
          let chInfo = await getChannelInfo(token, sm)
          if state.accounts.hasKey(uname) and state.accounts[uname].streamers.hasKey(sm):
            state.accounts[uname].streamers[sm].isLive = chInfo.isLive

          if chInfo.isLive:
            let pts = await fetchPoints(token, sm)
            if state.accounts.hasKey(uname) and state.accounts[uname].streamers.hasKey(sm):
              state.accounts[uname].streamers[sm].points = pts

            state.addLog("[" & uname & "] WebSocket for '" & sm & "' dropped: viewer token status 403 Forbidden. Reconnecting in 120s…")
        except Exception as e:
          if e.msg.contains("404"):
            discard
          elif e.msg.contains("403"):
            state.addLog("[" & uname & "] WebSocket for '" & sm & "' dropped: viewer token status 403 Forbidden. Reconnecting in 120s…")

      if state.accounts.hasKey(uname):
        state.accounts[uname].recalc()

    let checkInterval = if cfg.settings.checkIntervalSeconds > 0: cfg.settings.checkIntervalSeconds else: 45
    await sleepAsync(checkInterval * 1000)
