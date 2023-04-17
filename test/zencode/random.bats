load ../bats_setup
load ../bats_zencode
SUBDOC=random

@test "Copy random" {
    cat <<EOF | zexe copy_random.zen
Given nothing

When I create the random 'random'
When I copy 'random' to 'dest'

Then print 'random'
Then print 'dest'
EOF
    save_output "copy_random.out"
    assert_output '{"dest":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA=","random":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA="}'
}

@test "Read seed for random" {
    cat <<EOF | save_asset zeroseed.json
{"zeroseed": "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"}
EOF
    cat <<EOF | zexe seed.zen zeroseed.json
Given I have a 'hex' named 'zeroseed'

When I create the random object of '16' bytes
and I rename 'random object' to 'first'

When I seed the random with 'zeroseed'
and I create the random object of '16' bytes

When I verify 'random object' is equal to 'first'

Then print string 'random seed OK'
EOF
    save_output "seed.out"
    assert_output '{"output":["random_seed_OK"]}'
}

@test "Random from array" {
    cat <<EOF | zexe random_from_array.zen
rule check version 1.0.0
Given nothing
When I create the array of '32' random objects of '256' bits
and I pick the random object in 'array'
and I remove the 'random object' from 'array'
and I verify the 'random object' is not found in 'array'
Then print the 'random object'
EOF
    save_output "random_from_array.out"
    assert_output '{"random_object":"5SBll5N9mm8c0eNabWgJeQAv5yKsHeuUna5+BSeY9co="}'
}

@test "When I create the array of '' random objects of '' bits" {
    cat <<EOF | zexe array_32_256.zen
rule output encoding url64
Given nothing
When I create the array of '32' random objects of '256' bits
and I rename the 'array' to 'bonnetjes'
Then print the 'bonnetjes'
EOF
    save_output "arr.json"
    assert_output '{"bonnetjes":["XdjAYj-RY95-uyYMI8fR3-fmP5LyQaN54vyTTVKxZyA","VyJ47aH6-hysFuthAZJP-LyFxmZs6L56Ru0P-JlCbDs","5XsSIXmaZbf5ikQgMSVGjW6-YJofnEkTQL6HCgpgA9A","6UasczRKmme8SOUwelXq2y5du448E-Ms3dIvuzRnWQM","DR92VSF2l3Az1K1-LyWO13Jk1eBPmuhhPT2NbpxGgsk","vUyfVMMMHVYaO8E1eQEMC591AgvEm_0C8XvWkwdOUjk","5OZ3pH08vOIdcGfhzUUmQS0hxVuOU5edfnJt1ReFFJg","VYVQKZCn_GQdR9mu6gy1ogS3mzAxsI8LTQiWc7Q_2pc","kUmjtdzdkP7gLZAQ3Am4n1VQwGgLnEDImeDQ0F9OgBk","bWmZIej91n0gSDxXdi5F1xhL6NQZapxMC64JUwEKVk0","m7tnewtGthnnh6I78QRvQp2VmWEL37qPxX4p-7LE4O4","BI9zzAxwBz_u2WXlJpIw4IzgudgbGbmxKopjKgqOYf0","BdmP0s3Jx2Qq52sLctzLcGC4SA_yvuVOp8Mhnyekk60","m_39xIu3DVGPzHrQmEeQ7cxhqwZirNFkdreF-uGNZAQ","RBaI7NPhXzsdBwMQ7K96zWSzAk-xvIdIZVzVvzfUFGE","xNGfjivccZrNngUCk_7eD0HRuF5O67a1ZXP2LjMJ7-I","K92pVX82zraSqIaVjo_f05zj9LWoxZRvsyecsAx7Cp0","EFZOmr8weju6zXDu3acfzIEOx1TThs0C75dV3rIhZ0A","wqKrcdqo0NCgblVfTYZHAkHgH0CTGSA8JN2HIv0RDOc","xVSdE2JkMcMf_aV9RYqjgpGww6THq8397ncjD3E8Tiw","EC_n1b2K0mNCzpN5KsOIrxfo04UUWJH7qNXTsDWDUwc","mgWErshJfpk4OXrQF3SYO77VaMbL1E58CcVac7W12WY","QuZIXcyL-dL-iKsNm3zJCu6iZgDI85WpLuy91k7iAp4","-R49rUUw6isQZAaIPGoDwoPNA8hiJSVYCgdDrLVYibw","DkkLuomR3p677wM1dIsMq0trZQCzE7luapNh-mBySZw","YoTAnIKlZcDBCm8aDOQ-JeVg-h6CCBExisPCUjIqVwA","5SBll5N9mm8c0eNabWgJeQAv5yKsHeuUna5-BSeY9co","LRyhWwkzaJ62IOjHfTvZ11doFIXJabdQr7Bx3zOksv8","uuZQqj4sytqlhlUucvmidpISPwzpl2zDyZ9TZ9zakFg","kTFrEhS6hM8j7Cb2t5gbyEz3nj0cc1XvQZoSMtKOKII","nId85ZWClQzgST6ADlTZXhGVdMn7TwsWon2_gwqcSvs","B0xUR_ynNpQVzAl5-Ugh1680S50YjXsTlOquyQFirXM"]}'

}


@test "Array rename remove" {
    cat <<EOF | zexe array_rename_remove.zen arr.json
rule input encoding url64
rule output encoding hex
Given I have a 'url64 array' named 'bonnetjes'
When I pick the random object in 'bonnetjes'
and I rename the 'random object' to 'lucky one'
and I remove the 'lucky one' from 'bonnetjes'
# redundant check
and I verify the 'lucky one' is not found in 'bonnetjes'
Then print the 'lucky one'
EOF
    save_output 'array_rename_remove.out'
    assert_output '{"lucky_one":"91316b1214ba84cf23ec26f6b7981bc84cf79e3d1c7355ef419a1232d28e2882"}'
}

@test "Array random nums" {
    cat <<EOF | zexe random_numbers.zen
Given nothing
When I create the array of '64' random numbers
Then print the 'array' as 'number'
EOF
    save_output 'array_random_nums.json'
    assert_output '{"array":[55389,25280,37183,56931,47998,3110,50979,57297,59111,37439,16882,31139,64738,19859,45394,8295,8791,60792,64161,7418,5804,25067,37377,63567,34236,26310,59500,31422,60742,63503,17049,15212,31717,8466,39545,46949,35577,8260,9521,36166,48750,39520,39967,4937,48704,2695,24586,53251,18153,29612,18996,26522,18620,12517,21882,56298,23854,36539,4924,11491,53981,47919,26420,857]}'

}

@test "Array random nums modulo" {
    cat <<EOF | zexe random_numbers_modulo.zen
Given nothing
When I create the array of '64' random numbers modulo '100'
and I create the aggregation of array 'array'
Then print the 'array' as 'number'
and print the 'aggregation' as 'number'
EOF
    save_output "array_random_nums_modulo.json"
    assert_output '{"aggregation":3271,"array":[89,80,83,31,98,10,79,97,11,39,82,39,38,59,94,95,91,92,61,18,4,67,77,67,36,10,0,22,42,3,49,12,17,66,45,49,77,60,21,66,50,20,67,37,4,95,86,51,53,12,96,22,20,17,82,98,54,39,24,91,81,19,20,57]}'
}
