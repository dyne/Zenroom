#!/bin/bash

[ "$1" = "" ] && {
	echo "Missing argument: sidebar file"
	echo "This script reads the markdown input and converts it to a valid sitemap.xml"
	exit 1
}
#!/bin/bash

# Input Markdown file
input_file="$1"

# Output sitemap file
output_file="sitemap.xml"

# Start the sitemap XML
echo '<?xml version="1.0" encoding="UTF-8"?>' > "$output_file"
echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' >> "$output_file"

# Process the Markdown file with awk
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
    print "  <url>"
    print "    <loc>https://dev.zenroom.org/#" url "</loc>"
    print "    <changefreq>weekly</changefreq>"
    print "  </url>"
}
' "$input_file" >> "$output_file"

# Close the sitemap XML
echo '</urlset>' >> "$output_file"

sed -i "s/ ':ignore'//" "$output_file"
echo "Sitemap generated at $output_file"
exit 0
