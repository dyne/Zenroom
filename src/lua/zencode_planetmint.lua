--[[
--This file is part of zenroom
--
--Copyright (C) 2022-2025 Dyne.org foundation
--designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License as
--published by the Free Software Foundation, either version 3 of the
--License, or (at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--You should have received a copy of the GNU Affero General Public License 
--along with this program.  If not, see <https://www.gnu.org/licenses/>.
--
--Last modified by Matteo Cristino
--on Monday, 22th December 2025
--]]

local ED = require'ed'

When("create planetmint signatures of ''", function(tx)
    empty'planetmint_signatures'
    local serialized_tx = have(tx):string()
    local tx = JSON.decode(serialized_tx)

    local sk = havekey'eddsa'
    local planetmint_output_signatures = {}
    local SHA256 = hash.new('sha3_256')

    for index, input in pairs(tx.inputs) do
        local transactionUniqueFulfillment = nil
        if input.fulfills then
            transactionUniqueFulfillment = serialized_tx .. input.fulfills.transaction_id .. input.fulfills.output_index
        else
            transactionUniqueFulfillment = serialized_tx
        end
        local transactionHash = SHA256:process(O.from_string(transactionUniqueFulfillment))
        local signature = ED.sign(sk, transactionHash)
        table.insert(planetmint_output_signatures, signature)
    end

    ACK['planetmint_signatures'] = planetmint_output_signatures
    new_codec('planetmint_signatures', {zentype='a', luatype='table', encoding='hex'})
end)
