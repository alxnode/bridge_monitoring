#!/bin/bash
celestia_bridge_path="/root/.celestia-bridge/"

# Telegram API token and user ID
api="1831362"
uid=""

get_server_ip() {
    curl -4 ifconfig.me
}


send_red_alert() {
    server_ip=$1
    alert_message="!! Alert !! There was an error fetching data from Celestia. Server IP: $server_ip"
    curl -s -X POST "https://api.telegram.org/bot$api/sendMessage" -d "chat_id=$uid" -d "text=$alert_message"
}


server_ip=$(get_server_ip)


peer_id=$(/usr/local/bin/celestia p2p info --node.store "$celestia_bridge_path" | jq -r '.result.id')
if [ -z "$peer_id" ]; then
    send_red_alert "$server_ip"
    exit 1
fi


local_header=$(/usr/local/bin/celestia header local-head --node.store "$celestia_bridge_path" | jq -r '.result.header.height')
if [ -z "$local_header" ]; then
    send_red_alert "$server_ip"
    exit 1
fi

# Get network_header
network_header=$(/usr/local/bin/celestia header network-head --node.store "$celestia_bridge_path" | jq -r '.result.header.height')
if [ -z "$network_header" ]; then
    send_red_alert "$server_ip"
    exit 1
fi


chai_id=$(/usr/local/bin/celestia header local-head --node.store "$celestia_bridge_path" | jq -r '.result.header.chain_id')
if [ -z "$chai_id" ]; then
    send_red_alert "$server_ip"
    exit 1
fi


local_header=$(echo "$local_header" | tr -d '"')
network_header=$(echo "$network_header" | tr -d '"')


difference=$((network_header - local_header))


output="<b>Server IP:</b> $server_ip%0A"
output+="<b>Peer ID:</b> $peer_id%0A"
output+="<b>Local Header:</b> $local_header%0A"
output+="<b>Network Header:</b> $network_header%0A"
output+="<b>Chain ID:</b> $chai_id%0A"
output+="<b>Difference:</b> $difference%0A"


if [ "$difference" -gt 5 ]; then
    output+="ALERT: Difference in blocks exceeds 5!%0A"
fi


curl -s -X POST "https://api.telegram.org/bot$api/sendMessage" -d "chat_id=$uid" -d "text=$output" -d "parse_mode=HTML"
