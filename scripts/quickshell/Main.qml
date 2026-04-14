import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: masterWindow
    title: "qs-master"
    color: "transparent"

    // Always mapped to prevent Wayland from destroying the surface and Hyprland from auto-centering!
    visible: true

    // Push it off-screen the moment the component loads using Hyprland's dispatcher
    Component.onCompleted: {
        Quickshell.execDetached(["bash", "-c", `hyprctl dispatch resizewindowpixel "exact 1 1,title:^(qs-master)$" && hyprctl dispatch movewindowpixel "exact -5000 -5000,title:^(qs-master)$"`]);
    }

    property int screenW: 1920
    property int screenH: 1080
    property int screenOffsetX: 0
    property int screenOffsetY: 0

    Process {
        id: monitorQuery
        command: ["cat", "/tmp/qs_monitor_offset"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.trim().split(" ");
                if (parts.length === 4) {
                    masterWindow.screenOffsetX = parseInt(parts[0]) || 0;
                    masterWindow.screenOffsetY = parseInt(parts[1]) || 0;
                    masterWindow.screenW = parseInt(parts[2]) || 1920;
                    masterWindow.screenH = parseInt(parts[3]) || 1080;
                }
            }
        }
    }

    property string currentActive: "hidden"
    onCurrentActiveChanged: {
        Quickshell.execDetached(["bash", "-c", "echo '" + currentActive + "' > /tmp/qs_active_widget"]);
    }

    property bool isVisible: false
    property string activeArg: ""

    property int currentX: -5000
    property int currentY: -5000

    property real animW: 1
    property real animH: 1

    property var layouts: {
        "wallpaper": { w: screenW, h: 650, x: 0, y: Math.floor((screenH/2)-(650/2)), comp: "wallpaper/WallpaperPicker.qml" },
        "hidden":    { w: 1, h: 1, x: -5000, y: -5000, comp: "" }
    }
    implicitWidth: 1
    implicitHeight: 1

    Item {
        anchors.centerIn: parent
        width: masterWindow.animW
        height: masterWindow.animH
        clip: true

        Behavior on width  { NumberAnimation { duration: 250; easing.type: Easing.InOutCubic } }
        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.InOutCubic } }

        opacity: masterWindow.isVisible ? 1.0 : 0.0

        Item {
            anchors.centerIn: parent
            width:  masterWindow.currentActive !== "hidden" && layouts[masterWindow.currentActive] ? layouts[masterWindow.currentActive].w : 1
            height: masterWindow.currentActive !== "hidden" && layouts[masterWindow.currentActive] ? layouts[masterWindow.currentActive].h : 1

            StackView {
                id: widgetStack
                anchors.fill: parent
                focus: true

                Keys.onEscapePressed: {
                    Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"])
                    event.accepted = true
                }

                onCurrentItemChanged: {
                    if (currentItem) currentItem.forceActiveFocus();
                }

                replaceEnter: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 400; easing.type: Easing.OutExpo }
                        NumberAnimation { property: "scale"; from: 0.98; to: 1.0; duration: 400; easing.type: Easing.OutBack }
                    }
                }
                replaceExit: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 300; easing.type: Easing.InExpo }
                        NumberAnimation { property: "scale"; from: 1.0; to: 1.02; duration: 300; easing.type: Easing.InExpo }
                    }
                }
            }
        }
    }

    function switchWidget(newWidget, arg) {
        if (newWidget === "hidden") {
            if (currentActive !== "hidden" && layouts[currentActive]) {
                masterWindow.isVisible = false;
                masterWindow.currentActive = "hidden";
                widgetStack.clear();
                masterWindow.animW = 1;
                masterWindow.animH = 1;
                masterWindow.implicitWidth = 1;
                masterWindow.implicitHeight = 1;
                Quickshell.execDetached(["bash", "-c", `hyprctl dispatch resizewindowpixel "exact 1 1,title:^(qs-master)$" && hyprctl dispatch movewindowpixel "exact -5000 -5000,title:^(qs-master)$"`]);
            }
        } else if (currentActive === "hidden") {
            let t = layouts[newWidget];
            let cx = Math.floor(t.x + (t.w / 2));
            let cy = Math.floor(t.y + (t.h / 2));

            masterWindow.animW = 1;
            masterWindow.animH = 1;
            masterWindow.implicitWidth = 1;
            masterWindow.implicitHeight = 1;

            Quickshell.execDetached(["bash", "-c", `hyprctl dispatch movewindowpixel "exact ${cx + masterWindow.screenOffsetX} ${cy + masterWindow.screenOffsetY},title:^(qs-master)$"`]);

            prepTimer.newWidget = newWidget;
            prepTimer.newArg = arg;
            prepTimer.start();
        }
    }

    Timer {
        id: prepTimer
        interval: 50
        property string newWidget: ""
        property string newArg: ""
        onTriggered: executeSwitch(newWidget, newArg)
    }

    function executeSwitch(newWidget, arg) {
        masterWindow.currentActive = newWidget;
        masterWindow.activeArg = arg;

        let t = layouts[newWidget];
        masterWindow.animW = t.w;
        masterWindow.animH = t.h;
        masterWindow.implicitWidth = t.w;
        masterWindow.implicitHeight = t.h;
        masterWindow.currentX = t.x;
        masterWindow.currentY = t.y;

        Quickshell.execDetached(["bash", "-c", `hyprctl dispatch resizewindowpixel "exact ${t.w} ${t.h},title:^(qs-master)$" && hyprctl dispatch movewindowpixel "exact ${t.x + masterWindow.screenOffsetX} ${t.y + masterWindow.screenOffsetY},title:^(qs-master)$"`]);

        masterWindow.isVisible = true;
        widgetStack.replace(t.comp, { "widgetArg": arg });
    }

    Timer {
        interval: 50; running: true; repeat: true
        onTriggered: { if (!ipcPoller.running) ipcPoller.running = true; }
    }

    Process {
        id: ipcPoller
        command: ["bash", "-c", "if [ -f /tmp/qs_widget_state ]; then cat /tmp/qs_widget_state; rm /tmp/qs_widget_state; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                let rawCmd = this.text.trim();
                if (rawCmd === "") return;

                let parts = rawCmd.split(":");
                let cmd = parts[0];
                let arg = parts.length > 1 ? parts[1] : "";

                if (cmd === "close") {
                    switchWidget("hidden", "");
                } else if (layouts[cmd]) {
                    delayedClear.stop();
                    if (masterWindow.isVisible && masterWindow.currentActive === cmd) {
                        switchWidget("hidden", "");
                    } else {
                        switchWidget(cmd, arg);
                    }
                }
            }
        }
    }

    Timer {
        id: delayedClear
        interval: 150
        onTriggered: {
            masterWindow.currentActive = "hidden";
            widgetStack.clear();

            Quickshell.execDetached(["bash", "-c", `hyprctl dispatch resizewindowpixel "exact 1 1,title:^(qs-master)$" && hyprctl dispatch movewindowpixel "exact -5000 -5000,title:^(qs-master)$"`]);
        }
    }
}
