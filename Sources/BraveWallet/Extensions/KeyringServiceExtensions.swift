// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveCore
import OrderedCollections

extension BraveWalletKeyringService {
  
  // Fetches all keyrings for all given coin types
  func keyrings(
    for coins: OrderedSet<BraveWallet.CoinType>
  ) async -> [BraveWallet.KeyringInfo] {
    var allKeyrings: [BraveWallet.KeyringInfo] = []
    allKeyrings = await withTaskGroup(
      of: BraveWallet.KeyringInfo.self,
      returning: [BraveWallet.KeyringInfo].self,
      body: { @MainActor group in
        let keyringIds: [BraveWallet.KeyringId] = coins.flatMap(\.keyringIds)
        for keyringId in keyringIds {
          group.addTask { @MainActor in
            await self.keyringInfo(keyringId)
          }
        }
        return await group.reduce([BraveWallet.KeyringInfo](), { partialResult, prior in
          return partialResult + [prior]
        })
        .sorted(by: { lhs, rhs in
          if lhs.coin == .fil && rhs.coin == .fil {
            return lhs.id == BraveWallet.KeyringId.filecoin
          } else {
            return (lhs.coin ?? .eth).sortOrder < (rhs.coin ?? .eth).sortOrder
          }
        })
      }
    )
    return allKeyrings
  }
  
  // Fetches all keyrings for all given keyring IDs
  func keyrings(
    for keyringIds: [BraveWallet.KeyringId]
  ) async -> [BraveWallet.KeyringInfo] {
    var allKeyrings: [BraveWallet.KeyringInfo] = []
    allKeyrings = await withTaskGroup(
      of: BraveWallet.KeyringInfo.self,
      returning: [BraveWallet.KeyringInfo].self,
      body: { @MainActor group in
        for keyringId in keyringIds {
          group.addTask { @MainActor in
            await self.keyringInfo(keyringId)
          }
        }
        return await group.reduce([BraveWallet.KeyringInfo](), { partialResult, prior in
          return partialResult + [prior]
        })
        .sorted(by: { lhs, rhs in
          (lhs.coin ?? .eth).sortOrder < (rhs.coin ?? .eth).sortOrder
        })
      }
    )
    return allKeyrings
  }
}
