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

extension GCDAsyncSocket {
    var internetAddress: Data! {
        let address = self.localAddress!
        if isIPv6 {
            // Takes advantage of the data alignment in
            // `sockaddr_in6` to avoid messy castings
            let alignmentRange = 8..<24
            return address.subdata(in: alignmentRange)
        }
        else {
            // Same as above but with `sockaddr_in`
            let alignmentRange = 4..<8
            return address.subdata(in: alignmentRange)
        }
    }
}
