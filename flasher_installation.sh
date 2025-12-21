#!/data/data/com.termux/files/usr/bin/bash
# install_flasher.sh

echo -e "\e[36m╔══════════════════════════════════════════╗\e[0m"
echo -e "\e[36m║     Android Flasher Installation         ║\e[0m"
echo -e "\e[36m╚══════════════════════════════════════════╝\e[0m"

# Check if running in Termux
if [ ! -d "/data/data/com.termux" ]; then
    echo -e "\e[31m❌ This script must be run in Termux\e[0m"
    exit 1
fi

# Update packages
echo -e "\e[33m📦 Updating packages...\e[0m"
pkg update -y && pkg upgrade -y

# Install dependencies
echo -e "\e[33m📦 Installing dependencies...\e[0m"
pkg install -y git wget curl unzip tar bash

# Install ADB/Fastboot if not present
echo -e "\e[33m📱 Installing ADB/Fastboot...\e[0m"
curl -s https://raw.githubusercontent.com/offici5l/termux-adb-fastboot/main/install | bash

# Create installation directory
INSTALL_DIR="$PREFIX/share/flasher"
echo -e "\e[33m📁 Creating directories...\e[0m"
mkdir -p "$INSTALL_DIR"

echo -e "\e[33m📥 Downloading flasher script...\e[0m"
git clone https://github.com/sukuna567/flasher.git

cd flasher && rm LICENSE && rm README.md && rm flasher.png && mv flasher.sh "$INSTALL_DIR/" && rm -rf flasher

# Make executable
chmod +x "$INSTALL_DIR/flasher.sh"

# Create launcher script
echo -e "\e[33m🔗 Creating launcher...\e[0m"
cat > "$PREFIX/bin/flasher" << EOF
#!/data/data/com.termux/files/usr/bin/bash
cd "\$HOME"
exec "$INSTALL_DIR/flasher.sh" "\$@"
EOF
chmod +x "$PREFIX/bin/flasher"

# Create alias in bashrc
if ! grep -q "alias flasher=" "$HOME/.bashrc"; then
    echo "alias flasher='$PREFIX/bin/flasher'" >> "$HOME/.bashrc"
fi

# Create desktop notification
cat > "$HOME/.flasher/README.md" << EOF
# Android Flasher Tool

## Commands:
- \`flasher\` - Start the flasher tool
- \`flasher --help\` - Show help

## Features:
- Flash recovery images
- ADB sideload ROMs
- Fastboot ROM installation
- vbmeta/boot flashing
- Device information
- 

Created by @sukuna567
Version: 2.0.0
EOF

echo -e "\e[32m✅ Installation complete!\e[0m"
echo -e "\e[36m──────────────────────────────────────\e[0m"
echo -e "\e[33m🚀 To start: \e[32mflasher\e[0m"
echo -e "\e[33m📖 Or restart Termux and type: \e[32mflasher\e[0m"
echo -e "\e[36m──────────────────────────────────────\e[0m"
echo -e "\e[34m💾 Storage: $INSTALL_DIR\e[0m"
echo -e "\e[34m📝 Config: $HOME/.flasher_config\e[0m"
echo -e "\e[34m📋 Logs: /sdcard/flasher/logs/\e[0m"
echo -e "\e[36m══════════════════════════════════════\e[0m"