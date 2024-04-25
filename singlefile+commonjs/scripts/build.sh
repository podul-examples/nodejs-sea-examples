set -e

# 生成的可执行文件名
EXEC_NAME="hello"
# 入口文件
ENTRY="src/index.js"
# 临时文件目录
SEA_PATH=".sea"

mkdir -p "$SEA_PATH"

# 创建配置文件
echo "{ \"main\": \"$ENTRY\", \"output\": \"$SEA_PATH/sea-prep.blob\" }" > "$SEA_PATH/sea-config.json"

# Generate the blob that contains your application script
node --experimental-sea-config "$SEA_PATH/sea-config.json"

# Copy the Node.js binary and name it as needed
cp $(command -v node) "$SEA_PATH/$EXEC_NAME"

# 注意：下面的代码每个平台都有一点区别，由于笔者使用 macOS，所以只测试过 macOS 下的效果
# 如果是mac，使用下面代码
codesign --remove-signature "$SEA_PATH/$EXEC_NAME"
npx postject "$SEA_PATH/$EXEC_NAME" NODE_SEA_BLOB "$SEA_PATH/sea-prep.blob" \
    --sentinel-fuse NODE_SEA_FUSE_fce680ab2cc467b6e072b8b5df1996b2 \
    --macho-segment-name NODE_SEA
codesign --sign - "$SEA_PATH/$EXEC_NAME"


# 其它平台参考：https://nodejs.org/api/single-executable-applications.html

echo "生成的可执行文件在：$SEA_PATH/$EXEC_NAME"
