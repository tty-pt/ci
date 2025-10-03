# Install tty.pt packages

## Any

### From Source:
```sh
make
sudo make install
```

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

### pacman (Arch Linux, Etc)
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
