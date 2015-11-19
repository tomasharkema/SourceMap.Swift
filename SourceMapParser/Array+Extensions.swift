//
//  Array+Extensions.swift
//  SourceMapParser
//
//  Created by Tomas Harkema on 18-11-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation
extension Array {
  subscript (safe index: Int) -> Element? {
    return indices ~= index ? self[index] : nil
  }

  func joinString(seperator: String) -> String {
    return self.map { a in return "\(a)" }.joinWithSeparator(seperator)
  }
}

func filterOptionals<T>(array: [T?]) -> [T] {
  return array.filter { $0 != nil }.map { $0! }
}