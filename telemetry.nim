import std/[tables, times, strutils, os]

type
  StreamerStatus* = object
    streamer*: string
    isLive*: bool
    watching*: bool
    autoFill*: bool
    points*: int64
    watchTime*: string
    lastError*: string

  AccountStatus* = object
    username*: string
    activeStreams*: int
    totalPoints*: int64
    streamers*: Table[string, StreamerStatus]

  GlobalTelemetry* = object
    uptime*: string
    ramMb*: float
    goroutines*: int
    totalStreams*: int
    accounts*: Table[string, AccountStatus]
    logs*: seq[string]

  TelemetryState* = ref object
    startTime*: Time
    accounts*: Table[string, AccountStatus]
    logs*: seq[string]

proc newTelemetryState*(): TelemetryState =
  new(result)
  result.startTime = getTime()
  result.accounts = initTable[string, AccountStatus]()
  result.logs = @[]

var gState* = newTelemetryState()

proc formatUptime*(sec: int64): string =
  let h = sec div 3600
  let m = (sec mod 3600) div 60
  let s = sec mod 60
  result = align($h, 2, '0') & ":" & align($m, 2, '0') & ":" & align($s, 2, '0')

proc getRamMb*(): float =
  result = 9.0
  when defined(posix):
    try:
      if fileExists("/proc/self/statm"):
        let content = readFile("/proc/self/statm").strip()
        let parts = content.splitWhitespace()
        if parts.len >= 2:
          let residentPages = parseBiggestInt(parts[1])
          result = (residentPages.float * 4096.0) / (1024.0 * 1024.0)
    except CatchableError:
      discard

proc addLog*(self: TelemetryState, msg: string) =
  let ts = now().format("HH:mm:ss")
  let formatted = "[" & ts & "] " & msg
  self.logs.add(formatted)
  if self.logs.len > 150:
    self.logs = self.logs[^150..^1]

proc recalc*(acc: var AccountStatus) =
  var active = 0
  var total: int64 = 0
  for s in acc.streamers.values():
    if s.watching:
      active += 1
    total += s.points
  acc.activeStreams = active
  acc.totalPoints = total

proc buildTelemetry*(self: TelemetryState): GlobalTelemetry =
  let uptimeSec = (getTime() - self.startTime).inSeconds
  result.uptime = formatUptime(uptimeSec)
  result.ramMb = getRamMb()
  result.goroutines = 2
  result.logs = self.logs
  result.accounts = initTable[string, AccountStatus]()

  var totalStreams = 0
  for uname, acc in self.accounts.pairs():
    var a = acc
    a.recalc()
    totalStreams += a.activeStreams
    result.accounts[uname] = a

  result.totalStreams = totalStreams
