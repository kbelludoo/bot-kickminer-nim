import std/[asyncdispatch, asynchttpserver, json, strutils, tables]
import telemetry

const DashboardHtml = staticRead("docs/index.html")

type
  WebServer* = ref object
    port*: int
    state*: TelemetryState
    server*: AsyncHttpServer

proc newWebServer*(port: int, state: TelemetryState): WebServer =
  new(result)
  result.port = port
  result.state = state
  result.server = newAsyncHttpServer()

proc handleRequest(self: WebServer, req: Request) {.async, gcsafe.} =
  var headers = newHttpHeaders({
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type"
  })

  if req.reqMethod == HttpOptions:
    await req.respond(Http200, "{}", headers)
    return

  let path = req.url.path

  if req.reqMethod == HttpGet and path == "/api/status":
    headers["Content-Type"] = "application/json"
    let tel = self.state.buildTelemetry()

    var accountsNode = newJObject()
    for uname, acc in tel.accounts.pairs():
      var streamersNode = newJObject()
      for sm, st in acc.streamers.pairs():
        streamersNode[sm] = %*{
          "streamer": st.streamer,
          "is_live": st.isLive,
          "watching": st.watching,
          "auto_fill": st.autoFill,
          "points": st.points,
          "watch_time": st.watchTime
        }
      accountsNode[uname] = %*{
        "username": acc.username,
        "active_streams": acc.activeStreams,
        "total_points": acc.totalPoints,
        "streamers": streamersNode
      }

    var logsArr = newJArray()
    for l in tel.logs:
      logsArr.add(newJString(l))

    let respNode = %*{
      "uptime": tel.uptime,
      "ram_mb": tel.ramMb,
      "goroutines": tel.goroutines,
      "total_streams": tel.totalStreams,
      "accounts": accountsNode,
      "logs": logsArr
    }
    await req.respond(Http200, $respNode, headers)
    return

  if req.reqMethod == HttpGet and path == "/metrics":
    headers["Content-Type"] = "text/plain; charset=utf-8"
    let tel = self.state.buildTelemetry()
    var outText = ""
    outText.add("kick_ram_mb " & $tel.ramMb & "\n")
    outText.add("kick_total_streams " & $tel.totalStreams & "\n")
    outText.add("kick_threads " & $tel.goroutines & "\n")
    for uname, acc in tel.accounts.pairs():
      outText.add("kick_account_points{account=\"" & uname & "\"} " & $acc.totalPoints & "\n")
      outText.add("kick_account_streams{account=\"" & uname & "\"} " & $acc.activeStreams & "\n")
    await req.respond(Http200, outText, headers)
    return

  if req.reqMethod == HttpGet and (path == "/" or path == "/index.html"):
    headers["Content-Type"] = "text/html; charset=utf-8"
    await req.respond(Http200, DashboardHtml, headers)
    return

  await req.respond(Http404, "Not Found", headers)

proc start*(self: WebServer) {.async.} =
  echo "🌐 Dashboard Kick Miner online em http://0.0.0.0:", self.port
  let server = self.server
  let sSelf = self
  await server.serve(Port(self.port), proc(req: Request): Future[void] {.gcsafe.} =
    sSelf.handleRequest(req)
  )
