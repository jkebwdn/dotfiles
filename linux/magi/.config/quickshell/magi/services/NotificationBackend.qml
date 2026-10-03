import QtQuick
import Quickshell.Services.Notifications

NotificationServer {
    required property var owner
    keepOnReload: true
    actionsSupported: true
    bodySupported: true
    imageSupported: true
    persistenceSupported: false
    bodyMarkupSupported: false
    bodyHyperlinksSupported: false
    bodyImagesSupported: false
    actionIconsSupported: false
    inlineReplySupported: false
    onNotification: notification => owner.receive(notification)
}
