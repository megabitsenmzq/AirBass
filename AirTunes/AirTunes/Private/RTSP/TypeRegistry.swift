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

class TypeRegistry {
    private var typeMap = [Int: String]()
    private var tagMap = [String: Int]()
    private var tagIndex = 0

    func registerContentType(_ type: String) {
        createTag(for: type)
    }

    func tag(for contentType: String) -> Int? {
        return tagMap[contentType]
    }

    func contentType(for tag: Int) -> String? {
        return typeMap[tag]
    }

    private func createTag(for type: String) {
        tagMap[type] = tagIndex
        typeMap[tagIndex] = type
        tagIndex += 1
    }
}
