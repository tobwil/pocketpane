import PocketPaneCore
import Foundation

let output = """
List of devices attached
192.168.1.8:37149 device product:mustang model:Pixel_10_Pro device:mustang transport_id:2
ABC123 unauthorized usb:1-2 transport_id:1
"""

let devices = ADBParser.devices(from: output)
precondition(devices.count == 2)
precondition(devices[0].displayName == "Pixel 10 Pro")
precondition(devices[0].isWireless)
precondition(devices[1].state == .unauthorized)
let mdnsDevice = AndroidDevice(
    serial: "adb-ABC._adb-tls-connect._tcp",
    state: .device,
    model: "Pixel_10_Pro"
)
precondition(mdnsDevice.isWireless)
precondition(mdnsDevice.isMDNSWireless)
precondition(Endpoint.normalized(" 192.168.1.8:37149 ") == "192.168.1.8:37149")
precondition(Endpoint.normalized("192.168.1.8", defaultPort: 5555) == "192.168.1.8:5555")
precondition(Endpoint.normalized("192.168.1.8:99999") == nil)
precondition(ADBParser.ipAddress(fromRoute: "192.168.1.0/24 dev wlan0 proto kernel scope link src 192.168.1.8") == "192.168.1.8")

let mdns = """
List of discovered mdns services
adb-ABC-QXjCrW  _adb-tls-pairing._tcp  192.168.1.8:33861
adb-ABC-TnSdi9  _adb-tls-connect._tcp  192.168.1.8:33015
"""
let services = ADBParser.mdnsServices(from: mdns)
precondition(services.count == 2)
precondition(services[0].kind == .pairing)
precondition(services[1].kind == .connection)
precondition(services[1].endpoint == "192.168.1.8:33015")

let appOutput = """
[server] INFO: List of apps:
 * Kamera                         com.google.android.GoogleCamera
 * Automatische Transkription
                                  com.google.audio.scribe
 - WhatsApp                       com.whatsapp
"""
let apps = ADBParser.apps(fromScrcpyOutput: appOutput)
precondition(apps.count == 3)
precondition(apps.contains { $0.name == "WhatsApp" && $0.packageName == "com.whatsapp" })
precondition(apps.contains { $0.name == "Automatische Transkription" && $0.isSystem })

print("Core checks passed")
