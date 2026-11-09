import std/[asyncdispatch, httpclient, json, strutils]
import config, kick_api

const ChallengesUrl = "https://web.kick.com/api/v1/gamification/challenges"

proc runDailyClaims*(cfg: Config) {.async.} =
  if not cfg.settings.dailyClaimEnabled: return

  while true:
    for acc in cfg.accounts:
      if acc.bearerToken.len == 0: continue
      let client = newAsyncHttpClient()
      client.headers = newHttpHeaders({
        "Authorization": "Bearer " & acc.bearerToken,
        "Origin": "https://kick.com",
        "Referer": "https://kick.com/",
        "User-Agent": DefaultUserAgent
      })
      try:
        let resp = await client.get(ChallengesUrl)
        discard await resp.body
        client.close()
      except Exception:
        client.close()

    let interval = if cfg.settings.dailyClaimCheckMinutes > 0: cfg.settings.dailyClaimCheckMinutes else: 60
    await sleepAsync(interval * 60 * 1000)
