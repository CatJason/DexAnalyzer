#!/bin/bash

# 检查是否提供了两个输入文件参数
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <xml_file1> <xml_file2>"
    exit 1
fi

# 输入文件名由参数指定
xml_file1="$1"
xml_file2="$2"

# 输出文件夹为 comparePackage，文件名为 compare_packages.html
output_dir="./comparePackage"
output_file="$output_dir/compare_packages.html"

# 创建输出目录
mkdir -p "$output_dir"

# 创建HTML文件并写入头部
echo "<!DOCTYPE html>" > "$output_file"
echo "<html lang=\"en\">" >> "$output_file"
echo "<head><meta charset=\"UTF-8\"><title>Package Comparison</title></head>" >> "$output_file"
echo "<style>
    body { font-family: Arial, sans-serif; }
    ul { list-style-type: none; padding-left: 20px; }
    li { margin-left: 20px; cursor: pointer; }
    .package { font-weight: bold; cursor: pointer; }
    .class { margin-left: 40px; cursor: auto; }
    .hidden { display: none; }
</style>" >> "$output_file"
echo "<script>
    function toggleVisibility(event) {
        event.stopPropagation();
        const parentLi = event.currentTarget.parentElement;
        const childUls = parentLi.querySelectorAll('ul');
        childUls.forEach(childUl => {
            const isVisible = childUl.style.display !== 'none';
            childUl.style.display = isVisible ? 'none' : 'block';
        });
    }

    function expandAll() {
        const uls = document.querySelectorAll('ul');
        uls.forEach(ul => ul.style.display = 'block');
    }

    function collapseAll() {
        const uls = document.querySelectorAll('ul');
        uls.forEach(ul => ul.style.display = 'none');
    }

    document.addEventListener('DOMContentLoaded', function() {
        const packages = document.querySelectorAll('.package');
        packages.forEach(pkg => pkg.addEventListener('click', toggleVisibility));
    });
</script>" >> "$output_file"
echo "</head>" >> "$output_file"
echo "<body>" >> "$output_file"
echo "<h1>Package and Class Structure Comparison</h1>" >> "$output_file"
echo "<button onclick=\"expandAll()\">Expand All</button> <button onclick=\"collapseAll()\">Collapse All</button>" >> "$output_file"

# 初始化当前包计数
current_package=0

# 定义递归函数来解析嵌套的包结构，并生成独有的包列表
function parse_unique_packages() {
    local xml_file1=$1
    local xml_file2=$2
    local parent_xpath=$3
    local current_path=$4

    packages=$(xmllint --xpath "$parent_xpath/package/@name" "$xml_file1" 2>/dev/null | sed 's/name="\([^"]*\)"/\1\n/g')

    if [ ! -z "$packages" ]; then
        echo "<ul style=\"display: none;\">" >> "$output_file"

        for package in $packages; do
            current_xpath="$parent_xpath/package[@name='$package']"
            full_package_name="$current_path.$package"

            # 打印当前包名
            echo "<li><span class=\"package\">$full_package_name</span>" >> "$output_file"

            # 检查另一个文件中是否有相同包
            if ! xmllint --xpath "$current_xpath" "$xml_file2" &>/dev/null; then
                # 递归显示子包
                parse_unique_packages "$xml_file1" "$xml_file2" "$current_xpath" "$full_package_name"

                # 获取当前包内的所有类
                classes=$(xmllint --xpath "$current_xpath/class/text()" "$xml_file1" 2>/dev/null | tr '\n' ' ')
                if [ ! -z "$classes" ]; then
                    echo "<ul style=\"display: none;\">" >> "$output_file"
                    for class in $classes; do
                        echo "<li class=\"class\">$full_package_name.$class</li>" >> "$output_file"
                    done
                    echo "</ul>" >> "$output_file"
                fi
            else
                # 递归检查子包
                parse_unique_packages "$xml_file1" "$xml_file2" "$current_xpath" "$full_package_name"
            fi

            echo "</li>" >> "$output_file"

            # 更新当前包计数并打印在同一行
            current_package=$((current_package + 1))
            echo -ne "Processed packages: $current_package\r"
        done

        echo "</ul>" >> "$output_file"
    fi
}

# 定义递归函数来找出两边都有但不相同的包
function find_different_packages() {
    local xml_file1=$1
    local xml_file2=$2
    local parent_xpath=$3
    local current_path=$4

    packages=$(xmllint --xpath "$parent_xpath/package/@name" "$xml_file1" 2>/dev/null | sed 's/name="\([^"]*\)"/\1\n/g')

    if [ ! -z "$packages" ]; then
        echo "<ul style=\"display: none;\">" >> "$output_file"

        for package in $packages; do
            current_xpath="$parent_xpath/package[@name='$package']"
            full_package_name="$current_path.$package"

            # 打印当前包名
            echo "<li><span class=\"package\">$full_package_name</span>" >> "$output_file"

            # 提取两个文件中的类
            classes1=$(xmllint --xpath "$current_xpath/class/text()" "$xml_file1" 2>/dev/null | tr '\n' ' ')
            classes2=$(xmllint --xpath "$current_xpath/class/text()" "$xml_file2" 2>/dev/null | tr '\n' ' ')

            # 如果两个文件中的类不同，则显示
            if [ "$classes1" != "$classes2" ] && [ ! -z "$classes1" ] && [ ! -z "$classes2" ]; then
                echo "<ul style=\"display: none;\">" >> "$output_file"
                echo "<li class=\"class\"><b>File 1:</b> $(echo $classes1 | sed "s/\([^ ]*\)/$full_package_name.\1/g")</li>" >> "$output_file"
                echo "<li class=\"class\"><b>File 2:</b> $(echo $classes2 | sed "s/\([^ ]*\)/$full_package_name.\1/g")</li>" >> "$output_file"
                echo "</ul>" >> "$output_file"
            fi

            # 递归检查子包
            find_different_packages "$xml_file1" "$xml_file2" "$current_xpath" "$full_package_name"

            echo "</li>" >> "$output_file"

            # 更新当前包计数并打印在同一行
            current_package=$((current_package + 1))
            echo -ne "Processed packages: $current_package\r"
        done

        echo "</ul>" >> "$output_file"
    fi
}

# 写入唯一包标题和列表
echo "<h2>Packages unique to $xml_file1</h2>" >> "$output_file"
parse_unique_packages "$xml_file1" "$xml_file2" "/packages" ""

echo "<h2>Packages unique to $xml_file2</h2>" >> "$output_file"
parse_unique_packages "$xml_file2" "$xml_file1" "/packages" ""

# 在HTML中打印两边都有但不相同的包
echo "<h2>Packages present in both files but different</h2>" >> "$output_file"
find_different_packages "$xml_file1" "$xml_file2" "/packages" ""

# 关闭HTML标签
echo "</body>" >> "$output_file"
echo "</html>" >> "$output_file"

# 打印完成状态并换行
echo -ne "Processed packages: $current_package\n"
echo "Comparison complete. The result has been saved to $output_file"
