# Proxmox VE 9 Live Boot ISO Image

* Build a fully customizable Proxmox VE 9 live boot ISO image.[^services]
* Supports persistence filesystems across reboots (if configured).
* Use it to test Proxmox VE without installing it.
* Or create a portable USB to run a live Proxmox VE system.
* Dual boot with Windows in a single SSD.
* Lightweight LXDE desktop environment preconfigured.

---

## Usage
- Get the prebuild PVE-Live ISO here: [Release page](https://github.com/LongQT-sea/pve-live/releases)
- Or build your own: [How to build](#how-to-build)

> [!Important]
> **Password:** `live` (for both `user` and `root` accounts)[^pass]

---

## Network Configuration
By default, the `vmbr0` bridge obtains its IP from DHCP via ethernet.

### WiFi Setup
If no ethernet cable is connected, you can use WiFi instead. To connect to WiFi, use `wpa_supplicant` and `ifupdown2`:
> Replace `SSID_NAME` with your Wifi SSID name, `WIFI_PASSWD` with your WiFi password.
```
# Configure WiFi
wpa_passphrase "SSID_NAME" "WIFI_PASSWD" > /etc/wpa_supplicant/wpa_supplicant-wlan0.conf

# Establish the Wi-Fi connection
systemctl enable --now wpa_supplicant@wlan0

# Bring up the wlan0 interface and obtain an IP address via DHCP
ifup wlan0
```

To automatically connect to WiFi at boot, uncomment the `auto wlan0` line in `/etc/network/interfaces` (requires a persistence filesystem to be configured beforehand).

> [!Important]
> Use the `vmbr1` bridge for VMs when your internet source is WiFi.

> [!Tip]
> If you're using ethernet only, remove or comment out the `auto wlan0` line from `/etc/network/interfaces` and configure a static IP for `vmbr0` interface to speed up boot time.

---

## Create persistence filesystem

**Quick steps:**
1. Create a new ext4 partition (on any drive: internal or external), label it `persistence`
2. Add a file `persistence.conf` with the content: `/ union` to that partition

For detailed platform-specific instructions, see [persistence-setup.md](./persistence-setup.md)

> [!Tip]
> **Dual Boot with Windows (UEFI):** You can install Proxmox VE Live on your internal hard drive alongside Windows. Use Windows Disk Management to shrink your drive, then create 2 new partitions:
> 1. **FAT32 partition (3GB)** - Label it `PVE-LIVE` and copy all ISO contents to it
> 2. **Unformatted partition** - Boot into Proxmox VE Live and format as ext4 with label `persistence` (see Linux Step 4-5 in [persistence-setup.md](./persistence-setup.md#linux))

---

## How to build

### Build using GitHub Actions

1. **Fork this repository** to your GitHub account.  
2. Customization (optional)

   - Hook scripts: `config/hooks/normal/`
   - Add files to the root filesystem: `config/includes.chroot/`
3. Navigate to the **Actions** tab and enable workflows.
4. Select the **“Build ISO”** workflow from the left sidebar.  
5. Click the **“Run workflow”**, add a tag then click **“Run workflow”**.  
6. Wait for the build to finish and the generated ISO will appear under:
   - **Repo -> Actions -> Build ISO -> Artifacts**.
   - **Repo -> Release page**.

---

### Local build

**Requirements:**
- Debian 13
- Packages:
   ```
   apt update && apt install -y live-build git
   ```
**Steps:**
1. Clone the repository:
   ```
   git clone https://github.com/LongQT-sea/pve-live.git
   cd pve-live
   ```
2. Customization (optional)
   - Hook scripts: `config/hooks/normal/`
   - Add files to the root filesystem: `config/includes.chroot/`

3. Start the build:
   ```
   lb config && lb build
   ```
4. After building, rename the ISO:
   ```
   mv live-image-amd64.hybrid.iso proxmox-ve_9.0_lxde_live.iso
   ```
5. Cleanup before the next build:
   ```
   lb clean
   ```

---

## License

This project redistributes **Proxmox VE** (Copyright © 2008–2026 Proxmox Server Solutions GmbH) under the **AGPL-3.0** license.

[^services]: In `config/hooks/normal/9999-final-touch.hook.chroot`, these services are disabled: `pve-ha-crm pve-ha-lrm corosync pve-sdn-commit pve-firewall-commit`, and these are masked: `pve-firewall spiceproxy`.
[^pass]: Can be configured in `config/hooks/normal/9999-final-touch.hook.chroot`
