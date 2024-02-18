//
//  KlipschControlApp.swift
//  KlipschControl
//
//  Created by William Leese on 17/02/2024.
//

import SwiftUI
import Foundation
import CoreBluetooth

import os.log

let logger = Logger(subsystem: "KlipschControl", category: "Speaker")

let DEVICE_NAME = "Klipsch The Three Plus"

class Speaker: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    
    let VOLUME_UUID = "DA6D0FA2-0D18-442C-BABE-F85B5BAA6F11"
    let POWER_UUID = "DA6D0FE7-0D18-442C-BABE-F85B5BAA6F11"
    let INPUT_UUID = "DA6D0FD2-0D18-442C-BABE-F85B5BAA6F11"
    
    // Publish so our view is updated
    @Published var bluetoothReady = false
    @Published var deviceReady = false
    @Published var powerOn = false
    @Published var volume = Data([0x01])

    var UUIDS: [String] = []
    
    // Core Bluetooth properties
    var centralManager: CBCentralManager!
    
    var connectedPeripheral: CBPeripheral?
    
    var characteristics: [String: CBCharacteristic] = [:]
    var descriptors: [String: [CBDescriptor]] = [:]

    override init() {
        super.init()
        UUIDS = [VOLUME_UUID, POWER_UUID, INPUT_UUID]
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main, options: [CBCentralManagerOptionRestoreIdentifierKey: DEVICE_NAME])
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
       switch central.state {
       case .poweredOn:
           bluetoothReady = true
           centralManager.scanForPeripherals(withServices: nil, options: nil)
       default:
           deviceReady = false
           powerOn = false
           bluetoothReady = false
           break
       }
    }
    
    // Restore the connection to the peripherals
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        if bluetoothReady {
            if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
                for peripheral in peripherals {
                    centralManager.connect(peripheral, options: nil)
                }
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == DEVICE_NAME {
            // save a reference to the sensor tag
            connectedPeripheral = peripheral
            connectedPeripheral!.delegate = self
            
            // Request a connection to the peripheral
            centralManager.connect(connectedPeripheral!, options: nil)
            
            // Stop scanning for peripherals
            centralManager.stopScan()
        }
    }
    
    // callback connect
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral?.discoverServices(nil)
    }
    
    // callback service
    func peripheral( _ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services, error == nil else {
            logger.error("An error occurred discovering services: \(error)")
            return
        }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    // callback found characteristic
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            logger.error("An error occurred discovering characteristics: \(error)")
        }
        
        service.characteristics?.forEach({ characteristic in
            if UUIDS.contains(characteristic.uuid.uuidString) {
                characteristics[characteristic.uuid.uuidString] = characteristic
                peripheral.discoverDescriptors(for: characteristic)
                
                // read the volume value
                if characteristic.uuid.uuidString == VOLUME_UUID {
                    peripheral.readValue(for: characteristic)
                }
            }
        })
    }
    
    // callback discovery of characteristic descriptors
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        if UUIDS.contains(characteristic.uuid.uuidString) {
            descriptors[characteristic.uuid.uuidString] = characteristic.descriptors
            deviceReady = true
        }
    }
    
    // callback update characteristic
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
    }
    
    // callback characteristic update value
    // using the read value also is done here
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let e = error {
            logger.error("ERROR didUpdateValue \(e)")
            return
        }

        if characteristic.uuid.uuidString == VOLUME_UUID {
            guard let data = characteristic.value else { return }
            volume = data
            deviceReady = true
        }
        
        if characteristic.uuid.uuidString == POWER_UUID {
            guard let data = characteristic.value else { return }
            if data == Data([0x01]) {
                powerOn = true
            } else {
                connectedPeripheral?.setNotifyValue(true, for: characteristic)
                connectedPeripheral?.writeValue(Data([0x01]), for: characteristic, type: .withResponse)
                powerOn = true
            }
        }
    }
}

@main
struct KlipschControlApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
