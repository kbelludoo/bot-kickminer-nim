import std/[json, strutils, os]

const DefaultConfigExample* = staticRead("config.example.json")

type
  StreamerGroup* = object
    name*: string
    streamers*: seq[string]
    maxConcurrent*: int

  AccountConfig* = object
    username*: string
    bearerToken*: string
    streamers*: seq[string]
    maxConcurrentStreams*: int
    groups*: seq[StreamerGroup]

  SettingsConfig* = object
    checkIntervalSeconds*: int
    pingIntervalSeconds*: int
    trackingIntervalSeconds*: int
    pointsLogIntervalMinutes*: int
    webDashboardPort*: int
    autoFillEnabled*: bool
    autoFillTarget*: int
    dailyClaimEnabled*: bool
    dailyClaimCheckMinutes*: int

  ChatterConfig* = object
    enabled*: bool
    llmApiKey*: string
    llmModel*: string
    llmBaseURL*: string
    minIntervalMinutes*: int
    maxIntervalMinutes*: int
    streamers*: seq[string]

  Config* = object
    accounts*: seq[AccountConfig]
    settings*: SettingsConfig
    chatter*: ChatterConfig

proc defaultSettings*(): SettingsConfig =
  result = SettingsConfig(
    checkIntervalSeconds: 45,
    pingIntervalSeconds: 30,
    trackingIntervalSeconds: 10,
    pointsLogIntervalMinutes: 5,
    webDashboardPort: 3009,
    autoFillEnabled: true,
    autoFillTarget: 12,
    dailyClaimEnabled: false,
    dailyClaimCheckMinutes: 60
  )

proc parseConfig*(content: string): Config =
  let root = parseJson(content)
  result.settings = defaultSettings()

  if root.hasKey("settings"):
    let s = root["settings"]
    result.settings.checkIntervalSeconds = s{"checkIntervalSeconds"}.getInt(45)
    result.settings.pingIntervalSeconds = s{"pingIntervalSeconds"}.getInt(30)
    result.settings.trackingIntervalSeconds = s{"trackingIntervalSeconds"}.getInt(10)
    result.settings.pointsLogIntervalMinutes = s{"pointsLogIntervalMinutes"}.getInt(5)
    result.settings.webDashboardPort = s{"webDashboardPort"}.getInt(3009)
    result.settings.autoFillEnabled = s{"autoFillEnabled"}.getBool(true)
    result.settings.autoFillTarget = s{"autoFillTarget"}.getInt(12)
    result.settings.dailyClaimEnabled = s{"dailyClaimEnabled"}.getBool(false)
    result.settings.dailyClaimCheckMinutes = s{"dailyClaimCheckMinutes"}.getInt(60)

  if root.hasKey("chatter"):
    let ch = root["chatter"]
    result.chatter.enabled = ch{"enabled"}.getBool(false)
    result.chatter.llmApiKey = ch{"llmApiKey"}.getStr()
    result.chatter.llmModel = ch{"llmModel"}.getStr("free/gemini-3.8-flash")
    result.chatter.llmBaseURL = ch{"llmBaseURL"}.getStr("https://apinex.io/v1")
    result.chatter.minIntervalMinutes = ch{"minIntervalMinutes"}.getInt(13)
    result.chatter.maxIntervalMinutes = ch{"maxIntervalMinutes"}.getInt(19)
    result.chatter.streamers = @[]
    if ch.hasKey("streamers"):
      for sm in ch["streamers"]:
        result.chatter.streamers.add(sm.getStr())

  result.accounts = @[]
  if root.hasKey("accounts"):
    for a in root["accounts"]:
      var acc: AccountConfig
      acc.username = a{"username"}.getStr()
      acc.bearerToken = a{"bearerToken"}.getStr()
      acc.maxConcurrentStreams = a{"maxConcurrentStreams"}.getInt(2)
      acc.streamers = @[]
      if a.hasKey("streamers"):
        for sm in a["streamers"]:
          acc.streamers.add(sm.getStr())
      acc.groups = @[]
      if a.hasKey("groups"):
        for g in a["groups"]:
          var grp: StreamerGroup
          grp.name = g{"name"}.getStr("default")
          grp.maxConcurrent = g{"maxConcurrent"}.getInt(2)
          grp.streamers = @[]
          if g.hasKey("streamers"):
            for sm in g["streamers"]:
              grp.streamers.add(sm.getStr())
          acc.groups.add(grp)
      result.accounts.add(acc)
