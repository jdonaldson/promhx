echo "removing haxelib/promhx"
rm -r haxelib/promhx
echo "removing promhx.zip"
rm promhx.zip

cp -r src/* haxelib

zip -r promhx.zip haxelib -x "*.DS_Store" "*.un~"
