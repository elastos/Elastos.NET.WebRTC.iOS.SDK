/*
* Copyright (c) 2020 Elastos Foundation
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import Foundation

class DataManager {

    static let shared = DataManager()

    private var history: [String: [MockMessage]] = [:]
    var me: String = ""

    func write(message: String, from: String, to: String, id: String = UUID().uuidString, date: Date = Date()) {
        assert(me.isEmpty == false, "set me user id first")
        let key: String = (from == me) ? (from + to) : (to + from)
        if history[key] == nil {
            history[key] = []
        }
        history[key]?.append(MockMessage(text: message, user: MockUser(senderId: from, displayName: from), messageId: id, date: date))
    }

    func write(image: UIImage, from: String, to: String, id: String = UUID().uuidString, date: Date = Date()) {
        assert(me.isEmpty == false, "set me user id first")
        let key: String = (from == me) ? (from + to) : (to + from)
        if history[key] == nil {
            history[key] = []
        }
        history[key]?.append(MockMessage(image: image, user: MockUser(senderId: from, displayName: from), messageId: id, date: date))
    }

    func read(from: String) -> [MockMessage] {
        assert(me.isEmpty == false, "set me user id first")
        let key: String = me + from
        return history[key] ?? []
    }
}
