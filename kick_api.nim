import std/[asyncdispatch, httpclient, json, strutils]

const
  DefaultUserAgent* = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

type
  ChannelInfo* = object
    slug*: string
    channelId*: int64
    userId*: int64
    streamId*: int64
    isLive*: bool

proc getChannelInfo*(token: string, streamer: string): Future[ChannelInfo] {.async.} =
  let url = "https://kick.com/api/v2/channels/" & streamer
  let client = newAsyncHttpClient()
  client.headers = newHttpHeaders({
    "Authorization": "Bearer " & token,
    "Origin": "https://kick.com",
    "Referer": "https://kick.com/" & streamer & "/",
    "Accept": "application/json, text/plain, */*",
    "User-Agent": DefaultUserAgent,
    "Cookie": "session_token=" & token
  })

  try:
    let resp = await client.get(url)
    let body = await resp.body
    client.close()

    if not resp.status.startsWith("2"):
      raise newException(IOError, "channel info status " & resp.status)

    let parsed = parseJson(body)
    var info: ChannelInfo
    info.slug = streamer
    info.channelId = parsed{"id"}.getBiggestInt(0)
    info.userId = parsed{"user_id"}.getBiggestInt(0)

    let livestream = parsed{"livestream"}
    if livestream != nil and livestream.kind == JObject and not livestream.hasKey("null"):
      info.isLive = true
      info.streamId = livestream{"id"}.getBiggestInt(0)
    else:
      info.isLive = false
      info.streamId = 0

    result = info
  except Exception as e:
    client.close()
    raise e

proc fetchPoints*(token: string, streamer: string): Future[int64] {.async.} =
  let url = "https://kick.com/api/v2/channels/" & streamer & "/points"
  let client = newAsyncHttpClient()
  client.headers = newHttpHeaders({
    "Authorization": "Bearer " & token,
    "Origin": "https://kick.com",
    "Referer": "https://kick.com/" & streamer & "/",
    "Accept": "application/json, text/plain, */*",
    "User-Agent": DefaultUserAgent
  })

  try:
    let resp = await client.get(url)
    let body = await resp.body
    client.close()

    if not resp.status.startsWith("2"):
      return 0

    let parsed = parseJson(body)
    if parsed.hasKey("data") and parsed["data"].hasKey("points"):
      return parsed["data"]["points"].getBiggestInt(0)
    result = 0
  except Exception:
    client.close()
    result = 0

proc resolveChatroomId*(token: string, streamer: string): Future[int64] {.async.} =
  let info = await getChannelInfo(token, streamer)
  result = info.channelId

proc sendChatMessage*(token: string, chatroomId: int64, content: string, streamer: string): Future[bool] {.async.} =
  let url = "https://kick.com/api/v2/messages/send/" & $chatroomId
  let client = newAsyncHttpClient()
  client.headers = newHttpHeaders({
    "Authorization": "Bearer " & token,
    "Content-Type": "application/json",
    "Origin": "https://kick.com",
    "Referer": "https://kick.com/" & streamer,
    "User-Agent": DefaultUserAgent
  })

  let payload = %*{"content": content, "type": "message"}
  try:
    let resp = await client.post(url, body = $payload)
    client.close()
    result = resp.status.startsWith("2")
  except Exception:
    client.close()
    result = false
