#!/usr/bin/env bash

invoke_restart() {

	# Ensure gnome session
	[[ "$XDG_SESSION_DESKTOP" == "gnome" ]] || return 1

	# TODO: Handle gnome keyring dialog with automatic login
	# Enable automatic login
	# local configs="/etc/gdm/custom.conf"
	# local pattern="AutomaticLogin="
	# local payload="s/AutomaticLoginEnable=.*/AutomaticLoginEnable=True\nAutomaticLogin=$USER/"
	# if ! grep -q "$pattern" "$configs" 2>/dev/null; then sudo sed -i "$payload" "$configs"; fi
	# sudo sed -i "s/AutomaticLoginEnable=.*/AutomaticLoginEnable=True/" "$configs"
	# sudo sed -i "s/AutomaticLogin=.*/AutomaticLogin=$USER/" "$configs"

	# Create startup desktop
	local deposit=$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)
	local current=$(readlink -f "${BASH_SOURCE[0]}")
	local startup="$HOME/.config/autostart/invoke_restart.desktop"
	mkdir -p "$(dirname $startup)" && rm -f "$startup" &>/dev/null
	echo "[Desktop Entry]" >>"$startup"
	echo "Type=Application" >>"$startup"
	echo "Exec=/usr/bin/kgx --command \"/bin/bash '$current'\" --wait" >>"$startup"
	echo "Hidden=false" >>"$startup"
	echo "X-GNOME-Autostart-enabled=true" >>"$startup"
	echo "Name=archogen" >>"$startup"

	# Reboot system
	sudo reboot --force

}

update_android_cmdline() {

	# Update dependencies
	sudo pacman -S --needed --noconfirm curl jdk-openjdk

	# Update package
	local sdkroot="$HOME/Android/Sdk"
	local deposit="$sdkroot/cmdline-tools"
	if [[ ! -d "$deposit" ]]; then
		! grep -q "Android" "$HOME/.hidden" 2>/dev/null && echo "Android" >>"$HOME/.hidden"
		local address="https://developer.android.com/studio#command-tools"
		local version="$(curl -s "$address" | grep -oP "commandlinetools-linux-\K(\d+)" | head -1)"
		local address="https://dl.google.com/android/repository/commandlinetools-linux-${version}_latest.zip"
		local archive="$(mktemp -d)/$(basename "$address")"
		curl -LA "mozilla/5.0" "$address" -o "$archive"
		mkdir -p "$deposit" && unzip -d "$deposit" "$archive"
		yes | "$deposit/cmdline-tools/bin/sdkmanager" --sdk_root="$sdkroot" "cmdline-tools;latest"
		rm -rf "$deposit/cmdline-tools"
	fi

	# Change environment
	local configs="$HOME/.bashrc"
	if ! grep -q "ANDROID_HOME" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >>"$configs"
		echo 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"' >>"$configs"
		echo 'export PATH="$PATH:$ANDROID_HOME/emulator"' >>"$configs"
		echo 'export PATH="$PATH:$ANDROID_HOME/platform-tools"' >>"$configs"
		export ANDROID_HOME="$HOME/Android/Sdk"
		export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
		export PATH="$PATH:$ANDROID_HOME/emulator"
		export PATH="$PATH:$ANDROID_HOME/platform-tools"
	fi

}

update_android_studio() {

	# Update package
	local present=$([[ -n $(pacman -Q | grep android-studio) ]] && echo "true" || echo "false")
	yay -S --needed --noconfirm android-studio

	# Finish installation
	if [[ "$present" == "false" ]]; then
		update_android_cmdline
		yes | sdkmanager "build-tools;33.0.2"
		yes | sdkmanager "emulator"
		yes | sdkmanager "patcher;v4"
		yes | sdkmanager "platform-tools"
		yes | sdkmanager "platforms;android-33"
		yes | sdkmanager "platforms;android-33-ext5"
		yes | sdkmanager "sources;android-33"
		yes | sdkmanager "system-images;android-33;google_apis;x86_64"
		yes | sdkmanager --licenses
		yes | sdkmanager --update
	fi

}

update_appearance() {

	# Enable night light
	gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
	gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 0
	gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 0
	gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000

	# Change gtk theme
	gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
	gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
	gsettings set org.gnome.desktop.wm.preferences theme "Adwaita-dark"

	# Change backgrounds
	yay -S --needed --noconfirm gdm-tools
	local address="https://raw.githubusercontent.com/sharpordie/andpaper/main/src/android-bottom-darker.png"
	local picture="$HOME/Pictures/Backgrounds/$(basename "$address")"
	mkdir -p "$(dirname $picture)" && curl -L "$address" -o "$picture"
	set-gdm-theme -s default "$picture"
	gsettings set org.gnome.desktop.background picture-options "zoom"
	gsettings set org.gnome.desktop.background picture-uri-dark "file://$picture"
	gsettings set org.gnome.desktop.screensaver picture-options "zoom"
	gsettings set org.gnome.desktop.screensaver picture-uri "file://$picture"

	# Enable just-perfection extension
	yay -S --needed --noconfirm gnome-shell-extension-just-perfection-desktop
	local factors=$(gsettings get org.gnome.shell enabled-extensions)
	[[ $factors == "@as []" ]] && gsettings set org.gnome.shell enabled-extensions "['just-perfection-desktop@just-perfection']"
	local factors=$(gsettings get org.gnome.shell enabled-extensions)
	local enabled=$([[ $factors == *"'just-perfection-desktop@just-perfection'"* ]] && echo "true" || echo "false")
	[[ $enabled == "false" ]] && gsettings set org.gnome.shell enabled-extensions "${factors%]*}, 'just-perfection-desktop@just-perfection']"
	dconf write /org/gnome/shell/disable-user-extensions false
	dconf reset -f /org/gnome/shell/extensions/just-perfection/app-menu
	dconf write /org/gnome/shell/extensions/just-perfection/app-menu false
	dconf write /org/gnome/shell/extensions/just-perfection/background-menu false
	dconf write /org/gnome/shell/extensions/just-perfection/startup-status 0
	dconf write /org/gnome/shell/extensions/just-perfection/window-demands-attention-focus true

	# Change icon theme
	sudo pacman -S --needed --noconfirm papirus-icon-theme
	yay -S --needed --noconfirm papirus-folders
	gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
	sudo papirus-folders --color blue --theme Papirus-Dark

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

	# Change button layout
	gsettings set org.gnome.desktop.wm.preferences button-layout ":minimize,maximize,close"

	# Remove event sounds
	gsettings set org.gnome.desktop.sound event-sounds false

	# Remove favorite apps
	gsettings set org.gnome.shell favorite-apps "[]"

	# Change look for qt apps
	sudo pacman -S --needed --noconfirm kvantum
	sudo sed -i "s/#QT_QPA_PLATFORMTHEME=.*/QT_QPA_PLATFORMTHEME=qt5ct/" "/etc/environment"
	sudo sed -i "s/#QT_STYLE_OVERRIDE.*/QT_STYLE_OVERRIDE=kvantum/" "/etc/environment"
	sudo sed -i "s/QT_QPA_PLATFORMTHEME=.*/QT_QPA_PLATFORMTHEME=qt5ct/" "/etc/environment"
	sudo sed -i "s/QT_STYLE_OVERRIDE.*/QT_STYLE_OVERRIDE=kvantum/" "/etc/environment"
	kvantummanager --set KvGnomeDark

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
	sudo sed -i "s/BROWSER=.*/BROWSER=chromium/" "/etc/environment"

	# Change environment
	local configs="$HOME/.bashrc"
	if ! grep -q "CHROME_EXECUTABLE" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'export CHROME_EXECUTABLE="/usr/bin/chromium"' >>"$configs"
		export CHROME_EXECUTABLE="/usr/bin/chromium"
	fi

	# Finish installation
	if [[ "$present" == "false" ]]; then
		# Launch chromium
		sleep 1 && (sudo ydotoold &) &>/dev/null
		sleep 1 && (chromium --lang=en --start-maximized &) &>/dev/null
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

		# Change search engine
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://settings/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "search engines" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 3); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "duckduckgo" && sleep 1 && sudo ydotool key 28:1 28:0

		# Change custom-ntp flag
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "custom-ntp" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 5); do sleep 0.5 && sudo ydotool key 15:1 15:0; done
		sleep 1 && sudo ydotool key 29:1 30:1 30:0 29:0 && sleep 1 && sudo ydotool type "$startup"
		sleep 1 && for i in $(seq 1 2); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 108:1 108:0 && sleep 1 && sudo ydotool key 28:1 28:0

		# Change disable-sharing-hub flag
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "disable-sharing-hub" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 6); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 108:1 108:0 && sleep 1 && sudo ydotool key 28:1 28:0

		# Change extension-mime-request-handling flag
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "extension-mime-request-handling" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 6); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 2); do sleep 0.5 && sudo ydotool key 108:1 108:0; done && sleep 1 && sudo ydotool key 28:1 28:0

		# Change hide-sidepanel-button flag
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "hide-sidepanel-button" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 6); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 108:1 108:0 && sleep 1 && sudo ydotool key 28:1 28:0

		# Change remove-tabsearch-button flag
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "remove-tabsearch-button" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 6); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool key 108:1 108:0 && sleep 1 && sudo ydotool key 28:1 28:0

		# Change show-avatar-button flag
		sleep 1 && sudo ydotool key 29:1 38:1 38:0 29:0
		sleep 1 && sudo ydotool type "chrome://flags/" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && sudo ydotool type "show-avatar-button" && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 6); do sleep 0.5 && sudo ydotool key 15:1 15:0; done && sleep 1 && sudo ydotool key 28:1 28:0
		sleep 1 && for i in $(seq 1 3); do sleep 0.5 && sudo ydotool key 108:1 108:0; done && sleep 1 && sudo ydotool key 28:1 28:0

		# Toggle bookmark bar
		sleep 4 && sudo ydotool key 29:1 42:1 48:1 48:0 42:0 29:0

		# Finish chromium
		sleep 4 && sudo ydotool key 56:1 62:1 62:0 56:0

		# Update chromium-web-store extension
		local adjunct="NeverDecaf/chromium-web-store"
		local address="https://api.github.com/repos/$adjunct/releases/latest"
		local version=$(curl -LA "mozilla/5.0" "$address" | jq -r ".tag_name" | tr -d "v")
		update_chromium_extension "https://github.com/$adjunct/releases/download/v$version/Chromium.Web.Store.crx"

		# Update some extensions
		update_chromium_extension "bcjindcccaagfpapjjmafapmmgkkhgoa" # json-formatter
		update_chromium_extension "ibplnjkanclpjokhdolnendpplpjiace" # simple-translate
		update_chromium_extension "mnjggcdmjocbbbhaepdhchncahnbgone" # sponsorblock-for-youtube
		update_chromium_extension "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock-origin
	fi

	# Update bypass-paywalls-chrome-clean extension
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
			sleep 4 && sudo ydotool key 56:1 62:1 62:0 56:0
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

update_flutter() {

	# Update dependencies
	sudo pacman -S --needed --noconfirm git clang cmake ninja

	# Update package
	local deposit="$HOME/Android/Flutter" && mkdir -p "$deposit"
	git clone "https://github.com/flutter/flutter.git" -b stable "$deposit"

	# Change environment
	local configs="$HOME/.bashrc"
	if ! grep -q "Flutter" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'export PATH="$PATH:$HOME/Android/Flutter/bin"' >>"$configs"
		export PATH="$PATH:$HOME/Android/Flutter/bin"
	fi

	# Finish installation
	flutter channel stable
	flutter upgrade
	dart --disable-analytics
	flutter config --no-analytics
	yes | flutter doctor --android-licenses

	# Update android-studio plugins
	local product=$(find /opt/android-* -maxdepth 0 2>/dev/null | sort -r | head -1)
	update_jetbrains_plugin "$product" "6351"  # dart
	update_jetbrains_plugin "$product" "9212"  # flutter
	update_jetbrains_plugin "$product" "13666" # flutter-intl
	update_jetbrains_plugin "$product" "14641" # flutter-riverpod-snippets

	# Update vscode extensions
	update_vscode_extension "alexisvt.flutter-snippets"
	update_vscode_extension "dart-code.flutter"
	update_vscode_extension "pflannery.vscode-versionlens"
	update_vscode_extension "RichardCoutts.mvvm-plus"
	update_vscode_extension "robert-brunhage.flutter-riverpod-snippets"
	update_vscode_extension "usernamehw.errorlens"

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

update_jetbra() {

	# Forced to omit download for copyright reasons.
	# Please download the archive from jetbra.in/s manually.
	# Search ja-netfilter.jar and zhile.io for more information.
	local archive=${1:-/tmp/jetbra.zip}
	local deposit=${2:-/$HOME/.jetbra}

	if [[ -f "$archive" ]]; then return 0; fi

}

update_jetbrains_plugin() {

	# Handle parameters
	local deposit=${1:-/opt/android-studio}
	local element=${2}

	# Update dependencies
	[[ -d "$deposit" && -n "$element" ]] || return 0
	sudo pacman -S --needed --noconfirm curl dpkg jq

	# Update plugin
	local release=$(cat "$deposit/product-info.json" | jq -r ".buildNumber" | grep -oP "(\d.+)")
	local datadir=$(cat "$deposit/product-info.json" | jq -r ".dataDirectoryName")
	local adjunct=$([[ $datadir == "AndroidStudio"* ]] && echo "Google/$datadir" || echo "JetBrains/$datadir")
	local plugins="$HOME/.local/share/$adjunct" && mkdir -p "$plugins"
	for i in {1..3}; do
		for j in {0..19}; do
			local address="https://plugins.jetbrains.com/api/plugins/$element/updates?page=$i"
			local maximum=$(curl -s "$address" | jq ".[$j].until" | tr -d '"' | sed "s/\.\*/\.9999/")
			local minimum=$(curl -s "$address" | jq ".[$j].since" | tr -d '"' | sed "s/\.\*/\.9999/")
			if dpkg --compare-versions "${minimum:-0000}" "le" "$release" && dpkg --compare-versions "$release" "le" "${maximum:-9999}"; then
				local address=$(curl -s "$address" | jq ".[$j].file" | tr -d '"')
				local address="https://plugins.jetbrains.com/files/$address"
				local archive="$(mktemp -d)/$(basename "$address")"
				curl -LA "mozilla/5.0" "$address" -o "$archive"
				unzip -o "$archive" -d "$plugins"
				break 2
			fi
			sleep 1
		done
	done

}

update_keepassxc() {

	# Update package
	sudo pacman -S --needed --noconfirm keepassxc

}

update_kid3() {

	# Update package
	sudo pacman -S --needed --noconfirm kid3

}

update_losslesscut() {

	# Update package
	yay -S --needed --noconfirm losslesscut-bin

}

update_lutris() {

	# Update dependencies
	if [[ $(lspci | grep -e VGA) == *"GeForce"* ]]; then
		sudo pacman -S --needed --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader
	fi

	# Update package
	sudo pacman -S --needed --noconfirm lutris

}

update_mambaforge() {

	# Handle parameters
	local deposit=${1:-$HOME/.mambaforge}

	# Update dependencies
	sudo pacman -S --needed --noconfirm curl

	# Update package
	local present=$([[ -x "$(which mamba)" ]] && echo "true" || echo "false")
	if [[ "$present" == "false" ]]; then
		local address="https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"
		local fetched="$(mktemp -d)/$(basename "$address")"
		curl -L "$address" -o "$fetched" && sh "$fetched" -b -p "$deposit"
	fi

	# Change environment
	"$deposit/condabin/conda" init

	# Change settings
	"$deposit/condabin/conda" config --set auto_activate_base false

}

update_mkvtoolnix() {

	# Update dependencies
	sudo pacman -S --needed --noconfirm boost-libs

	# Update package
	sudo pacman -S --needed --noconfirm mkvtoolnix-gui

}

update_mpv() {

	# Update package
	sudo pacman -S --needed --noconfirm mpv

	# Create mpv.conf
	local configs="$HOME/.config/mpv/mpv.conf"
	mkdir -p "$(dirname "$configs")" && cat /dev/null >"$configs"
	echo "profile=gpu-hq" >>"$configs"
	echo "vo=gpu-next" >>"$configs"
	echo "keep-open=yes" >>"$configs"
	echo 'ytdl-format="bestvideo[height<=?2160]+bestaudio/best"' >>"$configs"
	echo "[protocol.http]" >>"$configs"
	echo "force-window=immediate" >>"$configs"
	echo "[protocol.https]" >>"$configs"
	echo "profile=protocol.http" >>"$configs"
	echo "[protocol.ytdl]" >>"$configs"
	echo "profile=protocol.http" >>"$configs"

	# Create input.conf
	local configs="$HOME/.config/mpv/input.conf"
	mkdir -p "$(dirname "$configs")" && cat /dev/null >"$configs"

}

update_newsflash() {

	# Update package
	sudo pacman -S --needed --noconfirm newsflash

}

update_nodejs() {

	# Update package
	sudo pacman -S --needed --noconfirm nodejs npm

	# Change settings
	npm set audit false

}

update_obs_studio() {

	# Update package
	sudo pacman -S --needed --noconfirm obs-studio

}

update_pycharm_professional() {

	# Update package
	local present=$([[ -n $(pacman -Q | grep pycharm-professional) ]] && echo "true" || echo "false")
	yay -S --needed --noconfirm pycharm-professional

}

update_python() {

	# Update package
	sudo pacman -S --needed --noconfirm python python-poetry

	# Change environment
	local configs="$HOME/.bashrc"
	if ! grep -q "PYTHONDONTWRITEBYTECODE" "$configs" 2>/dev/null; then
		[[ -s "$configs" ]] || touch "$configs"
		[[ -z $(tail -1 "$configs") ]] || echo "" >>"$configs"
		echo 'export PYTHONDONTWRITEBYTECODE=1' >>"$configs"
		export PYTHONDONTWRITEBYTECODE=1
	fi

	# Change settings
	poetry config virtualenvs.in-project true

}

update_quickemu() {

	# Handle parameters
	local deposit=${1:-$HOME/Machines}

	# Update dependencies
	sudo pacman -Rdd --noconfirm qemu-base
	sudo pacman -S --needed --noconfirm qemu-desktop

	# Update package
	yay -S --needed --noconfirm quickemu

	# Create macos monterey vm
	local current=$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)
	mkdir -p "$deposit" && cd "$deposit" && quickget macos monterey
	quickemu --vm macos-monterey.conf --shortcut && cd "$current"
	local desktop="$HOME/.local/share/applications/macos-monterey.desktop"
	sed -i "s/Icon=.*/Icon=distributor-logo-mac/" "$desktop"
	sed -i "s/Name=.*/Name=Monterey/" "$desktop"

	# Create windows 11 vm
	local current=$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)
	mkdir -p "$deposit" && cd "$deposit" && quickget windows 11
	quickemu --vm windows-11.conf --shortcut && cd "$current"
	local desktop="$HOME/.local/share/applications/windows-11.desktop"
	sed -i "s/Icon=.*/Icon=distributor-logo-windows/" "$desktop"
	sed -i "s/Name=.*/Name=Windows/" "$desktop"

}

update_scrcpy() {

	# Update package
	sudo pacman -S --needed --noconfirm scrcpy

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
	sudo pacman -S --needed --noconfirm fwupd
	sudo fwupdmgr get-devices -y
	sudo fwupdmgr refresh --force
	sudo fwupdmgr get-updates -y
	sudo fwupdmgr refresh --force
	sudo fwupdmgr update -y

	# Update system
	sudo pacman -Syyu --noconfirm

	# Handle display bug on first install with some systems
	local already=$([[ -d "$HOME/Downloads/DDL" ]] && echo "true" || echo "false")
	if [[ "$already" == "false" ]]; then mkdir -p "$HOME/Downloads/DDL" && invoke_restart; fi

}

update_tinymediamanager() {

	# Update package
	yay -S --needed --noconfirm tiny-media-manager

}

update_transmission() {

	# Handle parameters
	local deposit=${1:-$HOME/Downloads/P2P}
	local seeding=${2:-0.0}

	# Update dependencies
	sudo pacman -S --needed --noconfirm jq moreutils

	# Update package
	sudo pacman -S --needed --noconfirm transmission-gtk

	# Change settings
	local configs="$HOME/.config/transmission/settings.json"
	mkdir -p "$(dirname "$configs")" "$deposit/Incomplete"
	[[ -s "$configs" ]] || echo "{}" >"$configs"
	jq '."incomplete-dir-enabled" = true' "$configs" | sponge "$configs"
	jq '."ratio-limit-enabled" = true' "$configs" | sponge "$configs"
	jq '."user-has-given-informed-consent" = true' "$configs" | sponge "$configs"
	jq ".\"download-dir\" = \"$deposit\"" "$configs" | sponge "$configs"
	jq ".\"incomplete-dir\" = \"$deposit/Incomplete\"" "$configs" | sponge "$configs"
	jq ".\"ratio-limit\" = $seeding" "$configs" | sponge "$configs"

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

	# Change default editor
	sudo sed -i "s/EDITOR=.*/EDITOR=code/" "/etc/environment"

	# Update extensions
	update_vscode_extension "bierner.markdown-preview-github-styles"
	update_vscode_extension "foxundermoon.shell-format"
	update_vscode_extension "github.github-vscode-theme"

	# Change settings
	local configs="$HOME/.config/Code/User/settings.json"
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

update_yt_dlp() {

	# Update package
	sudo pacman -S --needed --noconfirm yt-dlp

}

main() {

	# Change headline
	clear && printf "\033]0;%s\007" "$(basename "$(readlink -f "${BASH_SOURCE[0]}")")"

	# Remove timeouts
	echo "Defaults timestamp_timeout=-1" | sudo tee "/etc/sudoers.d/disable_timeout" &>/dev/null
	# echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee -a "/etc/sudoers" &>/dev/null

	# Output greeting
	read -r -d "" welcome <<-EOD
		░█████╗░██████╗░░█████╗░██╗░░██╗░█████╗░░██████╗░███████╗███╗░░██╗
		██╔══██╗██╔══██╗██╔══██╗██║░░██║██╔══██╗██╔════╝░██╔════╝████╗░██║
		███████║██████╔╝██║░░╚═╝███████║██║░░██║██║░░██╗░█████╗░░██╔██╗██║
		██╔══██║██╔══██╗██║░░██╗██╔══██║██║░░██║██║░░╚██╗██╔══╝░░██║╚████║
		██║░░██║██║░░██║╚█████╔╝██║░░██║╚█████╔╝╚██████╔╝███████╗██║░╚███║
		╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝░╚════╝░░╚═════╝░╚══════╝╚═╝░░╚══╝
	EOD
	clear && printf "\n\033[92m%s\033[00m\n\n" "$welcome"

	# Remove sleeping
	gsettings set org.gnome.desktop.notifications show-banners false
	gsettings set org.gnome.desktop.screensaver lock-enabled false
	gsettings set org.gnome.desktop.session idle-delay 0

	# Remove rebooter
	rm -f "$HOME/.config/autostart/invoke_restart.desktop"
	# sudo sed -i "s/AutomaticLoginEnable=.*/AutomaticLoginEnable=False/" "/etc/gdm/custom.conf"

	# Handle elements
	local members=(
		"update_appearance"
		"update_system 'Europe/Brussels' 'archogen'"
		"update_android_cmdline"
		"update_android_studio"
		"update_chromium"
		"update_git 'main' 'sharpordie' '72373746+sharpordie@users.noreply.github.com'"
		"update_vscode"
		"update_flutter"
		"update_hashcat"
		"update_kid3"
		"update_losslesscut"
		# "update_lutris"
		"update_jdownloader"
		"update_keepassxc"
		"update_mambaforge"
		"update_mkvtoolnix"
		"update_mpv"
		"update_newsflash"
		"update_nodejs"
		"update_obs_studio"
		"update_pycharm_professional"
		"update_python"
		"update_quickemu"
		"update_scrcpy"
		"update_tinymediamanager"
		"update_transmission"
		# "update_vmware_workstation"
		# "update_waydroid"
		"update_wireshark"
		# "update_woeusb_ng"
		"update_yt_dlp"
	)

	# Output progress
	local maximum=$((${#welcome} / $(echo "$welcome" | wc -l)))
	local heading="\r%-"$((maximum - 20))"s   %-6s   %-8s\n\n"
	local loading="\r%-"$((maximum - 20))"s   \033[93mACTIVE\033[0m   %-8s\b"
	local failure="\r%-"$((maximum - 20))"s   \033[91mFAILED\033[0m   %-8s\n"
	local success="\r%-"$((maximum - 20))"s   \033[92mWORKED\033[0m   %-8s\n"
	printf "$heading" "FUNCTION" "STATUS" "DURATION"
	for element in "${members[@]}"; do
		local written=$(basename "$(echo "$element" | cut -d ' ' -f 1)" | tr "[:lower:]" "[:upper:]")
		local started=$(date +"%s") && printf "$loading" "$written" "--:--:--"
		eval "$element" >/dev/null 2>&1 && current="$success" || current="$failure"
		local extinct=$(date +"%s") && elapsed=$((extinct - started))
		local elapsed=$(printf "%02d:%02d:%02d\n" $((elapsed / 3600)) $(((elapsed % 3600) / 60)) $((elapsed % 60)))
		printf "$current" "$written" "$elapsed"
	done

	# Revert sleeping
	gsettings set org.gnome.desktop.notifications show-banners true
	gsettings set org.gnome.desktop.screensaver lock-enabled true
	gsettings set org.gnome.desktop.session idle-delay 300

	# Revert timeouts
	sudo rm "/etc/sudoers.d/disable_timeout"
	# sudo sed -i "s/$USER ALL=.*$//" "/etc/sudoers"

	# Output new line
	printf "\n"

}

main
