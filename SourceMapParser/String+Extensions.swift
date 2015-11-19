//
//  String+Extensions.swift
//  SourceMapParser
//
//  Created by Tomas Harkema on 18-11-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

extension String {
  func repeatChar(repeats: Int) -> String {
    return (0..<repeats).map { _ in
      self
    }.joinString("")
  }
}
