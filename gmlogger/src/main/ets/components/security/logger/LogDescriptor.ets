import { logger } from './Logger'
import { JSON } from '@kit.ArkTS'

/**
 * 方法调用日志装饰器
 *
 * @param target - 被装饰方法所属的类（静态方法对应构造函数，实例方法对应原型对象）
 * @param key - 被装饰方法的名称
 * @param descriptor - 方法属性描述符，包含方法的元数据信息
 * @returns 修改后的属性描述符
 */
export function MethodLog(target: Object, key: string, descriptor: PropertyDescriptor) {
  // 保存原始方法引用
  const originalMethod: Function = descriptor.value
  // 重写方法实现
  descriptor.value = (...args: Object[]) => {
    const startTime = Date.now()
    const result: Object = originalMethod(...args)
    const endTime = Date.now() - startTime
    try {
      let argumentStr = ''
      args.forEach(arg => {
        // 处理参数序列化：分离普通类型和对象类型参数
        if (arg instanceof Object) { // 拼接对象类型参数
          argumentStr += `${JSON.stringify(arg)},`
        } else { // 拼接普通类型参数
          argumentStr += `${arg},`
        }
      })
      // 构造完整的日志信息
      logger.info(`Calling Class:[${target.constructor.name}] method:[${key}] `
        + `with argument: [${argumentStr} returned: ${JSON.stringify(result)}] `
        + `castTime: ${endTime}ms`)
    } catch (e) {
      console.error(e)
    }
    return result
  }
  return descriptor
}

