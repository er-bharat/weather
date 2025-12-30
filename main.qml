import QtQuick
import QtQuick.Window
import QtQuick.Controls

Window {
    width: 680
    height: 820
    visible: true
    visibility: Window.Maximized
    flags: Qt.FramelessWindowHint
    color: "#1ba1e2"

    property bool editingCity: false

    Component.onCompleted: Weather.fetch(lastCity)

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentColumn.height
        clip: true
        interactive: true
        flickableDirection: Flickable.VerticalFlick

        Column {
            id: contentColumn
            width: parent.width
            spacing: 32
            anchors.top: parent.top
            anchors.topMargin: 48
            anchors.left: parent.left
            anchors.leftMargin: 48

            // ---- City ----
            Item {
                width: parent.width
                height: 64

                Row {
                    spacing: 12
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        source: "beacon.svg"   // or qrc:/icons/beacon.svg
                        width: 62
                        height: 62
                        sourceSize.width: 62
                        sourceSize.height: 62
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        visible: !editingCity
                        text: Weather.city || "Tap to set city"
                        color: "white"
                        font.pixelSize: 48
                        font.family: "Segoe UI"
                        font.weight: Font.Light
                        verticalAlignment: Text.AlignVCenter

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                editingCity = true
                                cityEdit.text = Weather.city
                                cityEdit.forceActiveFocus()
                            }
                        }
                    }

                    TextInput {
                        id: cityEdit
                        visible: editingCity
                        width: parent.width - 44
                        color: "white"
                        font.pixelSize: 48
                        font.family: "Segoe UI"
                        font.weight: Font.Light
                        cursorVisible: true
                        selectionColor: "#55ffffff"
                        verticalAlignment: Text.AlignVCenter

                        onAccepted: {
                            editingCity = false
                            Weather.fetch(text)
                        }

                        Keys.onEscapePressed: editingCity = false
                    }
                }
            }


            // ---- Temperature + Info ----
            Row {
                spacing: 24

                Rectangle {
                    width: temperature.width
                    height: width
                    color: "transparent"

                    Text {
                        id: temperature
                        anchors.centerIn: parent
                        text: Weather.temperature + "°"
                        color: "white"
                        font.pointSize: 150
                        font.family: "Segoe UI"
                        font.weight: Font.Light
                        lineHeight: 0.9
                        antialiasing: true
                    }
                }

                Column {
                    spacing: 0
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        width: 160
                        height: 160
                        color: "transparent"

                        Image {
                            anchors.centerIn: parent
                            source: "https://openweathermap.org/img/wn/" + Weather.icon + "@2x.png"
                            width: 200
                            height: 200
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                    }

                    Rectangle {
                        width: 160
                        height: 20
                        color: "transparent"

                        Text {
                            anchors.centerIn: parent
                            width: parent.width
                            text: Weather.description.toUpperCase()
                            color: "white"
                            font.pixelSize: 20
                            opacity: 0.85
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            // ---- Extra details strip ----
            Row {
                spacing: 32

                Rectangle {
                    width: 120
                    height: 60
                    color: "transparent"

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        // ---- AQI Value ----
                        Text {
                            text: "AQI " + Weather.aqi
                            color: "white"
                            font.pixelSize: 22
                            horizontalAlignment: Text.AlignHCenter
                            // width: parent.width
                        }

                        // ---- AQI Category ----
                        Text {
                            text: Weather.aqiCategory.toUpperCase()
                            color: "white"
                            opacity: 0.7
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            // width: parent.width
                        }
                    }
                }

                Rectangle {
                    width: 120
                    height: 60
                    color: "transparent"

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: Weather.humidity + "%"
                            color: "white"
                            font.pixelSize: 22
                            horizontalAlignment: Text.AlignHCenter
                            // width: parent.width
                        }

                        Text {
                            text: "HUMIDITY"
                            color: "white"
                            opacity: 0.7
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            // width: parent.width
                        }
                    }
                }

                Rectangle {
                    width: 120
                    height: 60
                    color: "transparent"

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: Weather.windSpeed.toFixed(1) + " m/s"
                            color: "white"
                            font.pixelSize: 22
                            horizontalAlignment: Text.AlignHCenter
                            // width: parent.width
                        }

                        Text {
                            text: "WIND"
                            color: "white"
                            opacity: 0.7
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            // width: parent.width
                        }
                    }
                }

                Rectangle {
                    width: 120
                    height: 60
                    color: "transparent"

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: Weather.pressure + " hPa"
                            color: "white"
                            font.pixelSize: 22
                            horizontalAlignment: Text.AlignHCenter
                            // width: parent.width
                        }

                        Text {
                            text: "PRESSURE"
                            color: "white"
                            opacity: 0.7
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            // width: parent.width
                        }
                    }
                }
            }

            // ---- AQI Pollutants ----
            Column {
                width: parent.width - 48 * 2
                spacing: 32
                anchors.left: parent.left
                anchors.leftMargin: 24

                Text {
                    text: "AIR QUALITY DETAILS"
                    color: "white"
                    opacity: 0.85
                    font.pixelSize: 18
                    font.weight: Font.Medium
                }

                Grid {
                    columns: 7
                    columnSpacing: 24
                    rowSpacing: 16

                    function item(label, value) {
                        return label + "\n" + value;
                    }

                    // PM2.5
                    Rectangle {
                        width: 120
                        height: 70
                        color: "transparent"
                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: Weather.pollutants.pm2_5 + " µg/m³"
                                color: "white"
                                font.pixelSize: 18
                            }
                            Text {
                                text: "PM2.5"
                                color: "white"
                                opacity: 0.6
                                font.pixelSize: 12
                            }
                        }
                    }

                    // PM10
                    Rectangle {
                        width: 120
                        height: 70
                        color: "transparent"
                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: Weather.pollutants.pm10 + " µg/m³"
                                color: "white"
                                font.pixelSize: 18
                            }
                            Text {
                                text: "PM10"
                                color: "white"
                                opacity: 0.6
                                font.pixelSize: 12
                            }
                        }
                    }

                    // CO
                    Rectangle {
                        width: 120
                        height: 70
                        color: "transparent"
                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: Weather.pollutants.co
                                color: "white"
                                font.pixelSize: 18
                            }
                            Text {
                                text: "CO"
                                color: "white"
                                opacity: 0.6
                                font.pixelSize: 12
                            }
                        }
                    }

                    // NO₂
                    Rectangle {
                        width: 120
                        height: 70
                        color: "transparent"
                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: Weather.pollutants.no2
                                color: "white"
                                font.pixelSize: 18
                            }
                            Text {
                                text: "NO₂"
                                color: "white"
                                opacity: 0.6
                                font.pixelSize: 12
                            }
                        }
                    }

                    // O₃
                    Rectangle {
                        width: 120
                        height: 70
                        color: "transparent"
                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: Weather.pollutants.o3
                                color: "white"
                                font.pixelSize: 18
                            }
                            Text {
                                text: "O₃"
                                color: "white"
                                opacity: 0.6
                                font.pixelSize: 12
                            }
                        }
                    }

                    // SO₂
                    Rectangle {
                        width: 120
                        height: 70
                        color: "transparent"
                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: Weather.pollutants.so2
                                color: "white"
                                font.pixelSize: 18
                            }
                            Text {
                                text: "SO₂"
                                color: "white"
                                opacity: 0.6
                                font.pixelSize: 12
                            }
                        }
                    }

                    // NH₃
                    Rectangle {
                        width: 120
                        height: 70
                        color: "transparent"
                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: Weather.pollutants.nh3
                                color: "white"
                                font.pixelSize: 18
                            }
                            Text {
                                text: "NH₃"
                                color: "white"
                                opacity: 0.6
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }

            // ---- Forecast ribbon ----
            ListView {
                width: parent.width - 48 * 2
                height: 240
                orientation: ListView.Horizontal
                spacing: 24
                model: Weather.forecast
                clip: true

                delegate: Rectangle {
                    width: 110
                    height: 240
                    color: "transparent"

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        // ---- Date (formatted) ----
                        Text {
                            property string dateStr: modelData.time.slice(0, 10)  // "YYYY-MM-DD"
                            text: {
                                var d = new Date(dateStr);
                                var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                                var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                                return days[d.getDay()] + " " + d.getDate() + " " + months[d.getMonth()];
                            }
                            color: "white"
                            font.pixelSize: 12
                            opacity: 0.7
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                        }

                        Text {
                            text: modelData.time.slice(11, 16)
                            color: "white"
                            font.pixelSize: 14
                            opacity: 0.8
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                        }

                        Image {
                            source: "https://openweathermap.org/img/wn/" + modelData.icon + "@2x.png"
                            width: 98
                            height: 98
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: modelData.temp + "°"
                            color: "white"
                            font.pixelSize: 18
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 400
            height: 400
            color: "#AA000000"
            visible: !Weather.hasApiKey
            z: 999

            Column {
                anchors.centerIn: parent
                spacing: 16
                width: parent.width * 0.8

                Text {
                    text: "Enter OpenWeather API Key"
                    color: "black"
                    font.pixelSize: 22
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }

                TextField {
                    id: apiInput
                    width: parent.width
                    color: "white"
                    font.pixelSize: 18
                    placeholderText: "API Key"
                    echoMode: TextInput.Password
                }

                Rectangle {
                    width: parent.width
                    height: 44
                    color: "#1ba1e2"

                    Text {
                        anchors.centerIn: parent
                        text: "Save"
                        color: "white"
                        font.pixelSize: 18
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Weather.saveApiKey(apiInput.text);
                            Weather.fetch(Weather.city || "Delhi");
                        }
                    }
                }
            }
        }

        // ---- Metro fade-in ----
        Behavior on opacity {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutCubic
            }
        }
    }
}
