#!/usr/bin/env bash

invoke_restart() {

	# Enable automatic login
	local configs="/etc/gdm/custom.conf"
	local pattern="AutomaticLogin="
	local payload="s/AutomaticLoginEnable=.*/AutomaticLoginEnable=True\nAutomaticLogin=$USER/"
	if ! grep -q "$pattern" "$configs" 2>/dev/null; then sudo sed -i "$payload" "$configs"; fi
	sudo sed -i "s/AutomaticLoginEnable=.*/AutomaticLoginEnable=True/" "$configs"
	sudo sed -i "s/AutomaticLogin=.*/AutomaticLogin=$USER/" "$configs"

	# Create startup desktop
	current="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)"
	startup="$HOME/.config/autostart/invoke_restart.desktop"
	mkdir -p "$(dirname $startup)" && rm -f "$startup" &>/dev/null
	echo "[Desktop Entry]" >>"$startup"
	echo "Type=Application" >>"$startup"
	echo "Exec=/usr/bin/kgx --command \"/bin/bash '$current/essentials.sh'\" --wait" >>"$startup"
	echo "Hidden=false" >>"$startup"
	echo "X-GNOME-Autostart-enabled=true" >>"$startup"
	echo "Name=archogen" >>"$startup"

	# Enable no-overview
	yay -S --needed --noconfirm gnome-shell-extension-no-overview
	local factors=$(gsettings get org.gnome.shell enabled-extensions)
	[[ $factors == "@as []" ]] && gsettings set org.gnome.shell enabled-extensions "['no-overview@fthx']"
	local factors=$(gsettings get org.gnome.shell enabled-extensions)
	local enabled=$([[ $factors == *"'no-overview@fthx'"* ]] && echo "true" || echo "false")
	[[ $enabled == "false" ]] && gsettings set org.gnome.shell enabled-extensions "${factors%]*}, 'no-overview@fthx']"

	# Reboot the system
	sudo reboot --force

}

update_appearance() {

	# Enable night-light
	gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
	gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 0
	gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 0
	gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000

	# Change color-theme
	gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
	gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"

	# Change fonts
	sudo pacman -S --needed --noconfirm noto-fonts-emoji ttf-ubuntu-font-family
	sudo pacman -Rdd --noconfirm bubblewrap
	yes | yay -S --needed fontconfig-ubuntu
	gsettings set org.gnome.desktop.interface font-name "Ubuntu 10"
	gsettings set org.gnome.desktop.interface document-font-name "Sans 10"
	gsettings set org.gnome.desktop.interface monospace-font-name ""
	gsettings set org.gnome.desktop.wm.preferences titlebar-font "Ubuntu Bold 10"
	gsettings set org.gnome.desktop.wm.preferences titlebar-uses-system-font false
	gsettings set org.gnome.desktop.interface font-antialiasing "rgba"
	gsettings set org.gnome.desktop.interface font-hinting "slight"

	# Change windows layout
	gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"

	# Change icon-theme
	sudo pacman -S --needed --noconfirm papirus-icon-theme
	gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"

	# Change folder-theme
	yay -S --needed --noconfirm papirus-folders
	sudo papirus-folders --color yaru --theme Papirus-Dark

	# Remove event-sounds
	gsettings set org.gnome.desktop.sound event-sounds false

	# Remove favorites
	gsettings set org.gnome.shell favorite-apps "[]"

}

update_chromium() {

	# Handle parameters
	local deposit=${1:-$HOME/Downloads/DDL}
	local startup=${2:-about:blank}

	# Update dependencies
	sudo pacman -S --needed --noconfirm curl jq ydotool

	# Update package
	local present=$([[ -n $(pacman -Q | grep ungoogled-chromium-bin) ]] && echo "true" || echo "false")
	yay -S --needed --noconfirm ungoogled-chromium-bin

	# Change default browser
	xdg-settings set default-web-browser "chromium.desktop"

	# Finish installation
	if [[ "$present" == "false" ]]; then
		# Launch chromium
		sleep 1 && (sudo ydotoold &) &>/dev/null
		sleep 1 && (chromium &) &>/dev/null
		sleep 4 && sudo ydotool key 125:1 103:1 103:0 125:0

		# Change deposit
		mkdir -p "$deposit"
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://settings/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "before downloading" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 3); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 56:1 15:1 15:0 56:0 && sleep 1 && sudo ydotool key 56:1 15:1 15:0 56:0
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0 && sleep 1 && sudo ydotool type "$deposit" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 15:1 15:0 && sleep 1 && sudo ydotool key 28:1 28:0

		# Change engine
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://settings/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "search engines" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 3); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "duckduckgo" && sleep 1 && sudo ydotool key 28:1 28:0

		# Change custom-ntp
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "custom-ntp" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 5); do sleep 0.5 && sudo ydotool key 15:1 15:0; done
		sleep 1 && sudo ydotool key 29:1 30:1 30:0 29:0 && sleep 1 && sudo ydotool type "$startup"
		sleep 1 && for i in $(seq 1 2); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 108:1 108:0 && sleep 1 && sudo ydotool key 28:1 28:0

		# Change disable-sharing-hub
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "disable-sharing-hub" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 6); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 108:1 108:0 && sleep 1 && sudo ydotool key 28:1 28:0

		# Change extension-mime-request-handling
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "extension-mime-request-handling" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 6); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 2); do sleep 0.5 && sudo ydotool key 108:1 108:0; done && sleep 1 && sudo ydotool key 28:1 28:0

		# Change hide-sidepanel-button
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "hide-sidepanel-button" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 6); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 108:1 108:0 && sleep 1 && sudo ydotool key 28:1 28:0

		# Change remove-tabsearch-button
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "remove-tabsearch-button" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 6); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 108:1 108:0 && sleep 1 && sudo ydotool key 28:1 28:0

		# Change show-avatar-button
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "show-avatar-button" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 6); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 3); do sleep 0.5 && sudo ydotool key 108:1 108:0; done && sleep 1 && sudo ydotool key 28:1 28:0

		# Toggle bookmark bar (ctr+shift+b)
		sleep 4 && sudo ydotool key 29:1 42:1 48:1 48:0 42:0 29:0

		# Finish chromium
		sleep 4 && sudo ydotool key 56:1 62:1 62:0 56:0

		# Update chromium-web-store
		local adjunct="NeverDecaf/chromium-web-store"
		local address="https://api.github.com/repos/$adjunct/releases/latest"
		local version=$(curl -LA "mozilla/5.0" "$address" | jq -r ".tag_name" | tr -d "v")
		update_chromium_extension "https://github.com/$adjunct/releases/download/v$version/Chromium.Web.Store.crx"

		# Update extensions
		update_chromium_extension "bcjindcccaagfpapjjmafapmmgkkhgoa" # json-formatter
		update_chromium_extension "ibplnjkanclpjokhdolnendpplpjiace" # simple-translate
		update_chromium_extension "mnjggcdmjocbbbhaepdhchncahnbgone" # sponsorblock-for-youtube
		update_chromium_extension "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock-origin
	fi

	# Update bypass-paywalls-chrome-clean
	local address="https://gitlab.com/magnolia1234/bypass-paywalls-chrome-clean"
	local address="$address/-/archive/master/bypass-paywalls-chrome-clean-master.zip"
	update_chromium_extension "$address"

}

update_chromium_extension() {

	# Handle parameters
	local payload=${1}

	# Update dependencies
	sudo pacman -S --needed --noconfirm curl libarchive ydotool

	# Update extension
	if [[ -x $(command -v chromium) ]]; then
		pkill chromium
		if [[ "$payload" == http* ]]; then
			local address="$payload"
			local package="$(mktemp -d)/$(basename "$address")"
		else
			local version=$(chromium --product-version)
			local address="https://clients2.google.com/service/update2/crx?response=redirect&acceptformat=crx2,crx3"
			local address="${address}&prodversion=${version}&x=id%3D${payload}%26installsource%3Dondemand%26uc"
			local package="$(mktemp -d)/$payload.crx"
		fi
		curl -LA "mozilla/5.0" "$address" -o "$package" || return 1
		if [[ "$package" == *.zip ]]; then
			local deposit="$HOME/.config/chromium/Unpacked/$(echo "$payload" | cut -d / -f5)"
			local present=$([[ -d "$deposit" ]] && echo "true" || echo "false")
			mkdir -p "$deposit"
			bsdtar -zxf "$package" -C "$deposit" --strip-components=1 || return 1
			[[ "$present" == "true" ]] && return 0
			sleep 2 && (sudo ydotoold &) &>/dev/null
			sleep 2 && (chromium --lang=en --start-maximized &) &>/dev/null
			sleep 4 && sudo ydotool key 29:1 38:1 38:0 29:0
			sleep 2 && sudo ydotool type "chrome://extensions/" && sleep 2 && sudo ydotool key 28:1 28:0
			sleep 2 && sudo ydotool key 15:1 15:0 && sleep 2 && sudo ydotool key 28:1 28:0
			sleep 2 && sudo ydotool key 15:1 15:0 && sleep 2 && sudo ydotool key 28:1 28:0
			sleep 2 && sudo ydotool type "$deposit" && sleep 2 && sudo ydotool key 28:1 28:0
			sleep 2 && sudo ydotool key 15:1 15:0 && sleep 2 && sudo ydotool key 28:1 28:0
			sleep 2 && sudo ydotool key 56:1 62:1 62:0 56:0
			sleep 2 && (chromium --lang=en --start-maximized &) &>/dev/null
			sleep 4 && sudo ydotool key 29:1 38:1 38:0 29:0
			sleep 2 && sudo ydotool type "chrome://extensions/" && sleep 2 && sudo ydotool key 28:1 28:0
			sleep 2 && sudo ydotool key 15:1 15:0 && sleep 2 && sudo ydotool key 28:1 28:0
			sleep 2 && sudo ydotool key 56:1 62:1 62:0 56:0
		else
			sleep 1 && (sudo ydotoold &) &>/dev/null
			sleep 1 && (chromium --lang=en --start-maximized "$package" &) &>/dev/null
			sleep 4 && sudo ydotool key 108:1 108:0 && sleep 1 && sudo ydotool key 28:1 28:0
			sleep 2 && sudo ydotool key 56:1 62:1 62:0 56:0
		fi
	fi

}

update_git() {

	# Handle parameters
	local default=${1:-main}
	local gituser=${2}
	local gitmail=${3}

	# Update package
	sudo pacman -S --needed --noconfirm git github-cli

	# Change settings
	git config --global http.postBuffer 1048576000
	git config --global init.defaultBranch "$default"
	if [[ -n "$gitmail" ]]; then git config --global user.email "$gitmail"; fi
	if [[ -n "$gituser" ]]; then git config --global user.name "$gituser"; fi

}

update_hashcat() {

	# Update dependencies
	if [[ $(lspci | grep -e VGA) == *"GeForce"* ]]; then sudo pacman -S --needed --noconfirm opencl-nvidia; fi

	# Update package
	sudo pacman -S --needed --noconfirm hashcat

}

update_jdownloader() {

	# Handle parameters
	local deposit=${1:-$HOME/Downloads/JD2}

	# Update dependencies
	sudo pacman -S --needed --noconfirm jdk-openjdk jq moreutils

	# Update package
	local present=$([[ -n $(pacman -Q | grep jdownloader2) ]] && echo "true" || echo "false")
	yay -S --needed --noconfirm jdownloader2

	# Finish installation
	if [[ "$present" == "false" ]]; then
		local appdata="$HOME/.jd/cfg"
		local config1="$appdata/org.jdownloader.settings.GraphicalUserInterfaceSettings.json"
		local config2="$appdata/org.jdownloader.settings.GeneralSettings.json"
		local config3="$appdata/org.jdownloader.gui.jdtrayicon.TrayExtension.json"
		local config4="$appdata/org.jdownloader.extensions.extraction.ExtractionExtension.json"
		(jdownloader >/dev/null 2>&1 &) && sleep 4
		while [[ ! -f "$config1" ]]; do sleep 2; done && pkill java && sleep 4
		jq ".bannerenabled = false" "$config1" | sponge "$config1"
		jq ".clipboardmonitored = false" "$config1" | sponge "$config1"
		jq ".donatebuttonlatestautochange = 4102444800000" "$config1" | sponge "$config1"
		jq ".donatebuttonstate = \"AUTO_HIDDEN\"" "$config1" | sponge "$config1"
		jq ".myjdownloaderviewvisible = false" "$config1" | sponge "$config1"
		jq ".premiumalertetacolumnenabled = false" "$config1" | sponge "$config1"
		jq ".premiumalertspeedcolumnenabled = false" "$config1" | sponge "$config1"
		jq ".premiumalerttaskcolumnenabled = false" "$config1" | sponge "$config1"
		jq ".specialdealoboomdialogvisibleonstartup = false" "$config1" | sponge "$config1"
		jq ".specialdealsenabled = false" "$config1" | sponge "$config1"
		jq ".speedmetervisible = false" "$config1" | sponge "$config1"
		mkdir -p "$deposit" && jq ".defaultdownloadfolder = \"$deposit\"" "$config2" | sponge "$config2"
		jq ".enabled = false" "$config3" | sponge "$config3"
		jq ".enabled = false" "$config4" | sponge "$config4"
		update_chromium_extension "fbcohnmimjicjdomonkcbcpbpnhggkip" # myjdownloader-browser-ext
	fi

}

update_keepassxc() {

	# Update package
	sudo pacman -S --needed --noconfirm keepassxc

}

update_lutris() {

	# Update dependencies
	if [[ $(lspci | grep -e VGA) == *"GeForce"* ]]; then
		sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader
	fi

	# Update package
	sudo pacman -S --needed --noconfirm lutris

}

update_pycharm_professional() {

	# Update package
	local present=$([[ -n $(pacman -Q | grep pycharm-professional) ]] && echo "true" || echo "false")
	yay -S --needed --noconfirm pycharm-professional

}

update_quickemu() {

	# Update package
	yay -S --needed --noconfirm quickemu

}

update_system() {

	# Handle parameters
	local country=${1:-Europe/Brussels}
	local machine=${2:-archogen}

	# Change hostname
	hostnamectl hostname "$machine"

	# Change timezone
	sudo unlink "/etc/localtime"
	sudo ln -s "/usr/share/zoneinfo/$country" "/etc/localtime"

	# Update firmware
	# sudo pacman -S --needed --noconfirm fwupd
	# sudo fwupdmgr get-devices
	# sudo fwupdmgr refresh --force
	# sudo fwupdmgr get-updates
	# sudo fwupdmgr update -y

	# Update system
	sudo pacman -Syyu --noconfirm

	# Reboot if latest reboot was done less than three minutes ago
	local current=$(date -d "$(uptime --since)" +"%s")
	local maximum=$(date -d "1 minutes ago" +"%s")
	local correct=$([[ $maximum -lt $current ]] && echo "false" || echo "true")
	# local correct="true"
	if [[ $correct == "true" ]]; then invoke_restart; fi

}

update_tinymediamanager() {

	# Update package
	yay -S --needed --noconfirm tiny-media-manager

}

update_vmware_workstation() {

	# Handle parameters
	local deposit=${1:-$HOME/Machines}
	local serials=${2:-MC60H-DWHD5-H80U9-6V85M-8280D}

	# Update package
	local present=$([[ -n $(pacman -Q | grep vmware-workstation) ]] && echo "true" || echo "false")
	yay -S --needed --noconfirm vmware-workstation

	# Launch modules
	sudo modprobe -a vmw_vmci vmmon

	# Enable services
	sudo systemctl enable --now vmware-networks.service
	sudo systemctl enable --now vmware-usbarbitrator.service

	# Change serials
	sudo /usr/lib/vmware/bin/vmware-vmx-debug --new-sn "$serials"

	# Change settings
	if [[ "$present" == "false" ]]; then
		local configs="$HOME/.vmware/preferences"
		(vmware >/dev/null 2>&1 &) && sleep 4
		while [[ ! -f "$configs" ]]; do sleep 2; done && pkill vmware && sleep 4
		if ! grep -q "prefvmx.defaultVMPath" "$configs" 2>/dev/null; then
			mkdir -p "$deposit"
			echo "prefvmx.defaultVMPath = \"$deposit\"" >>"$configs"
		fi
	fi

	# Update unlocker
	yay -S --needed --noconfirm vmware-unlocker-bin

}

update_vscode() {

	# Update dependencies
	sudo pacman -S --needed --noconfirm jq moreutils otf-cascadia-code

	# Update package
	yay -S --needed --noconfirm visual-studio-code-bin

	# Update extensions
	update_vscode_extension "bierner.markdown-preview-github-styles"
	update_vscode_extension "foxundermoon.shell-format"
	update_vscode_extension "github.github-vscode-theme"

	# Change settings
	configs="$HOME/.config/Code/User/settings.json"
	[[ -s "$configs" ]] || echo "{}" >"$configs"
	jq '."editor.fontFamily" = "Cascadia Code, monospace"' "$configs" | sponge "$configs"
	jq '."editor.fontSize" = 13' "$configs" | sponge "$configs"
	jq '."editor.lineHeight" = 35' "$configs" | sponge "$configs"
	jq '."security.workspace.trust.enabled" = false' "$configs" | sponge "$configs"
	jq '."telemetry.telemetryLevel" = "crash"' "$configs" | sponge "$configs"
	jq '."update.mode" = "none"' "$configs" | sponge "$configs"
	jq '."window.menuBarVisibility" = "toggle"' "$configs" | sponge "$configs"
	jq '."workbench.colorTheme" = "GitHub Dark Default"' "$configs" | sponge "$configs"

}

update_vscode_extension() {

	# Handle parameters
	local payload=${1}

	# Update extension
	code --install-extension "$payload" --force &>/dev/null || true

}

update_waydroid() {

	# Update dependencies
	if [[ "$XDG_SESSION_TYPE" == "x11" ]]; then sudo pacman -S --needed --noconfirm weston; fi

	# Update package
	yay -S --needed --noconfirm binder_linux-dkms waydroid waydroid-image-gapps
	sudo waydroid init -s GAPPS -f

	# Enable services
	sudo systemctl enable --now waydroid-container.service

	# Change desktop
	# local rootdir="$HOME/.local/share/applications"

}

update_wireshark() {

	# Update package
	sudo pacman -S --needed --noconfirm wireshark-qt

}

update_woeusb_ng() {

	# Update package
	yay -S --needed --noconfirm woeusb-ng

}

main() {

	clear

	# Prompt password
	# sudo -v && clear

	# Remove timeouts
	echo "Defaults timestamp_timeout=-1" | sudo tee "/etc/sudoers.d/disable_timeout" &>/dev/null
	# sudo sed -i "s/# %sudo.*ALL=.*/%sudo ALL=(ALL) NOPASSWD:ALL/" "/etc/sudoers"
	echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee -a "/etc/sudoers" &>/dev/null

	# Change headline
	printf "\033]0;%s\007" "archogen"

	# Output greeting
	read -r -d "" welcome <<-EOD
		░█████╗░██████╗░░█████╗░██╗░░██╗░█████╗░░██████╗░███████╗███╗░░██╗
		██╔══██╗██╔══██╗██╔══██╗██║░░██║██╔══██╗██╔════╝░██╔════╝████╗░██║
		███████║██████╔╝██║░░╚═╝███████║██║░░██║██║░░██╗░█████╗░░██╔██╗██║
		██╔══██║██╔══██╗██║░░██╗██╔══██║██║░░██║██║░░╚██╗██╔══╝░░██║╚████║
		██║░░██║██║░░██║╚█████╔╝██║░░██║╚█████╔╝╚██████╔╝███████╗██║░╚███║
		╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝░╚════╝░░╚═════╝░╚══════╝╚═╝░░╚══╝
	EOD
	printf "\n\033[92m%s\033[00m\n\n" "$welcome"

	# Remove sleeping
	gsettings set org.gnome.desktop.notifications show-banners false
	gsettings set org.gnome.desktop.screensaver lock-enabled false
	gsettings set org.gnome.desktop.session idle-delay 0

	# Remove rebooter
	sudo sed -i "s/AutomaticLoginEnable=.*/AutomaticLoginEnable=False/" "/etc/gdm/custom.conf"
	rm -f "$HOME/.config/autostart/invoke_restart.desktop"

	# Handle elements
	members=(
		# "update_appearance"
		"update_system 'Europe/Brussels' 'archogen'"
		"update_git 'main' 'sharpordie' '72373746+sharpordie@users.noreply.github.com'"
		"update_chromium"
		# "update_vscode"
		# "update_hashcat"
		# "update_lutris"
		# "update_jdownloader"
		# "update_keepassxc"
		# "update_pycharm_professional"
		# "update_tinymediamanager"
		# "update_vmware_workstation"
		# "update_waydroid"
		# "update_wireshark"
		# "update_woeusb_ng"
	)

	# Output progress
	maximum=$((${#welcome} / $(echo "$welcome" | wc -l)))
	heading="\r%-"$((maximum - 20))"s   %-6s   %-8s\n\n"
	loading="\r%-"$((maximum - 20))"s   \033[93mACTIVE\033[0m   %-8s\b"
	failure="\r%-"$((maximum - 20))"s   \033[91mFAILED\033[0m   %-8s\n"
	success="\r%-"$((maximum - 20))"s   \033[92mWORKED\033[0m   %-8s\n"
	printf "$heading" "FUNCTION" "STATUS" "DURATION"
	for element in "${members[@]}"; do
		written=$(basename "$(echo "$element" | cut -d ' ' -f 1)" | tr "[:lower:]" "[:upper:]")
		started=$(date +"%s") && printf "$loading" "$written" "--:--:--"
		eval "$element" >/dev/null 2>&1 && current="$success" || current="$failure"
		extinct=$(date +"%s") && elapsed=$((extinct - started))
		elapsed=$(printf "%02d:%02d:%02d\n" $((elapsed / 3600)) $(((elapsed % 3600) / 60)) $((elapsed % 60)))
		printf "$current" "$written" "$elapsed"
	done

	# Revert sleeping
	gsettings set org.gnome.desktop.notifications show-banners true
	gsettings set org.gnome.desktop.screensaver lock-enabled true
	gsettings set org.gnome.desktop.session idle-delay 300

	# Revert timeouts
	sudo rm "/etc/sudoers.d/disable_timeout"
	# sudo sed -i "s/%sudo.*ALL=.*/# %sudo ALL=(ALL:ALL) ALL/" "/etc/sudoers"
	sudo sed -i "s/$USER ALL=.*$//" "/etc/sudoers"

	# Output new line
	printf "\n" && sleep 30

}

main
