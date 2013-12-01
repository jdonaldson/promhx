echo "removing haxelib/promhx"
rm -r haxelib
mkdir -p haxelib/promhx
echo "removing promhx.zip"
rm promhx.zip

cp haxelib.json haxelib
cp -r src/main/promhx haxelib
cp -r ./src/main/js haxelib

zip -r promhx.zip haxelib -x "*.DS_Store" "*.un~"
