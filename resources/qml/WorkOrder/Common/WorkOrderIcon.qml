import QtQuick

Image
{
    id: root

    property string name: ""
    // accent, white, muted, orange
    property string tone: "accent"

    source:
    {
        var suffix = ""
        if(tone === "white")
            suffix = "_white"
        else if(tone === "muted")
            suffix = "_muted"
        else if(tone === "orange")
            suffix = "_orange"
        return "qrc:/resources/icons/ui/" + name + suffix + ".png"
    }

    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
    sourceSize.width: 96
    sourceSize.height: 96
}
