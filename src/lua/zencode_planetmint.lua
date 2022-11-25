
local ED = require'ed'

When("create the planetmint output signatures of ''", function(tx_name)
    empty'planetmint_output_signatures'
    local serialized_tx = have(tx_name):string()
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

    ACK['planetmint_output_signatures'] = planetmint_output_signatures
    new_codec('planetmint_output_signatures', {zentype='array', luatype='table', encoding='hex'})
end)
