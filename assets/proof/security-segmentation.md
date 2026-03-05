# Network Security & Segmentation Summary

## Firewall
- **Hardware:** Qotom Q20342G9 (dedicated appliance, not a VM)
- **Software:** OPNsense (FreeBSD-based, open source)
- **Interfaces:** WAN, LAN, Management VLAN, Storage VLAN, IoT VLAN

## Network Segments
| VLAN | Purpose | Speed | Nodes |
|---|---|---|---|
| Management | SSH, Ansible, OpenClaw control plane | 2.5 GbE | All |
| Storage | NFS, SMB, TrueNAS traffic | 2.5G / 10G | Nova ↔ All |
| Inference | Ollama API, model weights transfer | 2.5G / 10G | Jasper, Nova |
| IoT | Isolated IoT devices | 1 GbE | Sensors, cameras |

## Access Control
- **SSH:** Key-only authentication (ed25519). Password auth disabled on all nodes.
- **Remote access:** Tailscale mesh VPN (zero-trust, no port forwarding)
- **Firewall rules:** Default deny. Explicit allow per service per VLAN.
- **OpenClaw:** Pairing-based trust model. Nodes must be approved by gateway.

## Secrets Hygiene
- No credentials in Git repos (CI-enforced)
- Sanitize scripts strip 11 pattern types before commit
- Credentials stored locally in node-specific credential stores
- Rotation policy: API keys rotated on any suspected exposure

## WiFi
- **AP:** UniFi U7 Pro XG (WiFi 7)
- **SSIDs:** Separate SSIDs per VLAN (management, IoT, guest)
- **Encryption:** WPA3

## Monitoring
- SLO tracking on gateway availability (99.9% target)
- Automated health checks every 6 hours (Ansible)
- Incident auto-creation on anomalies
