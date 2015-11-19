//
//  Base64.swift
//  SourceMapParser
//
//  Created by Tomas Harkema on 15-11-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

let Base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".characters.enumerate()

let VLQBaseShift = 5;
let VLQBase = 1 << VLQBaseShift
let VLQBaseMask = VLQBase - 1
let VLQContinuationBit = VLQBase


class Base64 {
  static func encode(char: Character) -> Int? {
    return Base64Chars.filter { (inx, base64char) in
      base64char == char
    }.first.map{$0.index}
  }

  private static func fromVLQSigned(aValue: Int) -> Int {
    let isNegative = (aValue & 1) == 1;
    let shifted = aValue >> 1;
    return isNegative ? -shifted : shifted;
  }

  static func decodeVQLEncode(string: String) -> [Int]? {
    var index = 0
    var base64Values = [Int]()

    for _ in string.characters {
      var continuation = false
      var digit = 0
      var result = 0
      var shift = 0

      repeat {
        if index >= string.characters.count {
          break
        }
        digit = encode(string.characters[string.characters.startIndex.advancedBy(index)])!
        index++
        continuation = digit & VLQContinuationBit != 0
        digit &= VLQBaseMask
        result = result + (digit << shift)
        shift += VLQBaseShift
      } while continuation

      base64Values.append(fromVLQSigned(result))
    }

    return base64Values
  }
}
