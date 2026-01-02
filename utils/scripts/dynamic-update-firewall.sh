#!/bin/bash

# Dynamic Squid Proxy Whitelist Firewall Script
# Monitors multiple domains' IP changes and updates firewall automatically

# Configuration - Add multiple domains here
DOMAINS=(
    "dev.wordupx.com"
    "joe.wordupx.com"
    # Add more domains as needed
)

CACHE_DIR="/tmp/firewall_domain_cache"
LOG_FILE="/var/log/dynamic_firewall.log"
SCRIPT_DIR="$(dirname "$0")"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to get current IP of domain
get_domain_ip() {
    local domain="$1"
    local ip=$(dig +short "$domain" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -1)
    if [[ -n "$ip" ]]; then
        echo "$ip"
        return 0
    else
        log_message "ERROR: Could not resolve $domain"
        return 1
    fi
}

# Function to get cache file for domain
get_cache_file() {
    local domain="$1"
    echo "$CACHE_DIR/${domain}.cache"
}

# Function to get all current dynamic IPs
get_all_dynamic_ips() {
    local dynamic_ips=()
    
    for domain in "${DOMAINS[@]}"; do
        local ip
        ip=$(get_domain_ip "$domain")
        if [[ $? -eq 0 && -n "$ip" ]]; then
            dynamic_ips+=("$ip")
            log_message "Resolved $domain to $ip"
        else
            log_message "WARNING: Failed to resolve $domain"
        fi
    done
    
    # Remove duplicates and return unique IPs
    printf '%s\n' "${dynamic_ips[@]}" | sort -u
}

# Function to apply firewall rules
apply_firewall_rules() {
    local dynamic_ips=("$@")
    
    log_message "Applying firewall rules with ${#dynamic_ips[@]} dynamic IPs: ${dynamic_ips[*]}"
    
    # Flush existing rules
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    
    # Set default policies to DROP
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    
    # Allow loopback
    iptables -A INPUT -i lo -j ACCEPT
    
    # Allow established connections
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Define your static allowed networks
    STATIC_NETWORKS=(
        "192.168.0.0/16"        # Private networks
        "10.0.0.0/8"           # Private networks  
        "172.16.0.0/12"        # Private networks
        "126.156.205.62/32"    # Manami's phone
        "112.117.205.0/24"     # Joe's home network
        "210.157.218.0/24"     # Joe's home network
        "218.62.247.111/32"    # Joe's home network
    )
    
    # Combine static networks with dynamic IPs
    local all_networks=("${STATIC_NETWORKS[@]}")
    
    # Add dynamic IPs
    for ip in "${dynamic_ips[@]}"; do
        if [[ -n "$ip" ]]; then
            all_networks+=("$ip/32")
        fi
    done
    
    # Allow traffic from all whitelisted networks
    for network in "${all_networks[@]}"; do
        iptables -A INPUT -s "$network" -j ACCEPT
        log_message "Allowed: $network"
    done
    
    # Log dropped packets (with rate limiting to prevent log spam)
    iptables -A INPUT -m limit --limit 5/min --limit-burst 10 -j LOG --log-prefix "DROPPED: " --log-level 4
    
    # Drop everything else
    iptables -A INPUT -j DROP
    
    log_message "Firewall rules applied successfully"
}

# Function to check if any IP has changed
check_ip_changes() {
    local has_changes=false
    local current_ips=()
    
    # Get all current IPs
    while IFS= read -r ip; do
        current_ips+=("$ip")
    done < <(get_all_dynamic_ips)
    
    # Check each domain for changes
    for domain in "${DOMAINS[@]}"; do
        local cache_file
        cache_file=$(get_cache_file "$domain")
        local current_ip
        local cached_ip=""
        
        # Get current IP for this domain
        current_ip=$(get_domain_ip "$domain")
        if [[ $? -ne 0 ]]; then
            log_message "Failed to get IP for $domain, skipping"
            continue
        fi
        
        # Read cached IP if exists
        if [[ -f "$cache_file" ]]; then
            cached_ip=$(cat "$cache_file" 2>/dev/null)
        fi
        
        # Compare IPs
        if [[ "$current_ip" != "$cached_ip" ]]; then
            log_message "IP change detected for $domain: $cached_ip -> $current_ip"
            
            # Update cache
            echo "$current_ip" > "$cache_file"
            has_changes=true
        else
            log_message "No IP change for $domain (current: $current_ip)"
        fi
    done
    
    # If any changes detected, update firewall rules
    if [[ "$has_changes" == true ]]; then
        log_message "Changes detected, updating firewall rules"
        apply_firewall_rules "${current_ips[@]}"
        
        # Optional: Save rules permanently (uncomment if desired)
        # iptables-save > /etc/iptables/rules.v4
        
        return 0
    else
        log_message "No changes detected for any monitored domains"
        return 1
    fi
}

# Function to force update (ignores cache)
force_update() {
    log_message "Force updating firewall rules for all domains"
    
    local current_ips=()
    while IFS= read -r ip; do
        current_ips+=("$ip")
    done < <(get_all_dynamic_ips)
    
    # Update all cache files
    for domain in "${DOMAINS[@]}"; do
        local cache_file
        cache_file=$(get_cache_file "$domain")
        local current_ip
        current_ip=$(get_domain_ip "$domain")
        
        if [[ $? -eq 0 && -n "$current_ip" ]]; then
            echo "$current_ip" > "$cache_file"
        fi
    done
    
    # Apply firewall rules
    apply_firewall_rules "${current_ips[@]}"
}

# Function to run as daemon
run_daemon() {
    log_message "Starting dynamic firewall daemon for domains: ${DOMAINS[*]}"
    
    # Initial check and setup
    force_update
    
    # Run every 5 minutes
    while true; do
        sleep 300  # 5 minutes
        check_ip_changes
    done
}

# Function to run once
run_once() {
    log_message "Running single IP check for domains: ${DOMAINS[*]}"
    check_ip_changes
}

# Function to show current status
show_status() {
    echo "=== Dynamic Firewall Status ==="
    echo "Monitored domains: ${DOMAINS[*]}"
    echo ""
    
    for domain in "${DOMAINS[@]}"; do
        local cache_file
        cache_file=$(get_cache_file "$domain")
        echo "Domain: $domain"
        
        if [[ -f "$cache_file" ]]; then
            echo "  Cached IP: $(cat "$cache_file")"
        else
            echo "  Cached IP: None"
        fi
        
        local current_ip
        current_ip=$(get_domain_ip "$domain")
        if [[ $? -eq 0 ]]; then
            echo "  Current IP: $current_ip"
        else
            echo "  Current IP: Resolution failed"
        fi
        echo ""
    done
    
    echo "Cache directory: $CACHE_DIR"
    echo "Log file: $LOG_FILE"
    
    echo ""
    echo "=== Current Dynamic IPs ==="
    get_all_dynamic_ips | while read -r ip; do
        echo "  $ip"
    done
    
    echo ""
    echo "=== Current Firewall Rules ==="
    iptables -L INPUT -n --line-numbers
    
    echo ""
    echo "=== Recent Log Entries ==="
    tail -10 "$LOG_FILE" 2>/dev/null || echo "No log entries found"
}

# Function to add a new domain
add_domain() {
    local new_domain="$1"
    if [[ -z "$new_domain" ]]; then
        echo "Usage: $0 add-domain <domain>"
        exit 1
    fi
    
    # Check if domain already exists
    for existing_domain in "${DOMAINS[@]}"; do
        if [[ "$existing_domain" == "$new_domain" ]]; then
            echo "Domain $new_domain is already being monitored"
            exit 1
        fi
    done
    
    echo "To add domain '$new_domain', edit this script and add it to the DOMAINS array:"
    echo "DOMAINS=("
    for domain in "${DOMAINS[@]}"; do
        echo "    \"$domain\""
    done
    echo "    \"$new_domain\""
    echo ")"
    echo ""
    echo "Then run: $0 force-update"
}

# Function to install as systemd service
install_service() {
    local service_file="/etc/systemd/system/dynamic-firewall.service"
    
    cat > "$service_file" << EOF
[Unit]
Description=Dynamic Firewall for Multiple Domains
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$SCRIPT_DIR/$(basename "$0") daemon
Restart=always
RestartSec=30
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable dynamic-firewall
    
    echo "Service installed. Start with: sudo systemctl start dynamic-firewall"
    echo "View logs with: sudo journalctl -u dynamic-firewall -f"
}

# Main script logic
case "${1:-once}" in
    "daemon")
        run_daemon
        ;;
    "once")
        run_once
        ;;
    "force-update")
        force_update
        ;;
    "status")
        show_status
        ;;
    "add-domain")
        add_domain "$2"
        ;;
    "install")
        install_service
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [daemon|once|force-update|status|add-domain|install|help]"
        echo ""
        echo "Commands:"
        echo "  daemon       - Run continuously, checking every 5 minutes"
        echo "  once         - Run single check and exit (default)"
        echo "  force-update - Force update all domains (ignore cache)"
        echo "  status       - Show current status and firewall rules"
        echo "  add-domain   - Show instructions to add a new domain"
        echo "  install      - Install as systemd service"
        echo "  help         - Show this help message"
        echo ""
        echo "Currently monitoring domains: ${DOMAINS[*]}"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac