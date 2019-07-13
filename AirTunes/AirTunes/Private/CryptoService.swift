// Copyright 2017 Jenghis
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

class CryptoService {
    private var privateKey = Data()

    init(privateKeyPath path: String) {
        privateKey = loadKeyData(fromPath: path)
    }

    func decrypt(_ data: Data) -> Data {
        return transform(data, type: .Decrypt)
    }

    func sign(_ data: Data) -> Data {
        return transform(data, type: .Sign)
    }

    private func loadKeyData(fromPath path: String) -> Data {
        let keyString = try! String(contentsOfFile: path, encoding: .utf8)
            .match("\n([a-zA-Z0-9+=\\/\n]*)")!
            .replacingOccurrences(of: "\n", with: "")
        return Data(base64Encoded: keyString)!
    }

    private enum SecTransformType {
        case Sign
        case Decrypt
    }

    private func transform(_ input: Data, type: SecTransformType) -> Data {
        let parameters: [NSString: AnyObject] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate
        ]
        let key = SecKeyCreateFromData(
            parameters as CFDictionary, privateKey as CFData, nil)!
        var transform: SecTransform
        if type == .Sign {
            transform = SecSignTransformCreate(key, nil)!
            SecTransformSetAttribute(
                transform, kSecInputIsAttributeName, kSecInputIsRaw, nil)
        }
        else {
            transform = SecDecryptTransformCreate(key, nil)
            SecTransformSetAttribute(
                transform, kSecPaddingKey, kSecPaddingOAEPKey, nil)
        }
        SecTransformSetAttribute(
            transform, kSecTransformInputAttributeName, input as CFTypeRef, nil)
        return SecTransformExecute(transform, nil) as! Data
    }
}
