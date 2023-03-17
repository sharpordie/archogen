# <samp>OVERVIEW</samp>

Opinionated post-installation script for Arch Linux.

<img src="assets/img1.png" width="49.25%"/><img src="assets/img0.png" width="1.5%"/><img src="assets/img2.png" width="49.25%"/>

# <samp>GUIDANCE</samp>

Blindly executing this is strongly discouraged.

```bash
address="https://raw.githubusercontent.com/sharpordie/archogen/main/src/archogen.sh"
fetched="$HOME/$(basename $address)"
wget $address -O $fetched
bash $fetched
```
