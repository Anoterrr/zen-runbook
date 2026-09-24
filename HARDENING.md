# zen-runbook - internet & machine hardening (Windows / Fedora KDE / macOS)

This file is called `HARDENING.md` and not `SECURITY.md` because GitHub treats a root `SECURITY.md` as the repo's vulnerability disclosure policy and gives it its own tab.

## Why no antivirus

Most real compromises today come from phishing, a malicious browser extension, a fake installer or an unpatched app, and a signature-based scanner catches almost none of that. Third-party antivirus suites also bring their own attack surface (kernel drivers, HTTPS interception that breaks certificate checks) for little gain over what the OS already has. So the plan is: **keep the built-in protection on** (Defender / XProtect+Gatekeeper / SELinux), reduce what can go wrong (keep software patched, harden the browser, use filtering DNS, close unused ports), and don't give a third-party vendor more access than the OS vendor already has.

---

## Foundation (all platforms)

- Built-in protection **stays on**: Windows Defender, macOS XProtect/Gatekeeper, Fedora SELinux (enforcing, not permissive). Don't turn any of them off "temporarily" to fix some other problem. That's how they end up off for good.
- **Full-disk encryption**: BitLocker / FileVault / LUKS. See the per-OS sections below.
- **Security updates install on their own**, everything else when I run `topgrade` (`README.md`). `topgrade` only runs when I remember to, so it can't be the only thing patching the machine. Per-OS setup below.
- **Bitwarden** (`APPS.md`) for every password, unique per site, with 2FA on wherever it's offered. Leaked or reused passwords cause far more breaches than malware.
- **`curl | sh`**: the "Sources and owners" section in `README.md` lists the two pipe-to-shell installers this repo accepts (`mise`, Homebrew) and why. That doesn't extend to an install one-liner from some random blog post.

---

## Browser hardening (Brave)

Brave blocks ads, trackers and fingerprinting by default, so this section tightens settings that already exist. No extra ad blocker: every extension is a risk (see the last point), and Shields can load the same filter lists.

- **Shields** (`brave://settings/shields`): set trackers & ads blocking to Aggressive and "Upgrade connections to HTTPS" to Strict. Strict warns before loading a site over plain HTTP.
- **Filter lists** (`brave://settings/shields/filters`): turn on the extra lists I want (for example the uBlock Origin lists and a regional list). This gives what uBlock Origin would, without installing an extension.
- **Password manager**: Settings → Autofill and passwords → Password Manager, turn off "Offer to save passwords". Two password stores (Brave and Bitwarden) drift apart, and one of them is less protected. Keep Bitwarden only.
- **Extensions are the biggest risk here.** A legitimate extension gets sold, or its maintainer's account is hacked, and a malicious update goes out silently to everyone who has it. What to do:
  - Check `brave://extensions` every few months and remove anything you don't use.
  - Only install extensions from well-known, actively maintained publishers. Check the install count and the last update date first.
  - Keep the list short. Every extension can read everything you browse.

---

## Encrypted, filtering DNS

Plain DNS is neither encrypted nor filtered. Anyone on the network path can see every domain you look up, and nothing stops you from resolving a known-malicious one. I use Quad9 because it blocks domains known to serve malware or phishing, on top of the privacy. It's the DNS choice here that directly helps avoid malware.

Every platform gets both Quad9 IPv4 servers and both IPv6 ones. With only one server there's no fallback, and if IPv6 is left alone the router's IPv6 DNS keeps answering part of the queries, outside Quad9.

Sanity check, same on every platform (on Windows, run it from WSL2 or Git Bash, or open https://on.quad9.net in the browser):

```bash
curl -s https://on.quad9.net | grep -q "you ARE using quad9" \
  && echo "OK      DNS goes through Quad9" \
  || echo "MISMATCH DNS is not (only) Quad9"

```

### Windows (PowerShell, as Administrator)

```powershell
Get-NetAdapter   # find your active adapter's name, then use it below

Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ServerAddresses ("9.9.9.9","149.112.112.112","2620:fe::fe","2620:fe::9")

```

Windows 11 already knows Quad9's DNS-over-HTTPS address, so encryption is one toggle per adapter: Settings → Network & internet → your adapter → DNS server assignment → Edit. For each of the four servers, set DNS over HTTPS to "On (automatic template)" and turn "Fallback to plaintext" off.

### Fedora KDE (systemd-resolved)

Skip on WSL2. There, DNS comes from Windows, so the Windows section is the one that applies.

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d
echo '[Resolve]
DNS=9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 2620:fe::fe#dns.quad9.net 2620:fe::9#dns.quad9.net
DNSOverTLS=yes
Domains=~.' | sudo tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null
sudo systemctl restart systemd-resolved

```

`Domains=~.` sends every lookup to these servers. Without it, systemd-resolved can also use the DNS server your router hands out over DHCP.

### macOS (configuration profile)

macOS only turns on encrypted DNS through a configuration profile. The network settings screen only takes plain IP addresses. Public Quad9 profiles exist, but the whole profile is this short XML, so I write my own and can read every line of it:

```bash
cat > ~/Downloads/quad9-doh.mobileconfig <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PayloadType</key><string>Configuration</string>
  <key>PayloadVersion</key><integer>1</integer>
  <key>PayloadIdentifier</key><string>local.quad9.doh</string>
  <key>PayloadUUID</key><string>$(uuidgen)</string>
  <key>PayloadDisplayName</key><string>Quad9 encrypted DNS</string>
  <key>PayloadContent</key>
  <array>
    <dict>
      <key>PayloadType</key><string>com.apple.dnsSettings.managed</string>
      <key>PayloadVersion</key><integer>1</integer>
      <key>PayloadIdentifier</key><string>local.quad9.doh.dns</string>
      <key>PayloadUUID</key><string>$(uuidgen)</string>
      <key>PayloadDisplayName</key><string>Quad9 DoH</string>
      <key>DNSSettings</key>
      <dict>
        <key>DNSProtocol</key><string>HTTPS</string>
        <key>ServerURL</key><string>https://dns.quad9.net/dns-query</string>
        <key>ServerAddresses</key>
        <array>
          <string>9.9.9.9</string>
          <string>149.112.112.112</string>
          <string>2620:fe::fe</string>
          <string>2620:fe::9</string>
        </array>
      </dict>
    </dict>
  </array>
</dict>
</plist>
EOF
open ~/Downloads/quad9-doh.mobileconfig

```

`open` only registers the profile. To install it, open System Settings, search "Profiles", open "Quad9 encrypted DNS" and click Install.

Most VPN apps take over DNS while connected and give it back when you disconnect. That's expected.

---

## Per-OS hardening

### Windows (PowerShell, as Administrator)

```powershell
Get-MpComputerStatus | Select-Object AntivirusEnabled, RealTimeProtectionEnabled   # Defender status
Get-NetFirewallProfile | Select-Object Name, Enabled                              # firewall status
manage-bde -status C:                                                             # BitLocker status

```

If BitLocker is off: Settings → Privacy & security → Device encryption, or `manage-bde -on C:`.

Also check Windows Security → Device security → Core isolation → **Memory integrity** is on. It blocks malicious or vulnerable drivers from loading into the kernel. Some old drivers are incompatible, and Windows lists them on that screen if any are blocking it.

Windows Update installs security updates on its own by default. Just don't pause it for long.

### Fedora KDE (bare-metal or VM, not WSL2)

`firewall-cmd` and `getenforce` don't exist on Fedora WSL2. WSL doesn't run its own firewalld or SELinux, it relies on the Windows host. On WSL2 the Windows section above is what protects the machine, so skip this block.

**Firewall zone.** Fedora KDE uses the `FedoraWorkstation` zone by default, which **accepts incoming connections on every port from 1025 to 65535**, TCP and UDP. Any program that opens a port above 1024 is reachable from the network. The `public` zone only lets in ssh, mdns and dhcpv6-client. I switch to it, open Syncthing (`OBSIDIAN.md`), and close ssh since this machine doesn't run an SSH server:

```bash
sudo firewall-cmd --set-default-zone=public
sudo firewall-cmd --permanent --zone=public --add-service=syncthing
sudo firewall-cmd --permanent --zone=public --remove-service=ssh
sudo firewall-cmd --reload

```

If something that used to work on the local network stops (casting, a LAN game, KDE Connect), open that one service or port. Don't go back to the old zone.

**Automatic security updates.** `dnf5-automatic` installs only the updates Fedora marks as security fixes. Everything else still waits for `topgrade`:

```bash
sudo dnf install -y dnf5-plugin-automatic
echo '[commands]
upgrade_type = security
apply_updates = yes' | sudo tee /etc/dnf/automatic.conf > /dev/null
sudo systemctl enable --now dnf5-automatic.timer

```

Sanity check:

```bash
sudo firewall-cmd --state              # firewalld, on by default on the KDE spin
test "$(sudo firewall-cmd --get-default-zone)" = public \
  && echo "OK      firewall zone is public" || echo "MISMATCH firewall zone is not public"
test -z "$(sudo firewall-cmd --list-ports)" \
  && echo "OK      no open port ranges" || echo "MISMATCH open ports: $(sudo firewall-cmd --list-ports)"
getenforce                             # should print "Enforcing", not "Permissive" or "Disabled"
systemctl is-active --quiet dnf5-automatic.timer \
  && echo "OK      automatic security updates" || echo "MISSING dnf5-automatic.timer"

```

Disk encryption (LUKS) is chosen **at install time**, with the "Encrypt my data" checkbox. There's no clean way to add it to a system that's already installed unencrypted. If `lsblk -f` doesn't show a `crypto_LUKS` type under your root partition, it's off, and the only fix is reinstalling with that box checked.

### macOS

```bash
fdesetup status                                          # FileVault status
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate   # firewall status

```

The macOS firewall is **off by default**. Turn it on:

```bash
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

```

If FileVault is off: `sudo fdesetup enable`, or System Settings → Privacy & Security → FileVault.

For automatic security updates: System Settings → General → Software Update → the (i) next to Automatic updates, and turn on "Install Security Responses and system files".

---

## What not to do

Common "fixes" that add more risk than they remove:

- Installing a third-party antivirus on top of the built-in one (see the top of this file).
- Turning off SELinux (`setenforce 0`), Gatekeeper or UAC to get rid of an error. The error usually points at a specific problem you can fix. Disabling the check hides the message and leaves the problem.
- Opening a whole port range, or going back to the `FedoraWorkstation` zone, because one app couldn't connect. Open that app's port or service only.
- Reusing a password, or skipping 2FA because it's "just one more step".
- Running a `curl | sh` command from a random source just because `README.md` accepts the official ones from `mise` and Homebrew.
