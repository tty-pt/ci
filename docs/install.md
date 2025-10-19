# Install tty.pt packages
We distribute our packages for the different package managers and different operating systems. Follow these instructions to easily get them working in your computer.

## Any

## Linux

### Apt (Ubuntu, Debian, Etc)
At least once in your life you need to:
```sh
# Download and add the key
wget -qO- https://tty.pt/apt/archive-key.gpg \
    | sudo tee /etc/apt/keyrings/ttypt.asc > /dev/null

echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/ttypt.asc] https://tty.pt/apt stable main" \
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
# Add your repository to Alpine's sources
echo "https://tty.pt/apk" >> /etc/apk/repositories

# Add your GPG public key for verification
wget -O /etc/apk/keys/ttypt.rsa.pub https://tty.pt/apk/key.pub

# Update package indexes
apk update
```

Then it's just:
```sh
apk add <package-name>
```

### pacman (Arch Linux, Windows/Msys, Etc)
At least once in your life you need to:
```sh
# Add the repository to pacman.conf
echo -e "\n[ttypt]\nSigLevel = Optional TrustAll\nServer = https://tty.pt/pacman/\$arch" | sudo tee -a /etc/pacman.conf

# Import the GPG key (optional, for verification)
sudo pacman-key --add <(wget -qO- https://tty.pt/pacman/key.pub)
sudo pacman-key --lsign-key YOUR_KEY_ID

# Update package database
sudo pacman -Sy
```

Then it's just:
```sh
sudo pacman -S ttypt/<package-name>
```

### rpm (Fedora, Red Hat, etc)
At least once in your life you need to:
```sh
# Download the repository configuration
curl -O https://tty.pt/rpm/ttypt.repo

# Install the repository configuration
sudo mv ttypt.repo /etc/yum.repos.d/

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

## Brew (MacOS)
```sh
brew tap tty-pt/tap https://github.com/tty-pt/tap.git
brew install <package>
```

## OpenBSD
```sh
SUFFIX=$(uname -r)/packages/$(uname -m)
MY="https://tty.pt/openbsd/$SUFFIX/"
OFF="$(cat /etc/installurl)/$SUFFIX/"
doas env PKG_PATH="$MY:$OFF" pkg_add <package>
```

### Building from Source:
```sh
git clone https://github.com/tty-pt/mk.git ../mk
make
sudo make install
```
You'll need to manually install any dependencies in order to be able to run the project, in this case.
