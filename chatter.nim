import std/[asyncdispatch, random]
import config, kick_api

proc runChatter*(token: string, username: string, streamer: string, cfg: ChatterConfig) {.async.} =
  if not cfg.enabled: return

  var chatroomId: int64 = 0
  try:
    chatroomId = await resolveChatroomId(token, streamer)
  except Exception as e:
    echo "[Chatter/", streamer, "] falha ao resolver chatroom: ", e.msg
    return

  echo "[Chatter/", streamer, "] chatroom ", chatroomId, " — iniciando chatter humanizado"

  while true:
    let minWait = max(1, cfg.minIntervalMinutes)
    let maxWait = max(minWait + 1, cfg.maxIntervalMinutes)
    let waitMins = minWait + rand(maxWait - minWait)
    await sleepAsync(waitMins * 60 * 1000)

    let msg = "🎮 Bots 24/7 farmando pontos! kbelludoo.github.io/bot-template-rust/"
    discard await sendChatMessage(token, chatroomId, msg, streamer)
