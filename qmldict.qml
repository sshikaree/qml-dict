import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Dialogs 1.1
//import QtQuick.Controls.Styles 1.1
//import QtQuick.Window 2.1
import QtQuick.Layouts 1.1
import "main.js" as MainJS


ApplicationWindow {
    id: rootwindow
    title: qsTr("Dictionary Search")
    width: 900
    height: 700
    minimumWidth: 700

    property string appMode: appModeModel.get(appModeBox.currentIndex).nick
    property int currentSearchPosition: 0
    property string openedDictionary: ""

    MessageDialog {
        id: askForSave
        title: qsTr("Save dictionary?")
        text: qsTr("Save dictionary \"" + openedDictionary + "\" ?")
        icon: StandardIcon.Question
        standardButtons: StandardButton.Yes | StandardButton.No
        onYes: {
            console.log(openedDictionary)
            if (openedDictionary != "") {
                ctrl.save(textArea.text, openedDictionary)
            }
        }
    }

    Action {
        id: searchAction
        iconName: "edit-find"
        onTriggered: {
            var search_text = searchInput.text.trim().toLowerCase();
            if (search_text.length != 0) {
                if (appMode === "search" && MainJS.activeDicts.length > 0) {
                    ctrl.search(search_text, searchModeModel.get(searchModeBox.currentIndex).nick, MainJS.activeDicts)
                } else if (appMode === "edit" && textArea.text != "") {
                    var spacing = " "
                    if (searchModeModel.get(searchModeBox.currentIndex).nick === "wholeword") {
                        spacing = " "
                    } else if (searchModeModel.get(searchModeBox.currentIndex).nick === "startswith") {
                        spacing = ""
                    }
                    var patt = new RegExp("^" + search_text + spacing + "|" + "\n" + search_text + spacing);
                    (function searchFunc() {
                        var text_for_search = textArea.getText(currentSearchPosition, textArea.length).toLowerCase();
                        var firstFoundPosition = text_for_search.search(patt);
//                        console.log(firstFoundPosition);
                        if (firstFoundPosition === -1 && currentSearchPosition > 0) {
                            currentSearchPosition = 0;
                            searchFunc();
                        } else if (firstFoundPosition >= 0) {
                            currentSearchPosition = currentSearchPosition + firstFoundPosition;
                            textArea.select(currentSearchPosition, currentSearchPosition + searchInput.text.length + 1);
                            currentSearchPosition += searchInput.text.length;
						}
                    }());
                }
            }
        }
    }

    //    Context menu for search area
    Menu {
        id: searchInputContextMenu
        MenuItem {
            text: qsTr("Copy")
            onTriggered: searchInput.copy()
        }
        MenuItem {
            text: qsTr("Paste")
            onTriggered: searchInput.paste()
        }
    }

    toolBar: ToolBar {
        id: maintoolbar

        RowLayout {
            //            id: toolRow
            anchors.fill: parent

            Label {
                id: appModeLabel
                text: qsTr("App mode")
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            ComboBox {
                id: appModeBox
                width: 100
                anchors.left: appModeLabel.right
                anchors.leftMargin: 5
                model: appModeModel

                ListModel  {
                    id: appModeModel
                    ListElement {
                        text: "Search"
                        nick: "search"
                    }
                    ListElement {
                        text: "Edit"
                        nick: "edit"
                    }
                }
                onCurrentIndexChanged: {
                    if (appModeModel.get(currentIndex).nick === "edit") {
                        searchModeGroupBox.visible = false
                        editModeGroupBox.visible = true
                        textArea.textFormat = TextEdit.PlainText

                    } else if (appModeModel.get(currentIndex).nick === "search") {
                        editModeGroupBox.visible = false
                        searchModeGroupBox.visible = true
                        textArea.readOnly = true
                        textArea.textFormat = TextEdit.RichText
                    }
                    ctrl.searchResult = ""
                }
            }

            ToolButton {
                id: searchButton
                anchors.right: parent.right
                anchors.rightMargin: 5
                action: searchAction
            }

            Rectangle {
                id: searchRectangle
                anchors.right: searchButton.left
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                //                Add animation
                Behavior on width {
                    NumberAnimation {/*duration: 250*/easing.type: Easing.Bezier}
                }

                width: 180
                //                height: parent.height - 4
                height: 24
                //                color: "#eaeaea"
                border.color: "#adadad"
                radius: 6
                gradient: Gradient {
                    GradientStop {
                        position: 0.00;
                        color: "#eeeeee"
                    }
                    GradientStop {
                        position: 0.50;
                        color: "#f9f9f9"
                    }
                    GradientStop {
                        position: 1.00;
                        color: "#ffffff"
                    }
                }
                TextInput {
                    id:searchInput
                    selectionColor: "orange"
                    //                    maximumLength: 24
                    anchors.centerIn: parent
                    font.pixelSize: height - 4
                    width: searchRectangle.width - 10
                    height: searchRectangle.height - 4
                    wrapMode: TextInput.Wrap
                    selectByMouse: true
                    onActiveFocusChanged: {
                        if (searchInput.activeFocus) {
                            searchRectangle.border.width = 1
                            searchRectangle.border.color = "orange"
                            searchRectangle.width = 210;
                        } else {
                            searchRectangle.border.width = 1
                            searchRectangle.border.color = "#adadad"
                            searchRectangle.width = 180;
                        }
                    }
                    onAccepted: searchAction.trigger()

                    MouseArea {
                        propagateComposedEvents: true
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onClicked: {
                            searchInputContextMenu.popup()
                        }
                    }

                }


            }

            ComboBox {
                id: searchModeBox
                //                width: 150
                anchors.right: searchRectangle.left
                anchors.rightMargin: 10
                model: searchModeModel

                ListModel  {
                    id: searchModeModel

                    ListElement {
                        text: "Whole word"
                        nick: "wholeword"
                    }

                    ListElement {
                        text: "Word starts with"
                        nick: "startswith"
                    }
                }
            }

            Label {
                text: qsTr("Search mode")
                anchors.right: searchModeBox.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        GroupBox {
            id: searchModeGroupBox
            title: qsTr("Dictionaries list")
            width: 200
            Layout.minimumWidth: 60
            Column {
                Repeater {
                    model: ctrl.len
                    CheckBox {
                        text: ctrl.dictName(index)
                        onCheckedChanged: checked ? MainJS.activeDicts.push(text) : MainJS.activeDicts.splice(MainJS.activeDicts.indexOf(text), 1)
                    }
                }
            }

        }

        GroupBox {
            id: editModeGroupBox
            visible: false
            title: qsTr("Select dictionary")
            width: 200
            Layout.minimumWidth: 200

            Column {
                id: editModeColumn
                anchors.fill: parent

                ComboBox {
                    id: chooseDictComboBox
                    width:180
                    model: chooseDictModel
                }

                ListModel {
                    id: chooseDictModel
                }

                Button {
                    iconName: "document-open"
                    text: qsTr("Open")
                    onClicked: if (chooseDictModel.get(chooseDictComboBox.currentIndex).text !== "") {
                                   ctrl.load(chooseDictModel.get(chooseDictComboBox.currentIndex).text)
                                   textArea.readOnly = false
                                   openedDictionary = chooseDictModel.get(chooseDictComboBox.currentIndex).text
                               }

                }

                Button {
                    //                    anchors.bottom: editModeColumn.bottom
                    iconName: "document-save"
                    text: qsTr("Save")
                    onClicked: if (openedDictionary != "") {
                                   askForSave.open()
                               }
                }
            }
            Component.onCompleted: {
                for (var i=0; i<ctrl.len; i++) {
                    chooseDictModel.append({text: ctrl.dictName(i)})
                }
            }

        }




        TextArea {
            //            style: TextAreaStyle {
            //                backgroundColor: "#FFFEF2"
            //            }

            id: textArea
            width: parent.width
            height: parent.height
            frameVisible: true
            anchors.top: parent.top
            //            textFormat: TextEdit.PlainText
            textFormat: TextEdit.RichText
            readOnly: true
            text: ctrl.searchResult

            BusyIndicator {
                id: busyIndicator
                anchors.centerIn: parent
                running: ctrl.busy === true ? true : false
            }
        }

    }



    statusBar: StatusBar {
        width: parent.width
        RowLayout {
            Label {text: ctrl.busy === true ? qsTr("Searching...") : qsTr("Ready")}
        }
    }
}
