
-- define the validation schema for participant's data 
participant = schema.Record {
   birthdate = schema.String,
   nationid  = schema.String,
   postcode  = schema.String
}

-- read_json prints a meaningful error to stderr
data = read_json(DATA, participant)
-- quits here in case the schema does not validate the input DATA

print "Schema OK:"
-- write_json prints contents in json form to stdout
write_json(data)
