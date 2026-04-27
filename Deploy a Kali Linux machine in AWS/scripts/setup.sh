#!/bin/bash
# -------------------------------------------------------
# Kali Linux EC2 - Initial Setup Script (User Data)
# -------------------------------------------------------
set -euo pipefail

LOG_FILE="/var/log/kali-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================="
echo " Kali Linux EC2 - Setup Starting"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================="

# -------------------- System Update --------------------
echo "[*] Updating package lists..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y

echo "[*] Upgrading installed packages..."
apt-get upgrade -y

# -------------------- Install Common Tools --------------------
echo "[*] Installing additional useful packages..."
apt-get install -y \
  tmux \
  tree \
  jq \
  unzip \
  curl \
  wget \
  net-tools \
  htop

# -------------------- Install AWS CLI v2 --------------------
echo "[*] Installing AWS CLI v2..."
if ! command -v aws &>/dev/null; then
  arch=$(dpkg --print-architecture)
  if [ "$arch" = "arm64" ] || [ "$arch" = "aarch64" ]; then
    cli_url="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"
  else
    cli_url="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
  fi
  curl -s "$cli_url" -o "/tmp/awscliv2.zip"
  unzip -q /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install
  rm -rf /tmp/aws /tmp/awscliv2.zip
  echo "[+] AWS CLI installed: $(aws --version)"
else
  echo "[+] AWS CLI already present: $(aws --version)"
fi

# -------------------- Install SSM Agent --------------------
echo "[*] Installing AWS SSM Agent..."
if ! systemctl list-units --type=service | grep -q amazon-ssm-agent; then
  arch=$(dpkg --print-architecture)
  if [ "$arch" = "amd64" ]; then
    ssm_url="https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb"
  else
    ssm_url="https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_arm64/amazon-ssm-agent.deb"
  fi
  curl -sL "$ssm_url" -o /tmp/amazon-ssm-agent.deb
  dpkg -i /tmp/amazon-ssm-agent.deb
  rm -f /tmp/amazon-ssm-agent.deb
  echo "[+] SSM Agent installed"
else
  echo "[+] SSM Agent already present"
fi
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
echo "[+] SSM Agent status: $(systemctl is-active amazon-ssm-agent)"

# -------------------- Install XRDP & XFCE Desktop --------------------
# Following: https://www.kali.org/docs/general-use/xfce-with-rdp/
echo "[*] Installing Xfce4 & xrdp (this will take a while)..."
apt-get install -y kali-desktop-xfce xorg xrdp xorgxrdp

echo "[*] Keeping xrdp on default port 3389..."

# Set the kali user password for RDP login
echo "[*] Setting kali user password for RDP..."
echo "kali:kali" | chpasswd

# Fix "Authentication Required to Create Managed Color Device" error
echo "[*] Fixing polkit colord authentication prompt..."
mkdir -p /etc/polkit-1/localauthority/50-local.d
cat <<EOF > /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF

echo "[*] Enabling and starting xrdp..."
systemctl enable xrdp --now
echo "[+] XRDP status: $(systemctl is-active xrdp)"
echo "[!] IMPORTANT: Change the default kali password after first RDP login!"

# -------------------- SSH Hardening --------------------
echo "[*] Hardening SSH configuration..."
sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# -------------------- Set Timezone --------------------
echo "[*] Setting timezone to UTC..."
timedatectl set-timezone UTC

# -------------------- MOTD Banner --------------------
echo "[*] Setting up login banner..."
cat > /etc/motd << 'BANNER'

  ╔══════════════════════════════════════════════╗
  ║   Kali Linux - AWS EC2 Instance             ║
  ║   Managed by Terraform                      ║
  ║                                              ║
  ║   Use responsibly & only on authorised       ║
  ║   targets.                                   ║
  ╚══════════════════════════════════════════════╝

BANNER

# -------------------- Cleanup --------------------
echo "[*] Cleaning up..."
apt-get autoremove -y
apt-get clean

echo "========================================="
echo " Kali Linux EC2 - Setup Complete"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================="
