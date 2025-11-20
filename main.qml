import QtQuick
import QtQuick.Controls

import org.qfield
import org.qgis
import Theme

Item {
  id: nextBvgStopPlugin

  property var mainWindow: iface.mainWindow()
  property var positionSource: iface.findItemByObjectName('positionSource')

  Component.onCompleted: {
    iface.addItemToPluginsToolbar(pluginButton)
  }

  QfToolButton {
    id: pluginButton
    iconSource: 'busstop_sign.svg'
    bgcolor: Theme.darkGray
    round: true

    onClicked: {
      fetchNextBVGStop()
    }
  }

  function fetchNextBVGStop() {
    if (!positionSource) {
      mainWindow.displayToast("Position nicht verfügbar.")
      return
    }

    let coordinate = positionSource.positionInformation

    if (!coordinate.longitudeValid && !coordinate.latitudeValid) {
      mainWindow.displayToast("Ungültige Position.")
      return
    }

    let lat = coordinate.latitude
    let lon = coordinate.longitude

    console.log("Aktuelle Koordinaten:", lat, lon)

    let url = `https://v6.bvg.transport.rest/locations/nearby?latitude=${ lat }&longitude=${ lon }&results=1&linesOfStops=true`

    let request = new XMLHttpRequest()
    request.onreadystatechange = function() {
      if (request.readyState === XMLHttpRequest.DONE) {
        if (request.status === 200) {
          try {
            let response = JSON.parse(request.responseText)
            if (response.length > 0) {
              let station = response[0]
              let name = station.name
              let distance = station.distance
              mainWindow.displayToast(`Nächstgelegene Station:\n${ name }\n(${ distance } m entfernt)`)
            } else {
              mainWindow.displayToast("Keine Station gefunden.")
            }
          } catch (e) {
            console.error(e)
            mainWindow.displayToast("Fehler bei der Antwortverarbeitung.")
          }
        } else {
          mainWindow.displayToast("Fehler beim Abrufen der Daten.")
        }
      }
    }

    request.open("GET", url)
    request.send()
  }
}
