#!/bin/bash
set -e

echo "Starting browser installation..."

# Update package list
apt-get update

# Install common dependencies
apt-get install -y \
    wget \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    ca-certificates

# Install Firefox
echo "Installing Firefox..."
apt-get install -y firefox

# Install Chromium
echo "Installing Chromium browser..."
apt-get install -y chromium-browser

# Install Google Chrome
echo "Installing Google Chrome..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
apt-get update
apt-get install -y google-chrome-stable

# Install Microsoft Edge (alternative browser)
echo "Installing Microsoft Edge..."
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-dev.list
rm microsoft.gpg
apt-get update
apt-get install -y microsoft-edge-stable

# Install Opera (another alternative)
echo "Installing Opera..."
wget -qO- https://deb.opera.com/archive.key | apt-key add -
echo "deb https://deb.opera.com/opera-stable/ stable non-free" > /etc/apt/sources.list.d/opera-stable.list
apt-get update
apt-get install -y opera-stable

# Create desktop shortcuts
echo "Creating desktop shortcuts..."
mkdir -p /home/headless/Desktop

# Firefox shortcut
cat > /home/headless/Desktop/Firefox.desktop << EOF
[Desktop Entry]
Version=1.0
Name=Firefox
Comment=Web Browser
Exec=firefox %u
Icon=firefox
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;
StartupNotify=true
EOF

# Chrome shortcut
cat > /home/headless/Desktop/Chrome.desktop << EOF
[Desktop Entry]
Version=1.0
Name=Google Chrome
Comment=Access the Internet
Exec=google-chrome-stable %U
Icon=google-chrome
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=application/pdf;application/rdf+xml;application/rss+xml;application/xhtml+xml;application/xhtml_xml;application/xml;image/gif;image/jpeg;image/png;image/webp;text/html;text/xml;x-scheme-handler/ftp;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
EOF

# Chromium shortcut
cat > /home/headless/Desktop/Chromium.desktop << EOF
[Desktop Entry]
Version=1.0
Name=Chromium Web Browser
Comment=Access the Internet
Exec=chromium-browser %U
Icon=chromium-browser
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml_xml;image/webp;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;
StartupNotify=true
EOF

# Edge shortcut
cat > /home/headless/Desktop/Edge.desktop << EOF
[Desktop Entry]
Version=1.0
Name=Microsoft Edge
Comment=Access the Internet
Exec=microsoft-edge-stable %U
Icon=microsoft-edge
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=application/pdf;application/rdf+xml;application/rss+xml;application/xhtml+xml;application/xhtml_xml;application/xml;image/gif;image/jpeg;image/png;image/webp;text/html;text/xml;x-scheme-handler/ftp;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
EOF

# Opera shortcut
cat > /home/headless/Desktop/Opera.desktop << EOF
[Desktop Entry]
Version=1.0
Name=Opera
Comment=Fast and secure web browser
Exec=opera %U
Icon=opera
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/webcal;
StartupNotify=true
EOF

# Make desktop files executable
chmod +x /home/headless/Desktop/*.desktop

# Set proper ownership
chown -R headless:headless /home/headless/Desktop

# Clean up
apt-get autoremove -y
apt-get autoclean
rm -rf /var/lib/apt/lists/*

echo "Browser installation completed successfully!"
echo "Installed browsers:"
echo "- Firefox"
echo "- Google Chrome"
echo "- Chromium"
echo "- Microsoft Edge"
echo "- Opera"