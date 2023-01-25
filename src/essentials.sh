expand_archive() {

	# Handle parameters
	local archive=${1}
	local deposit=${2:-.}
	local subtree=${3:-0}

	# Expand archive
	if [[ -n "$archive" && ! -f "$deposit" && "$subtree" =~ ^[0-9]+$ ]]; then
		mkdir -p "$deposit"
		if [[ "$archive" == http* ]]; then
			curl -LA "mozilla/5.0" "$archive" | bsdtar -zxf - -C "$deposit" --strip-components=$((subtree))
		else
			bsdtar -zxf "$archive" -C "$deposit" --strip-components=$((subtree))
		fi
		printf "%s" "$deposit"
	fi

}

update_chromium() {

    # Update dependencies
    sudo pacman -S --needed --noconfirm ydotool

    # Update package
    local present=$([[ -n $(pacman -Q | grep ungoogled-chromium-bin) ]] && echo "true" || echo "false")
    yay -S --needed --noconfirm ungoogled-chromium-bin

    # Finish installation

}

update_chromium_extension() {

    # Handle parameters
    local payload=${1}

    # Update dependencies
    sudo pacman -S --needed --noconfirm curl libarchive ydotool

    # Update extension
    local present=$([[ -x $(command -v chromium) ]] && echo "true" || echo "false")
    if [[ "$present" == "true" ]]; then
        pkill chromium
        if [[ "$payload" == http* ]]; then
            address="$payload"
            package="$(mktemp -d)/$(basename "$address")"
        else
            version="$(chromium --product-version)"
            address="https://clients2.google.com/service/update2/crx?response=redirect&acceptformat=crx2,crx3"
            address="${address}&prodversion=${version}&x=id%3D${payload}%26installsource%3Dondemand%26uc"
            package="$(mktemp -d)/$payload.crx"
        fi
        curl -LA "mozilla/5.0" "$address" -o "$package" || return 1
        if [[ "$package" == *.zip ]]; then
            local deposit="$HOME/.config/chromium/Unpacked/$(echo "$payload" | cut -d / -f5)"
			local present=$([[ -d "$deposit" ]] && echo "true" || echo "false")
            mkdir -p "$deposit"
            curl -LA "mozilla/5.0" "$package" | bsdtar -zxf - -C "$deposit" --strip-components=1 || return 1
            if [[ "$present" == "false" ]]; then
                return
            fi
        else
            sleep 1 && (sudo ydotoold &) &>/dev/null
            sleep 1 && (chromium --lang=en --start-maximized "$package" &) &>/dev/null
            # sleep 4 && sudo ydotool key 125:1 103:1 103:0 125:0
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
	[[ -n "$gitmail" ]] && git config --global user.email "$gitmail" || true
	[[ -n "$gituser" ]] && git config --global user.name "$gituser" | true
	git config --global http.postBuffer 1048576000
	git config --global init.defaultBranch "$default"

}

update_hashcat() {

    # Update dependencies
    local geforce=$([[ $(lspci | grep -e VGA) == *"GeForce"* ]] && echo "true" || echo "false")
    [[ "$geforce" == "false" ]] && sudo pacman -S --needed --noconfirm opencl-nvidia || true

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
        jq ".defaultdownloadfolder = \"$deposit\"" "$config2" | sponge "$config2"
        jq ".enabled = false" "$config3" | sponge "$config3"
        jq ".enabled = false" "$config4" | sponge "$config4"
        # update_chromium_extension "fbcohnmimjicjdomonkcbcpbpnhggkip"
    fi

}

update_plasma() {

    local rootdir="$HOME/.kde/share/config"

    # Remove avatar
    sudo rm "/var/lib/AccountsService/icons/$USER"

}

main() {

    sudo -v
    # update_chromium_extension "https://github.com/iamadamdev/bypass-paywalls-chrome/archive/master.zip"
    # update_chromium_extension "ibplnjkanclpjokhdolnendpplpjiace"
    update_git main sharpordie 72373746+sharpordie@users.noreply.github.com

}

main
