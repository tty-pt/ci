# Install tty.pt packages
We distribute our packages for the different package managers and different operating systems. Follow these instructions to easily get them working in your computer.

Every repository is signed, and the commands below install and verify the tty.pt signing key before use.

## Linux

### Apt (Ubuntu, Debian, Etc)
At least once in your life you need to:
```sh
# Download and add the key
wget -qO- https://tty.pt/apt/keyrings/archive-key.gpg \
    | sudo tee /etc/apt/keyrings/ttypt.asc > /dev/null

echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/ttypt.asc] https://tty.pt/deb stable main" \
    | sudo tee /etc/apt/sources.list.d/ttypt.list
```

Then it's just:
```sh
sudo apt update
sudo apt install <package-name>
```

### Apk (Alpine, Etc)
At least once in your life you need to:
```sh
# Add your repository to Alpine's sources (apk appends the architecture itself)
echo "https://tty.pt/apk" >> /etc/apk/repositories

# Add the GPG public key for verification
wget -O /etc/apk/keys/ttypt.rsa.pub https://tty.pt/apk/keys/ttypt.rsa.pub

# Update package indexes
apk update
```

Then it's just:
```sh
apk add <package-name>
```

### pacman (Arch Linux, MSYS2, Etc)
At least once in your life you need to:
```sh
# Import and locally trust the tty.pt signing key
sudo pacman-key --add <(wget -qO- https://tty.pt/pacman/key-ttypt.pub)
# The fingerprint is printed by the command above; sign the imported key locally:
sudo pacman-key --lsign-key <KEY_FINGERPRINT>

# Add the repository (signatures are required)
echo -e "\n[ttypt]\nSigLevel = Required DatabaseOptional\nServer = https://tty.pt/pacman/\$arch" | sudo tee -a /etc/pacman.conf

# Update package database
sudo pacman -Sy
```

Then it's just:
```sh
sudo pacman -S ttypt/<package-name>
```

### rpm (Fedora, Red Hat, Etc)
At least once in your life you need to:
```sh
# Download the repository configuration (it ships with gpgcheck=1)
curl -O https://tty.pt/rpm/ttypt.repo
sudo mv ttypt.repo /etc/yum.repos.d/

# Import the signing key so signature checks pass
sudo rpm --import https://tty.pt/rpm/RPM-GPG-KEY-ttypt

# Update package cache
sudo dnf check-update  # For Fedora/RHEL 8+
# OR
sudo yum update  # For CentOS 7/RHEL 7
```

Then it's just:
```sh
sudo dnf install <package>
# OR
sudo yum install <package>
```

## Brew (macOS)
```sh
brew tap tty-pt/tap https://github.com/tty-pt/tap.git
brew trust tty-pt/tap || true
brew install <package>
```

## Windows

### winget

Add the tty.pt source once (requires the REST source to be running on `tty.pt`):
```powershell
winget source add --name ttypt --arg https://tty.pt/winget --type Microsoft.Rest
winget install tty-pt.<package>
```

Or install directly from a release manifest without adding the source:
```powershell
winget install --manifest https://tty.pt/winget/manifests/t/tty-pt/<package>/<version>/
```

### Direct download

Download the `.msix` package from the [GitHub Releases](https://github.com/tty-pt) page and
double-click to install, or via PowerShell:
```powershell
Add-AppxPackage <package>-<version>-winget-x64.msix
```

## OpenBSD
```sh
SUFFIX=$(uname -r)/packages/$(uname -m)
MY="https://tty.pt/openbsd/$SUFFIX/"
OFF="$(cat /etc/installurl)/$SUFFIX/"
doas env PKG_PATH="$MY:$OFF" pkg_add <package>
```

## Building from Source:
```sh
git clone https://github.com/tty-pt/mk.git ../mk
make
sudo make install
```
You'll need to manually install any dependencies in order to be able to run the project, in this case.
See each project's README (`## Build from source`) for the full dependency list.