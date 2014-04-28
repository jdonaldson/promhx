rm -rf bin/*
rm promhx.zip

zip -r promhx.zip . -x "*.DS_Store" "*.un~" "tags" *.git* *bin*
