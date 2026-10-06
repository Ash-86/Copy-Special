import QtQuick 2.0
import MuseScore 3.0

MuseScore {
    menuPath: "Plugins.Copy Special"
    description: "Copy individual notes."
    version: "1.0"

    //4.4 title: "Copy Special"
    //4.4 thumbnailName: "up.png"
    //4.4 categoryCode: ""

	Component.onCompleted : {
        if (mscoreMajorVersion >= 4) {
            title= "Copy Special"
            thumbnailName = "up.png"
            categoryCode = ""
        }
    }

    onRun: {
        var els = curScore.selection.elements

        if (((typeof els[0]) != "undefined") && (els[0].type == Element.NOTE)) {
            copySelection()
            return
        } else {
            console.log("Invalid selection")
            if (els.length > 0)
                console.log("els[0]="+els[0].userName())
            else
                console.log("no selection")
            return
        }
    }

    function copySelection() {

        var els = curScore.selection.elements

        var staves = {}
        var tracks = {}
        var ticks = {}
        var t1 = Infinity, t2 = -1
        var s1 = Infinity, s2 = -1

        for (var i = 0; i < els.length; i++){
            var el = els[i]
            if (el.type !== Element.NOTE) continue
            var chord = el.parent
            var seg = chord.parent
            if (!seg || seg.type !== Element.SEGMENT) continue   // skip grace notes

            var tick = seg.tick
            ticks[tick] = true
            if (tick < t1) t1 = tick
            if (tick + chord.duration.ticks > t2) t2 = tick + chord.duration.ticks

            tracks[el.track] = true
            var staff = Math.floor(el.track / 4)
            staves[staff] = true
            if (staff < s1) s1 = staff
            if (staff > s2) s2 = staff
        }

        var cursor = curScore.newCursor()

        curScore.startCmd("Copy special list selection")

        var notesDeleted = 0
        for(var s in staves) {
            for (var v = 0; v < 4; v++){
                var track = s * 4 + v
                cursor.track = track
                cursor.rewindToTick(t1)
                while (cursor.segment && (cursor.tick < t2)) {
                    var c = cursor.element
                    if (c.type == Element.CHORD) {
                        if (tracks[track] == undefined) {
                            removeElement(c)
                            removeElement(cursor.element)
                        } else {
                            for (var n = c.notes.length-1; n >= 0; n--) {
                                if (c.notes[n].selected == true) curScore.selection.deselect(c.notes[n], true)
                                else curScore.selection.select(c.notes[n], true)
                            }
                        }
                    }
                    cursor.next()
                }
            }
        }

        cmd("delete")

        curScore.selection.selectRange(t1, t2, s1, s2 + 1)

        curScore.endCmd()

        cmd("copy")
        cmd("undo")
    }
}