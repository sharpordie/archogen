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
	git config --global core.autocrlf true
	if [[ -n "$gitmail" ]]; then git config --global user.email "$gitmail"; fi
	if [[ -n "$gituser" ]]; then git config --global user.name "$gituser"; fi

}

update_kdenlive() {

	# Update package
	sudo pacman -S --needed --noconfirm kdenlive

}

update_keepassxc() {

	# Update package
	sudo pacman -S --needed --noconfirm keepassxc

}

update_kid3() {

	# Update package
	sudo pacman -S --needed --noconfirm kid3

}

update_krita() {

	# Update package
	sudo pacman -S --needed --noconfirm krita krita-plugin-gmic

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

	# Create associations
	xdg-mime default mpv.desktop video/mp4
	xdg-mime default mpv.desktop video/mpeg
	xdg-mime default mpv.desktop video/ogg
	xdg-mime default mpv.desktop video/quicktime
	xdg-mime default mpv.desktop video/webm
	xdg-mime default mpv.desktop video/x-flv
	xdg-mime default mpv.desktop video/x-matroska
	xdg-mime default mpv.desktop video/x-ms-wmv
	xdg-mime default mpv.desktop video/x-msvideo

}

update_obs_studio() {

	# Update package
	sudo pacman -S --needed --noconfirm obs-studio

}

update_plasma() {

	# Change background
	configs="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
	address="https://raw.githubusercontent.com/sharpordie/andpaper/main/src/android-higher-darker.png"
	picture="$HOME/Pictures/Backgrounds/$(basename "$address")"
	mkdir -p "$(dirname $picture)" && curl -L "$address" -o "$picture"
	kwriteconfig5 --file "$configs" --group "Containments" --group "1" --group "Wallpaper" --group "org.kde.image" --group "General" --key "Image" "file://$picture"
	plasmashell --replace >/dev/null 2>&1 & 

	# Change icon theme
	local configs="$HOME/.config/kdeglobals"
	sudo pacman -S --needed --noconfirm papirus-icon-theme
	yay -S --needed --noconfirm papirus-folders
	kwriteconfig5 --file "$configs" --group Icons --key Theme "Papirus"
	sudo papirus-folders --color blue --theme Papirus

	# Change global theme
	plasma-apply-colorscheme BreezeLight
	plasma-apply-desktoptheme breeze-light
	plasma-apply-lookandfeel -a org.kde.breeze.desktop

	# Enable night color
	local configs="$HOME/.config/kwinrc"
	kwriteconfig5 --file "$configs" --group NightColor --key Active "true"
	kwriteconfig5 --file "$configs" --group NightColor --key Mode "Constant"
	kwriteconfig5 --file "$configs" --group NightColor --key NightTemperature "4000"

	# Remove kwallet
	# kwriteconfig5 --file kwalletrc --group "Wallet" --key "Enabled" "false"
	# kwriteconfig5 --file kwalletrc --group "Wallet" --key "First Use" "false"

	# Remove single click
	local configs="$HOME/.config/kdeglobals"
	kwriteconfig5 --file "$configs" --group "KDE" --key "SingleClick" "false"

}

update_scrcpy() {

	# Update package
	sudo pacman -S --needed --noconfirm scrcpy

}

update_system() {

	# Handle parameters
	local country=${1:-Europe/Brussels}

	# Change timezone
	sudo unlink "/etc/localtime"
	sudo ln -s "/usr/share/zoneinfo/$country" "/etc/localtime"

	# Update fonts
	sudo pacman -S --needed --noconfirm noto-fonts-emoji

	# Update firmware
	sudo pacman -S --needed --noconfirm fwupd
	sudo fwupdmgr get-devices -y
	sudo fwupdmgr refresh --force
	sudo fwupdmgr get-updates -y
	sudo fwupdmgr refresh --force
	sudo fwupdmgr update -y

	# Update system
	sudo pacman -Syyu --noconfirm

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
	jq '."workbench.colorTheme" = "GitHub Light Default"' "$configs" | sponge "$configs"

}

update_vscode_extension() {

	# Handle parameters
	local payload=${1}

	# Update extension
	code --install-extension "$payload" --force &>/dev/null || true

}

update_wireshark() {

	# Update package
	sudo pacman -S --needed --noconfirm wireshark-qt

}

update_git 'main' 'sharpordie' '72373746+sharpordie@users.noreply.github.com'