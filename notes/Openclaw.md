这个问题问得好，想让 OpenClaw 在思考时利用本地文档，有几种不同层次的做法，我按从简单到强大的顺序给你说：

---

## 1. 📁 直接放 workspace 里（最简单）

把文档丢到 `~/.openclaw/workspace/` 下，主 Agent 可以直接 `read` 读取。适合少量、不经常变的文档。

**优点**：零配置，随时读
**缺点**：得知道文件名，没法语义搜索

---

## 2. 🧠 写入 memory/ 目录（推荐日常用）

**适合**：笔记、知识摘录、学习笔记等中等规模的内容

把文档内容整理后写到 `memory/` 目录下，agent 可以通过 `memory_search` 做语义搜索：

```markdown
# memory/my-knowledge-base.md

## Python 性能优化
- 用 `__slots__` 减少内存占用
- list comprehension 比 for 循环快
...
```

然后 agent 思考时会自动调用 `memory_search` 搜到相关内容。

**适用场景**：个人笔记、技术备忘、项目知识库

---

## 3. 📚 Compiled Wiki（适合大型文档库）

这是专门为"让 agent 能检索本地文档"设计的功能。

1. 把文档放在 `memory/wiki/` 目录下（或你指定的任何目录）
2. 运行编译命令让 OpenClaw 索引这些文档：

```bash
openclaw wiki build <目录路径>
```

3. 之后可以用 `memory_search(query, corpus="wiki")` 或 `memory_search(query, corpus="all")` 语义搜索

**适用场景**：技术手册、API 文档、产品文档、公司知识库等数百页的大规模文档

---

## 4. 🔧 自定义 Skill（适合结构化查询）

创建一个 Skill，让 agent 定义好查询本地文档的能力：

在 `~/.openclaw/workspace/skills/` 下写一个 `SKILL.md`，描述如何读取/搜索特定目录的文档。

**适用场景**：需要对文档做特定格式处理、有特殊的搜索逻辑

---

## 5. 🔗 MCP 工具桥接（最强大）

如果要对接已有的文档管理系统（Notion、Confluence、本地文件系统），可以通过 MCP 协议暴露工具：

```json
// 在配置里加 MCP server
{
  "mcpServers": {
    "local-docs": {
      "command": "python3",
      "args": ["mcp_doc_server.py"],
      "env": {
        "DOC_ROOT": "C:/path/to/your/docs"
      }
    }
  }
}
```

然后在 Skill 里声明使用这个 MCP 工具。

**适用场景**：对接已有系统、需要复杂过滤/权限、多源联合搜索

---

## 快速建议

| 场景 | 推荐做法 |
|------|---------|
| 几份笔记/备忘录 | `memory/` 目录 |
| 几十到几百页的文档库 | **Compiled Wiki**（`wiki build`） |
| 需要实时查文件系统 | 自定义 Skill + `read` |
| 对接 Notion/飞书等 | MCP 工具 |

---

**最推荐的是 Compiled Wiki** 方案——文档索引一次后，agent 每次思考都能语义搜索到相关内容，不需要你手动告诉它"去读哪个文件"。

要不要我帮你试试？比如先建个 `memory/wiki/` 目录，放几份文档进去编译一下？