rm -r haxelib/promhx
rm promhx.zip
cp -r src/* haxelib

zip -r promhx.zip haxelib -x "*.DS_Store" "*.un~"
