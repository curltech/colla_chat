import {BaseService, EntityStatus, BaseEntity} from "@/libs/datastore/base";
import {CollaUtil} from "@/libs/tool/util";

export class Conference extends BaseEntity {
  public peerId: string; // 发起人
  public conferenceId: string; // 会议编号
  public password: string = ''; // 密码
  public linkman = false; // 是否好友才能参加
  public contact = false; // 是否在地址本才能参加
  public startDate: Date; // 开始时间
  public endDate: Date; // 结束时间
  public notification = true; // 自动发送会议通知
  public mute = false; // 自动静音
  public video = true; // 是否视频
  public wait = true; // 自动等待
  public advance = true; // 参会者可提前加入
  public upperNumber = 300; // 参会人数上限
  public attach: any = {}; // 会议资料
  public participation: any = {}; // 参与人的集合
}

class ConferenceService extends BaseService {
  public defaultConference = new Conference();

  /**
   * 根据传入的会议参数开始会议
   * @param {*} conference
   */
  create(conference: any) {
    if (!conference) {
      conference = CollaUtil.clone(this.defaultConference);
      conference.startDate = new Date();
      conference.endDate = new Date();
    }
    conference = this.insert(conference);

    return conference;
  }

  /**
   * 加入会议
   * @param {*} peerId
   * @param {*} conferenceId
   * @param {*} password
   */
  join(peerId: string, conferenceId: string, password: string) {

  }
}

export let conferenceService = new ConferenceService("chat_conference", ['peerId', 'conferenceId'], []);
