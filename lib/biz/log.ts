import {BaseService, BaseEntity} from '@/libs/datastore/base'
import {user} from '../stock/user'

export class Log extends BaseEntity {
  public userId!: string
  public level!: string
  public code!: string
  public description!: string
  public createTimestamp!: number
}

export class LogService extends BaseService {
  private logLevel: string = 'error'
  public static logLevels = ['log', 'warn', 'error', 'none']

  setLogLevel(logLevel: string) {
    this.logLevel = logLevel
  }

  async log(description: string, code: string = '', level: string = 'error') {
    if (level === 'error') {
      console.error(code + ':' + description)
    } else if (level === 'warn') {
      console.warn(code + ':' + description)
    } else {
      level = 'log'
      console.log(code + ':' + description)
    }
    if (LogService.logLevels.indexOf(level) >= LogService.logLevels.indexOf(this.logLevel)) {
      let log = new Log()
      log.description = description
      log.code = code
      log.level = level
      if (user.account && user.account.accountId) {
        log.userId = user.account.accountId
      }
      log.createTimestamp = new Date().getTime()
      log = await this.insert(log)
    }
  }

  async clean() {
    let condition = {userId: user.account.accountId}
    let logs = await this.find(condition, null, null, 0, 0)
    if (logs && logs.length > 0) {
      await this.delete(logs)
    }
  }

  async search(phase: string, level: string, searchTimestamp: number): Promise<any> {
    let logResultList = []

    let options = {
      highlighting_pre: '<font color="' + 'primary' + '">',
      highlighting_post: '</font>'
    }
    /*if (!filter) {
      filter = function (doc) {
        return doc.peerId === myself.myselfPeer.peerId
      }
    }*/
    let logResults = await this.searchPhase(phase, ['code', 'description'], options, null, 0, 0)
    console.info(logResults)
    if (logResults && logResults.rows && logResults.rows.length > 0) {
      for (let logResult of logResults.rows) {
        let log = logResult.doc
        let createTimestampStart: number = 0
        let createTimestampEnd: number = 0
        if (searchTimestamp) {
          createTimestampStart = searchTimestamp
          createTimestampEnd = searchTimestamp + 24 * 60 * 60 * 1000
        }
        if ((!log.userId || log.userId === user.account.accountId)
          && (!level || log.level === level)
          && (!searchTimestamp || (log.createTimestamp >= createTimestampStart && log.createTimestamp < createTimestampEnd))) {
          if (logResult.highlighting.code) {
            log.highlightingCode = logResult.highlighting.code
          }
          if (logResult.highlighting.description) {
            log.highlightingDescription = logResult.highlighting.description
          }
          logResultList.push(log)
        }
      }
    }

    return logResultList
  }
}

export let logService = new LogService("bas_log", ['userId', 'level', 'createTimestamp'], ['code', 'description'])
