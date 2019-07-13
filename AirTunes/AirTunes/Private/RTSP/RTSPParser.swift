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

class RTSPParser: Parser {
    private let request: String
    private let names = [
        "Active-Remote",
        "Apple-Challenge",
        "Content-Length",
        "Content-Type",
        "CSeq",
        "DACP-ID",
        "RTP-Info",
    ]

    required init?(data: Data) {
        guard let request = String(
            data: data, encoding: .utf8) else { return nil }
        self.request = request
    }

    func parse() -> [String: AnyHashable] {
        var fields = getFieldValues(for: request, fieldNames: names)
        fields["Method"] = getMethod(for: request)!
        return fields
    }

    private func getMethod(for request: String) -> String? {
        return request.match("(^\\S*)")
    }

    private func getFieldValue(for request: String,
                               fieldName: String) -> String? {
        return request.match("(\(fieldName): )(\\S*)", group: 2)
    }

    private func getFieldValues(for request: String,
                                fieldNames: [String]) -> [String: String] {
        var result = [String: String]()
        fieldNames.forEach {
            if let value = getFieldValue(for: request, fieldName: $0) {
                result[$0] = value
            }
        }
        return result
    }
}
