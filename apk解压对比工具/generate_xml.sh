#!/bin/bash

# 检查是否提供了输入文件参数
if [ -z "$1" ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

# 输入文件名由参数指定
input_file="$1"

# 获取输入文件的基名（不带路径和扩展名）
base_name=$(basename "$input_file" .txt)

# 输出文件夹为 classTree，文件名为 <base_name>.xml
output_dir="./classTree"
output_file="$output_dir/$base_name.xml"

# 检查输入文件是否存在
if [ ! -f "$input_file" ]; then
    echo "Input file not found: $input_file"
    exit 1
fi

# 创建输出目录
mkdir -p "$output_dir"

# 获取总行数用于进度显示
total_lines=$(wc -l < "$input_file")
current_line=0

echo "Processing $total_lines lines from $input_file..."

# 开始时间
start_time=$(date +%s)

# 写入XML文件头
echo '<?xml version="1.0" encoding="UTF-8"?>' > "$output_file"
echo '<packages>' >> "$output_file"

# 初始化包名堆栈
package_stack=()

# 读取每一行
while IFS= read -r line
do
    # 提取包名（去掉最后的类名部分）
    package=$(echo "$line" | sed 's/\.[^\.]*$//')

    # 获取类名
    class_name=$(echo "$line" | sed 's/^.*\.//')

    # 处理包名层级结构
    IFS='.' read -ra package_parts <<< "$package"
    depth=0

    # 处理当前包名与堆栈中的包名，找出公共部分
    while [ $depth -lt ${#package_parts[@]} ] && [ $depth -lt ${#package_stack[@]} ] && [ "${package_parts[$depth]}" = "${package_stack[$depth]}" ]; do
        depth=$((depth + 1))
    done

    # 关闭多余的包名标签
    for ((i=${#package_stack[@]}-1; i>=depth; i--)); do
        echo "$(printf '%*s' $((i + 1)) | tr ' ' '    ')</package>" >> "$output_file"
        unset package_stack[$i]
    done

    # 打开新的包名标签
    for ((i=$depth; i<${#package_parts[@]}; i++)); do
        echo "$(printf '%*s' $((i + 1)) | tr ' ' '    ')<package name=\"${package_parts[$i]}\">" >> "$output_file"
        package_stack+=("${package_parts[$i]}")
    done

    # 写入类名
    echo "$(printf '%*s' $((${#package_parts[@]} + 1)) | tr ' ' '    ')<class>$class_name</class>" >> "$output_file"

    # 更新进度
    current_line=$((current_line + 1))
    percentage=$((current_line * 100 / total_lines))
    
    # 计算预计完成时间
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))
    estimated_total_time=$((elapsed_time * total_lines / current_line))
    remaining_time=$((estimated_total_time - elapsed_time))

    # 格式化剩余时间
    hours=$((remaining_time / 3600))
    minutes=$(( (remaining_time % 3600) / 60))
    seconds=$((remaining_time % 60))

    # 打印进度和预计完成时间
    echo -ne "Progress: $percentage% done, Estimated time remaining: ${hours}h ${minutes}m ${seconds}s\r"

done < "$input_file"

# 关闭剩余的包名标签
for ((i=${#package_stack[@]}-1; i>=0; i--)); do
    echo "$(printf '%*s' $((i + 1)) | tr ' ' '    ')</package>" >> "$output_file"
done

# 关闭<packages>标签
echo '</packages>' >> "$output_file"

# 打印100%的完成状态
echo "Progress: 100% done"
echo "XML file has been generated: $output_file"
