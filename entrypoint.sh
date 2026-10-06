#!/bin/bash

# 1. 启动 zcode2api
python main.py serve &
APP_PID=$!

# 2. 等待应用就绪（镜像里 curl 已被 purge，用 Python 探测）
echo "[entrypoint] waiting for zcode2api on :3000 ..."
for i in $(seq 1 30); do
    python -c "import urllib.request as u; u.urlopen('http://127.0.0.1:3000/v1/models', timeout=2)" 2>/dev/null && break
    sleep 1
done
echo "[entrypoint] zcode2api is up"

# 3. 启动隧道（token 来自环境变量，绝不写进镜像）
if [ -n "$CF_TUNNEL_TOKEN" ]; then
    echo "[entrypoint] starting cloudflared tunnel ..."
    cloudflared tunnel run --token "$CF_TUNNEL_TOKEN" &
else
    echo "[entrypoint] WARN: CF_TUNNEL_TOKEN not set, tunnel disabled" >&2
fi

# 4. 挂在主进程上
wait $APP_PID
