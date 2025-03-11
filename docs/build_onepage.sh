#!/bin/bash

input_file="_sidebar.md"
output_file="onepage.md"
#!/bin/bash

# Function to replace []() patterns with file content
replace_markdown_includes() {
  local markdown_file="$1"

  # Check if the file exists
  if [[ ! -f "$markdown_file" ]]; then
    echo "Error: File '$markdown_file' not found."
    return 1
  fi

  # Create a temporary file for processing
  local temp_file
  temp_file=$(mktemp)

  # Use awk to process the file
  awk -v markdown_dir="$(dirname "$markdown_file")" \
	  -v markdown_file="$markdown_file" '
  # Match lines containing []() patterns
  /\[\]\([^)]+\)/ {
    # Extract the file path from the first argument inside ()
    if (match($0, /\[\]\(([^)]+)/, matches)) {
      file_path = matches[1]

      fragment = ""
      if (match($0, /:fragment=([^[:space:]]+)/, frag_matches)) {
        fragment = frag_matches[1]
      }

      # Remove any additional arguments (e.g., ":include :type=code json")
      sub(/ .*/, "", file_path)

      # Resolve relative paths
      file_path = markdown_dir "/" file_path

      # Check if the referenced file exists
      if ((getline first_line < file_path) > 0) {
        # Determine the file extension
        if (file_path ~ /\.json$/) {
          prefix = "```json"
        } else if (file_path ~ /\.zen$/) {
          prefix = "```gherkin"
        } else {
          prefix = "```"
        }
        # Start the code block
        inside_fragment = (fragment == "")
        output = prefix
        if (inside_fragment) {
          output = output "\n" first_line
        }
        # Read the rest of the file content
        while ((getline line < file_path) > 0) {
          if (fragment != "" && match(line, /^### \[[^]]+\]/)) {
            if (line ~ "^### \\[" fragment "\\]") {
              inside_fragment = 1  # Start capturing when fragment header is found
              continue
            } else if (inside_fragment) {
              inside_fragment = 0  # Stop capturing at the next fragment header
              break  # Stop at the next fragment header
            }
          }
          if (inside_fragment) {
            output = output "\n" line
          }
        }
        close(file_path)
        # End the code block
        $0 = output "\n```"

      } else {
        print(markdown_file " error: file " file_path " not found.") > "/dev/stderr"
      }
    }
  }
  { print }  # Print the processed line
  ' "$markdown_file" > "$temp_file"

  # Replace the original file with the processed content
  cat "$temp_file"
  rm -f "$temp_file"
  >&2 echo "Processed file: $markdown_file"
}

# Process the Markdown file with awk
pages=`
awk '
# Match lines that contain links
/\[.*\]\(.*\)/ {
    # Extract the link text and URL
    match($0, /\[([^\]]+)\]\(([^)]+)/, matches)
    title = matches[1]
    url = matches[2]
    # Remove any title attribute from the URL
    gsub(/ ".*"/, "", url)
    # Print the URL entry in the sitemap format
    print(url)
}
' "$input_file" \
	| grep -v '^/$'   \
	| grep -v 'ignore.$'   \
	| grep -v 'CHANGELOG'   \
	| grep -v 'CONTRIBUTING' \
	| grep -v 'lua.md$' \
	| grep -v 'ldoc/o/'
`

rm "$output_file"
for i in ${pages}; do
	replace_markdown_includes ".$i" >> "$output_file"
done
