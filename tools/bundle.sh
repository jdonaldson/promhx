echo "removing haxelib/promhx"
rm -r haxelib
mkdir -p haxelib/promhx
echo "removing promhx.zip"
rm promhx.zip

cp haxelib.json haxelib
mkdir -p haxelib/lib/setImmediate
cp ./lib/setImmediate/setImmediate.js haxelib/lib/setImmediate/setImmediate.js
cp -r src/main/promhx haxelib
cp -r ./src/main/js haxelib

zip -r promhx.zip haxelib -x "*.DS_Store" "*.un~"
