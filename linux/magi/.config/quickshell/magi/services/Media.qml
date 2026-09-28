pragma Singleton
import QtQuick
import Quickshell.Services.Mpris

MediaController {
    players: Mpris.players.values
    preferredPlayer: Settings.data.media.preferredPlayer || ""
}
