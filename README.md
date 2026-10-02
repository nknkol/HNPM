# HNPM

HarmonyOS PC 上的 HAP 签名与安装工具。本仓库目前只用于发布 Release，源码稍后公开。

## 首次安装（无需安装器）

在设备终端中执行：

```sh
wget -O - https://github.com/nknkol/HNPM/releases/latest/download/install.sh | sh
```

安装过程：

1. 输入开发者选项中显示的**调试端口**（动态端口，每次开启调试都会变化）。
2. 设备弹出「是否允许调试」时点击**信任/允许**。
3. 在自动打开的浏览器中**登录华为开发者账号**。

之后脚本会用一次性的调试证书签名并安装 HNPM，完成后自动删除云端调试证书和本地签名材料。
