 //
//  SourceMap.swift
//  SourceMapParser
//
//  Created by Tomas Harkema on 15-11-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

struct Segment {
  let segmentData: [Int]

  var generatedColumn: Int {
    return segmentData[0]
  }

  var source: Int {
    return segmentData[1]
  }

  var orginalLine: Int {
    return segmentData[2]
  }

  var orginalColumn: Int {
    return segmentData[3]
  }

  var name: Int? {
    if segmentData.count > 4 {
      return segmentData[4]
    }
    return nil
  }

  init?(base64String: String) {

    guard let vlq = Base64.decodeVQLEncode(base64String) else {
      print("\(base64String) not conformable to Base64")
      return nil
    }
    
    segmentData = vlq
  }
}

struct Line {
  let lineNumber: Int
  let segments: SegmentGenerator
}

struct Mapping {
  let generatedLine: Int
  let generatedColumn: Int
  let source: Int
  let sourceLine: Int
  let sourceColumn: Int
  let name: Int?
}

enum ContextType {
  case Minified
  case Normal
}

enum LinesContext {
  case Line(line: String, lineColumn: Int)
  case Lines(lines: [String], lineOffset: Int, lineColumn: Int)

  func presentation() -> String {
    switch self {
    case let .Line(line, lineColumn):
      let startIndexPre = (lineColumn - 20) < 0 ? 0 : -20
      let start = line.startIndex.advancedBy(lineColumn).advancedBy(startIndexPre)
      let endIndexPost = (lineColumn + 20) > line.characters.count-1 ? 0 : 20
      let end = line.startIndex.advancedBy(lineColumn).advancedBy(endIndexPost)

      return "\(lineColumn)\n" + line.substringWithRange(start...end) + "\n" + "~".repeatChar(startIndexPre == 0 ? 0 : 20) + "^"

    case let .Lines(lines, lineOffset, lineColumn):
      return "\(lineOffset),\(lineColumn)\n" + lines.enumerate().map { idx, line -> String in
        let normalizedString = line.stringByReplacingOccurrencesOfString("\t", withString: " ")

        if lineOffset == idx {
          return normalizedString + "\n" + "~".repeatChar(lineColumn) + "^\n"
        }

        return normalizedString
      }.joinString("\n")
    }
  }
}

struct MappingContext {
  let generatedLines: LinesContext
  let sourceLines: LinesContext
  let symbolName: String?

  var presentation: String {
    var string = ""

    // source part
    string += "Source: \(symbolName ?? "")\n\n"
    string += sourceLines.presentation()

    // generated part:
    string += "\n\nGenerated: \n\n"

    string += generatedLines.presentation()


    return string
  }
}

struct SourceMap {

  let version: Int
  let file: String
  let sources: [String]
  let names: [String]
  let mappings: String
  let generatedType: ContextType
  let sourceType: ContextType
  let generatedLines: [String]
  let sourceLines: [String]

  static func fromData(sourceMap: NSData, generated: String, source: String) -> SourceMap? {
    guard let sourceJson = parseJson(sourceMap) else {
      print("Source json not readable")
      return nil
    }

    guard let version = sourceJson["version"] as? Int else {
      print("Version not found")
      return nil
    }

    guard let file = sourceJson["file"] as? String else {
      print("File not found")
      return nil
    }

    guard let sources = sourceJson["sources"] as? [String] else {
      print("Sources not found")
      return nil
    }

    guard let names = sourceJson["names"] as? [String] else {
      print("Names not found")
      return nil
    }

    guard let mappings = sourceJson["mappings"] as? String else {
      print("Mappings not found")
      return nil
    }

    return SourceMap(version: version, file: file, sources: sources, names: names, mappings: mappings, generatedType: .Minified, sourceType: .Normal, generatedLines: generated.componentsSeparatedByString("\n"), sourceLines: source.componentsSeparatedByString("\n"))
  }

  private func generateLines() -> LineSequence {
    return LineSequence(lines: mappings.componentsSeparatedByString(";").enumerate().generate())
  }

  func regenerateMappings() -> MappingSequence {
    return MappingSequence(lines: generateLines().enumerate().generate())
  }

  private func linesAndOffset(line: Int, lines: [String]) -> ([String], Int) {
    let sourceLinesContextAndOffset = (line-2...line+2).enumerate().map {
      (line: lines[safe: $0.element], offset: $0.index)
    }

    let sourceLinesContext = filterOptionals(sourceLinesContextAndOffset.map { $0.0 })
    let sourceLineOffsetArr = sourceLinesContextAndOffset.enumerate().filter {
      $0.element.line != nil && $0.element.offset == 2
    }

    return (sourceLinesContext, sourceLineOffsetArr.first.map { $0.element.1 } ?? 0)
  }

  private func lineContext(type: ContextType, lines: [String], line: Int, column: Int) -> LinesContext {
    switch type {
    case .Minified:
      return .Line(line: lines[line], lineColumn: column)

    case .Normal:
      let (lines, lineOffset) = linesAndOffset(line, lines: lines)
      return .Lines(lines: lines, lineOffset: lineOffset, lineColumn: column)
    }
  }

  func contextForMapping(mapping: Mapping) -> MappingContext {

    let generatedLine = mapping.generatedLine
    let sourceLine = mapping.sourceLine

    let generatedLinesContext = lineContext(generatedType, lines: generatedLines, line: mapping.generatedLine, column: mapping.generatedColumn)

    let sourceLinesContext = lineContext(sourceType, lines: sourceLines, line: mapping.sourceLine, column: mapping.sourceColumn)

    return MappingContext(generatedLines: generatedLinesContext,
      sourceLines: sourceLinesContext, symbolName:  mapping.name.flatMap{names[safe: $0]})
  }

}