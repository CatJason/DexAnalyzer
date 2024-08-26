#!/bin/bash

# 设置相对路径
TOOLS_PATH="tools/dex-tools-v2.4"
APK_DIR="apk"
JD_GUI_APP="tools/jd-gui-osx-1.6.6"

UNZIP_BASE_DIR="unzip"
JAR_BASE_DIR="jar"
MERGED_BASE_DIR="mergeJar"

# 创建必要的文件夹
mkdir -p "$UNZIP_BASE_DIR"
mkdir -p "$JAR_BASE_DIR"
mkdir -p "$MERGED_BASE_DIR"

# 检查 APK 目录是否为空
if [ -z "$(ls -A $APK_DIR/*.apk 2>/dev/null)" ]; then
    echo "Error: APK directory is empty or APK files not found."
    exit 1
fi

# 处理 apk 文件夹中的每个 APK 文件
for apk_file in "$APK_DIR"/*.apk; do
    # 输出处理的 APK 文件名
    echo "Processing APK: $apk_file"
    
    # 获取 APK 文件名并去掉路径和扩展名
    apk_filename=$(basename "$apk_file" .apk)

    # 创建特定 APK 的解压和 jar 文件夹
    UNZIP_DIR="$UNZIP_BASE_DIR/$apk_filename"
    JAR_DIR="$JAR_BASE_DIR/$apk_filename"
    MERGED_JAR="$MERGED_BASE_DIR/merged_$apk_filename.jar"
    CONFLICT_LOG="$MERGED_BASE_DIR/conflict_$apk_filename.txt"

    mkdir -p "$UNZIP_DIR"
    mkdir -p "$JAR_DIR"

    # 解压 APK 文件
    unzip -qo "$apk_file" -d "$UNZIP_DIR"

    # 检查是否成功解压
    dex_files=("$UNZIP_DIR"/*.dex)
    total_dex=${#dex_files[@]}
    if [ "$total_dex" -eq 0 ]; then
        echo "Error: No DEX files found in $UNZIP_DIR. Skipping $apk_filename."
        continue
    fi

    # 读取解压后的文件夹中的所有 dex 文件并转成 jar 文件
    processed_dex=0
    for dex_file in "${dex_files[@]}"; do
        dex_filename=$(basename "$dex_file" .dex)
        jar_output="$JAR_DIR/$dex_filename.jar"
        "$TOOLS_PATH/d2j-dex2jar.sh" "$dex_file" -o "$jar_output" >/dev/null 2>&1
        processed_dex=$((processed_dex + 1))
        echo -ne "Converting: $processed_dex/$total_dex dex files\r"
    done
    echo -ne "\n"

    echo "APK: $apk_filename - DEX 文件已成功转换为 JAR 文件，保存在 $JAR_DIR 文件夹中。"

    # 检查是否成功生成 JAR 文件
    jar_files=("$JAR_DIR"/*.jar)
    total_jar=${#jar_files[@]}
    if [ "$total_jar" -eq 0 ]; then
        echo "Error: No JAR files found in $JAR_DIR. Skipping $apk_filename."
        continue
    fi

    # 创建解压临时文件夹
    TEMP_UNZIP_DIR="$apk_filename-jar解压临时文件"
    mkdir -p "$TEMP_UNZIP_DIR"

    # 初始化冲突日志
    > "$CONFLICT_LOG"

    # 解压所有 JAR 文件并合并内容，检查冲突
    processed_jar=0
    for jar_file in "${jar_files[@]}"; do
        unzip -qo "$jar_file" -d "$TEMP_UNZIP_DIR" | grep "replace" >> "$CONFLICT_LOG"
        processed_jar=$((processed_jar + 1))
        echo -ne "Unzipping: $processed_jar/$total_jar JAR files\r"
    done
    echo -ne "\n"

    # 如果冲突日志文件为空，则删除它
    if [ ! -s "$CONFLICT_LOG" ]; then
        rm "$CONFLICT_LOG"
    else
        echo "Conflicts detected and logged in $CONFLICT_LOG."
    fi

    # 统计类数量
    class_count=$(find "$TEMP_UNZIP_DIR" -name '*.class' | wc -l)
    echo "APK: $apk_filename - 处理了 $class_count 个类"

    # 打包合并后的内容成新的 JAR 文件
    cd "$TEMP_UNZIP_DIR"
    jar cvf "../$MERGED_JAR" . >/dev/null
    cd -

    echo "APK: $apk_filename - 所有 JAR 文件的内容已成功合并"
    
    # 清理临时解压文件夹
    rm -rf "$TEMP_UNZIP_DIR"
done

echo "所有 APK 文件已处理完毕。"
