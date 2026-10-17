import QtQuick
import QtQuick.Controls

import org.qfield
import org.qgis
import Theme

Item {
  id: nextBvgStopPlugin

  // Set references
  property var mainWindow: iface.mainWindow()
  property var positionSource: iface.findItemByObjectName('positionSource')

  Component.onCompleted: {
    iface.addItemToPluginsToolbar(pluginButton)
  }

  // Button to get nearest station
  QfToolButton {
    id: pluginButton
    iconSource: 'busstop_sign.svg'
    bgcolor: Theme.darkGray
    round: true

    onClicked: {
      fetchNextBVGStop()
    }
  }

  // Function to call BVG API to get nearest station details
  function fetchNextBVGStop() {

    // Check if position is available, otherwise return
    if (!positionSource) {
      mainWindow.displayToast('Position nicht verfügbar.')
      return
    }

    // Get current position
    let coordinate = positionSource.positionInformation

    // Check coordinate validity
    if (!coordinate.longitudeValid || !coordinate.latitudeValid) {
      mainWindow.displayToast('Ungültige Position.')
      return
    }

    // Save latitude and longitude
    let lat = coordinate.latitude
    let lon = coordinate.longitude

    // URL for API request, poplated with current position latitude and longitude
    let url = `https://v6.bvg.transport.rest/locations/nearby?latitude=${ encodeURIComponent(lat) }&longitude=${ encodeURIComponent(lon) }&results=1&linesOfStops=true`

    // Send request
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
              mainWindow.displayToast('Keine Station gefunden.')
            }
          } catch (e) {
            console.error(e)
            mainWindow.displayToast('Fehler bei der Antwortverarbeitung.')
          }
        } else {
          mainWindow.displayToast('Fehler beim Abrufen der Daten.')
        }
      }
    }

    // Add timeout to prevent request taking forever
    request.timeout = 10000
    request.ontimeout = function() {
      mainWindow.displayToast('Zeitüberschreitung bei der Anfrage. Bitte erneut versuchen.')
    }

    // Show error when request fails
    request.onerror = function() {
      mainWindow.displayToast('Netzwerkfehler. Bitte die Verbindung überprüfen.')
    }

    request.open('GET', url)
    request.send()

  }
}
