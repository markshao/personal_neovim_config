-- Neovim 主配置入口
-- 这里按顺序加载 lua/ 目录下的配置模块

require("options")  -- 加载基础选项配置
require("keymaps")  -- 加载快捷键映射配置
require("plugins")  -- 加载插件管理及配置
require("configs")  -- 加载其他额外的全局配置
