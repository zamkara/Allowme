//
//  main.swift
//  allowme
//
//  Created by zamkara on 04/05/24.
//

import Foundation

func usage() {
  print("Usage: allowme [path_to_app]")
  print("Grant permissions to the specified app.")
  print("If no path is provided, you will be prompted to enter the app path.")
}

if CommandLine.arguments.count == 2 && (CommandLine.arguments[1] == "-h" || CommandLine.arguments[1] == "--help") {
  usage()
  exit(0)
}

let tccplusPath = "/usr/local/bin/tccplus"
let fileManager = FileManager.default

if !fileManager.fileExists(atPath: tccplusPath) {
  print("Package 'tccplus' is not found. Downloading and installing...")
  let curlTask = Process()
  curlTask.launchPath = "/usr/bin/env"
  curlTask.arguments = ["curl", "-L", "-o", "/usr/local/bin/tccplus", "https://github.com/zamkara/Allowme/raw/main/tccplus"]
  curlTask.launch()
  curlTask.waitUntilExit()

  let chmodTask = Process()
  chmodTask.launchPath = "/usr/bin/env"
  chmodTask.arguments = ["chmod", "+x", "/usr/local/bin/tccplus"]
  chmodTask.launch()
  chmodTask.waitUntilExit()
} else {
  print("Set app permissions...")
}

var folderPath: String
if CommandLine.arguments.count == 1 {
  print("Enter the folder path to execute:")
  folderPath = readLine() ?? ""
} else {
  folderPath = CommandLine.arguments[1]
}

folderPath = folderPath.replacingOccurrences(of: #"\"#, with: "")

let appURL = URL(fileURLWithPath: folderPath)

if !fileManager.changeCurrentDirectoryPath(appURL.path) {
  print("Failed to enter the folder: \(appURL.path)")
  exit(1)
}

let contentsURL = URL(fileURLWithPath: "Contents", relativeTo: appURL)

if !fileManager.changeCurrentDirectoryPath(contentsURL.path) {
  print("Failed to enter the Contents folder")
  exit(1)
}

let infoPlistURL = URL(fileURLWithPath: "Info.plist", relativeTo: contentsURL)

guard let infoPlistData = fileManager.contents(atPath: infoPlistURL.path) else {
  print("Failed to open Info.plist")
  exit(1)
}

guard let infoPlistString = String(data: infoPlistData, encoding: .utf8) else {
  print("Failed to read Info.plist")
  exit(1)
}

let pattern = "<key>CFBundleIdentifier</key>\\s*<string>(.*?)</string>"
guard let regex = try? NSRegularExpression(pattern: pattern) else {
  print("Invalid regex pattern")
  exit(1)
}

let range = NSRange(infoPlistString.startIndex..., in: infoPlistString)
if let match = regex.firstMatch(in: infoPlistString, options: [], range: range) {
  let bundleIdentifierRange = match.range(at: 1)
  if let swiftRange = Range(bundleIdentifierRange, in: infoPlistString) {
    let bundleIdentifier = String(infoPlistString[swiftRange])
    let tccplusTask = Process()
    tccplusTask.launchPath = tccplusPath
    tccplusTask.arguments = ["add", "All", bundleIdentifier]
    tccplusTask.launch()
    tccplusTask.waitUntilExit()
  } else {
    print("Failed to extract the bundle identifier value")
    exit(1)
  }
} else {
  print("Failed to find the bundle identifier in Info.plist")
  exit(1)
}
