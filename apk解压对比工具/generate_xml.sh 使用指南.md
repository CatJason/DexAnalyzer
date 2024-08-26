### generate_xml.sh 使用指南

1. **运行脚本**：
   在终端中运行以下命令：
   ```bash
   ./generate_xml.sh <input_file>
   ```
   例如：
   ```bash
   ./generate_xml.sh classes.txt
   ```

2. **产出文件**：
   - 脚本会在当前目录下生成一个 `classTree` 文件夹。
   - 输出的 XML 文件将保存在该文件夹中，文件名为 `<input_file>` 的基名加 `.xml` 后缀。

运行后，生成的 XML 文件路径类似：
```
./classTree/classes.xml
```
