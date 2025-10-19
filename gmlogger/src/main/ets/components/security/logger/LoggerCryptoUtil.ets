import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { buffer } from '@kit.ArkTS';

/**
 * LoggerCryptoUtil 类提供了与日志记录和加密相关的实用工具。
 * 该类包含用于日志加密、解密、签名验证等功能的方法。
 * 通过使用该类，开发者可以确保日志数据的安全性和完整性。
 */
export class LoggerCryptoUtil {
  /**
   * 静态私有变量 `iv`，用于存储加密过程中使用的初始化向量（IV）。
   * 该变量通过调用 `LoggerCryptoUtil.genIvParamsSpec()` 方法生成，确保每次加密操作使用唯一的初始化向量。
   */
  private static iv = LoggerCryptoUtil.genIvParamsSpec();

  /**
   * 生成一个随机的SM4对称密钥。
   * 该函数使用SM4算法生成一个128位的对称密钥，并返回其编码后的数据。
   *
   * @returns {cryptoFramework.SymKey} 返回生成的SM4对称密钥。
   */
  static generateSM4Key() {
    // 创建SM4对称密钥生成器实例。
    const symKeyGenerator = cryptoFramework.createSymKeyGenerator('SM4_128');
    // 生成对称密钥并返回其编码数据。
    const symKey = symKeyGenerator.generateSymKeySync();
    return symKey.getEncoded().data
  }

  /**
   * 根据给定的数据生成SM4对称密钥。
   * 该函数将输入的字节数组转换为SM4对称密钥。
   *
   * @param {Uint8Array} symKeyData - 用于生成对称密钥的字节数组。
   * @returns {cryptoFramework.SymKey} 返回生成的SM4对称密钥。
   */
  static genSymKeyByData(symKeyData: Uint8Array) {
    // 将输入的字节数组封装为DataBlob对象。
    const symKeyBlob: cryptoFramework.DataBlob = { data: symKeyData };
    // 创建SM4对称密钥生成器实例。
    const sm4Generator = cryptoFramework.createSymKeyGenerator('SM4_128');
    // 将DataBlob对象转换为对称密钥。
    const symKey = sm4Generator.convertKeySync(symKeyBlob);
    return symKey;
  }

  /**
   * 生成指定长度的随机字节数组
   * 该函数使用加密框架生成一个指定长度的随机字节数组，并返回该数组。
   *
   * @param len - 需要生成的随机字节数组的长度，类型为 `number`。
   * @returns 返回生成的随机字节数组，类型为 `Uint8Array`。
   */
  static generateRandom(len: number) {
    // 创建一个随机数生成器实例
    let rand = cryptoFramework.createRandom();
    // 同步生成指定长度的随机字节数组
    let generateRandSync = rand.generateRandomSync(len);
    // 返回生成的随机字节数组
    return generateRandSync;
  }

  /**
   * 生成一个用于加密的初始化向量参数规范（IvParamsSpec）。
   * 该函数创建了一个包含固定初始化向量（IV）的IvParamsSpec对象，用于加密算法中。
   *
   * @returns {cryptoFramework.IvParamsSpec} 返回一个包含初始化向量参数的IvParamsSpec对象。
   */
  private static genIvParamsSpec() {
    // 创建一个固定的16字节初始化向量（IV）数组
    let ivBlob = new Uint8Array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5]);

    // 构建IvParamsSpec对象，包含算法名称和初始化向量
    let ivParamsSpec: cryptoFramework.IvParamsSpec = {
      algName: "IvParamsSpec",
      iv: { data: ivBlob }
    };

    return ivParamsSpec;
  }

  /**
   * 使用SM4算法对明文进行加密。
   *
   * @param key - 用于加密的密钥，类型为Uint8Array。
   * @param plainText - 需要加密的明文，类型为字符串。
   * @returns 返回加密后的数据，类型为Uint8Array。如果加密失败，则返回明文的Uint8Array表示。
   */
  static encryptSM4(key: Uint8Array, plainText: string) {
    try {
      // 生成对称密钥
      let symKey = LoggerCryptoUtil.genSymKeyByData(key);
      // 创建SM4加密器，使用CBC模式和PKCS7填充
      let cipher = cryptoFramework.createCipher('SM4_128|CBC|PKCS7');
      // 初始化加密器为加密模式，并设置密钥和初始化向量
      cipher.initSync(cryptoFramework.CryptoMode.ENCRYPT_MODE, symKey, LoggerCryptoUtil.iv);
      // 对明文进行加密
      let encryptData = cipher.doFinalSync({ data: new Uint8Array(buffer.from(plainText, 'utf-8').buffer) });
      return encryptData.data;
    } catch (e) {
      // 如果加密失败，记录错误并返回明文的Uint8Array表示
      console.log(e);
      return new Uint8Array(buffer.from(plainText, 'utf-8').buffer)
    }
  }

  /**
   * 使用SM4算法对密文进行解密。
   *
   * @param key - 用于解密的密钥，类型为Uint8Array。
   * @param cipherText - 需要解密的密文，类型为Uint8Array。
   * @returns 返回解密后的明文，类型为字符串。如果解密失败，则返回密文的字符串表示。
   */
  static decryptSM4(key: Uint8Array, cipherText: Uint8Array) {
    try {
      // 生成对称密钥
      let symKey = LoggerCryptoUtil.genSymKeyByData(key);
      // 创建SM4解密器，使用CBC模式和PKCS7填充
      let decoder = cryptoFramework.createCipher('SM4_128|CBC|PKCS7');
      // 初始化解密器为解密模式，并设置密钥和初始化向量
      decoder.initSync(cryptoFramework.CryptoMode.DECRYPT_MODE, symKey, LoggerCryptoUtil.iv);
      // 对密文进行解密
      let decryptData = decoder.doFinalSync({ data: cipherText });
      return buffer.from(decryptData.data).toString('utf-8');
    } catch (e) {
      // 如果解密失败，记录错误并返回密文的字符串表示
      console.log(e);
      return buffer.from(cipherText).toString('utf-8');
    }
  }
}