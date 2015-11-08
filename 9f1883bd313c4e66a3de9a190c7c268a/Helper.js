//------------------------------------------------------------------------------

function helperSayHi(){
    console.log("Helper says Hi.")
}

//------------------------------------------------------------------------------

//take actions based on whetehr user already has local copies of tpk and gdb
function doorkeeper(){
    updatesCheckfile.refresh()
    gdbfile.refresh()
    tpkfile.refresh()

    if (!gdbfile.exists) {
        gdbinfobuttontext.text = " Download floor plan operational layers to be able to proceed. "
    }
    else if (updatesCheckfile.exists) {
        gdbinfobuttontext.text = " Download updates for floor plan operational layers. Last updates downloaded " + updatesCheckfile.lastModified.toLocaleString("MM.dd.yyyy hh:mm ap") + "."
    }
    else {gdbinfobuttontext.text = " Download updates for floor plan operational layers. Last updates downloaded " + gdbfile.lastModified.toLocaleString("MM.dd.yyyy hh:mm ap") + "."
    }

    if (!tpkFolder.exists){
        tpkinfobuttontext.text = " Download the basemap tile package to be able to proceed. "
    }
    else {tpkinfobuttontext.text = " Download updates for background map layer. Last updates downloaded " + tpkfile.lastModified.toLocaleString("MM.dd.yyyy hh:mm ap") + "."
    }

    if (!tpkFolder.exists || !gdbfile.exists){
        proceedbuttoncontainer.color = "red"
        proceedbuttoncontainermousearea.enabled = false
    }
    else{proceedbuttoncontainer.color = "green"
         proceedbuttoncontainermousearea.enabled = true
    }
}

//----------------------------------------------------------------------
//add all layers to the map
function addAllLayers(){
    map.addLayer(localBuildingsLayer);
    map.addLayer(localRoomsLayer);
    map.addLayer(localLinesLayer);
}

//----------------------------------------------------------------------
//take actions when app is not ready to download or sync .geodatabase
function preventGDBSync(){
    gdbinfobuttontext.text = "  At this time the app is unable to download updates for floor plan operational layers.  "
}

