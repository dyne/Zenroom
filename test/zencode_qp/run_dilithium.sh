#!/bin/bash

# from the article on medium.com
SUBDOC=qp/dilithium
. ../utils.sh $*
Z="`detect_zenroom_path` `detect_zenroom_conf`"

set -e

### DILITHIUM ###

#needed for Dilithium_createpublickey2.zen
cat <<EOF | save $SUBDOC  Dilithium_readsecretkeys.keys
{
"private_key": "1C0EE1111B08003F28E65E8B3BDEB037CF8F221DFCDAF5950EDB38D506D85BEF394D1695059DFF40AE256C5D5EDABFB69F5F40F37A588F50532CA408A8168AB187D0AD11522110931494BF2CAEAE36979711BC585B32F08C78496F379D604D53C0A6711A966C11312AD9A821D8086542A600A4B42C1940720242628106210A43852331709308108B188C022492C1B28412C4218B042181C8610248059C9201C0348819326C582046891868A2C28D82346A1C094200A28CE3A6491C112CC24812E0902191985062C084622451CA062C64240E1BB3312496854B4606DB2668C38268441046C9B6211404811445502442084422710B92459AA0811A91709C241003957004C504C82692D29200C0B260C0A26809190AA2300E188969E0008DD84862DA14712018051907440412409B1240118010D142819928508B1091022464A0206D1246211C838C1B4769010690CC062481846920982C24120521B15041360298446ED1A63111056AD3A840CAA84C62B00003134A53344614194004C54CE306695AB08961168ECB10808B168ED990640B94602483851AB30454262251B8251C424A0B814842C4445A102023808409B7254CC64814854D19380E601651D8326A0A918908C170E0964D18468C01328D91C4054A0061230868A2104210A8611306218A248E620689C9B24508278451200D980466DC42054424852426282221612016090BA62C0A1144E0928158480D422210A006098B246E81288CC0248090308D8436404CA68450042494B68DA2926D18B344A00085E3B805140504A4C290842281C3262D0B2066CC903198382810166CC13445C0102224C688034632D840901C20680415289A188144988D9C206E9C302CC1B820614221080310A0C28C58128553204C0330814CA48D44C08D51404C1CA72C440865A03840DA20808106858C260DE2A88C9C4411594228C42604441426A1426408C0851101869B483199B20C80464459A88C0042089882900AB54562244812960544124600C88813A061E1284D0AB9914B962099B84400314E98128500B60183A00D14150E1881101901224A06681A498DE1A28411C63121262591A06D030524A1B6089444724334125BB42041B650D0888D0B074D1C94644C208E8B8808E0300944200549864D03134E19C9840937611A43684A80900204311C1742184080C8308EE1A241C33404A3282251247188D6FEF46712CA182872AB2919678AFF9D94E743E063A39E0C35CAF72A7F2EDA28E65858520D5D8467DE747CF340653B52C268F55413F5ADDC7D49011EC33EDD537423A84288869337AEA0781A124269071451722DB3BB8F2CE5B1552F83D2AF07F25613918A9F4E6F1257603888E589308CA5F95F07143D23BAAE17520B36B6E0E94FAF6845EB2131AEC383E63BC8644EE5F1ACCBA82F9211E57AFCBF509C1131A37466BC91B357DCBBBC14CCC319C4CC6AC75FCDC82C6596D07770C8277AD370B192A0B4E05F812E0E265D2912AA29F03FC9F72DFA69C9B1291A3FC583642B235F6991A954788347F60A0328C48ECEE51BA02DFF323ABD911667CB14549B618F1C5D250CAC9E35E071601992FBEC0BAE6F74213081404744D12F2A0E04BDB265E0924CADA40D1FA1F38ACA4606BFD4575712B8260A456FDDEEEFE7CA259BCDA97B9B939A5FD2889C9B49FB7D4E3553DEA61B3339BD0E6B16BF3BB227103BF9202E72DC502E28F7CE1559A4631F372520324E4EBA07545F78BF4D94B0E5B8BF51B8F176533D5CFEA5232F283A47605FA65DDB17C891C251011C4E98EEB6EB00CB65BA31C8F025C87A9FE02DBC10C5D83A065EBA5D7B2A19D5A1CB2C160AE166E867F2AF8C7D49D63FB83A614957FC0A3B5A5C74990E9A2B02120C7E6DE37E155FB472F50F0A45E47CF5F9D7A4C82982C9DC86AE877C3FD1885943E439FB003C7A9A42F71B4FF6F0A28B140CBDBA6E71B13AC31B23DE9EAB7837E15A69F833EB7B56A71D8BC2CAF1F2A31C345BD5F46EE013A7C689372337191DAA800C0AC6C46C9FF688B1A01347F257C474AA3D97C1D63A8C00E0A37B681673F57C1C9C8FCCD46F174C74A29D84CEB71F7E6B2F8CD2B089ED43F7C96DAE81A223418C20B16F1DF3D1A978AE28F6DF35EC559D04D20EC74B224AEA31A289B015B069E9CBBBF7CF6DE94CFB2A96E4AE3462C96003CDDA87DB561AF2CE3C0BA1D90413FDCE3CCF4390C02C1CB9F654F4820EC33015457D4A629FBF39419CAB7642D6885E103FCE0D4206CCE7C12C6FC44FA33AD0864C3371A7CBE820E3B371B656A38F2E7FF18FE4A50C8AB3F85D783FB57835CED8490B84EE0D99AF0D64C483CEB6366FF54F8AC8A40DB1AFA573A4FB326C74F0236ECEF3DA7120665CCE05DD654B5071723A8348E7CD7793513819B61CB64E1328E8B22E7664BD6B41B5710D19EA8809D4450850E907DFC4D0B75F588CECE962E9E0937CE1402446A4D2891A46E6617FB29D4FCD712606F7819ECA60F7E0D5B19E7FFB57C73C16FFEEB90038410CB9FCBB5E9D51EB3EB6297E9FF6AB7088FE2D9B237BC24CF7F8290118A5E0E00A0B903FB6375C848176CD0A8C8875CC59199CDA11A87A78F65CC404330B087571FD0633E27129FDAB5A8A1F793E52412B0083FD5C74DB3CF60C2543CE7C91B2800E40203F8D99FE5FDE5B108E7EDC80EBB9BB34986EC5C5A8F580E75752907FF0F294C866C2CF1F362E840B6881BD43219201781C63B0039A95BCFB4A0FECE569DF00523CE9C084B022B3B022242E28419796ACF0A0C995F948DBFFFD30D77ED105A3C9943C406B305BC81A6A248A291548F2A67F438D966A57D53F4B7BE15354E581BE16F7AD64D164E85787DF5849C810AFC28D06482F441B5FDE3DB2ED36DD25AA6664D4D43FFA32EDA25689C9F4A5D514FC66231C5401520922524438EF1DC78D693C9718DEBBD243312674C899F18910E389C8EBE505824BCC42CD4A9ACE193768220219011F3B1F335427BFF9E8BDED5C08711A09C2B71CB964C56A8393BFD2B56E9B6B2F513E682587DC1B8ED196066326871025628036700063176D345DE384E182D6C417A32AB11095EF59BB4D171B9CF81D17AC42664DED933CCB722C69857FFC53C8E7F2474B0CB2DFF2DDC8A5C601C84A701981199BCCF74112A6EC062C4FEB601A028AF01032ADB6BD15D4C2B9550AA850AD62CCC3A3665D5212B12E0FD5C5326A1E5EB1F10D557D94605E8E3F356E08FF7FD884ED3C4205463594C9AF2F39E4B1274695234B54EECED93F460EDF1A13C2CB4B17D322F6F79FE16F0357C1C4739863E796791F8647FABF730AB00E0DA509706D94571740F61F7BAF366D2774C9B5B8C61DD6BE9819A6028B264BB2E4AEA54B56D4ECAB5B528CE0C0C0CCDB73023352CB00445BAB6F7467B4644D4361C464FAC6B5B137D32391021B475FCB5F31774FD8ECABDF65475F25574C65559CB331F41C0F498B74DD941C344C50D8E64F9578714A32561FAACEAF78148E6DA4B566826925714B17108AFDD546385A3CD454D5CAA16960916282A47C4315CE236BD9E3255C604EBDC39772DB5CE0B236"
}
EOF

# elements that are signed
cat <<EOF | save $SUBDOC  message.json
{
"message": "Dear Bob, this message was written by Alice and signed with Dilithium!" ,
"message array":[
	"Hello World! This is my string array, element [0]",
	"Hello World! This is my string array, element [1]",
	"Hello World! This is my string array, element [2]"
	],
"message dict": {
	"sender":"Alice",
	"message":"Hello Bob!",
	"receiver":"Bob"
	}
}
EOF

#---simple dilithium operations: uploading, creating private and public keys, sign/ver --#
cat <<EOF | zexe Dilithium_createprivatekey.zen | save $SUBDOC Alice_Dilithium_privatekey.keys
Rule check version 2.0.0
Scenario qp : Create the dilithium private key
Given I am 'Alice'
When I create the dilithium key
Then print the 'keyring'
EOF

cat <<EOF | zexe Dilithium_readkeys.zen -k Alice_Dilithium_privatekey.keys
Rule check version 2.0.0 
Scenario qp : Upload the dilithium key
Given I am 'Alice'
and I have the 'keyring'
Then print my 'keyring'
EOF

cat <<EOF | zexe Dilithium_createpublickey.zen -k Alice_Dilithium_privatekey.keys | save $SUBDOC Alice_Dilithium_pubkey.json
Rule check version 2.0.0 
Scenario qp : Create and publish the dilithium public key
Given I am 'Alice'
and I have the 'keyring'
When I create the dilithium public key
Then print my 'dilithium public key' 
EOF

cat <<EOF | zexe Dilithium_createpublickey2.zen -k Dilithium_readsecretkeys.keys 
Rule check version 2.0.0 
Scenario qp : Create and publish the dilithium public key
Given I am 'Alice'
and I have a 'hex' named 'private key' 
When I create the dilithium public key with secret key 'private key'
Then print my 'dilithium public key'
EOF

cat <<EOF | zexe Dilithium_sign.zen -k Alice_Dilithium_privatekey.keys -a message.json | save $SUBDOC Alice_Dilithium_sign.json
Rule check version 2.0.0 
Scenario qp : Alice signs the message

# Declearing who I am and load all the stuff
Given I am 'Alice'
and I have the 'keyring'
and I have a 'string' named 'message'
and I have a 'string array' named 'message array'
and I have a 'string dictionary' named 'message dict'

# Creating the signatures and rename them
When I create the dilithium signature of 'message'
and I rename the 'dilithium signature' to 'string dilithium signature'
When I create the dilithium signature of 'message array'
and I rename the 'dilithium signature' to 'array dilithium signature'
When I create the dilithium signature of 'message dict'
and I rename the 'dilithium signature' to 'dictionary dilithium signature'

# Printing both the messages and the signatures
Then print the 'string dilithium signature'
and print the 'array dilithium signature'
and print the 'dictionary dilithium signature'
and print the 'message'
and print the 'message array'
and print the 'message dict'
EOF

#merging Alice pubkey with Alice signature and message
jq -s '.[0]*.[1]' Alice_Dilithium_pubkey.json Alice_Dilithium_sign.json | save $SUBDOC Alice_Dilithium_data.json

cat <<EOF | zexe Dilithium_verifysign.zen -a Alice_Dilithium_data.json | save $SUBDOC Dilitihum_verifysign.json
Rule check version 2.0.0 
Scenario qp : Bob verifies Alice signature

# Declearing who I am and load all the stuff
Given that I am known as 'Bob'
and I have a 'dilithium public key' from 'Alice'
and I have a 'string' named 'message'
and I have a 'string array' named 'message array'
and I have a 'string dictionary' named 'message dict'
and I have a 'dilithium signature' named 'string dilithium signature'
and I have a 'dilithium signature' named 'array dilithium signature'
and I have a 'dilithium signature' named 'dictionary dilithium signature'

# Verifying the signatures
When I verify the 'message' has a dilithium signature in 'string dilithium signature' by 'Alice'
and I verify the 'message array' has a dilithium signature in 'array dilithium signature' by 'Alice'
and I verify the 'message dict' has a dilithium signature in 'dictionary dilithium signature' by 'Alice'

# Print the original messages and a string of success
Then print the 'message'
and print the 'message array'
and print the 'message dict'
Then print string 'Zenroom certifies that signatures are all correct!'
EOF



#--- Test for multiple Dilithium keys ---#
cat <<EOF | zexe Eve_Dilithium_pubkey.zen | save $SUBDOC Eve_Dilithium_pubkey.json
Rule check version 2.0.0 
Scenario qp : Crate Eve dilithium public key
Given I am 'Eve'
When I create the dilithium key
and I create the dilithium public key
Then print my 'dilithium public key'
EOF

#merging Alice data and Eve public key for next test
jq -s '.[0]*.[1]' Alice_Dilithium_data.json Eve_Dilithium_pubkey.json | save $SUBDOC Alice_Eve_Dilithium.json

cat <<EOF | zexe Dilithium_multiplekeys.zen -a Alice_Eve_Dilithium.json
Rule check version 2.0.0 
Scenario qp : Verify the signature among multiple pub key
Given that I am known as 'Carl'
and I have a 'dilithium public key' from 'Alice'
and I have a 'dilithium public key' from 'Eve'
and I have a 'string' named 'message'
and I have a 'dilithium signature' named 'string dilithium signature'
If I verify the 'message' has a dilithium signature in 'string dilithium signature' by 'Eve'
Then print string 'Eve'
Endif 
If I verify the 'message' has a dilithium signature in 'string dilithium signature' by 'Alice'
Then print string 'Alice'
Endif
EOF


#--- checking the possibility to use ECDH and Dilithium together ---#
cat <<EOF |zexe Bob_ECDH.zen | save $SUBDOC Bob_data.json
Rule check version 2.0.0
Scenario ecdh : Create the private and public key and sign
Given I am 'Bob'
When I create the ecdh key
and I create the ecdh public key
and I write string 'Message signed by Bob with ECDH' in 'message ECDH'
and I create the signature of 'message ECDH'
Then print my 'ecdh public key'
and print the 'signature'
and print the 'message ECDH'
EOF

#merging Alice and Bob data
jq -s '.[0]*.[1]' Alice_Dilithium_data.json Bob_data.json | save $SUBDOC Alice_Bob_data.json

cat <<EOF | zexe Dave_Verify_ECDH_Dilithium.zen -a Alice_Bob_data.json
Rule check version 2.0.0
Scenario ecdh : Dave verifies the ECDH signature
Scenario qp : Dave verifies the Dilithium signature
Given I am 'Dave'
and I have a 'ecdh public key' from 'Bob'
and I have a 'dilithium public key' from 'Alice'
and I have a 'signature'
and I have a 'dilithium signature' named 'string dilithium signature'
and I have a 'string' named 'message ECDH'
and I have a 'string' named 'message'
If I verify the 'message ECDH' has a signature in 'signature' by 'Bob'
If I verify the 'message' has a dilithium signature in 'string dilithium signature' by 'Alice'
Then print string 'Succes!!!!'
Endif
EOF

#cleaning the folder
rm *.json *.zen *.keys
