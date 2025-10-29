//
//  StatusParser.swift
//  Testicool
//
//  Created by Claude Code
//  Copyright © 2025 Testicool Team. All rights reserved.
//

import Foundation

/// Parses status strings received from the Testicool firmware
struct StatusParser {

    // MARK: - Main Parsing Method

    /// Parse a status string from the device
    /// Expected format: STATUS:{State:ON,Speed:70%,Runtime:5m,Remaining:25m,WaterTemp:10.0C,SkinTemp:34.5C}
    static func parseStatus(_ statusString: String) -> ParsedStatus? {
        // Remove "STATUS:" prefix if present
        let cleanString = statusString.replacingOccurrences(of: "STATUS:", with: "")

        // Remove curly braces
        let content = cleanString
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")

        // Split by comma to get key-value pairs
        let pairs = content.split(separator: ",")

        var state: PumpState?
        var speed: Int?
        var runtimeMinutes: Int?
        var remainingMinutes: Int?
        var waterTemperature: Double?
        var skinTemperature: Double?

        for pair in pairs {
            let keyValue = pair.split(separator: ":")
            guard keyValue.count == 2 else { continue }

            let key = String(keyValue[0]).trimmingCharacters(in: .whitespaces)
            let value = String(keyValue[1]).trimmingCharacters(in: .whitespaces)

            switch key {
            case "State":
                state = PumpState(rawValue: value)

            case "Speed":
                // Remove '%' symbol and convert to 0-255 range
                let percentString = value.replacingOccurrences(of: "%", with: "")
                if let percent = Int(percentString) {
                    speed = Int((Double(percent) / 100.0) * 255.0)
                }

            case "Runtime":
                runtimeMinutes = parseTimeValue(value)

            case "Remaining":
                remainingMinutes = parseTimeValue(value)

            case "WaterTemp":
                // Remove 'C' suffix and parse as double
                let tempString = value.replacingOccurrences(of: "C", with: "").trimmingCharacters(in: .whitespaces)
                waterTemperature = Double(tempString)
                print("[Parser] WaterTemp: '\(value)' -> '\(tempString)' -> \(waterTemperature ?? -999)")

            case "SkinTemp":
                // Remove 'C' suffix and parse as double
                let tempString = value.replacingOccurrences(of: "C", with: "").trimmingCharacters(in: .whitespaces)
                skinTemperature = Double(tempString)
                print("[Parser] SkinTemp: '\(value)' -> '\(tempString)' -> \(skinTemperature ?? -999)")

            case "Temp":
                // Legacy single temperature support - use as water temp
                let tempString = value.replacingOccurrences(of: "C", with: "")
                if waterTemperature == nil {
                    waterTemperature = Double(tempString)
                }

            default:
                break
            }
        }

        // Validate required fields - only state is truly required
        // Speed, runtime, and remaining are optional (may not be present when OFF)
        guard let state = state else {
            print("[Parser] ERROR: No state found in STATUS response!")
            return nil
        }

        return ParsedStatus(
            state: state,
            speed: speed ?? 0,  // Default to 0 if not present
            runtimeMinutes: runtimeMinutes ?? 0,
            remainingMinutes: remainingMinutes ?? 30,  // Default to max time
            waterTemperature: waterTemperature,
            skinTemperature: skinTemperature
        )
    }

    /// Parse temperature string
    /// Expected format: TEMP:{Water:10.0C,Skin:34.5C}
    static func parseTemperature(_ tempString: String) -> (water: Double?, skin: Double?)? {
        // Remove "TEMP:" prefix if present
        let cleanString = tempString.replacingOccurrences(of: "TEMP:", with: "")

        // Check if it's the new dual format {Water:10.0C,Skin:34.5C}
        if cleanString.contains("{") && cleanString.contains("}") {
            let content = cleanString
                .replacingOccurrences(of: "{", with: "")
                .replacingOccurrences(of: "}", with: "")

            let pairs = content.split(separator: ",")
            var waterTemp: Double?
            var skinTemp: Double?

            for pair in pairs {
                let keyValue = pair.split(separator: ":")
                guard keyValue.count == 2 else { continue }

                let key = String(keyValue[0]).trimmingCharacters(in: .whitespaces)
                let value = String(keyValue[1]).trimmingCharacters(in: .whitespaces)

                let tempValue = Double(value.replacingOccurrences(of: "C", with: "").trimmingCharacters(in: .whitespaces))

                if key == "Water" {
                    waterTemp = tempValue
                } else if key == "Skin" {
                    skinTemp = tempValue
                }
            }

            return (water: waterTemp, skin: skinTemp)
        } else {
            // Legacy single temperature format: TEMP:34.5 or 34.5C
            let singleValue = Double(cleanString.replacingOccurrences(of: "C", with: "").trimmingCharacters(in: .whitespaces))
            return (water: singleValue, skin: nil)
        }
    }

    /// Parse pump state notification
    /// Expected format: PUMP:ON or PUMP:OFF
    static func parsePumpState(_ stateString: String) -> PumpState? {
        let cleanString = stateString
            .replacingOccurrences(of: "PUMP:", with: "")
            .trimmingCharacters(in: .whitespaces)

        return PumpState(rawValue: cleanString.uppercased())
    }

    /// Parse error message
    /// Expected format: ERROR:SAFETY_SHUTOFF
    static func parseError(_ errorString: String) -> String {
        let cleanString = errorString
            .replacingOccurrences(of: "ERROR:", with: "")
            .trimmingCharacters(in: .whitespaces)

        // Convert error codes to user-friendly messages
        switch cleanString {
        case "SAFETY_SHUTOFF":
            return "Safety shutoff: Maximum runtime reached (30 minutes)"
        case "OVERHEAT":
            return "Overheat detected: Device stopped for safety"
        case "PUMP_START_FAILED":
            return "Pump failed to start. Check power connection."
        case "PUMP_NOT_RUNNING":
            return "Pump not running. Turn it on first."
        case "INVALID_SPEED_VALUE":
            return "Invalid speed value. Use 0-255."
        case "UNKNOWN_COMMAND":
            return "Command not recognized by device"
        case "CMD_TOO_LONG":
            return "Command too long"
        default:
            return "Error: \(cleanString)"
        }
    }

    /// Parse manual control notification
    /// Expected format: MANUAL:ON or MANUAL:OFF
    static func parseManualControl(_ manualString: String) -> PumpState? {
        let cleanString = manualString
            .replacingOccurrences(of: "MANUAL:", with: "")
            .trimmingCharacters(in: .whitespaces)

        return PumpState(rawValue: cleanString.uppercased())
    }

    // MARK: - Helper Methods

    /// Parse time value (e.g., "5m" -> 5, "25m" -> 25)
    private static func parseTimeValue(_ timeString: String) -> Int? {
        let cleanString = timeString
            .replacingOccurrences(of: "m", with: "")
            .replacingOccurrences(of: "min", with: "")
            .trimmingCharacters(in: .whitespaces)

        return Int(cleanString)
    }
}

// MARK: - Preview Helper

extension StatusParser {
    /// Sample status strings for testing
    static let sampleStatusStrings = [
        "STATUS:{State:ON,Speed:70%,Runtime:5m,Remaining:25m,WaterTemp:10.0C,SkinTemp:34.5C}",
        "STATUS:{State:OFF,Speed:0%,Runtime:0m,Remaining:30m,WaterTemp:12.5C,SkinTemp:35.2C}",
        "PUMP:ON",
        "PUMP:OFF",
        "TEMP:{Water:10.0C,Skin:34.5C}",
        "ERROR:SAFETY_SHUTOFF",
        "MANUAL:ON"
    ]
}
