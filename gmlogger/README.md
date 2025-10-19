# 安全日志组件

## 简介
安全日志模块提供加密日志记录功能，主要特性包括：
- **加密存储**： 支持使用SM4算法加密日志内容（[`LoggerCryptoUtil.ets`](file://gmlogger/src/main/ets/components/security/logger/LoggerCryptoUtil.ets#L69-L125)）
- **分级控制**：支持INFO/DEBUG/ERROR/WARN/FATAL五级日志
- **文件管理**：自动分割日志文件，支持日志解密导出（[`LoggerFileUtil.ets`](file://gmlogger/src/main/ets/components/security/logger/LoggerFileUtil.ets#L140-L190)）
- **线程安全**：通过Worker线程实现异步文件写入，确保高性能不造成主线程卡顿（[`LogToFileWorker.ets`](file://gmlogger/src/main/ets/workers/LogToFileWorker.ets#L0-L51)）
- **堆栈跟踪**：支持堆栈跟踪，记录调用方法流程（[`LoggerUtil.ets`](file://gmlogger/src/main/ets/components/security/logger/LoggerUtil.ets#L0-L51)）
- **方法装饰器**：支持使用装饰器装饰方法，自动记录方法调用（参数、返回值、耗时）（[`LogDescriptor.ets`](file://gmlogger/src/main/ets/components/security/logger/LogDescriptor.ets#L0-L40)）
## 集成方法

### 1. 添加依赖

在需要引入的模块 `oh-package.json5` 文件中添加：

```json
"dependencies": { 
    "@chenchl/gmlogger": "file:../entry/libs/chenchl-gmlogger-1.0.0.har" 
}
```

### 2. 同步依赖

```bash
ohpm install
```
## 使用说明

### 初始化配置

```typescript
import { logger } from '@chenchl/gmlogger'; 
import { common } from '@kit.AbilityKit';
// 在Ability中初始化 
logger.init(context, 
            { tag: 'MyApp', // 日志分类标签 
              domain: 0x0022, // 系统日志域标识 
              isLogToFile: true, // 启用文件存储 
              encryptKey: new Uint8Array([...]), // 16字节加密密钥 
              logSize: 1024, // 单条日志文件最大1024字节 
              stackTraceNum: 4 // 堆栈跟踪深度 
            });
```

### 记录日志

```typescript
// 记录不同级别日志 
logger.info('用户登录成功'); 
logger.error({ code: 500, msg: '网络连接失败' });
// 动态切换日志域 
logger.setDomain(0x0001);
// 动态切换是否打印
logger.setEnable(true)
// 控制台输出（不加密） 
logger.console('调试信息');
//装饰器记录自动记录方法调用（参数、返回值、耗时）
@MethodLog
function testLog(str:string) {
  let result = str + 'test';
  return result;
}
```

### 解密日志

```typescript
const decryptKey = new Uint8Array([...]); 
//解密日志到指定文件
logger.decryptLogFile(`${context.filesDir}/security_log/log_0.txt`, 
                       decryptKey, 
                      `${context.filesDir}/decrypted_logs` 
                     )
                     .then((success) => { 
                         console.info(解密${success ? '成功' : '失败'}); 
					 });
```

## 完整示例

```typescript
//EntryAbility.ets
import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
//导入依赖
import { logger } from '@chenchl/gmlogger';

export default class EntryAbility extends UIAbility {
  ...
  //在hap入口EntryAbilityonCreate方法中进行初始化
  onCreate(_want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    logger.init(this.context, {
      tag: 'testTag111',
      domain: 0x0022,
      isLogToFile: true,
      enable: true,
      isHilog: true,
      showLogLocation: true,
      logSize: 1024,
      stackTraceNum: 4,
      encryptKey: new Uint8Array([7, 154, 52, 176, 4, 236, 150, 43, 237, 9, 145, 166, 141, 174, 224, 131])
    })
    ...
  }
}

//具体使用场景
//Index.ets
import { logger } from '@chenchl/gmlogger';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

interface Message {
  message: string;
  code: number;
}

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  //装饰器记录自动记录方法调用（参数、返回值、耗时）
  @MethodLog
  testLog() {
    logger.info('安全日志info')
    logger.error('安全日志error')
    logger.debug('安全日志debug')
    logger.setDomain(0x0002)
    let object: Message = {
      message: '安全日志warn',
      code: 1000
    }
    logger.warn(object)
    logger.fatal('安全日志fatal')
    logger.console('安全日志console')
  }

  build() {
    Column({ space: 20 }) {
      Button('安全日志').onClick(() => {
        this.testLog()
      })
      Button('安全日志解密').onClick(() => {
        const context = getContext() as common.UIAbilityContext
        logger.decryptLogFile(`${context.filesDir}/security_log/log_0.txt`,
          new Uint8Array([7, 154, 52, 176, 4, 236, 150, 43, 237, 9, 145, 166, 141, 174, 224, 131]),
          `${context.filesDir}/security_log_decrypt`).then((success) => {
          promptAction.showToast({ message: success ? '解密成功' : '解密失败' })
        })
      })
    }.width('100%').height('100%')
  }
}
```

