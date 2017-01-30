//
//  Module.swift
//  Noze.io
//
//  Created by Helge Hess on 26/06/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

// MARK: - Vaca

private let globalVaca = uniqueRandomArray(allCows)
public func vaca() -> String {
  return globalVaca()
}
