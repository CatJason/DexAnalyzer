#!/bin/bash

# 检查参数是否正确
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <jar1> <jar2>"
    exit 1
fi

JAR1=$1
JAR2=$2

# 获取JAR文件的名称
JAR1_NAME=$(basename "$JAR1" .jar)
JAR2_NAME=$(basename "$JAR2" .jar)

# 检查输入文件是否是 JAR 文件
if [[ "${JAR1##*.}" != "jar" ]]; then
    echo "Error: $JAR1 不是一个有效的 JAR 文件。需要输入 .jar 文件。"
    exit 1
fi

if [[ "${JAR2##*.}" != "jar" ]]; then
    echo "Error: $JAR2 不是一个有效的 JAR 文件。需要输入 .jar 文件。"
    exit 1
fi

echo "输入的 JAR 文件: $JAR1 和 $JAR2"

# 获取脚本所在目录的路径
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
echo "脚本目录: $SCRIPT_DIR"

# 创建 compareJar 目录在脚本的下级目录
OUTPUT_DIR="$SCRIPT_DIR/compareJar"
echo "创建输出目录: $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# 创建临时目录用于解压 JAR 文件在脚本的下级目录
echo "创建临时目录用于解压 JAR 文件"
TMPDIR1=$(mktemp -d "$SCRIPT_DIR/tmpdir1.XXXXXX" 2>&1)
TMPDIR2=$(mktemp -d "$SCRIPT_DIR/tmpdir2.XXXXXX" 2>&1)

# 检查临时目录是否创建成功
if [ ! -d "$TMPDIR1" ] || [ ! -d "$TMPDIR2" ]; then
    echo "Error creating temporary directories."
    exit 1
fi

echo "创建的临时目录: $TMPDIR1 和 $TMPDIR2"

# 解压 JAR 文件
echo "开始解压 $JAR1 到 $TMPDIR1"
unzip -q "$JAR1" -d "$TMPDIR1" 2>&1 || { echo "Error extracting $JAR1"; exit 1; }
echo "解压 $JAR1 完成"

echo "开始解压 $JAR2 到 $TMPDIR2"
unzip -q "$JAR2" -d "$TMPDIR2" 2>&1 || { echo "Error extracting $JAR2"; exit 1; }
echo "解压 $JAR2 完成"

# 提取类名并写入文件
echo "提取 $JAR1 中的类名并写入文件 $OUTPUT_DIR/${JAR1_NAME}_类.txt"
find "$TMPDIR1" -name "*.class" | sed "s#^$TMPDIR1/##;s/\.class$//;s#/#.#g" | sort > "$OUTPUT_DIR/${JAR1_NAME}_类.txt" 2>&1
if [ $? -ne 0 ]; then
    echo "Error extracting class names from $JAR1."
    exit 1
fi

echo "提取 $JAR2 中的类名并写入文件 $OUTPUT_DIR/${JAR2_NAME}_类.txt"
find "$TMPDIR2" -name "*.class" | sed "s#^$TMPDIR2/##;s/\.class$//;s#/#.#g" | sort > "$OUTPUT_DIR/${JAR2_NAME}_类.txt" 2>&1
if [ $? -ne 0 ]; then
    echo "Error extracting class names from $JAR2."
    exit 1
fi

# 查找共同的类
echo "查找共同的类并写入文件 $OUTPUT_DIR/${JAR1_NAME}_与_${JAR2_NAME}_共同的类.txt"
comm -12 "$OUTPUT_DIR/${JAR1_NAME}_类.txt" "$OUTPUT_DIR/${JAR2_NAME}_类.txt" > "$OUTPUT_DIR/${JAR1_NAME}_与_${JAR2_NAME}_共同的类.txt" 2>&1
if [ $? -ne 0 ]; then
    echo "Error finding common classes."
    exit 1
fi

# 查找各自的类
echo "查找 $JAR1 独有的类并写入文件 $OUTPUT_DIR/${JAR1_NAME}_独有的类.txt"
comm -23 "$OUTPUT_DIR/${JAR1_NAME}_类.txt" "$OUTPUT_DIR/${JAR2_NAME}_类.txt" > "$OUTPUT_DIR/${JAR1_NAME}_独有的类.txt" 2>&1
if [ $? -ne 0 ]; then
    echo "Error finding unique classes in $JAR1."
    exit 1
fi

echo "查找 $JAR2 独有的类并写入文件 $OUTPUT_DIR/${JAR2_NAME}_独有的类.txt"
comm -13 "$OUTPUT_DIR/${JAR1_NAME}_类.txt" "$OUTPUT_DIR/${JAR2_NAME}_类.txt" > "$OUTPUT_DIR/${JAR2_NAME}_独有的类.txt" 2>&1
if [ $? -ne 0 ]; then
    echo "Error finding unique classes in $JAR2."
    exit 1
fi

# 删除临时目录
echo "删除临时文件夹: $TMPDIR1 和 $TMPDIR2"
rm -rf "$TMPDIR1" "$TMPDIR2" 2>&1
if [ $? -ne 0 ]; then
    echo "Error deleting temporary directories."
    exit 1
fi

# 打印三个文件的绝对路径
echo "类比较结果的文件路径:"
echo "共同的类文件: $(readlink -f "$OUTPUT_DIR/${JAR1_NAME}_与_${JAR2_NAME}_共同的类.txt")"
echo "$JAR1_NAME 独有的类文件: $(readlink -f "$OUTPUT_DIR/${JAR1_NAME}_独有的类.txt")"
echo "$JAR2_NAME 独有的类文件: $(readlink -f "$OUTPUT_DIR/${JAR2_NAME}_独有的类.txt")"

echo "比较完成"
