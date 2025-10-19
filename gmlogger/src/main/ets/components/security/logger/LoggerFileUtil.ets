import { fileIo as fs, ReadOptions } from '@kit.CoreFileKit';
import { LoggerCryptoUtil } from './LoggerCryptoUtil';
import { buffer } from '@kit.ArkTS';

/**
 * LoggerFileUtil 类用于管理日志文件的写入和删除操作。
 * 该类提供了两个方法：writeLog 和 deleteOldLog，分别用于写入日志文件并删除旧日志文件。
 */
class LoggerFileUtil {
  // 定义日志文件的最大大小为 20MB
  private MAX_SIZE = 1024 * 1024 * 20
  // 定义日志文件的分隔符，用于分割加密日志文件
  private LINES_DELIMITER = [0x0A, 0x0D, 0x22, 0x7D, 0xAE]
  // 定义日志文件的存储路径
  logPath: string = ''

  /**
   * 获取一个可用的日志文件。
   * 该方法会检查日志文件的大小，如果当前文件大小超过最大限制，则创建一个新的日志文件。
   *
   * @returns {fs.File} 返回一个可读写的日志文件对象。
   */
  private getLogFile() {
    let index = 0
    let filePath = `${this.logPath}log_${index}.txt`

    // 检查当前日志文件的大小，如果超过最大大小，则递增索引，寻找下一个可用的日志文件
    while (fs.accessSync(filePath) && fs.statSync(filePath).size >= this.MAX_SIZE) {
      index++
      filePath = `${this.logPath}log_${index}.txt`
    }

    // 以读写、创建、追加模式打开日志文件并返回
    return fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.APPEND)
  }

  /**
   * 将日志内容写入日志文件。
   *
   * @param content - 要写入的日志内容，可以是字符串(明文)或Uint8Array(密文)类型。
   * @returns 无返回值。
   *
   * 注：如果写入的是加密数据 则在末尾增加特殊字符分割，用于后续解密操作
   */
  writeLog(content: string | Uint8Array) {
    let fd = 0
    try {
      // 如果日志路径为空，则直接返回
      if (this.logPath === '') {
        return
      }
      // 检查日志路径是否存在，如果不存在则创建
      if (!fs.accessSync(this.logPath)) {
        fs.mkdirSync(this.logPath, true)
      }
      // 删除旧的日志文件
      this.deleteOldLog()
      // 获取当前日志文件并写入内容
      let file = this.getLogFile()
      fd = file.fd
      if (typeof content === 'string') {
        fs.writeSync(file.fd, `${content}\n`)
      } else {
        fs.writeSync(file.fd, buffer.from(content).buffer)
        fs.writeSync(file.fd, buffer.from(this.LINES_DELIMITER).buffer)
      }
    } catch (e) {
      // 捕获并输出异常信息
      console.error('writeLog error is ' + e)
    } finally {
      if (fd != 0) {
        fs.closeSync(fd)
      }
    }
  }

  /**
   * 删除超过12小时的旧日志文件。
   *
   * @returns 无返回值。
   */
  private deleteOldLog() {
    try {
      // 获取日志路径下的所有文件
      const listFile = fs.listFileSync(this.logPath)
      // 遍历文件列表，删除超过12小时的文件
      listFile.forEach((file) => {
        if (fs.statSync(`${this.logPath}${file}`).mtime * 1000 < Date.now() - 43200000) {
          fs.unlinkSync(`${this.logPath}${file}`)
        }
      })
    } catch (e) {
      console.error('deleteOldLog error is ' + e)
    }
  }

  /**
   * 将给定的 Uint8Array 按照特定的分隔符进行分割，并返回分割后的 Uint8Array 数组。
   *
   * @param uint8Array - 需要分割的 Uint8Array 数据。
   * @returns 返回一个 Uint8Array 数组，每个元素是原数组按照分隔符分割后的子数组。
   */
  private splitUint8Array(uint8Array: Uint8Array): Uint8Array[] {
    const result: Uint8Array[] = []
    // 定义分隔符，分隔符是一个包含5个字节的数组
    const delimiter: number[] = this.LINES_DELIMITER
    let start = 0
    // 遍历 Uint8Array，查找分隔符并进行分割
    for (let i = 0; i < uint8Array.length; i++) {
      // 如果剩余的元素不足5个，则停止查找
      if (i + 4 >= uint8Array.length) {
        break
      }
      // 检查当前字节及其后续4个字节是否与分隔符匹配
      if (uint8Array[i] === delimiter[0] && uint8Array[i + 1] === delimiter[1] && uint8Array[i + 2] === delimiter[2] &&
        uint8Array[i + 3] === delimiter[3] && uint8Array[i + 4] === delimiter[4]) {
        // 将分隔符前的部分添加到结果数组中
        result.push(uint8Array.slice(start, i))
        // 更新起始位置为分隔符后的位置
        start = i + 5
        // 跳过已匹配的分隔符
        i += 4
      }
    }
    // 将最后一部分数据添加到结果数组中
    if (start < uint8Array.length) {
      result.push(uint8Array.slice(start))
    }
    return result
  }

  /**
   * 解密日志文件
   *
   * 该函数用于解密指定的加密日志文件，并将解密后的内容写入到指定的解密日志文件中。
   *
   * @param logPath - 加密日志文件的路径。如果为空字符串，则函数返回 false。
   * @param encryptKey - 用于解密的密钥，类型为 Uint8Array。如果密钥长度为 0，则函数返回 false。
   * @param decryptLogPath - 解密日志文件的存储路径。如果为空字符串，则函数返回 false。
   * @returns 返回一个布尔值，表示解密操作是否成功。如果成功返回 true，否则返回 false。
   */
  async decryptLogFile(logPath: string, encryptKey: Uint8Array, decryptLogPath: string) {
    try {
      // 检查输入参数是否有效
      if (logPath === '' || encryptKey.length === 0 || decryptLogPath === '') {
        return false;
      }
      // 检查日志文件是否存在
      if (!fs.accessSync(logPath)) {
        return false;
      }
      // 检查解密日志存储路径是否存在，如果不存在则创建
      if (!fs.accessSync(decryptLogPath)) {
        fs.mkdirSync(decryptLogPath, true);
      }
      // 打开加密日志文件以进行读写
      const encryptFile = fs.openSync(logPath, fs.OpenMode.READ_WRITE)
      // 创建解密日志文件并打开以进行读写
      const decryptFile = fs.openSync(`${decryptLogPath}/decryptLog-${Date.now()}.txt`,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.APPEND)
      let decryptLine = '';
      // 创建一个大小为1024字节的ArrayBuffer对象，用于存储从文件中读取的数据
      let arrayBuffer = new ArrayBuffer(this.MAX_SIZE);
      // 设置读取的偏移量和长度
      let readOptions: ReadOptions = {
        offset: 0,
        length: arrayBuffer.byteLength
      };
      // 从加密日志文件中读取数据
      let readCount = fs.readSync(encryptFile.fd, arrayBuffer, readOptions)
      arrayBuffer = arrayBuffer.slice(0, readCount)
      // 将读取的数据分割成多行
      let readerArray = this.splitUint8Array(new Uint8Array(arrayBuffer))
      // 对每一行进行解密并写入解密后的内容
      readerArray.forEach((line) => {
        if (line.length > 0) {
          decryptLine = LoggerCryptoUtil.decryptSM4(encryptKey, line);
          fs.writeSync(decryptFile.fd, `${decryptLine}\n`);
        }
      })
      // 关闭加密日志文件和解密日志文件
      fs.closeSync(encryptFile.fd);
      fs.closeSync(decryptFile.fd);
      return true;
    } catch (e) {
      // 捕获并输出异常信息
      console.error('decryptLogFile error is ' + e);
      return false;
    }
  }
}

export const loggerFileUtil = new LoggerFileUtil()