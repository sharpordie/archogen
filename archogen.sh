update_archlinux() {

	# Change the hostname.
	hostnamectl hostname archlinux

	# Update chaotic-aur
	sudo pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
	sudo pacman-key --lsign-key FBA220DFC880C036
	keyring="https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst"
	mirrors="https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst"
	sudo pacman -U --noconfirm "$keyring" "$mirrors"
	configs="/etc/pacman.conf"
	if ! grep -q "chaotic-aur" "$configs" 2>/dev/null; then
		[[ -z $(tail -1 "$configs") ]] || echo "" | sudo tee -a "$configs"
		echo "[chaotic-aur]" | sudo tee -a "$configs"
		echo "Include = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a "$configs"
	fi

	# Update system
	sudo pacman -Syyu --noconfirm

	# Update firmware
	sudo pacman -S --needed --noconfirm fwupd
	sudo fwupdmgr get-devices && sudo fwupdmgr refresh --force
	sudo fwupdmgr get-updates && sudo fwupdmgr update -y

	# Update yay
	sudo pacman -S --needed --noconfirm base-devel git
	git clone "https://aur.archlinux.org/yay-bin.git"
	cd yay-bin && makepkg -si --noconfirm
	cd .. && rm -rf yay-bin

}

update_gnome() {

	# Change icons
	sudo pacman -S --needed --noconfirm papirus-icon-theme
	gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"

	# Change favorites
	gsettings set org.gnome.shell favorite-apps "[ \
		'org.gnome.Nautilus.desktop', \
		'org.gnome.Console.desktop' \
	]"

}

update_jdownloader() {

	deposit=${1:-$HOME/Downloads/JD2}

	# Update dependencies
	sudo pacman -S --needed --noconfirm flatpak jq moreutils

	# Update jdownloader
	flatpak install --assumeyes flathub org.jdownloader.JDownloader

	# Create deposit
	mkdir -p "$deposit"

	# Change desktop
	desktop="/var/lib/flatpak/exports/share/applications/org.jdownloader.JDownloader.desktop"
	sudo sed -i 's/Icon=.*/Icon=jdownloader/' "$desktop" # TODO: Add revert as comment

	# Change settings
	appdata="$HOME/.var/app/org.jdownloader.JDownloader/data/jdownloader"
	config1="$appdata/cfg/org.jdownloader.settings.GraphicalUserInterfaceSettings.json"
	config2="$appdata/cfg/org.jdownloader.settings.GeneralSettings.json"
	config3="$appdata/cfg/org.jdownloader.gui.jdtrayicon.TrayExtension.json"
	(flatpak run org.jdownloader.JDownloader >/dev/null 2>&1 &) && sleep 8
	while [[ ! -f "$config1" ]]; do sleep 2; done
	flatpak kill org.jdownloader.JDownloader && sleep 8
	jq '.bannerenabled = false' "$config1" | sponge "$config1"
	jq '.donatebuttonlatestautochange = 4102444800000' "$config1" | sponge "$config1"
	jq '.donatebuttonstate = "AUTO_HIDDEN"' "$config1" | sponge "$config1"
	jq '.myjdownloaderviewvisible = false' "$config1" | sponge "$config1"
	jq '.premiumalertetacolumnenabled = false' "$config1" | sponge "$config1"
	jq '.premiumalertspeedcolumnenabled = false' "$config1" | sponge "$config1"
	jq '.premiumalerttaskcolumnenabled = false' "$config1" | sponge "$config1"
	jq '.specialdealoboomdialogvisibleonstartup = false' "$config1" | sponge "$config1"
	jq '.specialdealsenabled = false' "$config1" | sponge "$config1"
	jq '.speedmetervisible = false' "$config1" | sponge "$config1"
	jq ".defaultdownloadfolder = \"$deposit\"" "$config2" | sponge "$config2"
	jq '.enabled = false' "$config3" | sponge "$config3"

}

update_ungoogled_chromium() {

	# Update ungoogled-chromium
	yay -S --needed --noconfirm ungoogled-chromium-bin

}

main() {

	# Prompt password
	sudo -v && clear

	# Remove timeout
	echo "Defaults timestamp_timeout=-1" | sudo tee "/etc/sudoers.d/disable_timeout" &>/dev/null

	# Remove screensaver
	gsettings set org.gnome.desktop.screensaver lock-enabled false

	# Change title
	printf "\033]0;%s\007" "archogen"

	# Output welcome
	read -r -d "" welcome <<-EOD
		░█████╗░██████╗░░█████╗░██╗░░██╗░█████╗░░██████╗░███████╗███╗░░██╗
		██╔══██╗██╔══██╗██╔══██╗██║░░██║██╔══██╗██╔════╝░██╔════╝████╗░██║
		███████║██████╔╝██║░░╚═╝███████║██║░░██║██║░░██╗░█████╗░░██╔██╗██║
		██╔══██║██╔══██╗██║░░██╗██╔══██║██║░░██║██║░░╚██╗██╔══╝░░██║╚████║
		██║░░██║██║░░██║╚█████╔╝██║░░██║╚█████╔╝╚██████╔╝███████╗██║░╚███║
		╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝░╚════╝░░╚═════╝░╚══════╝╚═╝░░╚══╝
	EOD
	printf "\n\033[92m%s\033[00m\n\n" "$welcome"

	# Handle functions
	factors=(
		"update_archlinux"
		"update_jdownloader"
		# "update_ungoogled_chromium"
		# "update_gnome"
	)

	# Output progress
	maximum=$((${#welcome} / $(echo "$welcome" | wc -l)))
	heading="\r%-"$((maximum - 20))"s   %-6s   %-8s\n\n"
	loading="\r%-"$((maximum - 20))"s   \033[93mACTIVE\033[0m   %-8s\b"
	failure="\r%-"$((maximum - 20))"s   \033[91mFAILED\033[0m   %-8s\n"
	success="\r%-"$((maximum - 20))"s   \033[92mWORKED\033[0m   %-8s\n"
	printf "$heading" "FUNCTION" "STATUS" "DURATION"
	for element in "${factors[@]}"; do
		written=$(basename "$(echo "$element" | cut -d '"' -f 1)" | tr "[:lower:]" "[:upper:]")
		started=$(date +"%s") && printf "$loading" "$written" "--:--:--"
		eval "$element" >/dev/null 2>&1 && current="$success" || current="$failure"
		extinct=$(date +"%s") && elapsed=$((extinct - started))
		elapsed=$(printf "%02d:%02d:%02d\n" $((elapsed / 3600)) $(((elapsed % 3600) / 60)) $((elapsed % 60)))
		printf "$current" "$written" "$elapsed"
	done

	# Revert timeout
	printf "\n" && sudo rm "/etc/sudoers.d/disable_timeout"

	# Revert screensaver
	gsettings set org.gnome.desktop.screensaver lock-enabled true

}

main "$@"
