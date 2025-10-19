/**
 * LogOptions 类用于配置日志记录的相关选项。
 * 该类提供了多个可选参数，允许用户自定义日志的行为和输出方式。
 */
export class LogOptions {
  /**
   * 日志的标签，用于标识日志的来源或类别。
   */
  tag?: string
  /**
   * 日志的域，通常用于区分不同的日志模块或子系统。
   */
  domain?: number
  /**
   * 是否关闭日志记录。如果设置为 true，则日志记录将被禁用。
   */
  enable?: boolean
  /**
   * 是否使用 HiLog 日志系统。如果设置为 true，则日志将通过HiLog输出，false则日志通过console输出。
   */
  isHilog?: boolean
  /**
   * 是否将日志记录到文件中。如果设置为 true，则日志将被写入文件。
   */
  isLogToFile?: boolean
  /**
   * 日志加密密钥，用于对日志内容进行加密，默认为空不加密 秘钥长度为16
   */
  encryptKey?: Uint8Array
  /**
   * 是否在日志中显示日志位置信息。如果设置为 true，则日志中将包含文件路径和行号等信息。
   */
  showLogLocation?: boolean
  /**
   * 日志中显示的堆栈跟踪行数。用于控制日志中堆栈跟踪信息的详细程度。
   */
  stackTraceNum?: number
  /**
   * 日志每次输出大小，最大1024字节。
   */
  logSize?: number
}
