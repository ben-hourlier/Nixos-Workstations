pragma ComponentBehavior: Bound

import qs.common
import qs.components
import qs.services
import QtQuick

// Which applications are using the microphone, the camera or the screen.
Panel {
    title: "In use"
    panelWidth: 300

    Repeater {
        model: Privacy.apps

        delegate: ListRow {
            id: row

            required property var modelData

            clickable: false
            text: modelData.name
            detail: [modelData.microphone ? "Microphone" : "", modelData.camera ? "Camera" : "", modelData.screen ? "Screen sharing" : ""].filter(s => s !== "").join(", ")

            Icon {
                visible: row.modelData.microphone
                name: "mic"
                filled: true
                color: Theme.love
            }

            Icon {
                visible: row.modelData.camera
                name: "videocam"
                filled: true
                color: Theme.love
            }

            Icon {
                visible: row.modelData.screen
                name: "screen_share"
                filled: true
                color: Theme.love
            }
        }
    }

    ListRow {
        visible: Privacy.dictating
        clickable: false
        text: "Dictation"
        detail: "Microphone"

        Icon {
            name: "graphic_eq"
            color: Theme.iris
        }
    }

    ListRow {
        visible: Privacy.screenRecording
        clickable: false
        text: "Capture"
        detail: "Screen recording"

        Icon {
            name: "screen_record"
            filled: true
            color: Theme.love
        }
    }
}
