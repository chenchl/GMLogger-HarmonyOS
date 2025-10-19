import { logger, MethodLog } from '@chenchl/gmlogger';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';

interface Message {
  message: string;
  code: number;
}

const defObj: Message = {
  message: '安全日志info',
  code: 1100
}


@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  @MethodLog
  testLog(num: number = 0, str: string = '2', message: Message) {
    logger.info('安全日志info' + num)
    logger.error('安全日志error' + str)
    logger.debug('安全日志debug')
    logger.setDomain(0x0002)
    logger.warn(message)
    logger.fatal('安全日志fatal')
    logger.console('安全日志console')
  }

  build() {
    Column({ space: 20 }) {
      Button('安全日志').onClick(() => {
        this.testLog(1, '4', { message: '安全日志warn', code: 1000 })
      })
      Button('安全日志解密').onClick(() => {
        const context = getContext() as common.UIAbilityContext
        logger.decryptLogFile(`${context.filesDir}/security_log/log_0.txt`,
          new Uint8Array([7, 154, 52, 176, 4, 236, 150, 43, 237, 9, 145, 166, 141, 174, 224, 131]),
          `${context.filesDir}/security_log_decrypt`).then((success) => {
          promptAction.showToast({ message: success ? '解密成功' : '解密失败' })
        })
      })
    }
    .height('100%')
    .width('100%')
  }
}