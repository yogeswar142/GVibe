#!/bin/bash

# ─────────────────────────────────────────────
#  GVibe Dev Launcher
#  Starts: MongoDB check → Backend → Database UI → Ngrok
# ─────────────────────────────────────────────

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

NGROK_CONFIG="/home/yogeswar/snap/ngrok/419/.config/ngrok/ngrok.yml"
BACKEND_DIR="$(cd "$(dirname "$0")/backend" && pwd)"
STATIC_DOMAIN="https://levitative-unpresumptuously-claire.ngrok-free.dev"

BACKEND_PID=""
EXPRESS_PID=""
NGROK_PID=""

# ── Cleanup on exit ──────────────────────────
cleanup() {
  echo ""
  echo -e "${YELLOW}⏹  Shutting down GVibe services...${RESET}"
  [ -n "$BACKEND_PID" ] && kill "$BACKEND_PID" 2>/dev/null && echo -e "   ${RED}✗${RESET} Backend stopped"
  [ -n "$EXPRESS_PID" ] && kill "$EXPRESS_PID" 2>/dev/null && echo -e "   ${RED}✗${RESET} DB Web UI stopped"
  [ -n "$NGROK_PID"   ] && kill "$NGROK_PID"   2>/dev/null && echo -e "   ${RED}✗${RESET} Ngrok stopped"
  echo -e "${YELLOW}👋 All services stopped. Bye!${RESET}"
  exit 0
}
trap cleanup SIGINT SIGTERM

# ── Banner ───────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}"
echo "  ██████╗ ██╗   ██╗██╗██████╗ ███████╗"
echo "  ██╔════╝ ██║   ██║██║██╔══██╗██╔════╝"
echo "  ██║  ███╗██║   ██║██║██████╔╝█████╗  "
echo "  ██║   ██║╚██╗ ██╔╝██║██╔══██╗██╔══╝  "
echo "  ╚██████╔╝ ╚████╔╝ ██║██████╔╝███████╗"
echo "   ╚═════╝   ╚═══╝  ╚═╝╚═════╝ ╚══════╝"
echo -e "${RESET}"
echo -e "${BOLD}  GVibe Dev Launcher${RESET}"
echo "  ─────────────────────────────────────"
echo ""

# ── Step 1: Check MongoDB ────────────────────
echo -e "${BLUE}[1/4]${RESET} Checking MongoDB..."
if systemctl is-active --quiet mongod 2>/dev/null; then
  echo -e "      ${GREEN}✓${RESET} MongoDB is running"
else
  echo -e "      ${YELLOW}⚡ MongoDB not running — attempting start...${RESET}"
  systemctl start mongod 2>/dev/null || service mongod start 2>/dev/null
  sleep 2
  if systemctl is-active --quiet mongod 2>/dev/null; then
    echo -e "      ${GREEN}✓${RESET} MongoDB started"
  else
    echo -e "      ${RED}✗ Could not start MongoDB automatically.${RESET}"
    echo -e "      ${YELLOW}  Run: sudo systemctl start mongod${RESET}"
    echo -e "      ${YELLOW}  Then re-run this script.${RESET}"
    exit 1
  fi
fi

# ── Step 2: Start Backend ────────────────────
echo ""
echo -e "${BLUE}[2/4]${RESET} Starting Backend (port 5000)..."
cd "$BACKEND_DIR" || { echo -e "${RED}✗ Backend directory not found!${RESET}"; exit 1; }

# Free up port 5000 if occupied
fuser -k 5000/tcp 2>/dev/null
sleep 1

node server.js 2>&1 | sed "s/^/  ${CYAN}[backend]${RESET} /" &
BACKEND_PID=$!
sleep 3

if kill -0 "$BACKEND_PID" 2>/dev/null; then
  echo -e "      ${GREEN}✓${RESET} Backend running ${CYAN}(PID: $BACKEND_PID)${RESET}"
else
  echo -e "      ${RED}✗ Backend failed to start. Check logs above.${RESET}"
  exit 1
fi

# ── Step 3: Start Mongo Express Web UI ────────
echo ""
echo -e "${BLUE}[3/4]${RESET} Starting Database Web UI (port 8081)..."
# Free up port 8081 if occupied
fuser -k 8081/tcp 2>/dev/null
sleep 1

# Start Mongo Express using env variables
ME_CONFIG_MONGODB_URL="mongodb://localhost:27017/gvibe" \
ME_CONFIG_SITE_PORT=8081 \
VCAP_APP_PORT=8081 \
node ./node_modules/mongo-express/app.js > /dev/null 2>&1 &
EXPRESS_PID=$!
sleep 2

if kill -0 "$EXPRESS_PID" 2>/dev/null; then
  echo -e "      ${GREEN}✓${RESET} DB Web UI running ${MAGENTA}(PID: $EXPRESS_PID)${RESET}"
else
  echo -e "      ${YELLOW}⚠ Could not start DB Web UI automatically (port 8081 might be in use)${RESET}"
fi

# ── Step 4: Start Ngrok ──────────────────────
echo ""
echo -e "${BLUE}[4/4]${RESET} Starting Ngrok tunnel..."
# Kill any existing ngrok tunnels
pkill -f "ngrok start" 2>/dev/null
sleep 1

ngrok start gvibe-backend --config="$NGROK_CONFIG" 2>&1 | sed "s/^/  ${YELLOW}[ngrok]${RESET}   /" &
NGROK_PID=$!
sleep 4

if kill -0 "$NGROK_PID" 2>/dev/null; then
  echo -e "      ${GREEN}✓${RESET} Ngrok tunnel active"
else
  echo -e "      ${RED}✗ Ngrok failed to start.${RESET}"
  cleanup
  exit 1
fi

# ── Status Summary ───────────────────────────
echo ""
echo -e "  ${BOLD}─────────────────────────────────────${RESET}"
echo -e "  ${BOLD}${GREEN}🚀 GVibe is LIVE!${RESET}"
echo -e "  ${BOLD}─────────────────────────────────────${RESET}"
echo -e "  ${GREEN}✓${RESET} Backend   → ${CYAN}http://localhost:5000${RESET}"
echo -e "  ${GREEN}✓${RESET} Database  → ${MAGENTA}http://localhost:8081${RESET} (Web Console)"
echo -e "  ${GREEN}✓${RESET} Ngrok URL → ${CYAN}${STATIC_DOMAIN}${RESET}"
echo -e "  ${GREEN}✓${RESET} Ngrok UI  → ${CYAN}http://localhost:4040${RESET}"
echo ""
echo -e "  ${YELLOW}Press Ctrl+C to stop all services${RESET}"
echo -e "  ${BOLD}─────────────────────────────────────${RESET}"
echo ""

# ── Keep alive ───────────────────────────────
wait
