import CoreAudio
import Foundation

let systemObject = AudioObjectID(kAudioObjectSystemObject)

// MARK: - Configuration

let preferredInputSubstring = ProcessInfo.processInfo.environment["PODBLOCK_PREFERRED_INPUT"] ?? "DJI"

// MARK: - Logging

func log(_ message: String) {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let timestamp = formatter.string(from: Date())
    print("[\(timestamp)] \(message)")
    fflush(stdout)
}

// MARK: - CoreAudio Helpers

func getDeviceName(_ id: AudioDeviceID) -> String? {
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioObjectPropertyName,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain)
    var name: Unmanaged<CFString>?
    var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    guard AudioObjectGetPropertyData(id, &address, 0, nil, &size, &name) == noErr,
          let cfName = name?.takeUnretainedValue()
    else { return nil }
    return cfName as String
}

func getAllDeviceIDs() -> [AudioDeviceID] {
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain)
    var size: UInt32 = 0
    AudioObjectGetPropertyDataSize(
        systemObject, &address, 0, nil, &size)
    let count = Int(size) / MemoryLayout<AudioDeviceID>.size
    var ids = [AudioDeviceID](repeating: 0, count: count)
    AudioObjectGetPropertyData(
        systemObject, &address, 0, nil, &size, &ids)
    return ids
}

func hasInputStreams(_ id: AudioDeviceID) -> Bool {
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyStreams,
        mScope: kAudioObjectPropertyScopeInput,
        mElement: kAudioObjectPropertyElementMain)
    var size: UInt32 = 0
    let status = AudioObjectGetPropertyDataSize(id, &address, 0, nil, &size)
    return status == noErr && size > 0
}

func getDefaultInputDevice() -> AudioDeviceID? {
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultInputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain)
    var deviceID: AudioDeviceID = 0
    var size = UInt32(MemoryLayout<AudioDeviceID>.size)
    guard AudioObjectGetPropertyData(
        systemObject, &address, 0, nil, &size, &deviceID) == noErr
    else { return nil }
    return deviceID
}

func setDefaultInputDevice(_ id: AudioDeviceID) -> Bool {
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultInputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain)
    var deviceID = id
    let status = AudioObjectSetPropertyData(
        systemObject, &address, 0, nil,
        UInt32(MemoryLayout<AudioDeviceID>.size), &deviceID)
    return status == noErr
}

func findPreferredInputDevice() -> (AudioDeviceID, String)? {
    for id in getAllDeviceIDs() {
        guard hasInputStreams(id),
              let name = getDeviceName(id),
              name.localizedCaseInsensitiveContains(preferredInputSubstring)
        else { continue }
        return (id, name)
    }
    return nil
}

// MARK: - State

var knownIDs = Set<AudioDeviceID>()
var nameCache: [AudioDeviceID: String] = [:]

func refreshCache() {
    let ids = getAllDeviceIDs()
    knownIDs = Set(ids)
    for id in ids { nameCache[id] = getDeviceName(id) }
}

// MARK: - Input Switching

func switchToPreferredInputIfNeeded() {
    // Check if current default input is AirPods
    guard let currentInputID = getDefaultInputDevice(),
          let currentInputName = getDeviceName(currentInputID),
          currentInputName.localizedCaseInsensitiveContains("airpods")
    else { return }

    log("Default input is currently: \(currentInputName)")

    guard let (preferredID, preferredName) = findPreferredInputDevice() else {
        log("Preferred input device matching \"\(preferredInputSubstring)\" not found — no switch")
        return
    }

    if setDefaultInputDevice(preferredID) {
        log("Switched default input: \(currentInputName) -> \(preferredName)")
    } else {
        log("ERROR: Failed to set default input to \(preferredName)")
    }
}

// MARK: - CoreAudio Callback

func onDeviceListChanged(
    _: AudioObjectID, _: UInt32,
    _: UnsafePointer<AudioObjectPropertyAddress>,
    _: UnsafeMutableRawPointer?
) -> OSStatus {
    let currentIDs = Set(getAllDeviceIDs())

    var airpodsConnected = false

    for id in currentIDs.subtracting(knownIDs) {
        let name = getDeviceName(id) ?? "Unknown"
        nameCache[id] = name
        log("Device connected: \(name) (ID: \(id))")
        if name.localizedCaseInsensitiveContains("airpods") {
            airpodsConnected = true
        }
    }

    for id in knownIDs.subtracting(currentIDs) {
        let name = nameCache.removeValue(forKey: id) ?? "Unknown"
        log("Device disconnected: \(name) (ID: \(id))")
    }

    knownIDs = currentIDs

    if airpodsConnected {
        // Small delay: macOS may not have switched the default input yet
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            switchToPreferredInputIfNeeded()
        }
    }

    return noErr
}

// MARK: - Main

refreshCache()

// Log current state
log("podblock started")
log("Preferred input device substring: \"\(preferredInputSubstring)\"")

if let currentInputID = getDefaultInputDevice(),
   let currentInputName = getDeviceName(currentInputID) {
    log("Current default input: \(currentInputName) (ID: \(currentInputID))")
}

if let (_, preferredName) = findPreferredInputDevice() {
    log("Preferred input device found: \(preferredName)")
} else {
    log("WARNING: No input device matching \"\(preferredInputSubstring)\" currently connected")
}

log("Monitoring for AirPods connections...")

// Also do an initial check in case AirPods are already the default input
switchToPreferredInputIfNeeded()

// Register listener
var address = AudioObjectPropertyAddress(
    mSelector: kAudioHardwarePropertyDevices,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain)

let status = AudioObjectAddPropertyListener(
    systemObject, &address, onDeviceListChanged, nil)
guard status == noErr else {
    log("FATAL: Failed to register CoreAudio listener (error \(status))")
    exit(1)
}

// Also listen for default input device changes directly
var inputAddress = AudioObjectPropertyAddress(
    mSelector: kAudioHardwarePropertyDefaultInputDevice,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain)

func onDefaultInputChanged(
    _: AudioObjectID, _: UInt32,
    _: UnsafePointer<AudioObjectPropertyAddress>,
    _: UnsafeMutableRawPointer?
) -> OSStatus {
    if let id = getDefaultInputDevice(), let name = getDeviceName(id) {
        log("Default input changed to: \(name) (ID: \(id))")
        if name.localizedCaseInsensitiveContains("airpods") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                switchToPreferredInputIfNeeded()
            }
        }
    }
    return noErr
}

let inputStatus = AudioObjectAddPropertyListener(
    systemObject, &inputAddress, onDefaultInputChanged, nil)
if inputStatus != noErr {
    log("WARNING: Failed to register default input listener (error \(inputStatus))")
}

RunLoop.main.run()
