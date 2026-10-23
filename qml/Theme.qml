pragma Singleton
import Quickshell
import QtQuick

Singleton {
    property string bg: "#171717"
    property string bg1: "#151515"
    property string surface: "#1a1a1a"
    property string inputSurface: "#222222"
    property string raisedSurface: "#242424"
    property string borderSubtle: "#333"
    property string textMuted: "#777"
    property string warning: "#f9cb41"

    property string fg: "#dadada"
    property string fg1: "#e7e7e7"
    property string fg2: "#dfdfdf"
    property string fg3d: "#a7a7a7"
    property string fg4d: "#c5c4c4" // d == darker

    property string fontFamily: Config.textFontFamily
    property string nerdFontFamily: Config.nerdFontFamily

    property string accent: "#979797"
    property string coverArtGlowShadow: "#80aae6" // hardcored for now

    property int fontSizeBase: 15
    property int fontSize: Math.round(fontSizeBase * Config.pillScale)
}
