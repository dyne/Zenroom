
local ED = require'ed'

When("create the '' of '' with the eddsa key", function(signatures, tx)
    empty(tx)
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

    ACK[signatures] = planetmint_output_signatures
    new_codec(signatures, {zentype='array', luatype='table', encoding='hex'})
end)
