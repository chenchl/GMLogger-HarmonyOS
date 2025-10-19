import { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS';
import { LoggerCryptoUtil } from '../components/security/logger/LoggerCryptoUtil';
import { loggerFileUtil } from '../components/security/logger/LoggerFileUtil';
import { LogModel } from '../components/security/logger/LogModel';

const workerPort: ThreadWorkerGlobalScope = worker.workerPort;

/**
 * Defines the event handler to be called when the worker thread receives a message sent by the host thread.
 * The event handler is executed in the worker thread.
 *
 * @param e message data
 */
/**
 * 处理从主线程接收到的消息。
 * 该函数根据接收到的消息类型执行不同的操作：
 * 1. 如果消息是字符串类型，则将其作为日志文件路径保存。
 * 2. 如果消息是LogModel类型，则根据是否提供加密密钥对日志内容进行加密，并将日志写入文件。
 *
 * @param e - 接收到的消息事件，包含消息数据。
 */
workerPort.onmessage = (e: MessageEvents) => {
  try {
    // 当接收到的消息是字符串类型时，将其作为日志文件路径保存
    if (typeof e.data === 'string') {
      loggerFileUtil.logPath = e.data as string
      return
    }

    // 将接收到的消息数据解析为LogModel类型
    const logModel = e.data as LogModel;

    // 打印日志内容和加密密钥（用于调试）
    //console.info('LogToFileWorker onmessage message data is: ' + logModel.logContent)
    //console.info('LogToFileWorker onmessage message encryptKey is: ' + logModel.encryptKey)

    // 如果日志内容存在，则根据是否提供加密密钥进行相应处理
    if (logModel.logContent) {
      if (logModel.encryptKey) {
        // 使用SM4算法对日志内容进行加密，并将加密后的内容写入日志文件
        const encryptLogContent = LoggerCryptoUtil.encryptSM4(new Uint8Array(logModel.encryptKey), logModel.logContent)
        loggerFileUtil.writeLog(encryptLogContent)
      } else {
        // 直接将日志内容写入日志文件
        loggerFileUtil.writeLog(logModel.logContent)
      }
    }
  } catch (e) {
    // 捕获并打印处理消息过程中发生的错误
    console.error('LogToFileWorker onmessage error is ' + e)
  }
}

/**
 * Defines the event handler to be called when the worker receives a message that cannot be deserialized.
 * The event handler is executed in the worker thread.
 *
 * @param e message data
 */
workerPort.onmessageerror = (event: MessageEvents) => {
  console.error('LogToFileWorker onmessageerror is ' + event.data)
}

/**
 * Defines the event handler to be called when an exception occurs during worker execution.
 * The event handler is executed in the worker thread.
 *
 * @param e error message
 */
workerPort.onerror = (event: ErrorEvent) => {
  console.error("LogToFileWorker onerror message is: " + event.message)
}