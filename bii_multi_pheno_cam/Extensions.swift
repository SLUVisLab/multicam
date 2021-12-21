//
//  Extensions.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 12/20/21.
//

import Foundation
import RealmSwift

extension Results {
    func toArray() -> [Element] {
      return compactMap {
        $0
      }
    }
 }
