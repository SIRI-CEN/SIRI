#!/bin/bash
/usr/bin/find . -name "*.xsd" -type f | while read i; do XMLLINT_INDENT=" " xmllint --pretty 1 "$i" > "$i.pretty"; mv "$i.pretty" "$i"; done; /usr/bin/find . -name "*.xml" -type f | while read i; do XMLLINT_INDENT=" " xmllint --pretty 1 "$i" > "$i.pretty"; mv "$i.pretty" "$i"; done; /usr/bin/find . -name "*.wsdl" -type f | while read i; do XMLLINT_INDENT=" " xmllint --pretty 1 "$i" > "$i.pretty"; mv "$i.pretty" "$i"; done;
echo "finished formatting"
find examples/ -iname "*.xml" | xargs xmllint --noout --schema xsd/siri.xsd