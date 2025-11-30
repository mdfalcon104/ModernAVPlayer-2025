//
//  PlayerMediaEquatable.swift
//  ModernAVPlayer_Tests
//
//  Created by ankierman on 09/10/2018.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
@testable
import ModernAVPlayer2

func matchPlayerMedia(lhs: PlayerMedia, rhs: PlayerMedia) -> Bool {
    return lhs.url == rhs.url
}
