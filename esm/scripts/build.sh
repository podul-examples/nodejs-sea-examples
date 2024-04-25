
# 入口文件
ENTRY="src/index.js"
# 源文件目录，将转换成 commonjs
SRC_DIR="src"
BABEL_OUT_DIR=".babel"
# ncc 打包目录
NCC_OUT_DIR=".ncc"

# 生成的可执行文件名
EXEC_NAME="hello"
# 入口文件，因为使用了 ncc，所以入口文件需要调整路径
ENTRY="$NCC_OUT_DIR/$(basename "$ENTRY")"
# 临时文件目录
SEA_PATH=".sea"

# 开始：
mkdir -p "$BABEL_OUT_DIR"
mkdir -p "$NCC_OUT_DIR"
mkdir -p "$SEA_PATH"

# 1. 转换成 commonjs
# 这里为了方便，直接使用命令行，没有生成 .babelrc 文件
npx babel "$SRC_DIR" --out-dir "$BABEL_OUT_DIR" --copy-files --presets=@babel/preset-env


# 2. 打包


# 生成一个 package.json，相当于把 babel 转换后的目录当做项目目录
echo "{\"type\": \"commonjs\"}" > "$BABEL_OUT_DIR/package.json"

ORIGINAL_PWD=$PWD
# 切换到 babel 转换后的目录
cd "$BABEL_OUT_DIR"
# 入口文件切换到 babel 转换后的目录，因为cd到了babel目录，所以只需要文件名即可
ENTRY="$(basename "$ENTRY")"

npx ncc build "$ENTRY" -o "$ORIGINAL_PWD/$NCC_OUT_DIR"

# 切回原目录
cd -


# 3. 生成可执行文件
ENTRY="$NCC_OUT_DIR/$(basename "$ENTRY")"
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