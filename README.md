# ⚡ Kick Miner — Native Nim Engine (ARC/ORC)

Autonomous channel points miner and stream watcher for **Kick.com** rewritten in native **Nim 2.2** with zero-overhead memory management (`--mm:orc`), asynchronous streaming telemetry, and complete parity with Go and Rust implementations.

---

## 🚀 Características & Paridade 100%

- **Auto-Farm de Channel Points**: Monitoramento assíncrono de canais ao vivo, contagem de watch time e pontos via API Kick v2.
- **Humanized LLM Chatter**: Suporte a interação orgânica em chatrooms com intervalos configuráveis e mensagens geradas por IA.
- **Gamification Daily Claims**: Resgate periódico de missões e desafios diários no Kick.
- **Dashboard Web & Prometheus Metrics (Porta 3009)**: Telemetria em tempo real em `/api/status`, métricas Prometheus em `/metrics`, e interface HTML em `/`.
- **Baixo Consumo de Recursos**: < 10 MB de RAM utilizando o modelo determinístico ARC/ORC do Nim.

---

## 🛠️ Compilação Cruzada (Cross-Compilation via Zig)

```bash
nim c --os:linux --cpu:amd64 --gcc.exe:zigcc-linux-gnu.bat --gcc.linkerexe:zigcc-linux-gnu.bat -d:ssl -d:release -o:kick-miner-linux-nim main.nim
```

---

## ⚙️ Configuração

Copie o arquivo `config.example.json` para `config.json` e configure seu bearer token e streamers:

```bash
cp config.example.json config.json
```
