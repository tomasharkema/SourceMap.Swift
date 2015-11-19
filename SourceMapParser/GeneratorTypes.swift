//
//  GeneratorTypes.swift
//  SourceMapParser
//
//  Created by Tomas Harkema on 19-11-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

struct SegmentGenerator: GeneratorType {
  typealias Element = Segment?

  private var index: Int = 0

  private let segments: [String]

  init(segments: [String]) {
    self.segments = segments
  }

  mutating func next() -> Element? {
    guard let segmentString = segments[safe: index++] else {
      return nil
    }

    if segmentString == "" {
      return Optional.Some(nil)
    }

    return Optional.Some(Segment(base64String: segmentString))
  }
}

struct SegmentSequence: SequenceType {
  private let segments: [String]
  func generate() -> SegmentGenerator {
    return SegmentGenerator(segments: segments)
  }
}

struct LineGenerator: GeneratorType {
  typealias Element = Line?

  private var lines: EnumerateGenerator<IndexingGenerator<Array<String>>>

  init(lines: EnumerateGenerator<IndexingGenerator<Array<String>>>) {
    self.lines = lines
  }

  mutating func next() -> Element? {
    guard let (lineNumber, lineString) = lines.next() else {
      return nil
    }

    return Line(lineNumber: lineNumber, segments: SegmentGenerator(segments: lineString.componentsSeparatedByString(",")))
  }
}

struct LineSequence: SequenceType {
  let lines: EnumerateGenerator<IndexingGenerator<Array<String>>>

  func generate() -> LineGenerator {
    return LineGenerator(lines: lines)
  }
}

struct MappingGenerator: GeneratorType {
  typealias Element = Mapping?

  private var lines: EnumerateGenerator<LineGenerator>

  init(lines: EnumerateGenerator<LineGenerator>) {
    self.lines = lines
  }

  private var previousSource = 0
  private var previousOriginalLine = 0
  private var previousName = 0
  private var previousOriginalColumn = 0

  private var previousGeneratedColumn = 0

  private var previousLine: (index: Int, element: Line?)?
  private var previousLineSegments: SegmentGenerator?

  mutating func next() -> Element? {

    if previousLine == nil {
      if let newLine = lines.next() {
        previousLine = newLine
        previousGeneratedColumn = 0
      } else {
        return nil
      }
    }

    if previousLineSegments == nil {
      if let newSegments = previousLine?.element?.segments {
        previousLineSegments = newSegments
      } else {
        return .Some(nil)
      }
    }

    if let nextSegment = previousLineSegments?.next() {

      if let segment = nextSegment {
        previousGeneratedColumn += segment.generatedColumn
        previousSource += segment.source
        previousOriginalLine += segment.orginalLine
        previousOriginalColumn += segment.orginalColumn

        return Mapping(generatedLine: previousLine!.index, generatedColumn: previousGeneratedColumn, source: previousSource, sourceLine: previousOriginalLine, sourceColumn: previousOriginalColumn, name: segment.name)
      } else {
        return .Some(nil)
      }
    } else {
      // has no extra segment, go to new line
      previousLine = nil
      previousLineSegments = nil

      return next()
    }
  }
}

struct MappingSequence: SequenceType {
  typealias Element = Mapping?

  private var lines: EnumerateGenerator<LineGenerator>

  init(lines: EnumerateGenerator<LineGenerator>) {
    self.lines = lines
  }

  func generate() -> MappingGenerator {
    return MappingGenerator(lines: lines)
  }
}

