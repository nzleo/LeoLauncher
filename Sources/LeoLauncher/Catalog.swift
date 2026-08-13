import Foundation

enum Catalog {
    static let byBundle: [String: AppCategory] = {
        var map: [String: AppCategory] = [:]
        for (category, ids) in bundles {
            for id in ids { map[id] = category }
        }
        return map
    }()

    static let byName: [String: AppCategory] = [
        "115生活": .life,
        "豆包浏览器": .browser,
        "chatgpt": .ai,
        "chatgpt classic": .ai,
        "claude": .ai,
        "kimi": .ai,
        "doubao": .ai,
        "qianwen": .ai
    ]

    static let aliases: [String: [String]] = [
        "com.tencent.xinWeChat": ["weixin", "wechat", "wx", "微信"],
        "com.tencent.WeWorkMac": ["wecom", "qiyeweixin", "企业微信"],
        "com.tencent.qq": ["qq"],
        "com.alibaba.DingTalkMac": ["dingding", "dingtalk", "钉钉"],
        "com.electron.lark": ["feishu", "lark", "飞书"],
        "com.kingsoft.wpsoffice.mac": ["wps"],
        "com.bilibili.bilibiliPC": ["bilibili", "b站", "哔哩哔哩"],
        "com.bytedance.douyin.desktop": ["douyin", "tiktok", "抖音"],
        "com.google.Chrome": ["chrome", "谷歌"],
        "com.apple.Safari": ["safari"],
        "md.obsidian": ["obsidian"],
        "notion.id": ["notion"],
        "com.microsoft.VSCode": ["vscode", "code"],
        "com.todesktop.230313mzl4w4u92": ["cursor"],
        "com.anthropic.claudefordesktop": ["claude"],
        "com.openai.chat": ["chatgpt"],
        "com.bot.pc.doubao": ["doubao", "豆包"],
        "com.moonshot.kimichat": ["kimi"],
        "com.leo.fancontrol": ["fan", "风扇"],
        "com.leo.leomdreader": ["markdown", "md"]
    ]

    static let obscureSystem: Set<String> = [
        "com.apple.airport.airportutility",
        "com.apple.bootcampassistant",
        "com.apple.ColorSyncUtility",
        "com.apple.DigitalColorMeter",
        "com.apple.grapher",
        "com.apple.Magnifier",
        "com.apple.MigrateAssistant",
        "com.apple.VoiceOverUtility",
        "com.apple.BluetoothFileExchange",
        "com.apple.apps.launcher",
        "com.apple.siri.launcher",
        "com.apple.exposelauncher",
        "com.apple.helpviewer",
        "com.apple.audio.AudioMIDISetup",
        "com.apple.printcenter",
        "com.google.chromeremotedesktop.me2me-host-uninstaller",
        "com.apple.DirectoryUtility",
        "com.apple.ExpansionSlotUtility",
        "com.apple.appleseed.FeedbackAssistant",
        "com.apple.FolderActionsSetup",
        "com.apple.Ticket-Viewer",
        "com.apple.wifi.diagnostics",
        "com.apple.DVDPlayer",
        "com.apple.DeskCam",
        "com.apple.AboutThisMacLauncher",
        "com.apple.archiveutility",
        "com.apple.IPAInstaller"
    ]

    static let skipBundlePrefixes = [
        "com.apple.dt.XcodePreviews",
        "com.apple.Safari.WebApp"
    ]

    private static let bundles: [AppCategory: [String]] = [
        .ai: [
            "com.openai.chat",
            "com.openai.codex",
            "com.anthropic.claudefordesktop",
            "com.moonshot.kimichat",
            "com.bot.pc.doubao",
            "com.alibaba.tongyi",
            "im.manus.desktop",
            "ai.multica.desktop",
            "com.nousresearch.hermes.setup",
            "com.workbuddy.workbuddy",
            "com.apple.GenerativePlaygroundApp"
        ],
        .dev: [
            "com.todesktop.230313mzl4w4u92",
            "com.microsoft.VSCode",
            "com.apple.dt.Xcode",
            "com.apple.TestFlight",
            "com.docker.docker",
            "com.github.GitHubClient",
            "com.sublimetext.4",
            "com.googlecode.iterm2",
            "com.apple.Terminal",
            "com.apple.ScriptEditor2",
            "com.tencent.codebuddycn",
            "com.trae.solo.app",
            "com.tencent.webplusdevtools",
            "com.ant.miniprogram",
            "com.alipay.alipayleytool",
            "FiT.WXCertUtil-En",
            "com.apple.Automator"
        ],
        .office: [
            "com.kingsoft.wpsoffice.mac",
            "com.apple.iWork.Pages",
            "com.apple.iWork.Numbers",
            "com.apple.iWork.Keynote",
            "com.apple.Pages",
            "com.apple.Numbers",
            "com.apple.Keynote",
            "com.apple.TextEdit",
            "com.apple.Preview"
        ],
        .chat: [
            "com.tencent.xinWeChat",
            "com.tencent.WeWorkMac",
            "com.tencent.qq",
            "com.tencent.meeting",
            "ru.keepcoder.Telegram",
            "net.whatsapp.WhatsApp",
            "com.alibaba.DingTalkMac",
            "com.electron.lark",
            "com.netease.sirius-desktop",
            "com.apple.mail",
            "com.apple.MobileSMS",
            "com.apple.FaceTime",
            "com.apple.mobilephone",
            "com.apple.AddressBook",
            "com.apple.ScreenSharing"
        ],
        .media: [
            "com.apple.Music",
            "com.apple.TV",
            "com.apple.podcasts",
            "com.apple.QuickTimePlayerX",
            "com.apple.VoiceMemos",
            "com.apple.news",
            "com.apple.Chess",
            "com.apple.games",
            "com.lemon.lvpro",
            "com.bilibili.bilibiliPC",
            "com.bytedance.douyin.desktop"
        ],
        .system: [
            "com.apple.systempreferences",
            "com.apple.AppStore",
            "com.apple.ActivityMonitor",
            "com.apple.DiskUtility",
            "com.apple.calculator",
            "com.apple.backup.launcher",
            "com.apple.findmy",
            "com.apple.Passwords",
            "com.apple.keychainaccess",
            "com.apple.Console",
            "com.apple.SystemProfiler",
            "com.apple.screenshot.launcher",
            "com.apple.shortcuts",
            "com.apple.ScreenContinuity",
            "com.leo.fancontrol",
            "com.west2online.ClashXPro",
            "com.logi.optionsplus",
            "ltd.anybox.FolderPreview",
            "folder-slice",
            "com.mac123.mfy",
            "com.oplus.devicespace",
            "com.taglauncher.app",
            "com.leo.leolauncher"
        ],
        .browser: [
            "com.apple.Safari",
            "com.google.Chrome"
        ],
        .notes: [
            "com.apple.Notes",
            "com.apple.Stickies",
            "com.apple.journal",
            "com.apple.freeform",
            "md.obsidian",
            "notion.id",
            "com.leo.leomdreader"
        ],
        .photo: [
            "com.apple.Photos",
            "com.apple.PhotoBooth",
            "com.apple.Image_Capture"
        ],
        .learn: [
            "com.apple.iBooksX",
            "com.apple.Dictionary",
            "com.apple.helpviewer"
        ],
        .design: [
            "com.apple.FontBook",
            "dev.pencil.desktop",
            "io.open-design.desktop",
            "com.tourbox.ui.launch"
        ],
        .life: [
            "com.apple.Maps",
            "com.apple.weather",
            "com.apple.Home",
            "com.apple.stocks"
        ],
        .tasks: [
            "com.apple.reminders",
            "com.apple.iCal",
            "com.apple.clock"
        ]
    ]

    static func aliases(for bundleID: String, name: String) -> [String] {
        var items = aliases[bundleID] ?? []
        items.append(name)
        items.append(bundleID)
        return items
    }
}
