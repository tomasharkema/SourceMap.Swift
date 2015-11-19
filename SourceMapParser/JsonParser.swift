//
//  JsonParser.swift
//  SourceMapParser
//
//  Created by Tomas Harkema on 15-11-15.
//  Copyright © 2015 Tomas Harkema. All rights reserved.
//

import Foundation

func parseJson(data: NSData) -> [NSString: AnyObject]? {
  let result = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
  return result as? [NSString: AnyObject]
}