import { collections } from '@kit.ArkTS'

/**
 * LogModel 类用于表示日志模型。
 * 该类包含日志内容和加密密钥。
 */
@Sendable
export class LogModel {
  logContent?: string
  encryptKey?: collections.Uint8Array

  /**
   * 构造函数创建日志模型实例
   * @param content - 可选参数，表示日志的文本内容
   * @param encryptKey - 可选参数，用于加密日志的原始密钥数据
   */
  constructor(content?: string, encryptKey?: Uint8Array) {
    this.logContent = content
    if (encryptKey) {
      this.encryptKey = collections.Uint8Array.from(encryptKey)
    }
  }
}