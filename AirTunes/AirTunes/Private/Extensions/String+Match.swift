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

extension String {
    /// Searches for a regex pattern in `self` and returns the first
    /// full string match or the matched capture group if the `group`
    /// argument is passed.
    ///
    /// - parameter pattern: The regex pattern to match.
    /// - parameter group: The capture group to return. Defaults to
    ///                    the full match.
    /// - returns: The first matched string if it exists; nil otherwise.
    func match(_ pattern: String, group: Int = 0) -> String? {
        let pattern = try! NSRegularExpression(pattern: pattern)
        guard let match = pattern.firstMatch(
            in: self, range: NSRange(
                location: 0, length: count)) else { return nil }
        var captureGroups = [String]()
        for i in 0..<match.numberOfRanges {
            captureGroups.append((self as NSString).substring(
                with: match.range(at: i)))
        }
        return captureGroups[group]
    }
}
