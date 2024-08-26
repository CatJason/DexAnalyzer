### 使用指南: compare_xml.sh

1. **运行脚本**：
   在终端中运行以下命令：
   ```bash
   ./compare_xml.sh <xml_file1> <xml_file2>
   ```
   例如：
   ```bash
   ./compare_xml.sh file1.xml file2.xml
   ```

2. **产出文件**：
   - 脚本会在当前目录下生成一个 `comparePackage` 文件夹。
   - 输出的 HTML 文件将保存在该文件夹中，文件名为 `compare_packages.html`。

运行后，生成的 HTML 文件路径类似：
```
./comparePackage/compare_packages.html
```

这就是使用 `compare_xml.sh` 脚本的简化指南。