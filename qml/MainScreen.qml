/*
 * Copyright (C) 2015 Florent Revest <revestflo@gmail.com>
 *               2014 Aleksi Suomalainen <suomalainen.aleksi@gmail.com>
 * All rights reserved.
 *
 * You may use this file under the terms of BSD license as follows:
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the author nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import QtQuick 2.1
import QtQuick.Window 2.1
import QtGraphicalEffects 1.0
import org.nemomobile.time 1.0
import org.nemomobile.configuration 1.0
import org.nemomobile.lipstick 0.1
import org.asteroid.controls 1.0
import "desktop.js" as Desktop

Item {
    id: desktop
    anchors.fill: parent;
    property var switcher: null

    Component.onCompleted: {
        Desktop.instance = desktop
        Lipstick.compositor.screenOrientation = nativeOrientation
        LipstickSettings.lockScreen(true)
    }

    WallClock {
        id: wallClock
        enabled: true
        updateFrequency: WallClock.Minute
    }

    Connections {
        target: Lipstick.compositor
        onDisplayAboutToBeOn: wallClock.enabled = true
        onDisplayAboutToBeOff: wallClock.enabled = false
    }

    ConfigurationValue {
        id: watchFaceSource
        key: "/desktop/asteroid/watchface"
        defaultValue: "file:///usr/share/asteroid-launcher/watchfaces/000-default-digital.qml"
    }

    property bool switcherVisibleInHome: false;

    Component { id: topPage;    QuickSettings { id: quickSet; width: desktop.width; height: desktop.height } }
    Component { id: leftPage;   AppSwitcher   { id: switcher; width: desktop.width; height: desktop.height; visibleInHome: switcherVisibleInHome; Component.onCompleted: { desktop.switcher = switcher }} }
    Component { id: centerPage; Loader        { id: clock;    width: desktop.width; height: desktop.height; source: watchFaceSource.value } }
    Component { id: rightPage;  FeedsPage     { id: feed;     width: desktop.width; height: desktop.height } }
    Component { id: bottomPage; AppLauncher   { id: launcher; width: desktop.width; height: desktop.height; switcher: desktop.switcher } }

    Component { id: centerRow; ListView { id: centerListView // The three columns of the center row
            model: 3
            orientation: ListView.Horizontal
            width: desktop.width; height: desktop.height;
            snapMode: ListView.SnapOneItem
            cacheBuffer: width*3

            delegate: Loader {
                sourceComponent: {
                    switch (index)
                    {
                        case 0: return leftPage
                        case 1: return centerPage
                        case 2: return rightPage
                    }
                }
            }
            contentItem.onWidthChanged: positionViewAtIndex(1, ListView.Beginning)
            onContentXChanged: {
                verticalListView.interactive = centerListView.contentX == width // Only allows vertical flicking for the center item
                wallpaperBlur.radius = Math.abs(centerListView.contentX - width)/width*35
                wallpaperDarkener.brightness = Math.abs(centerListView.contentX - width)/width*(-0.2)
                wallpaper.anchors.horizontalCenterOffset = (centerListView.contentX - width)*(-0.05)
                switcherVisibleInHome = centerListView.contentX < width
            }

            Timer {
                id: delayTimer
                interval: 150
                repeat: false
                onTriggered: {
                    verticalListView.positionViewAtIndex(1, ListView.Beginning);
                    centerListView.positionViewAtIndex(1, ListView.Beginning);
                }
            }
            Connections {
                target: Lipstick.compositor
                onDisplayOff: delayTimer.start();
                onHomeActiveChanged: delayTimer.start();
            }
        }
    }

    ListView { // three rows
        id: verticalListView
        model: 3
        orientation: ListView.Vertical
        anchors.fill: parent
        snapMode: ListView.SnapOneItem
        cacheBuffer: height*3

        delegate:Loader {
            sourceComponent: {
                switch (index)
                {
                    case 0: return topPage
                    case 1: return centerRow
                    case 2: return bottomPage
                }
            }
        }
        contentItem.onHeightChanged: positionViewAtIndex(1, ListView.Beginning)
        onContentYChanged: {
            wallpaperBlur.radius = Math.abs(verticalListView.contentY - height)/height*35
            wallpaperDarkener.brightness = Math.abs(verticalListView.contentY - height)/height*(-0.2)
            wallpaper.anchors.verticalCenterOffset = (verticalListView.contentY - height)*(-0.05)
        }
    }

// Wallpaper
    ConfigurationValue {
        id: wallpaperSource
        key: "/desktop/asteroid/background_filename"
        property bool isQml: {
            var endsWithQml = /qml$/;
            return endsWithQml.test(value)
        }
        defaultValue: "file:///usr/share/asteroid-launcher/wallpapers/flatmesh.qml"
    }

    Item {
        id: wallpaper
        width:parent.width*1.1
        height:parent.height*1.1
        z: -100
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter

        Component {
            id: imageWallpaper
            Image { source: wallpaperSource.value }
        }

        Loader {
            source: wallpaperSource.isQml ? wallpaperSource.value : ""
            sourceComponent: wallpaperSource.isQml ? undefined : imageWallpaper
            anchors.fill: parent
        }
    }

    FastBlur {
        id: wallpaperBlur
        anchors.fill: wallpaper
        source: wallpaper
        z: -99
    }

    BrightnessContrast {
        id: wallpaperDarkener
        anchors.fill: wallpaperBlur
        source: wallpaperBlur
        z: -99
    }
}
