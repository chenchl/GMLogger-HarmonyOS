import hilog from '@ohos.hilog'
import { LogOptions } from './LogOptions'
import { ErrorEvent, MessageEvents, worker } from '@kit.ArkTS'
import { LogModel } from './LogModel'
import { common } from '@kit.AbilityKit'
import { loggerFileUtil } from './LoggerFileUtil'

/**
 * 日志记录工具类，用于记录应用程序的日志信息。
 * 该类提供了多个方法，用于记录不同级别的日志信息，如信息、调试、警告和错误等。
 * 同时，该类还支持对日志进行加密和加密存储，以保护应用程序的安全性。
 *
 * @remarks
 * 该类通过调用hilog.isLoggable方法来检查当前是否允许记录指定级别的日志，
 * 并通过调用hilog.log方法来记录日志信息。
 * 该类还支持对日志进行加密和加密存储，以保护应用程序的安全性。
 */
class Logger {
  private mTag?: string = "HarmonyOSLog"
  private mDomain?: number = 0x0000
  private mEnable?: boolean = false
  private mHilog?: boolean = true //默认是用hilog进行打印
  private mShowLogLocation?: boolean = true //展示点击的位置
  private mIsLogToFile?: boolean = false //是否将日志记录到文件中
  private mEncryptKey?: Uint8Array //日志加密密钥,空代表不加密 秘钥长度16
  private mLogSize = 1024 //打印的最大长度，默认是1024
  private mStackTraceNum = 2 //日志中显示的堆栈跟踪行数
  private mLogPath = '' // 日志文件路径
  private workerInstance: worker.ThreadWorker = new worker.ThreadWorker('../../../workers/LogToFileWorker.ets');

  constructor() {
    this.initWorker()
  }

  /**
   * 初始化worker线程
   */
  private initWorker() {
    // 注册onmessage回调，当宿主线程接收到来自其创建的Worker通过workerPort.postMessage接口发送的消息时被调用，在宿主线程执行
    this.workerInstance.onmessage = (_e: MessageEvents) => {
      //let data: string = e.data
    }

    // 注册onerror回调，当Worker在执行过程中发生异常时被调用，在宿主线程执行
    this.workerInstance.onerror = (err: ErrorEvent) => {
      console.error("LogToFileWorker onerror message is: " + err.message)
    }

    // 注册onmessageerror回调，当Worker对象接收到一条无法被序列化的消息时被调用，在宿主线程执行
    this.workerInstance.onmessageerror = (event) => {
      console.error('LogToFileWorker onmessageerror is ' + event.data)
    }

    // 注册onexit回调，当Worker销毁时被调用，在宿主线程执行
    this.workerInstance.onexit = (e: number) => {
      // 当Worker正常退出时code为0，异常退出时code为1
      console.info("LogToFileWorker onexit code is: ", e)
    }
  }

  /**
   * 初始化日志配置参数
   *
   * @param context - 获取当前上下文对象，用于获取文件目录等
   * @param options 日志配置选项对象，包含以下可配置项：
   * @param options.tag - 日志输出标识，用于分类日志信息
   * @param options.domain - 日志域标识符（数值类型），用于系统级日志分类
   * @param options.enable - 布尔值，控制是否关闭所有日志输出
   * @param options.isHilog - 布尔值，指定是否使用hilog系统进行日志记录
   * @param options.showLogLocation - 布尔值，控制是否显示日志调用位置信息
   * @param options.logSize - 数值类型，设置单个日志文件的最大容量（单位：KB）
   * @param options.stackTraceNum - 数值类型，配置堆栈跟踪深度
   * @param options.isLogToFile - 布尔值，控制是否将日志写入本地文件
   * @param options.encryptKey - 字符串类型，设置日志文件加密密钥
   */
  init(context: common.UIAbilityContext, options: LogOptions) {
    const tag = options.tag //日志输出Tag
    const domain = options.domain //日志输出的域
    const enable = options.enable //是否关闭日志
    const isHilog = options.isHilog //是否是hilog打印
    const showLogLocation = options.showLogLocation //是否展示日志位置
    const logSize = options.logSize //日志输出大小
    const stackTraceNum = options.stackTraceNum
    const isLogToFile = options.isLogToFile
    const encryptKey = options.encryptKey
    if (tag) {
      this.mTag = tag
    }
    if (domain) {
      this.mDomain = domain
    }
    if (enable) {
      this.mEnable = enable
    }
    if (isHilog) {
      this.mHilog = isHilog
    }
    if (showLogLocation) {
      this.mShowLogLocation = showLogLocation
    }
    if (logSize) {
      this.mLogSize = logSize
    }
    if (stackTraceNum) {
      this.mStackTraceNum = stackTraceNum
    }
    if (isLogToFile) {
      this.mIsLogToFile = isLogToFile
    }
    if (encryptKey) {
      this.mEncryptKey = encryptKey
      this.mLogPath = `${context.filesDir}/security_log/`
    } else {
      this.mEncryptKey = undefined
      this.mLogPath = `${context.filesDir}/normal_log/`
    }

    this.workerInstance.postMessage(this.mLogPath)
  }

  /**
   * 设置当前操作的域标识
   *
   * @param domain - 要设置的域值，通常用于标识不同的业务域或数据隔离域。
   * 该参数应为整型数值，具体取值范围和含义需参考业务上下文定义，
   * 例如：0-主域, 1-备用域 等（具体数值定义需根据实际业务补充）
   */
  setDomain(domain: number) {
    // 更新成员变量的域值状态
    this.mDomain = domain
  }

  /**
   * 设置日志的启用状态
   *
   * @param isEnable - 布尔值，表示是否启用对象。true 表示启用，false 表示禁用。
   * @returns 无返回值
   */
  setEnable(isEnable: boolean) {
    this.mEnable = isEnable
  }

  /**
   * 检查当前是否允许记录指定级别的日志
   *
   * @param level - 需要检查的日志级别，类型为hilog.LogLevel
   * @returns 如果允许记录该级别日志则返回true，否则返回false
   *
   * @remarks
   * 该函数通过调用hilog.isLoggable方法，结合当前实例的mDomain和mTag，
   * 判断指定日志级别是否可记录
   */
  isLoggable(level: hilog.LogLevel): boolean {
    return hilog.isLoggable(this.mDomain, this.mTag, level)
  }

  /**
   * 控制台日志输出函数（只支持输出到控制台不支持加密存储）
   *
   * @param message - 需要输出的消息内容，支持字符串或对象类型
   * @param [tag] - 可选标签参数，用于标识日志来源。当未提供时默认使用类实例的mTag属性值
   */
  console(message: string | object, tag?: string | undefined) {
    // 组合标签和消息内容后输出日志
    console.log(this.getMessage(tag == undefined ? this.mTag : tag, message))
  }

  /**
   * 记录信息级别的日志。
   *
   * @param message - 要记录的消息内容，可以是字符串或对象。
   * @param tag - 可选的日志标签，用于标识日志的来源或类别。
   */
  info(message: string | object, tag?: string) {
    this.logLevel(hilog.LogLevel.INFO, tag, message)
  }

  /**
   * 记录调试级别的日志。
   *
   * @param message - 要记录的消息内容，可以是字符串或对象。
   * @param tag - 可选的日志标签，用于标识日志的来源或类别。
   */
  debug(message: string | object, tag?: string) {
    this.logLevel(hilog.LogLevel.DEBUG, tag, message)
  }

  /**
   * 记录错误级别的日志。
   *
   * @param message - 要记录的消息内容，可以是字符串或对象。
   * @param tag - 可选的日志标签，用于标识日志的来源或类别。
   */
  error(message: string | object, tag?: string) {
    this.logLevel(hilog.LogLevel.ERROR, tag, message)
  }

  /**
   * 记录警告级别的日志。
   *
   * @param message - 要记录的消息内容，可以是字符串或对象。
   * @param tag - 可选的日志标签，用于标识日志的来源或类别。
   */
  warn(message: string | object, tag?: string) {
    this.logLevel(hilog.LogLevel.WARN, tag, message)
  }

  /**
   * 记录致命错误级别的日志。
   *
   * @param message - 要记录的消息内容，必须是字符串。
   * @param tag - 可选的日志标签，用于标识日志的来源或类别。
   */
  fatal(message: string, tag?: string) {
    this.logLevel(hilog.LogLevel.FATAL, tag, message)
  }

  /**
   * 解密日志文件并将解密后的内容写入指定路径的文件中。
   *
   * @param logPath 需要解密的日志文件路径。
   * @param encryptKey 用于解密的密钥，类型为Uint8Array。
   * @param decryptLogPath 解密后的日志文件存储路径。
   * @returns 如果解密和写入成功，返回true；否则返回false。
   */
  async decryptLogFile(logPath: string, encryptKey: Uint8Array, decryptLogPath: string): Promise<boolean> {
    return loggerFileUtil.decryptLogFile(logPath, encryptKey, decryptLogPath)
  }

  /**
   * 根据指定的日志级别、标签和消息内容打印日志。
   * 如果日志系统处于关闭状态，则不执行任何操作。
   * 支持将日志内容分块打印，并可以选择将日志输出到文件。
   *
   * @param level 日志级别，决定日志的严重程度和打印方式。
   * @param tag 日志标签，用于标识日志来源。如果未提供，则使用默认标签。
   * @param message 日志消息内容，可以是字符串或对象。如果未提供，则默认为空字符串。
   */
  private logLevel(level: hilog.LogLevel, tag?: string, message: string | object = "") {
    // 如果日志系统处于关闭状态，则不执行任何操作
    if (!this.mEnable) {
      return
    }

    // 如果未提供标签，则使用默认标签
    if (tag == undefined) {
      tag = this.mTag
    }

    // 获取最终的日志内容
    const content = this.getMessage(tag, message)

    // 将日志内容分块打印，每块大小为mLogSize
    const len = content.length / this.mLogSize
    for (let i = 0; i < len; i++) {
      let con = content.substring(i * this.mLogSize, (i + 1) * this.mLogSize)
      if (i != 0) {
        con = "|" + con
      }

      // 根据日志级别选择打印方式，支持hilog和console两种方式
      if (this.mHilog) {
        switch (level) {
          case hilog.LogLevel.INFO:
            hilog.info(this.mDomain, tag, con)
            break
          case hilog.LogLevel.WARN:
            hilog.warn(this.mDomain, tag, con)
            break
          case hilog.LogLevel.DEBUG:
            hilog.debug(this.mDomain, tag, con)
            break
          case hilog.LogLevel.ERROR:
            hilog.error(this.mDomain, tag, con)
            break
          case hilog.LogLevel.FATAL:
            hilog.fatal(this.mDomain, tag, con)
            break
        }
      } else {
        switch (level) {
          case hilog.LogLevel.INFO:
            console.info(con)
            break
          case hilog.LogLevel.WARN:
            console.warn(con)
            break
          case hilog.LogLevel.DEBUG:
            console.debug(con)
            break
          case hilog.LogLevel.ERROR:
            console.error(con)
            break
          case hilog.LogLevel.FATAL:
            console.log(con)
            break
        }
      }
    }
    // 如果需要将日志输出到文件，则发送到worker线程进行加密和存储操作
    if (this.mIsLogToFile) {
      this.workerInstance.postMessage(new LogModel(content, this.mEncryptKey))
    }
  }

  /**
   * 获取格式化后的日志消息。
   *
   * 该函数用于生成带有标签和消息内容的格式化日志字符串。支持展示日志位置信息，并处理不同类型的消息内容。
   *
   * @param tag 日志标签，用于标识日志的来源或类别，默认为空字符串。
   * @param message 日志消息内容，可以是字符串或对象。
   * @returns 返回格式化后的日志字符串。
   */
  private getMessage(tag: string = "", message: string | object): string {
    // 初始化日志字符串，包含标签和分隔线
    let log = "┌───────" + tag + "────────────────────────────────────────────────────────────────────────────────"
    log = log.substring(0, log.length - tag.length) + "\n"
    //添加当前日期和时间 精确到毫秒格式为xxxx年xx月xx日 xx时xx分xx秒xxx毫秒，北京时区，并添加到日志中
    log = log + "|    " + new Date().toLocaleString('zh-CN') + "\n"

    try {
      // 如果需要展示日志位置信息，则从堆栈中提取并添加到日志中
      if (this.mShowLogLocation) {
        const stackTrace = new Error().stack
        const traceArray = stackTrace!.split('\n')
        // 从堆栈中提取指定数量的调用信息，排除日志本身的调用
        const traceNum = Math.min(this.mStackTraceNum, traceArray.length - 4)
        let currentTrace = ''
        for (let i = 0; i < traceNum; i++) {
          currentTrace = traceArray[traceArray.length - 2 - i]
          //过滤自定义装饰器的影响
          if (!currentTrace.includes("LogDescriptor") && !currentTrace.includes("Logger")) {
            log = log + "|" + currentTrace + "\n"
          }
        }
        log = log + "|───────────────────────────────────────────────────────────────────────────────────────"
      }

      // 处理消息内容，根据类型进行转换
      let type = typeof message
      if (type == "object") {
        // 如果消息是对象，则将其转换为JSON字符串
        message = this.getObjectToJson(message)
      } else if (type == "string") {
        // 如果消息是字符串且包含大括号，则尝试将其解析为JSON对象并转换为字符串
        const content = message + ""
        if (content.startsWith("{") && content.endsWith("}")) {
          const obj: object = JSON.parse(message.toString())
          message = this.getObjectToJson(obj)
        } else {
          message = content
        }
      }
      // 将处理后的消息内容添加到日志中
      log = log + "\n|    " + message
    } catch (e) {
      // 捕获并记录处理消息时的错误
      hilog.error(this.mDomain, tag, `logger getMessage error :${e}`)
    }
    // 添加日志的结束分隔线
    log = log + "\n└───────────────────────────────────────────────────────────────────────────────────────"
    return log
  }

  /**
   * 将传入的消息对象或字符串转换为格式化的 JSON 字符串，并在每行前添加 "|    " 作为缩进。
   *
   * @param message - 需要转换的消息，可以是字符串或对象。如果是对象，将会被序列化为 JSON 字符串。
   * @returns 返回格式化后的 JSON 字符串，每行前添加了 "|    " 作为缩进。
   */
  private getObjectToJson(message: string | object): string {
    // 将消息对象或字符串序列化为 JSON 字符串，并进行格式化（缩进为 2 个空格）
    const json = JSON.stringify(message, null, 2)
    // 在每行前添加 "|    " 作为缩进
    const endMessage = json.replace(/\n/g, "\n|    ")
    return endMessage
  }
}

export const logger = new Logger()