import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import Qt.labs.platform

KCM.SimpleKCM {
    id: configPage
    
    property alias cfg_filePath: filePathField.text
    
    Kirigami.FormLayout {
        RowLayout {
            Kirigami.FormData.label: "File path:"
            
            QQC2.TextField {
                id: filePathField
                Layout.fillWidth: true
                placeholderText: "/path/to/your/file.txt"
            }
            
            QQC2.Button {
                icon.name: "document-open"
                onClicked: fileDialog.open()
                
                QQC2.ToolTip.text: "Browse for file"
                QQC2.ToolTip.visible: hovered
            }
        }
        
        QQC2.Label {
            text: "The widget will automatically update when the file changes (using inotify)."
            opacity: 0.6
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
        
        Item {
            Kirigami.FormData.isSection: true
        }
        
        QQC2.Label {
            text: "Requirements:"
            font.bold: true
        }
        
        QQC2.Label {
            text: "• inotify-tools must be installed\n• File must be readable by your user"
            opacity: 0.6
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }
    
    FileDialog {
        id: fileDialog
        fileMode: FileDialog.OpenFile
        currentFolder: StandardPaths.writableLocation(StandardPaths.HomeLocation)
        
        onAccepted: {
            filePathField.text = fileDialog.file.toString().replace("file://", "")
        }
    }
}
