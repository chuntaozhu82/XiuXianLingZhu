# 修仙领主 (XiuXianLingZhu)

一个竖屏RPG游戏原型，使用Godot 4.x开发。

## 项目简介

修仙领主是一款回合制RPG游戏原型，包含完整的战斗系统、物品系统、技能系统和存档系统。

## 功能模块

### 核心系统
- **PlayerData** - 玩家数据管理（属性、装备、技能、背包）
- **CombatSystem** - 回合制战斗系统
- **EnemyAI** - 敌人AI决策系统
- **Inventory** - 物品栏管理
- **SkillTree** - 技能学习系统
- **GameManager** - 游戏存档系统

### 数据库
- **EnemyData** - 敌人数据库（7种敌人类型）
- **ItemData** - 物品数据库（武器、防具、消耗品、材料、技能书）
- **SkillData** - 技能数据库（20+技能）

### 管理器
- **UIManager** - UI界面管理
- **AudioManager** - 音频管理

## 项目结构

```
XiuXianLingZhu/
├── scenes/              # 场景文件
│   ├── Battle.tscn      # 战斗场景
│   ├── MainMenu.tscn    # 主菜单
│   ├── Inventory.tscn   # 物品栏
│   ├── SkillTree.tscn   # 技能树
│   └── CharacterStatus.tscn # 角色状态
├── scripts/
│   ├── autoload/        # 全局管理器
│   ├── combat/          # 战斗系统
│   ├── data/            # 数据库
│   └── ui/              # UI脚本
└── project.godot        # 项目配置
```

## 开发环境

- **引擎**: Godot 4.2+
- **语言**: GDScript
- **平台**: Windows/macOS/Linux/Android

## 如何运行

1. 安装 [Godot 4.x](https://godotengine.org/download)
2. 打开Godot，点击"导入"
3. 选择项目目录中的 `project.godot`
4. 点击"导入并编辑"
5. 按 `F5` 运行游戏

## 项目状态

- **完成度**: 75%
- **核心系统**: ✅ 已完成
- **数据验证**: ✅ 已通过
- **Lint检查**: ✅ 无错误

## 后续开发

- [ ] 世界地图系统
- [ ] NPC对话系统
- [ ] 任务系统
- [ ] 商店系统

## 许可证

私有项目 - 仅供学习研究使用

---

**开发团队**: AI Game Factory  
**创建时间**: 2026-03-12
