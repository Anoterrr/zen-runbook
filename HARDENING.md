# zen-runbook — internet & machine hardening (Windows / Fedora KDE / macOS)

Named `HARDENING.md`, not `SECURITY.md` — GitHub treats a root `SECURITY.md` as this repo's vulnerability-disclosure policy and surfaces it in its own tab, which isn't what this is.

## Why no antivirus recommendation

Third-party AV suites are mostly theater against how people actually get compromised today: phishing, a malicious browser extension, a fake installer, an unpatched app — not a classic "virus" a signature scanner catches. They also add their own attack surface (kernel drivers, HTTPS interception breaking certificate validation) for marginal benefit over what's already built into the OS. The move is: **keep the built-in protection on** (Defender / XProtect+Gatekeeper / SELinux), shrink what can go wrong (patched software, hardened browser, filtering DNS), and don't hand a third-party vendor deeper access than the OS vendor already has.

---

## Foundation (all platforms)

- Built-in protection **stays on** — Windows Defender, macOS XProtect/Gatekeeper, Fedora SELinux (enforcing, not permissive). Don't disable any of these "temporarily" to fix an unrelated problem; that's how they end up off permanently.
- **Full-disk encryption** — BitLocker / FileVault / LUKS. See per-OS section below.
- **Automatic updates** — OS and apps. On Fedora this is already `topgrade` from `README.md`; run it regularly, don't let it pile up.
- **Bitwarden** (`APPS.md`) for every password, unique per site, with 2FA turned on everywhere it's offered — a leaked/reused password is a far more common breach path than any malware.
- **`curl | sh` awareness** — `README.md`'s Trust boundaries section already names the two pipe-to-shell installers this repo accepts (`mise`, Homebrew) as a deliberate, examined risk. Don't extend that same trust to a random blog post's install one-liner.

---

## Browser hardening (Brave)

Brave already ships ad/tracker blocking on by default, so this is about tightening what's already there, not bolting something new on:

- **Shields** (the lion icon) — set to Aggressive for trackers & ads, and block fingerprinting.
- **`brave://settings/privacy`** — turn on "Always use secure connections" (refuses plain HTTP silently upgrading you to HTTPS instead of asking).
- **`brave://settings/passwords`** — turn the built-in password manager **off**. Two credential stores (Brave's + Bitwarden) drift out of sync and one of them is worse-protected; Bitwarden should be the only one.
- **uBlock Origin** — install it anyway, even with Shields on. It carries more filter lists and finer-grained per-site control than Shields alone; defense in depth costs nothing here.
- **Extension hygiene — the actual top risk, not a footnote:** a legitimate extension gets sold or its maintainer account compromised, and a malicious update ships to everyone who has it installed, silently. Concretely:
  - Check `brave://extensions` every few months and remove anything you don't actively use.
  - Only install from a well-known, actively-maintained publisher — check the install count and last-update date before adding one.
  - Fewer extensions is strictly safer; each one is a standing grant of access to everything you browse.

---

## Encrypted, filtering DNS

Plain DNS is unencrypted and unfiltered — anyone on the network path can see every domain you resolve, and nothing stops you from resolving a known-malicious one. Quad9 (`9.9.9.9`) is used below specifically because its whole purpose is blocking domains already known to serve malware/phishing, not just privacy — it's the one DNS choice here that maps directly to "avoid virus problems."

### Windows (PowerShell, as Administrator)

```powershell
Get-NetAdapter   # find your active adapter's name for the next command

Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ServerAddresses ("9.9.9.9")
Add-DnsClientDohServerAddress -ServerAddress "9.9.9.9" -DohTemplate "https://dns.quad9.net/dns-query" -AllowFallbackToUdp $True -AutoUpgrade $True

```

Sanity check:

```powershell
Get-DnsClientDohServerAddress

```

### Fedora KDE (systemd-resolved) — also applies to WSL2's `systemd-resolved`, but the Windows section above is what actually matters there since WSL2's traffic exits through the host

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d
echo '[Resolve]
DNS=9.9.9.9#dns.quad9.net
DNSOverTLS=yes' | sudo tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null
sudo systemctl restart systemd-resolved

```

Sanity check:

```bash
resolvectl status | grep -i "DNS Servers\|DNSOverTLS"

```

### macOS (System Settings — no clean CLI path for this one)

System Settings → Network → your active interface → Details → DNS → add `https://dns.quad9.net/dns-query` as a server entry. macOS 13+ recognizes the `https://` prefix and treats it as DNS-over-HTTPS automatically — this is a GUI-only step, Apple doesn't expose it over the command line.

Note: most VPN apps override DNS while connected and hand it back to this setting on disconnect — that's expected, not a sign it broke.

---

## Per-OS hardening

### Windows

```powershell
Get-MpComputerStatus | Select-Object AntivirusEnabled, RealTimeProtectionEnabled   # Defender status
Get-NetFirewallProfile | Select-Object Name, Enabled                              # firewall status
manage-bde -status C:                                                             # BitLocker status

```

If BitLocker shows off: Settings → Privacy & security → Device encryption (or `manage-bde -on C:` from an elevated prompt).

### Fedora KDE (bare-metal/VM only — not WSL2)

`firewall-cmd`/`getenforce` don't exist on Fedora WSL2 (confirmed — WSL trusts the Windows host's boundary instead, it doesn't run its own firewalld/SELinux stack). If you're on WSL2, the Windows section above is what's actually protecting the machine; skip this block.

```bash
sudo firewall-cmd --state              # firewalld — on by default on the KDE spin
getenforce                             # should print "Enforcing", not "Permissive" or "Disabled"

```

Disk encryption (LUKS) is a Fedora **installer-time** choice ("Encrypt my data" checkbox during install) — there's no clean way to retrofit it onto an already-installed unencrypted system without reinstalling. If `lsblk -f` doesn't show a `crypto_LUKS` type under your root partition, it wasn't enabled, and the fix is a reinstall with that box checked, not a script.

### macOS

```bash
fdesetup status                                          # FileVault status
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate   # firewall status

```

If FileVault is off: `sudo fdesetup enable` (or System Settings → Privacy & Security → FileVault).

---

## What not to do

These create more risk than they remove — worth naming since they're common "fixes" people reach for:

- Installing a third-party AV suite on top of the built-in one — see the top of this file.
- Turning off SELinux (`setenforce 0`), Gatekeeper, or UAC to make an error message go away — the error is usually telling you something specific and fixable; disabling the check removes the message, not the actual problem.
- Reusing a password, or skipping 2FA because it's "just one more step."
- Trusting a `curl | sh` command from a random source the way `README.md`'s Trust boundaries section trusts `mise`'s or Homebrew's own official one.
