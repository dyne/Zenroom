--[[
--This file is part of zenroom
--
--Copyright (C) 2025-2026 Dyne.org foundation
--designed, written and maintained by Denis Roio
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
-- Last modified by Matteo Sangalli
-- on Monday, 20th April 2026
--]]

-- Threshold Mayo (vinaigrette)
-- See https://eprint.iacr.org/2026/710.pdf for reference

TRM = {}

TRM.f16 = {}
TRM.rand = {}
TRM.shamir = {}
TRM.additive = {}

local f16_log = {
    [0] = 0, 0, 1, 4, 2, 8, 5, 10, 3, 14, 9, 7, 6, 13, 11, 12
}

local f16_exp = {
    [0] = 1, 2, 4, 8, 3, 6, 12, 11, 5, 10, 7, 14, 15, 13, 9, 1
}

local function add_matrices(A, B)
    local C = {}
    for r = 1, #A do
        C[r] = OCTET.xor(A[r], B[r])
    end
    return C
end

local function multiply_matrix_with_constant(A, b)
    local rows = #A
    local cols = #A[1]
    local C = {}
    for r = 1, rows do
        local row = {}
        local row_array = A[r]:to_array()
        for c = 1, cols do
            local a_rc = row_array[c]
            local c_rc = TRM.f16.mul(a_rc, b)
            row[c] = string.format("%02x", c_rc)
        end
        C[r] = OCTET.from_hex(table.concat(row))
    end
    return C
end

local function generate_zero_matrix(rows, cols)
    local matrix = {}
    for r = 1, rows do
        local row = {}
        for c = 1, cols do
            row[c] = "00"
        end
        matrix[r] = OCTET.from_hex(table.concat(row))
    end
    return matrix
end

local function matrix_equal(A, B)
    if #A ~= #B then
        return false
    end
    for r = 1, #A do
        if A[r] ~= B[r] then
            return false
        end
    end
    return true
end

local function generate_coefficients(secret, t)
    local coeffs = {secret}
    for i = 1, t-1 do
        coeffs[i+1] = TRM.f16.random()
    end
    return coeffs
end

function TRM.f16.random()
    local rand_hex = OCTET.random(1):hex()
    return tonumber(rand_hex, 16) % 16
end

function TRM.f16.add(a, b)
    return a ~ b
end

function TRM.f16.mul(a, b)
    if a == 0 or b == 0 then
        return 0
    end
    local log_a = f16_log[a]
    local log_b = f16_log[b]
    local log_result = (log_a + log_b) % 15
    return f16_exp[log_result]
end

function TRM.f16.inv(a)
    if a == 0 then
        return 0
    end
    local log_a = f16_log[a]
    local log_inv = (15 - log_a) % 15
    return f16_exp[log_inv]
end

function TRM.f16.sub(a, b)
    return a ~ b
end

function TRM.f16.div(a, b)
    if b == 0 then
        error("Division by zero in F16")
    end
    if a == 0 then
        return 0
    end
    return TRM.f16.mul(a, TRM.f16.inv(b))
end

function TRM.rand.coin(amount_of_parties, lambda)
    local result = {}
    local size = lambda + 64

    for i = 1, size do
        local current = 0
        for p = 1, amount_of_parties do
            current = current ~ TRM.f16.random()
        end
        result[i] = string.format("%02x", current)
    end

    return OCTET.from_hex(table.concat(result))
end

function TRM.rand.coin_matrix(amount_of_parties, rows, cols)
    local matrix = {}
    for r = 1, rows do
        local row = {}
        for c = 1, cols do
            local current = 0
            for p = 1, amount_of_parties do
                current = current ~ TRM.f16.random()
            end
            row[c] = string.format("%02x", current)
        end
        matrix[r] = OCTET.from_hex(table.concat(row))
    end
    return matrix
end

function TRM.rand.matrix(rows, cols)
    local matrix = {}
    for r = 1, rows do
        local row = {}
        for c = 1, cols do
            row[c] = string.format("%02x", TRM.f16.random())
        end
        matrix[r] = OCTET.from_hex(table.concat(row))
    end
    return matrix
end

function TRM.rand.vector(cols)
    local vector = {}
    for c = 1, cols do
        vector[c] = string.format("%02x", TRM.f16.random())
    end
    return OCTET.from_hex(table.concat(vector))
end

function TRM.shamir.create_shares(secret, n, t, global_alphas)
    local mac_amount = #global_alphas
    local share_coeffs = generate_coefficients(secret, t)
    local shares = {}

    for x = 1, n do
        local y = share_coeffs[t]
        for j = t-1, 1, -1 do
            y = TRM.f16.add(TRM.f16.mul(y, x), share_coeffs[j])
        end
        shares[x] = y
    end

    local gamma_shares = {}
    for p = 1, n do
        gamma_shares[p] = {}
    end

    for k = 1, mac_amount do
        local gamma_secret = TRM.f16.mul(secret, global_alphas[k])
        local gamma_coeffs = generate_coefficients(gamma_secret, t)
        for x = 1, n do
            local y = gamma_coeffs[t]
            for j = t-1, 1, -1 do
                y = TRM.f16.add(TRM.f16.mul(y, x), gamma_coeffs[j])
            end
            gamma_shares[x][k] = y
        end
    end

    local result = {}
    for p = 1, n do
        result[p] = {share = shares[p], gamma = gamma_shares[p]}
    end
    return result
end

function TRM.shamir.reconstruct_secret(shares, t)
    local secret = 0
    for j = 1, t do
        local xj = j
        local lj = 1
        for m = 1, t do
            if m ~= j then
                local xm = m
                lj = TRM.f16.mul(lj, TRM.f16.div(xm, TRM.f16.sub(xm, xj)))
            end
        end
        secret = TRM.f16.add(secret, TRM.f16.mul(shares[j], lj))
    end
    return secret
end

function TRM.shamir.create_shares_for_matrix(secret_matrix, n, t, global_alphas)
    local rows = #secret_matrix
    local cols = #secret_matrix[1]
    local mac_amount = #global_alphas

    local party_shares = {}
    for p = 1, n do
        party_shares[p] = {
            shares = {},
            gamma = {}
        }
        for k = 1, mac_amount do
            party_shares[p].gamma[k] = {}
        end
    end

    for r = 1, rows do
        local row_array = secret_matrix[r]:to_array()
        local row = {}
        local gamma = {}
        for p = 1, n do
            row[p] = {}
            gamma[p] = {}
            for k = 1, mac_amount do
                gamma[p][k] = {}
            end
        end

        for c = 1, cols do
            local secret = row_array[c]
            local shares = TRM.shamir.create_shares(secret, n, t, global_alphas)
            
            for p = 1, n do
                row[p][c] = string.format("%02x", shares[p].share)
                for k = 1, mac_amount do
                    gamma[p][k][c] = string.format("%02x", shares[p].gamma[k])
                end
            end
        end

        for p = 1, n do
            party_shares[p].shares[r] = OCTET.from_hex(table.concat(row[p]))
            for k = 1, mac_amount do
                party_shares[p].gamma[k][r] = OCTET.from_hex(table.concat(gamma[p][k]))
            end
        end
    end

    return party_shares
end

function TRM.shamir.open_matrix(shares_all_parties, t)
    local rows = #shares_all_parties[1]
    local cols = #shares_all_parties[1][1]
    local secret_matrix = {}
    
    for r = 1, rows do
        local row = {}
        local party_rows = {}
        for p = 1, t do
            party_rows[p] = shares_all_parties[p][r]:to_array()
        end

        for c = 1, cols do
            local shares = {}
            for p = 1, t do
                shares[p] = party_rows[p][c]
            end

            local reconstructed_val = TRM.shamir.reconstruct_secret(shares, t)
            row[c] = string.format("%02x", reconstructed_val)
        end
        secret_matrix[r] = OCTET.from_hex(table.concat(row))
    end
    return secret_matrix
end

function TRM.shamir.add_public_left(A, B_share, party_id, alpha_shares)
    local mac_amount = #alpha_shares[1]
    local result = {shares = add_matrices(A, B_share.shares), gamma = {}}
    for k = 1, mac_amount do
        result.gamma[k] = add_matrices(multiply_matrix_with_constant(A, alpha_shares[party_id][k]), B_share.gamma[k])
    end
    return result
end

function TRM.shamir.authenticated_open_matrix(shares, t, alpha_shares)
    local parties = #shares
    local rows = #shares[1].shares
    local cols = #shares[1].shares[1]
    local mac_amount = #alpha_shares[1]
    
    local zero = generate_zero_matrix(rows, cols)

    local s_prime_shares = {}
    for p = 1, t do
        s_prime_shares[p] = shares[p].shares
    end

    local s_prime = TRM.shamir.open_matrix(s_prime_shares, t)

    for k = 1, mac_amount do
        local mu_shares = {}
        for p = 1, t do
            local s_prime_times_alpha = multiply_matrix_with_constant(s_prime, alpha_shares[p][k])
            mu_shares[p] = add_matrices(s_prime_times_alpha, shares[p].gamma[k])
        end

        local mu_open = TRM.shamir.open_matrix(mu_shares, t)
        if not matrix_equal(mu_open, zero) then
            error("MAC verification failed during authenticated opening")
        end
    end

    return s_prime
end

function TRM.shamir.create_shares_for_random_matrix(n, t, rows, cols, global_alphas)
    local random_matrix = TRM.rand.matrix(rows, cols)
    return TRM.shamir.create_shares_for_matrix(random_matrix, n, t, global_alphas)
end

function TRM.additive.create_shares_for_matrix(M, n, mac_amount, global_alphas)
    local rows = #M
    local cols = #M[1]:to_array()
    local result = {}

    for p = 1, n do
        result[p] = {shares = {}, gamma = {}}
        for k = 1, mac_amount do
            result[p].gamma[k] = {}
        end
    end

    for r = 1, rows do
        local row_array = M[r]:to_array()
        local row_shares_hex = {}
        local row_gammas_hex = {}
        for p = 1, n do
            row_shares_hex[p] = {}
            row_gammas_hex[p] = {}
            for k = 1, mac_amount do
                row_gammas_hex[p][k] = {}
            end
        end

        for c = 1, cols do
            local secret = row_array[c]
            local shares_sum = 0
            for p = 1, n-1 do
                local rnd = TRM.f16.random()
                row_shares_hex[p][c] = string.format("%02x", rnd)
                shares_sum = TRM.f16.add(shares_sum, rnd)
            end
            local last_share = TRM.f16.sub(secret, shares_sum)
            row_shares_hex[n][c] = string.format("%02x", last_share)

            for k = 1, mac_amount do
                local gamma_sum = 0
                for p = 1, n-1 do
                    local rnd_gamma = TRM.f16.random()
                    row_gammas_hex[p][k][c] = string.format("%02x", rnd_gamma)
                    gamma_sum = TRM.f16.add(gamma_sum, rnd_gamma)
                end
                local alpha_times_secret = TRM.f16.mul(secret, global_alphas[k])
                local last_gamma = TRM.f16.sub(alpha_times_secret, gamma_sum)
                row_gammas_hex[n][k][c] = string.format("%02x", last_gamma)
            end
        end

        for p = 1, n do
            result[p].shares[r] = OCTET.from_hex(table.concat(row_shares_hex[p]))
            for k = 1, mac_amount do
                result[p].gamma[k][r] = OCTET.from_hex(table.concat(row_gammas_hex[p][k]))
            end
        end
    end

    return result
end

function TRM.additive.open_matrix(shares)
    local rows = #shares[1]
    local cols = #shares[1][1]
    local result = generate_zero_matrix(rows, cols)

    for p = 1, #shares do
        result = add_matrices(result, shares[p])
    end

    return result
end

function TRM.additive.create_shares_for_random_matrix(n, rows, cols, mac_amount, global_alphas)
    local random_matrix = TRM.rand.matrix(rows, cols)
    return TRM.additive.create_shares_for_matrix(random_matrix, n, mac_amount, global_alphas)
end

return TRM

