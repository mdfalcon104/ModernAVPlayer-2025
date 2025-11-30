// The MIT License (MIT)
//
// ModernAVPlayer
// Copyright (c) 2018 Raphael Ankierman <raphael.ankierman@radiofrance.com>
//
// PlayerContextDelegateProxy.swift
// Created by Jean-Charles Dessaint on 16/05/2018.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

// Compilation failed from SPM without this import
import ModernAVPlayer2
import RxCocoa
import RxSwift

extension ModernAVPlayer2: HasDelegate {
    public typealias Delegate = ModernAVPlayerDelegate
}

public class RxPlayerContextDelegateProxy: DelegateProxy<ModernAVPlayer2, ModernAVPlayerDelegate>,
    DelegateProxyType,
ModernAVPlayerDelegate {
    
    // MARK: - Initialization
    
    public init(playerContext: ModernAVPlayer2) {
        super.init(parentObject: playerContext, delegateProxy: RxPlayerContextDelegateProxy.self)
    }
    
    public static func registerKnownImplementations() {
        register { RxPlayerContextDelegateProxy(playerContext: $0) }
    }
    
    // MARK: - Proxy Subjects
    
    lazy var stateSubject = PublishSubject<ModernAVPlayer2.State>()
    lazy var currentMediaSubject = PublishSubject<PlayerMedia?>()
    lazy var currentTimeSubject = PublishSubject<Double>()
    lazy var itemDurationSubject = PublishSubject<Double?>()
    lazy var unavailableActionSubject = PublishSubject<PlayerUnavailableActionReason>()
    lazy var itemPlayToEndTimeSubject = PublishSubject<Double>()
    
    // MARK: - ModernAVPlayerDelegate
    
    public func modernAVPlayer(_ player: ModernAVPlayer2, didStateChange state: ModernAVPlayer2.State) {
        stateSubject.onNext(state)
    }
    
    public func modernAVPlayer(_ player: ModernAVPlayer2, didCurrentMediaChange media: PlayerMedia?) {
        currentMediaSubject.onNext(media)
    }
    
    public func modernAVPlayer(_ player: ModernAVPlayer2, didCurrentTimeChange currentTime: Double) {
        currentTimeSubject.onNext(currentTime)
    }
    
    public func modernAVPlayer(_ player: ModernAVPlayer2, didItemDurationChange itemDuration: Double?) {
        itemDurationSubject.onNext(itemDuration)
    }
    
    public func modernAVPlayer(_ player: ModernAVPlayer2, unavailableActionReason: PlayerUnavailableActionReason) {
        unavailableActionSubject.onNext(unavailableActionReason)
    }
    
    public func modernAVPlayer(_ player: ModernAVPlayer2, didItemPlayToEndTime endTime: Double) {
        itemPlayToEndTimeSubject.onNext(endTime)
    }
}
