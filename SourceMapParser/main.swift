//
//  main.swift
//  SourceMapParser
//
//  Created by Tomas Harkema on 15-11-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

let JqueryMinifiedUrl = NSURL(string: "http://code.jquery.com/jquery-1.11.3.min.js")
let JquerySourceMapUrl = NSURL(string: "http://code.jquery.com/jquery-1.11.3.min.map")
let JquerySourceUrl = NSURL(string: "http://code.jquery.com/jquery-1.11.3.js")

print("Download jQuery Files")

guard let JqueryMinifiedUrl = JqueryMinifiedUrl else {
  print("Minified URL not correct")
  exit(1)
}

guard let JquerySourceMapUrl = JquerySourceMapUrl else {
  print("Source Map URL not correct")
  exit(1)
}

guard let minifiedData = NSData(contentsOfURL: JqueryMinifiedUrl) else {
  print("Minified Data not able to download")
  exit(1)
}

guard let minifiedDataString = String(data: minifiedData, encoding: NSUTF8StringEncoding) else {
  print("Minified Data not decodable")
  exit(1)
}

guard let JquerySourceUrl = JquerySourceUrl else {
  print("Source Data not correct")
  exit(1)
}

guard let sourceData = NSData(contentsOfURL: JquerySourceUrl) else {
  print("Source Data not able to download")
  exit(1)
}

guard let sourceDataString = String(data: sourceData, encoding: NSUTF8StringEncoding) else {
  print("Source Data not decodable")
  exit(1)
}

guard let sourceMapData = NSData(contentsOfURL: JquerySourceMapUrl) else {
  print("SourceMap Data not able to download")
  exit(1)
}

print("Downloaded jQuery Files")

guard let sourceMap = SourceMap.fromData(sourceMapData, generated: minifiedDataString, source: sourceDataString) else {
  print("Could not parse files")
  exit(1)
}

print("Regenerate Mappings")

let regenerateMappings = sourceMap.regenerateMappings()

print("Regenerated Mappings")

for (idx, map) in regenerateMappings.enumerate() {
  print("\(idx)\n")
  if let map = map {
    let context = sourceMap.contextForMapping(map)
    print(context.presentation)
    print("\n\n==================\n\n")
  }
}
