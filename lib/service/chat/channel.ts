/**
 * 我的频道的定义
 */
import {BaseService, EntityStatus, BaseEntity} from "@/libs/datastore/base";
import {EntityState} from '@/libs/datastore/datastore';
import {myself} from '@/libs/p2p/dht/myselfpeer';
import {SecurityPayload} from '@/libs/p2p/payload';

export enum ChannelType {
  'PUBLIC',
  'PRIVATE'
}

export enum EntityType {
  'INDIVIDUAL',
  'ENTERPRISE'
}

export class Channel extends BaseEntity {
  public ownerPeerId: string;// 区分本地不同peerClient属主
  public creator: string;
  /**
   * 基本信息：类型，ID，头像，名称，描述
   */
  public channelType: string;
  public channelId: string;
  public avatar: string;
  public name: string;
  /**
   * 主体信息：类型，ID，名称
   */
  public description: string;
  public entityType: string;
  public entityName: string;
  /**
   * 关注日期
   */
  public markDate: Date;
  public top: boolean;// 是否置顶，包括：true（置顶）, false（不置顶）
}

export class ChannelService extends BaseService {
  search() {
    let options = {
      highlighting_pre: '<font color="' + myself.myselfPeerClient.primaryColor + '">',
      highlighting_post: '</font>'
    };
    return options;
  }
}

export let channelService = new ChannelService("chat_channel", ['ownerPeerId', 'channelId', 'updateDate'], ['name']);

export class Article extends BaseEntity {
  public ownerPeerId: string; // 区分本地不同peerClient属主
  public channelId: string; // 所属渠道ID
  /**
   * 基本信息：ID，作者，标题，封面，摘要
   */
  public articleId: string;
  public author: string;
  public title: string;
  public cover: string;
  public abstract: string;
  /**
   * 正文内容
   */
  public content: string;
  public plainContent: string;
  public pyPlainContent: string;
  /**
   * 是否原创
   */
  public ifOriginal: boolean;
  /**
   * 来源渠道ID，来源渠道名称，来源文章ID，来源文章作者名称
   */
  public srcChannelId: string;
  public srcChannelName: string;
  public srcArticleId: string;
  public srcArticleAuthor: string;

  /**
   * 其它信息
   */
  public attachs: string;
  public payloadKey: string;
  public payloadHash: string;
  public signature: string;
}


export class ArticleService extends BaseService {
  /**
   * 保存本地产生的文档的摘要部分，并且异步地上传到网络
   *
   * 摘要部分有两个属性需要加密处理，内容和缩略
   * @param {*} article
   * @param {*} parent
   */
  async store(article: any, parent: any) {
    if (!article) {
      return;
    }
    let state = article.state;
    let content = article.content;
    let thumbnail = article.thumbnail;
    let payloadKey = article.payloadKey;
    let now = new Date().getTime();
    if (EntityState.New === state) {
      if (!article.createDate) {
        article.createDate = now;
      }
      if (!article.updateDate) {
        article.updateDate = now;
      }
    } else if (EntityState.Modified === state) {
      if (article.versionFlag !== 'sync') {
        article.updateDate = now;
      }
    }
    // put content into attach
    if (EntityState.Deleted === state) {
      await articleAttachService.store(article);
    }
    let ignore = ['attachs', 'content'];
    //let start = new Date().getTime()
    await articleService.save([article], ignore, parent);
    //let end = new Date().getTime()
    //console.log('channelArticle save run time:' + (end - start))
    if (EntityState.Deleted !== state) {
      article.attachs = [{content: content}];
      await articleAttachService.store(article);
    }
    delete article['content_'];
    delete article['thumbnail_'];
  }


  // 删除
  async remove(article: any, parent: any) {
    let state = article.state;
    if (state === EntityState.New) {
      if (parent) {
        parent.splice(parent.indexOf(article), 1);
      }
    } else {
      article['state'] = EntityState.Deleted;
      let attachs = article['attachs'];
      if (attachs && attachs.length > 0) {
        for (let attach of attachs) {
          attach['state'] = EntityState.Deleted;
        }
      }
      await articleAttachService.store(article);
      // put content into attach
      //await this.saveAttach(current)
    }
  }
}

export let articleService = new ArticleService("chat_article", ['ownerPeerId', 'channelId', 'articleId', 'updateDate'], ['title', 'plainContent']);

export class ArticleAttach extends BaseEntity {
  public ownerPeerId: string; // 区分本地不同peerClient属主
  public articleId: string;
  public content: string;
}

export class ArticleAttachService extends BaseService {
  async load(article: any, from: number, limit: number) {
    let data = await this.seek({articleId: article.articleId}, [{createDate: 'desc'}], null, null, limit);
    if (data && data.length > 0) {
      let payloadKey = article.payloadKey;
      if (payloadKey) {
        let securityParams: any = {};
        securityParams.PayloadKey = payloadKey;
        securityParams.NeedCompress = true;
        securityParams.NeedEncrypt = true;
        for (let d of data) {
          let content_ = d.content_;
          if (content_) {
            let payload = await SecurityPayload.decrypt(content_, securityParams);
            //d.content = StringUtil.decodeURI(payload)
            d.content = payload;
          }
        }
      }
    }

    return data;
  }


  /**
   * 保存本地产生的文档的附件部分，并且异步地上传到网络
   *
   * 附件部分有两个属性需要加密处理，缩略（可以没有）和附件内容
   * @param {*} current
   */
  async store(article: any) {
    if (article._id && article.attachs) {
      let securityParams: any = {};
      securityParams.PayloadKey = article.payloadKey;
      securityParams.NeedCompress = true;
      securityParams.NeedEncrypt = true;
      for (let key in article.attachs) {
        let attach = article.attachs[key];
        // put content into attach
        /*if (EntityState.Deleted === current.state) {
            attach.state = EntityState.Deleted
            continue
        } else {
            attach.channelId = current.channelId
        }*/
        attach.state = article.state;
        attach.channelId = article.channelId;
        if (EntityState.Deleted !== article.state) {
          if (myself.myselfPeerClient.localDataCryptoSwitch === true) {
            if (attach.content) {
              let result = await SecurityPayload.encrypt(attach.content, securityParams);
              if (result) {
                attach.securityContext = article.SecurityContext;
                attach.payloadKey = result.PayloadKey;
                attach.needCompress = result.NeedCompress;
                attach.content_ = result.TransportPayload;
                attach.payloadHash = result.PayloadHash;
              }
            }
          }
        }
      }
      let ignore: string[] = [];
      if (myself.myselfPeerClient.localDataCryptoSwitch === true) {
        ignore = ['content'];
      }
      //let start = new Date().getTime()
      await this.save(article.attachs, ignore, article.attachs);
      //let end = new Date().getTime()
      //console.log('channelArticle attachs save run time:' + (end - start))
      for (let attach of article.attachs) {
        delete attach['content_'];
      }
    }
  }

  async remove(attach: any, parent: any) {
    let state = attach.state;
    if (state === EntityState.New) {
      if (parent) {
        parent.splice(parent.indexOf(attach), 1);
      }
    } else {
      attach['state'] = EntityState.Deleted;
      await this.save([attach], null, parent);
    }
  }
}

export let articleAttachService = new ArticleAttachService("chat_articleAttach", ['ownerPeerId', 'articleId'], []);
