
update_plasma() {

    # Enable double click.
    local configs="$HOME/.config/kdeglobals"
    kwriteconfig5 --file "$configs" --group "KDE" --key "SingleClick" "false"

}