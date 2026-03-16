local _, addonTable = ...

if GetLocale() ~= "zhCN" and GetLocale() ~= "zhTW" then
    return
end

addonTable.L = addonTable.L or {}
local L = addonTable.L

L.ADDON_TITLE = "NatLust"
L.SUBTITLE = "这里只输入文件名。NatLust 会从 Interface\\AddOns\\NatLust\\Media\\ 自动加载文件"
L.TEXTURE_FILE = "材质文件"
L.SOUND_FILE = "音频文件"
L.TEXTURE_EXAMPLE = "示例：pedro.tga"
L.SOUND_EXAMPLE = "示例：pedro.mp3"
L.APPLY = "应用"
L.DEFAULT = "默认"
L.FAKE_LUST = "模拟嗜血"
L.END_FAKE_LUST = "结束模拟"
L.UNLOCK = "解锁"
L.LOCK = "锁定"
L.SETTINGS_APPLIED = "设置已应用。"
L.DEFAULTS_RESTORED = "已恢复默认文件名。"
L.FAKE_LUST_STARTED = "已开始模拟嗜血。"
L.FAKE_LUST_ENDED = "已结束模拟嗜血。"
L.FRAME_LOCKED = "框体已锁定。"
L.FRAME_UNLOCKED = "框体已解锁。"
L.STATUS_HINT = "NatLust 会始终从 Interface\\AddOns\\NatLust\\Media\\ 加载文件"
L.USAGE = "输入 /nl 或 /natlust 打开设置界面。"
L.SOUND_EMPTY = "音频加载失败：文件名为空。"
L.SOUND_STARTED = "音频已开始播放："
L.SOUND_FAILED = "音频加载失败："
L.TEXTURE_FAILED = "材质加载失败："
L.TEXTURE_STARTED = "材质已开始显示："
L.LUST_DETECTED = "已检测到玩家身上的嗜血类光环。"
