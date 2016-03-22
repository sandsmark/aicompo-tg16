import QtQuick 2.2
import QtQuick.Window 2.2
import QtGraphicalEffects 1.0
import QtQuick.Particles 2.0

Rectangle {
    id: main

    color: "black"

    height: 1200
    width: 1600

    property int scaleSize: (width < height) ? width : height

    property var playerColors: [
        "#c0ff400f", // red
        "#c0400fff", // blue
        "#c040ff0f", // green
        "#c0f0ff40"  // yellow
    ]

    signal userMove(string direction)

    Keys.onDownPressed: userMove("DOWN")
    Keys.onUpPressed: userMove("ACCELERATE")
    Keys.onRightPressed: userMove("RIGHT")
    Keys.onLeftPressed: userMove("LEFT")
    Keys.onEscapePressed: {
        GameManager.stopGame();
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_F5) {
            GameManager.endRound();
            return true;
        } else if (event.key === Qt.Key_P) {
            GameManager.togglePause()
            pauseText.visible = !pauseText.visible
            pauseAnimation.restart()
            return true;
        } else if (event.key === Qt.Key_Period) {
            userMove("SEEKING")
        } else if (event.key === Qt.Key_Comma) {
            userMove("MINE")
        } else if (event.key === Qt.Key_M) {
            userMove("MISSILE")
        }

        return false;
    }


    ColorAnimation on color {
        id: backgroundColorAnimation
        from: "red"
        to: "black"
        duration: 1000
        running: false
    }

    Connections {
        target: GameManager
        onRoundOver: {
            backgroundColorAnimation.restart()
        }
    }

    Item {
        id: gameArea
        anchors.fill: parent


        Image {
            id: background
            anchors.fill: parent
            source: "qrc:/sprites/starfield.jpg"
            fillMode: Image.Tile
            opacity: 0.5
        }

        Text {
            id: pauseText
            anchors.top: parent.top
            anchors.right: parent.right
            text: "PAUSED"
            color: "white"
            font.bold: true
            font.pointSize: 40
            opacity: 0.7
            visible: false
            z: 10


            Text {
                id: pauseOverlay
                anchors.top: parent.top
                anchors.right: parent.right
                color: "white"
                text: parent.text
                visible: opacity > 0
                font.bold: true

                ParallelAnimation {
                    id: pauseAnimation
                    NumberAnimation {
                        target: pauseOverlay
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: 200
                    }
                    NumberAnimation {
                        target: pauseOverlay
                        property: "font.pointSize"
                        from: 40
                        to: 200
                        duration: 300
                    }
                }
            }
        }

        Text {
            id: roundsPlayed
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            text: "round: " + (GameManager.roundsPlayed + 1) + "/" + GameManager.maxRounds
            color: "#7f000000"
            font.bold: true
            style: Text.Outline
            styleColor: "white"
            font.pointSize: 40
            z: 10
            opacity: (GameManager.roundsPlayed < GameManager.maxRounds) ? 0.7 : 0
        }

        Image {
            id: sun
            source: "qrc:///sprites/sun.png"
            anchors.centerIn: parent
            width: main.scaleSize / 10
            height: width

            Emitter {
                anchors.fill: parent
                emitRate: 1000
                lifeSpan: 2000
                size: 20
                sizeVariation: 5
                endSize: 0

                shape: EllipseShape {fill: false}
                velocity: TargetDirection {
                    targetX: sun.width/2
                    targetY: sun.height/2
                    proportionalMagnitude: true
                    magnitude: 0.5
                    magnitudeVariation: 0.9
                }
                system: particleSystem
                group: "Sun"
            }
        }

        ParticleSystem {
            id: particleSystem
            anchors.fill: parent

            property var particleGroups: ["Player1", "Player2", "Player3", "Player4"]

            ImageParticle {
                opacity: 0.5
                source: "qrc:///sprites/star.png"
                alpha: 0.1
                alphaVariation: 0.1
                colorVariation: 0.5
                color: playerColors[0]
                groups: ["Player1"]
            }
            ImageParticle {
                opacity: 0.5
                source: "qrc:///sprites/star.png"
                alpha: 0.1
                alphaVariation: 0.1
                colorVariation: 0.5
                color: playerColors[1]
                groups: ["Player2"]
            }
            ImageParticle {
                opacity: 0.5
                source: "qrc:///sprites/star.png"
                alpha: 0.1
                alphaVariation: 0.1
                colorVariation: 0.5
                color: playerColors[2]
                groups: ["Player3"]
            }
            ImageParticle {
                opacity: 0.5
                source: "qrc:///sprites/star.png"
                alpha: 0.1
                alphaVariation: 0.1
                colorVariation: 0.5
                color: playerColors[3]
                groups: ["Player4"]
            }
            ImageParticle {
                opacity: 0.5
                source: "qrc:///sprites/star.png"
                alpha: 0.1
                alphaVariation: 0.1
                color: "white"
                groups: ["Explosion", "Logo"]
            }
            ImageParticle {
                source: "qrc:///sprites/star.png"
                alphaVariation: 0.1
                colorVariation: 0.5
                color: "#0fffff00"
                groups: ["Sun"]
            }
            ImageParticle {
                source: "qrc:///particleresources/fuzzydot.png"
                alpha: 0.0
                groups: ["Petal"]
            }
        }

        Emitter {
            id: crashEmitter
            anchors.centerIn: parent
            width: 10
            height: 10
            emitRate: 1000
            lifeSpan: 250
            lifeSpanVariation: 100
            enabled: false
            velocity: AngleDirection{magnitude: 128; angleVariation: 360}
            size: 16
            sizeVariation: 16
            system: particleSystem
            group: "Explosion"

            Connections {
                target: GameManager
                onExplosion: {
                    crashEmitter.burst(500, main.width / 2 + position.x * main.width / 2, main.height/ 2 + position.y * main.height/ 2)
                }
            }
        }

        Component {
            id: missileSpriteSpawner

            MissileSprite {
            }
        }
        Connections {
            target: GameManager
            onMissileCreated: {
                missileSpriteSpawner.createObject(gameArea, {"missileData": missile})
            }
        }


        // List of names of players
        Column {
            anchors.left: parent.left
            anchors.top: parent.top
            height: 100
            width: 100
            Repeater {
                model: GameManager.players
                delegate: Image {
                    source: modelData.spritePath
                    height: 45
                    width: height


                    Rectangle {
                        anchors.left: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        color: playerColors[modelData.id]
                        opacity: modelData.energy / 2000 + 0.5
                        width: 410 * modelData.energy / 1000
                        Behavior on width { NumberAnimation { duration: 60; } }
                        ColorAnimation on color {
                            id: coloranim
                            duration: 100
                            from: "white"
                            to: playerColors[modelData.id]
                        }
                    }
                    Text {
                        id: playerName
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.right
                        width: 300
                        text: modelData.name
                        color: "white"
                        style: Text.Outline
                        styleColor: "black"
                        font.family: "Aldrich"
                        font.pointSize: 20
                        font.strikeout: !modelData.alive
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: playerName.right
                        width: font.pointSize * 10
                        text: modelData.energy
                        color: "white"
                        style: Text.Outline
                        styleColor: "black"
                        font.family: "Aldrich"
                        font.pointSize: 20
                        font.strikeout: !modelData.alive
                    }

                }
            }
        }

        Rectangle {
            id: startCountdown
            anchors.centerIn: parent
            height: parent.height / 2
            width: height / 3
            color: "#a0000000"
            border.color: "white"
            border.width: 2

            opacity: countdownTimer.running ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 500
                }
            }

            Rectangle {
                id: countdownFirst
                color: "yellow"
                opacity: 0
                width: parent.width
                height: width
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                }
            }

            Rectangle {
                id: countdownSecond
                color: "yellow"
                opacity: 0
                width: parent.width
                height: width
                anchors {
                    verticalCenter: parent.verticalCenter
                    horizontalCenter: parent.horizontalCenter
                }
            }


            Rectangle {
                id: countdownThird
                color: "green"
                opacity: 0
                width: parent.width
                height: width
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                }
            }

            Connections {
                target: GameManager
                onShowCountdown: {
                    countdownFirst.opacity = 0
                    countdownSecond.opacity = 0
                    countdownThird.opacity = 0
                    countdownTimer.progress = 0
                    countdownTimer.restart()
                }
                onGameRunningChanged: {
                    countdownTimer.stop()
                }
            }

            Timer {
                id: countdownTimer
                interval: 250
                running: false
                repeat: true
                property int progress: 0

                onTriggered: {
                    if (progress === 0) {
                        countdownFirst.opacity = 0.5
                    } else if (progress === 1) {
                        countdownSecond.opacity = 0.5
                    } else {
                        countdownThird.opacity = 0.5
                        countdownTimer.stop()
                    }

                    progress++
                }
            }
        }
    }

    FastBlur {
        id: gameBlur
        anchors.fill: gameArea
        source: gameArea
        radius: 16
        visible: false;
    }

    BrightnessContrast {
        id: gameFilter
        source: gameBlur
        anchors.fill: gameBlur
        opacity: 0
        NumberAnimation on opacity {
            running: false
            id: blurAnimation
            duration: 250
            from: 1
            to: 0
        }
        brightness: 1.1
        contrast: 0.3
    }


    // List of player sprites
    Repeater {
        model: GameManager.players
        delegate: PlayerSprite {
            playerId: model.modelData.id
            height: main.scaleSize / 15
            width: height
        }
    }

    focus: true


    EndScreen {
        opacity: (GameManager.roundsPlayed >= GameManager.maxRounds) ? 1 : 0
        objectName: "endScreen"
    }

    StartScreen {
        id: startScreen
        opacity: GameManager.gameRunning ? 0 : 1
    }

    Text {
        id: aboutText
        anchors.bottom: buildId.top
        anchors.right: parent.right
        anchors.margins: 10
        color: "white"
        text: "code:martin^remarkable"
        font.pointSize: 10
        opacity: 0.5
    }

    Text {
        id: buildId
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        color: "white"
        text: GameManager.version()
        font.pointSize: 10
        opacity: 0.3
    }
}
