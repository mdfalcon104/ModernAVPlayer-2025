// The MIT License (MIT)
//
// ModernAVPlayer
// Copyright (c) 2018 Raphael Ankierman <raphael.ankierman@radiofrance.com>
//
// MediaResource.swift
// Created by raphael ankierman on 12/10/2019.
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

import AVFoundation
import ModernAVPlayer

enum MediaResource: CustomStringConvertible {
    case live
    case remote
    case local
    case invalid
    case custom(String)

    var description: String {
        switch self {
        case .live:
            return "Live MP3"
        case .local:
            return "Local MP3"
        case .remote:
            return "Remote MP3"
        case .invalid:
            return "Invalid file - txt"
        case .custom:
            return "Custom url"
        }
    }

    var type: MediaType {
        switch self {
        case .live:
            return .stream(isLive: true)
        case .local, .remote, .invalid, .custom:
            return .clip
        }
    }

    var url: URL {
        switch self {
        case .live:
            return URL(string: "http://direct.franceinter.fr/live/franceinter-midfi.mp3")!
        case .local:
            return URL(fileURLWithPath: Bundle.main.path(forResource: "AllNew", ofType: "mp3")!)
        case .remote:
            return URL(string: "https://rr3---sn-8qj-jmgl.googlevideo.com/videoplayback?expire=1764442810&ei=Wu4qacDSOvOW1d8Pua6eiAo&ip=123.19.25.115&id=o-AE6unX5b7ujkP0zUXdVG9yoZQnncst365PEnBj3Tp6SM&itag=140&source=youtube&requiressl=yes&xpc=EgVo2aDSNQ%3D%3D&cps=301&met=1764421210,&mh=wp&mm=31,29&mn=sn-8qj-jmgl,sn-i3belne6&ms=au,rdu&mv=m&mvi=3&pl=25&rms=au,au&gcr=vn&initcwndbps=2507500&bui=AdEuB5RzaWCz0Wp_39nUuofu5nVhocxmqs0ejaGLhMuZqW6yeHRg2m0zTNza0U_HfNZYU098vrzEYHgd&vprv=1&svpuc=1&mime=audio/mp4&ns=O68K2G26rQmiqwF_hZeHDOcQ&rqh=1&gir=yes&clen=3896503&dur=240.639&lmt=1761961515347015&mt=1764420796&fvip=5&keepalive=yes&lmw=1&fexp=51557447,51565116,51565682,51580970&c=TVHTML5&sefc=1&txp=5532534&n=4s40YI3cCOgH4A&sparams=expire,ei,ip,id,itag,source,requiressl,xpc,gcr,bui,vprv,svpuc,mime,ns,rqh,gir,clen,dur,lmt&lsparams=cps,met,mh,mm,mn,ms,mv,mvi,pl,rms,initcwndbps&lsig=APaTxxMwRAIgQ9RI8oKEBUsS2rWXeaq-ViPGuDql6Op0gIguQ-gm1hkCIEV5C-APwR6Yo66zNixcrMSPONDJl-1EiPOYu0HAuJUE&sig=AJfQdSswRgIhAOmlSkmtLu27WbVGJ5CCW-MA7xwzbLIjZ0UgCyjdjzHjAiEA3NTJT1MnmuUpYSCXYSRbhJ3G23ujvkr06VW_C3wNQgY%3D")!
        case .invalid:
            return URL(fileURLWithPath: Bundle.main.path(forResource: "noreason", ofType: "txt")!)
        case .custom(let customUrl):
            return URL(string: customUrl)!
        }
    }

    var metadata: ModernAVPlayerMediaMetadata? {
        switch self {
        case .live:
            return ModernAVPlayerMediaMetadata(title: "Le live",
                                               albumTitle: "Album0",
                                               artist: "Artist0",
                                               image: UIImage(named: "sennaLive")?.jpegData(compressionQuality: 1.0))
        case .local:
            return ModernAVPlayerMediaMetadata(title: "Local clip",
                                               albumTitle: "Album2",
                                               artist: "Artist2",
                                               image: UIImage(named: "ankierman")?.jpegData(compressionQuality: 1.0),
                                               remoteImageUrl: URL(string: "https://goo.gl/U4QoQj"))
        case .remote:
            return ModernAVPlayerMediaMetadata(title: "Remote clip",
                                               albumTitle: "Album1",
                                               artist: "Artist1",
                                               image: nil)
        case .invalid, .custom:
            return nil
        }
    }

    var item: AVPlayerItem {
        return AVPlayerItem(url: url)
    }

    var playerMedia: ModernAVPlayerMedia {
        return ModernAVPlayerMedia(url: url, type: type, metadata: metadata)
    }

    var playerMediaFromItem: ModernAVPlayerMediaItem? {
        return ModernAVPlayerMediaItem(item: item, type: type, metadata: metadata)
    }
}
