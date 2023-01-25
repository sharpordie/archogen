update_chromium() {

	local deposit=${1:-$HOME/Downloads/DDL}
	local startup=${2:-about:blank}

	sudo pacman -S --needed --noconfirm curl jq ydotool

	local present=$([[ -n $(pacman -Q | grep ungoogled-chromium-bin) ]] && echo "true" || echo "false")
	yay -S --needed --noconfirm ungoogled-chromium-bin

	if [[ "$present" == "false" ]]; then
		break
	fi

	if [[ "$present" == "false" ]]; then
		local adjunct="NeverDecaf/chromium-web-store"
		local address="https://api.github.com/repos/$adjunct/releases/latest"
		local version=$(curl -LA "mozilla/5.0" "$address" | jq -r ".tag_name" | tr -d "v")
		update_chromium_extension "https://github.com/$adjunct/releases/download/v$version/Chromium.Web.Store.crx"
		update_chromium_extension "bcjindcccaagfpapjjmafapmmgkkhgoa" # json-formatter
		update_chromium_extension "ibplnjkanclpjokhdolnendpplpjiace" # simple-translate
		update_chromium_extension "mnjggcdmjocbbbhaepdhchncahnbgone" # sponsorblock-for-youtube
		update_chromium_extension "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock-origin
	fi

	local address="https://gitlab.com/magnolia1234/bypass-paywalls-chrome-clean"
	local address="$address/-/archive/master/bypass-paywalls-chrome-clean-master.zip"
	update_chromium_extension "$address"

}

update_chromium_extension() {

	local payload=${1}

	sudo pacman -S --needed --noconfirm curl libarchive ydotool

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

	local default=${1:-main}
	local gituser=${2}
	local gitmail=${3}

	sudo pacman -S --needed --noconfirm git github-cli

	git config --global http.postBuffer 1048576000
	git config --global init.defaultBranch "$default"
	if [[ -n "$gitmail" ]]; then git config --global user.email "$gitmail"; fi
	if [[ -n "$gituser" ]]; then git config --global user.name "$gituser"; fi

}

update_hashcat() {

	sudo pacman -S --needed --noconfirm hashcat

	if [[ $(lspci | grep -e VGA) == *"GeForce"* ]]; then sudo pacman -S --needed --noconfirm opencl-nvidia; fi

}

update_jdownloader() {

	local deposit=${1:-$HOME/Downloads/JD2}

	sudo pacman -S --needed --noconfirm jdk-openjdk jq moreutils

	local present=$([[ -n $(pacman -Q | grep jdownloader2) ]] && echo "true" || echo "false")
	yay -S --needed --noconfirm jdownloader2

	if [[ "$present" == "false" ]]; then
		update_chromium_extension "fbcohnmimjicjdomonkcbcpbpnhggkip" # myjdownloader-browser-ext
	fi

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
		jq ".defaultdownloadfolder = \"$deposit\"" "$config2" | sponge "$config2"
		jq ".enabled = false" "$config3" | sponge "$config3"
		jq ".enabled = false" "$config4" | sponge "$config4"
	fi

}

main() {

	sudo -v
	update_chromium
	update_git main sharpordie 72373746+sharpordie@users.noreply.github.com
	update_hashcat
	update_jdownloader

}

main
