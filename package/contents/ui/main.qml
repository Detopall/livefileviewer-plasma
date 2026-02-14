import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import Qt5Compat.GraphicalEffects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import Qt.labs.platform

PlasmoidItem {
    id: root
    
    width: Kirigami.Units.gridUnit * 20
    height: Kirigami.Units.gridUnit * 15
    
    property string filePath: plasmoid.configuration.filePath
    property string fileContent: ""
    property bool fileExists: false
    property bool isEdited: false
    property string saveStatus: ""
    
    // File monitoring process
    property var watchProcess: null
    
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    
    // Monitor file changes using inotifywait
    function startFileMonitoring() {
        stopFileMonitoring()
        
        if (filePath === "") {
            fileContent = "No file selected.\n\nClick the folder icon to select a file."
            fileExists = false
            return
        }
        
        // Initial read
        readFile()
        
        // Start inotify monitoring
        watchProcess = Qt.createQmlObject('
            import QtQuick
            import org.kde.plasma.plasma5support as Plasma5Support
            Plasma5Support.DataSource {
                id: watcher
                engine: "executable"
                interval: 0
                
                property string targetFile: ""
                
                function startWatch(filepath) {
                    targetFile = filepath
                    var cmd = "inotifywait -m -e modify,attrib,move_self,delete_self \\"" + 
                              filepath.replace(/"/g, "\\\\\\"") + "\\" 2>&1"
                    connectedSources = [cmd]
                }
                
                function stopWatch() {
                    disconnectSource(connectedSources[0])
                    connectedSources = []
                }
                
                onNewData: (sourceName, data) => {
                    if (data["stdout"]) {
                        root.readFile()
                    }
                    if (data["stderr"] && data["stderr"].includes("No such file")) {
                        root.fileContent = "Error: File not found\\n" + targetFile
                        root.fileExists = false
                    }
                }
            }
        ', root, "watcherComponent")
        
        if (watchProcess) {
            watchProcess.startWatch(filePath)
        }
    }
    
    function stopFileMonitoring() {
        if (watchProcess) {
            try {
                watchProcess.stopWatch()
                watchProcess.destroy()
            } catch (e) {}
            watchProcess = null
        }
    }
    
    // Read file function
    function readFile() {
        if (filePath === "") {
            fileContent = "No file selected.\n\nClick the folder icon to select a file."
            fileExists = false
            return
        }
        
        var readerSource = Qt.createQmlObject('
            import QtQuick
            import org.kde.plasma.plasma5support as Plasma5Support
            Plasma5Support.DataSource {
                engine: "executable"
                connectedSources: []
                
                function read(filepath) {
                    var cmd = "cat \\"" + filepath.replace(/"/g, "\\\\\\"") + "\\" 2>&1"
                    connectedSources = [cmd]
                }
            }
        ', root, "readerComponent")
        
        readerSource.onNewData.connect(function(sourceName, data) {
            var stdout = data["stdout"] || ""
            var stderr = data["stderr"] || ""
            var exitCode = data["exit code"]
            
            if (exitCode === 0) {
                fileContent = stdout || "(empty file)"
                fileExists = true
                isEdited = false
                saveStatus = ""
            } else {
                fileContent = "Error reading file:\n" + (stderr || "File not found or not readable")
                fileExists = false
            }
            
            readerSource.disconnectSource(sourceName)
            readerSource.destroy()
        })
        
        readerSource.read(filePath)
    }
    
    // Save file function
    function saveFile(content) {
        if (filePath === "") {
            saveStatus = "error"
            return
        }
        
        var writerSource = Qt.createQmlObject('
            import QtQuick
            import org.kde.plasma.plasma5support as Plasma5Support
            Plasma5Support.DataSource {
                engine: "executable"
                connectedSources: []
                
                function write(filepath, content) {
                    var escapedContent = content.replace(/\\\\/g, "\\\\\\\\").replace(/"/g, "\\\\\\"").replace(/\\$/g, "\\\\$").replace(/`/g, "\\\\`")
                    var cmd = "printf \\"%s\\" \\"" + escapedContent + "\\" > \\"" + filepath.replace(/"/g, "\\\\\\"") + "\\" 2>&1"
                    connectedSources = [cmd]
                }
            }
        ', root, "writerComponent")
        
        writerSource.onNewData.connect(function(sourceName, data) {
            var exitCode = data["exit code"]
            var stderr = data["stderr"] || ""
            
            if (exitCode === 0) {
                saveStatus = "success"
                isEdited = false
                statusTimer.restart()
            } else {
                saveStatus = "error"
                console.log("Save error:", stderr)
            }
            
            writerSource.disconnectSource(sourceName)
            writerSource.destroy()
        })
        
        writerSource.write(filePath, content)
    }
    
    Timer {
        id: statusTimer
        interval: 3000
        onTriggered: saveStatus = ""
    }
    
    fullRepresentation: Item {
        id: fullRep
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.preferredHeight: Kirigami.Units.gridUnit * 15
        Layout.minimumWidth: Kirigami.Units.gridUnit * 10
        Layout.minimumHeight: Kirigami.Units.gridUnit * 8
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 0
            
            // Enhanced header
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: headerLayout.implicitHeight + Kirigami.Units.largeSpacing
                color: Kirigami.Theme.alternateBackgroundColor
                radius: 4
                
                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 1
                    radius: 4
                    samples: 9
                    color: Qt.rgba(0, 0, 0, 0.1)
                }
                
                RowLayout {
                    id: headerLayout
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.largeSpacing
                    
                    Kirigami.Icon {
                        source: "document-preview"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                        color: Kirigami.Theme.highlightColor
                    }
                    
                    Kirigami.Heading {
                        Layout.fillWidth: true
                        level: 3
                        text: filePath ? filePath.split('/').pop() : "Live File Viewer"
                        font.weight: Font.DemiBold
                        elide: Text.ElideMiddle
                    }
                    
                    QQC2.ToolButton {
                        icon.name: "document-open"
                        onClicked: fileDialog.open()
                        QQC2.ToolTip.text: "Select file"
                        QQC2.ToolTip.visible: hovered
                    }
                    
                    QQC2.ToolButton {
                        icon.name: "view-refresh"
                        onClicked: readFile()
                        QQC2.ToolTip.text: "Refresh"
                        QQC2.ToolTip.visible: hovered
                        enabled: fileExists
                    }
                    
                    QQC2.ToolButton {
                        icon.name: "document-save"
                        onClicked: saveFile(textArea.text)
                        QQC2.ToolTip.text: "Save file"
                        QQC2.ToolTip.visible: hovered
                        enabled: fileExists && isEdited
                        highlighted: isEdited
                    }
                    
                    QQC2.ToolButton {
                        icon.name: "help-about"
                        onClicked: infoDialog.open()
                        QQC2.ToolTip.text: "About"
                        QQC2.ToolTip.visible: hovered
                    }
                }
            }
            
            // File content display
            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                QQC2.TextArea {
                    id: textArea
                    text: fileContent
                    readOnly: !fileExists
                    wrapMode: TextEdit.Wrap
                    font.family: "JetBrains Mono, Fira Code, Consolas, monospace"
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize
                    selectByMouse: true
                    padding: Kirigami.Units.largeSpacing
                    background: Rectangle {
                        color: Kirigami.Theme.backgroundColor
                        border.color: textArea.activeFocus ? Kirigami.Theme.highlightColor : Kirigami.Theme.disabledTextColor
                        radius: 3
                        border.width: 1
                    }
                    
                    onTextChanged: {
                        if (fileExists && text !== fileContent) {
                            isEdited = true
                        }
                    }
                }
            }
            
            // Enhanced footer with status
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: footerLayout.implicitHeight + Kirigami.Units.largeSpacing
                color: saveStatus === "success" ? Kirigami.Theme.positiveBackgroundColor :
                       saveStatus === "error" ? Kirigami.Theme.negativeBackgroundColor :
                       Kirigami.Theme.alternateBackgroundColor
                radius: 4
                
                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: -1
                    radius: 4
                    samples: 9
                    color: Qt.rgba(0, 0, 0, 0.1)
                }
                
                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
                
                RowLayout {
                    id: footerLayout
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.largeSpacing
                    
                    Kirigami.Icon {
                        source: saveStatus === "success" ? "emblem-success" :
                                saveStatus === "error" ? "emblem-error" :
                                fileExists ? "emblem-checked" : "emblem-warning"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                        visible: filePath !== ""
                        color: saveStatus === "success" ? Kirigami.Theme.positiveTextColor :
                               saveStatus === "error" ? Kirigami.Theme.negativeTextColor :
                               Kirigami.Theme.textColor
                    }
                    
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: saveStatus === "success" ? "✓ Saved successfully" :
                              saveStatus === "error" ? "✗ Error saving file" :
                              filePath ? (fileExists ? (isEdited ? "● Modified - unsaved changes" : filePath) : "⚠ File not found") : 
                              "Select a file to get started"
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize
                        font.weight: saveStatus !== "" ? Font.Medium : Font.Normal
                        opacity: saveStatus !== "" ? 1.0 : 0.7
                        elide: Text.ElideMiddle
                        
                        Behavior on opacity {
                            NumberAnimation { duration: 200 }
                        }
                    }
                }
            }
        }
        
        // Info Dialog
        QQC2.Dialog {
            id: infoDialog
            title: "About Live File Viewer"
            modal: true
            parent: fullRep
            anchors.centerIn: parent
            width: Math.min(Kirigami.Units.gridUnit * 25, fullRep.width * 0.9)
            
            standardButtons: QQC2.Dialog.Close
            
            ColumnLayout {
                spacing: Kirigami.Units.largeSpacing * 1.5
                width: parent.width
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing * 1.5
                    
                    Kirigami.Icon {
                        source: "document-preview"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                        Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                        color: Kirigami.Theme.highlightColor
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing
                        
                        Kirigami.Heading {
                            text: "Live File Viewer"
                            level: 1
                            font.weight: Font.Bold
                        }
                        
                        QQC2.Label {
                            text: "Version 1.1"
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.6
                        }
                    }
                }
                
                Kirigami.Separator {
                    Layout.fillWidth: true
                }
                
                QQC2.Label {
                    Layout.fillWidth: true
                    text: "Display and edit live file contents on your desktop."
                    wrapMode: Text.Wrap
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    
                    Kirigami.Heading {
                        text: "Features"
                        level: 3
                        font.weight: Font.DemiBold
                    }
                    
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: "• Real-time file monitoring with refresh\n• In-app editing with save functionality\n• Syntax highlighting for code files\n• Lightweight and fast"
                        wrapMode: Text.Wrap
                        lineHeight: 1.4
                    }
                }
                
                Kirigami.Separator {
                    Layout.fillWidth: true
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    
                    Kirigami.Heading {
                        text: "Author"
                        level: 3
                        font.weight: Font.DemiBold
                    }
                    
                    QQC2.Label {
                        text: "Denis Topallaj"
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.05
                    }
                    
                    QQC2.Label {
                        text: "denis.topallaj13@gmail.com"
                        font.family: "monospace"
                        opacity: 0.6
                    }
                }
                
                QQC2.Button {
                    Layout.alignment: Qt.AlignHCenter
                    text: "View on GitHub"
                    icon.name: "internet-services"
                    highlighted: true
                    font.weight: Font.Medium
                    onClicked: Qt.openUrlExternally("https://github.com/Detopall/livefileviewer-plasma")
                }
            }
        }
    }
    
    compactRepresentation: QQC2.Button {
        icon.name: "document-preview"
        text: filePath ? filePath.split('/').pop() : "File Viewer"
        
        onClicked: {
            root.expanded = !root.expanded
        }
    }
    
    FileDialog {
        id: fileDialog
        fileMode: FileDialog.OpenFile
        folder: StandardPaths.writableLocation(StandardPaths.HomeLocation)
        
        onAccepted: {
            var newPath = fileDialog.file.toString().replace("file://", "")
            plasmoid.configuration.filePath = newPath
        }
    }
    
    // Watch for configuration changes
    onFilePathChanged: {
        startFileMonitoring()
    }
    
    Component.onCompleted: {
        startFileMonitoring()
    }
    
    Component.onDestruction: {
        stopFileMonitoring()
    }
}
