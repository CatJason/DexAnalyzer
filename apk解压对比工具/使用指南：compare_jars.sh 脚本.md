### 使用指南：`compare_jars.sh` 脚本

#### 概述
`compare_jars.sh` 是一个用于比较两个 JAR 文件中的类名的脚本。它会解压两个 JAR 文件，提取类名并生成比较结果，包括两个 JAR 中共同类和各自独有类的列表。

#### 使用方法
在终端中运行以下命令：
```bash
./compare_jars.sh <jar1> <jar2>
```
- `<jar1>`：第一个 JAR 文件的路径。
- `<jar2>`：第二个 JAR 文件的路径。

例如：
```bash
./compare_jars.sh /path/to/first.jar /path/to/second.jar
```

#### 生成的文件夹与产物

- **`compareJar` 目录**：脚本执行后会自动创建此目录，存放所有生成的比较结果文件。主要产物包括：
  - `<JAR1_NAME>_类.txt`：JAR1 中所有类的列表。
  - `<JAR2_NAME>_类.txt`：JAR2 中所有类的列表。
  - `<JAR1_NAME>_与_<JAR2_NAME>_共同的类.txt`：两个 JAR 文件中共有的类列表。
  - `<JAR1_NAME>_独有的类.txt`：仅存在于 JAR1 中的类列表。
  - `<JAR2_NAME>_独有的类.txt`：仅存在于 JAR2 中的类列表。

这些文件为用户提供了详细的类差异信息，方便进一步分析和处理。