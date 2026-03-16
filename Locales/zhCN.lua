local _, addonTable = ...

if GetLocale() ~= "zhCN" and GetLocale() ~= "zhTW" then
    return
end

addonTable.L = addonTable.L or {}
local L = addonTable.L

L.ADDON_TITLE = "NatLust"
L.SUBTITLE = "这里只输入文件名。\nNatLust 会自动从 Interface\\AddOns\\NatLust\\Media\\ 读取文件。"
L.TEXTURE_FILE = "材质文件"
L.SOUND_FILE = "音频文件"
L.SPRITE_SECTION = "逐帧动画设置"
L.SPRITE_COLUMNS = "列数"
L.SPRITE_ROWS = "行数"
L.SPRITE_FRAMES = "帧数"
L.SPRITE_FPS = "FPS"
L.WIDTH_LABEL = "宽度"
L.HEIGHT_LABEL = "高度"
L.TEXTURE_EXAMPLE = "示例：###.tga。材质文件留空时，将不显示任何图片和动画。"
L.SOUND_EXAMPLE = "示例：###.mp3。音乐文件留空时，将不播放任何音乐。"
L.SPRITE_HINT = ""
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
L.STATUS_HINT = "可以把自定义材质和音乐放到 Interface\\AddOns\\NatLust\\Media\\ 位置，并修改上面文件名。注意：更新插件会覆盖 Media 文件夹，请备份好自定义材质和音乐。"
L.AUDIO_HINT = "推荐的 WoW 音频格式：MP3、OGG 或 WAV。若使用 MP3，建议 44.1 kHz、128/192 kbps、立体声、尽量少元数据、不要嵌入封面图。"
L.USAGE = "输入 /nl 或 /natlust 打开设置界面。"
L.SOUND_EMPTY = "音频加载失败：文件名为空。"
L.SOUND_STARTED = "音频已开始播放："
L.SOUND_FAILED = "音频加载失败："
L.TEXTURE_FAILED = "材质加载失败："
L.TEXTURE_STARTED = "材质已开始显示："
L.LUST_DETECTED = "已检测到玩家身上的嗜血类光环。"
