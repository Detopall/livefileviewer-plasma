# Live File Viewer - KDE Plasma Widget

A KDE Plasma 6 widget that displays file contents in real-time on your desktop. Uses inotify for instant updates when files change.

## Requirements

- KDE Plasma 6.x
- Qt 6.x
- kpackagetool6 (included with KDE Plasma)
- inotify-tools (for file monitoring)

### Installing inotify-tools

```bash
# Debian/Ubuntu
sudo apt install inotify-tools

# Fedora
sudo dnf install inotify-tools

# Arch
sudo pacman -S inotify-tools

# openSUSE
sudo zypper install inotify-tools
```

## Installation

### Method 1: From KDE Store (Recommended)

Once published, you can install directly from System Settings:

1. Right-click desktop > Add Widgets
2. Get New Widgets > Download New Plasma Widgets
3. Search for "Live File Viewer"
4. Click Install

### Method 2: Local Installation

```bash
# Navigate to the widget directory
cd livefileviewer

# Install the widget
kpackagetool6 --type Plasma/Applet --install package

# Or upgrade if already installed
kpackagetool6 --type Plasma/Applet --upgrade package

# Restart plasmashell
systemctl --user restart plasma-plasmashell.service
```

### Method 3: Development/Testing

For local development and testing:

```bash
# Install to local user directory
kpackagetool6 --type Plasma/Applet --install package

# Or manually copy to:
mkdir -p ~/.local/share/plasma/plasmoids/
cp -r package ~/.local/share/plasma/plasmoids/org.kde.plasma.livefileviewer

# Restart plasmashell
systemctl --user restart plasma-plasmashell.service
```

## Usage

1. Right-click on your desktop
2. Select "Add Widgets..."
3. Search for "Live File Viewer"
4. Drag it to your desktop or panel
5. Right-click the widget > Configure
6. Select a file to monitor
7. The widget will update instantly when the file changes

## Configuration

Right-click the widget and select "Configure Live File Viewer..." to set:

- File path: Browse or enter the path to any text file
- The widget automatically monitors the file using inotify

## Uninstallation

```bash
# Using the script
./uninstall.sh

# Or manually
kpackagetool6 --type Plasma/Applet --remove org.kde.plasma.livefileviewer
```

## License

GPL-2.0+
