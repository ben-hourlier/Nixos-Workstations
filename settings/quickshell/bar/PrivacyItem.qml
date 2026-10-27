import qs.common
import qs.components
import qs.services
import QtQuick
import QtQuick.Layouts

// Shown only while something captures: dictation, microphone, camera or screen.
BarItem {
    visible: Privacy.dictating || Privacy.microphone || Privacy.video || Privacy.screenRecording

    Icon {
        visible: Privacy.dictating
        name: "graphic_eq"
        color: Theme.iris
    }

    Icon {
        visible: Privacy.microphone
        name: "mic"
        filled: true
        color: Theme.love
    }

    Icon {
        visible: Privacy.video
        name: "videocam"
        filled: true
        color: Theme.love
    }

    Icon {
        visible: Privacy.screenRecording
        name: "screen_record"
        filled: true
        color: Theme.love
    }
}
