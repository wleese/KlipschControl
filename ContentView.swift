//
//  ContentView.swift
//  KlipschControl
//
//  Created by William Leese on 17/02/2024.
//

import SwiftUI

let bluetooth = Data([0x00])
let digital = Data([0x01])
let usbComputer = Data([0x02])
let usbStorage = Data([0x03])
let analog = Data([0x04])


struct ContentView: View {
    @StateObject var speaker: Speaker
    init(speaker: Speaker) {
        _speaker = StateObject(wrappedValue: speaker)
    }
    
    var body: some View {
        VStack {
            Text("Speaker").font(.title).bold()
            
            if speaker.deviceReady {
                Image(systemName: "speaker.3.fill")
                    .font(.system(size: 140))
                    .padding().foregroundColor(.green).opacity(0.5)
                    .onTapGesture {
                        speaker.connectedPeripheral?.setNotifyValue(true, for: speaker.characteristics[speaker.INPUT_UUID]!)
                        speaker.connectedPeripheral?.writeValue(Data([0x01]), for: speaker.characteristics[speaker.POWER_UUID]!, type: .withResponse)
                    }
            } else {
                Image(systemName: "speaker.3.fill")
                    .font(.system(size: 140))
                    .padding().foregroundColor(.red).opacity(0.3)
                    .onTapGesture {
                        speaker.connectedPeripheral?.setNotifyValue(true, for: speaker.characteristics[speaker.INPUT_UUID]!)
                        speaker.connectedPeripheral?.writeValue(Data([0x01]), for: speaker.characteristics[speaker.POWER_UUID]!, type: .withResponse)
                    }
            }
        }.padding()
        
        Text(speaker.statusText)

        Divider()
        
        VStack {
            HStack {
                Button(action: {
                    speaker.connectedPeripheral?.setNotifyValue(true, for: speaker.characteristics[speaker.INPUT_UUID]!)
                    speaker.connectedPeripheral?.writeValue(digital, for: speaker.characteristics[speaker.INPUT_UUID]!, type: .withResponse)
                }) {
                    Text("Television")
                        .padding(.horizontal, 30)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                }
                Button(action: {
                    speaker.connectedPeripheral?.setNotifyValue(true, for: speaker.characteristics[speaker.INPUT_UUID]!)
                    speaker.connectedPeripheral?.writeValue(usbComputer, for: speaker.characteristics[speaker.INPUT_UUID]!, type: .withResponse)
                }) {
                    Text("Speaker Only")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }.padding().padding()
        
        
        VStack {
            let vol = speaker.volume.withUnsafeBytes { $0.load(as: UInt8.self) }
            Text("Volume (\(vol))").font(.title3).bold()
            
                Button(action: {
                    let integerValue = speaker.volume.withUnsafeBytes { $0.load(as: UInt8.self) }
                    let newValue = integerValue +  1
                    let data = Data([newValue])
                    
                    speaker.connectedPeripheral?.setNotifyValue(true, for: speaker.characteristics[speaker.VOLUME_UUID]!)
                    speaker.connectedPeripheral?.writeValue(data, for: speaker.characteristics[speaker.VOLUME_UUID]!, type: .withResponse)
                }) {
                    Image(systemName: "arrow.up").bold()
                        .padding(.horizontal, 60)
                        .padding(.vertical, 30)
                        .background(Color.green)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }
                Button(action: {
                    let integerValue = speaker.volume.withUnsafeBytes { $0.load(as: UInt8.self) }
                    let newValue = integerValue - 1
                    let data = Data([newValue])
                    
                    speaker.connectedPeripheral?.setNotifyValue(true, for: speaker.characteristics[speaker.VOLUME_UUID]!)
                    speaker.connectedPeripheral?.writeValue(data, for: speaker.characteristics[speaker.VOLUME_UUID]!, type: .withResponse)
                }) {
                    Image(systemName: "arrow.down").bold()
                        .padding(.horizontal, 60)
                        .padding(.vertical, 30)
                        .background(Color.red)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                }
        }.padding()
        
        Spacer()

    }
}

#Preview {
    ContentView(speaker: Speaker())
}
