//
//  main.swift
//  SwiftUSB
//
//  Created by Justin England on 10/17/15.
//  Copyright © 2015 Justin England. All rights reserved.
//

import Foundation

import IOKit
import IOKit.usb
import IOKit.usb.IOUSBLib

print("Scanning USB Bus.....\n\n\n")

//
// These constants are not imported into Swift from IOUSBLib.h as they
// are all #define constants
//

let kIOUSBDeviceUserClientTypeID:   CFUUID = CFUUIDGetConstantUUIDWithBytes(kCFAllocatorDefault,
                                                    0x9d, 0xc7, 0xb7, 0x80, 0x9e, 0xc0, 0x11, 0xD4,
                                                    0xa5, 0x4f, 0x00, 0x0a, 0x27, 0x05, 0x28, 0x61)

let kIOCFPlugInInterfaceID:         CFUUID = CFUUIDGetConstantUUIDWithBytes(kCFAllocatorDefault,
                                                    0xC2, 0x44, 0xE8, 0x58, 0x10, 0x9C, 0x11, 0xD4,
                                                    0x91, 0xD4, 0x00, 0x50, 0xE4, 0xC6, 0x42, 0x6F)

let kIOUSBDeviceInterfaceID:        CFUUID = CFUUIDGetConstantUUIDWithBytes(kCFAllocatorDefault,
                                                    0x5c, 0x81, 0x87, 0xd0, 0x9e, 0xf3, 0x11, 0xD4,
                                                    0x8b, 0x45, 0x00, 0x0a, 0x27, 0x05, 0x28, 0x61)

var usbIterator:    io_iterator_t   = io_iterator_t()
var usbDevice:      io_service_t    = io_service_t()

var usbVendorID:    UInt16          = 0

var plugInInterfacePtrPtr           = UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>>()
var score:          Int32           = 0

// From: CFPlugInCOM.h: public typealias LPVOID =  UnsafeMutablePointer<Void>()
var deviceInterfaceVoidPtr = UnsafeMutablePointer<Void>()

// create dictionary with IOUSBDevice as IOProviderClass
let matchingDictionary: NSMutableDictionary =  IOServiceMatching(kIOUSBDeviceClassName)

// get iterator for matching USB devices
let matchingServicesResult = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDictionary, &usbIterator)

if (matchingServicesResult != kIOReturnSuccess) {
    print("Error getting deviceList!")
    exit(EXIT_FAILURE)
}

// get first usbDevice
usbDevice = IOIteratorNext(usbIterator)

// usbDevice = 0 when finished iterating all devices
while(usbDevice != 0) {
	
    // io_name_t imports to swift as a tuple (Int8, ..., Int8) 128 ints
    // although in device_types.h it's defined:
    // typedef	char io_name_t[128];
    var deviceNameCString: [CChar] = [CChar](count: 128, repeatedValue: 0)
    let deviceNameResult = IORegistryEntryGetName(usbDevice, &deviceNameCString)
	
    if(deviceNameResult != kIOReturnSuccess) {
        print("Error getting device name")
        exit(EXIT_FAILURE)
    }
	
    let deviceName = String.fromCString(&deviceNameCString)!
    print("usb Device Name: \(deviceName)")
	
    // Get plugInInterface for current USB device
    let plugInInterfaceResult = IOCreatePlugInInterfaceForService(
                                        usbDevice,
                                        kIOUSBDeviceUserClientTypeID,
                                        kIOCFPlugInInterfaceID,
                                        &plugInInterfacePtrPtr,
                                        &score)
	
	
    if ( (plugInInterfacePtrPtr == nil)  || (plugInInterfaceResult != kIOReturnSuccess)) {
        print("Unable to get Plug-In Interface")
        exit(EXIT_FAILURE)
    }
	
    // dereference pointer for the plug in interface
    let plugInInterface: IOCFPlugInInterface = plugInInterfacePtrPtr.memory.memory
	
    // use plug in interface to get a device interface
    let deviceInterfaceResult = plugInInterface.QueryInterface(
                                        plugInInterfacePtrPtr,
                                        CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID),
                                        &deviceInterfaceVoidPtr)
	
    if( (deviceInterfaceResult != kIOReturnSuccess) || (deviceInterfaceVoidPtr == nil) ) {
        print("Unable to get Device Interface")
        exit(EXIT_FAILURE)
    }
	
    // derefence pointer for device interface
    let deviceInterface = (UnsafeMutablePointer<IOUSBDeviceInterface>(deviceInterfaceVoidPtr)).memory
	
    // get USB Vendor ID
    let vendorResult = deviceInterface.GetDeviceVendor(deviceInterfaceVoidPtr, &usbVendorID)
	
    if(vendorResult != kIOReturnSuccess) {
        print("Unable to get Device Vendor ID")
        exit(EXIT_FAILURE)
    }
	
    print("usb Vendor ID: \(usbVendorID)")

    usbDevice = IOIteratorNext(usbIterator)
}

exit(EXIT_SUCCESS)





