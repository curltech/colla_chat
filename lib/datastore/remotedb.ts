import {EntityState} from '@/libs/datastore/datastore';
import {webClient} from '@/libs/transport/webclient';

/**
 * 对远程数据库访问的基本操作，希望有localdbentity类，相同接口，用于本地数据库
 */
export class RemoteDbEntity {
  private name: string;
  public index: number = 0;

  constructor(name: string) {
    this.name = name;
  }

  get(param: any, orderby: string) {
    let url = '/' + this.name + '/Get';
    if (orderby && orderby.length > 0) {
      url = url + '?orderby=' + orderby;
    }
    return webClient.send(url, param).then((response: any) => {
      const entity = response.data;
      if (entity) {
        if (!entity.entityId) {
          entity.entityId = this.name + this.index++;
          entity.state = EntityState.None;
        }
      }

      return entity;
    }).catch((error: any) => {
      console.error(error);
    });
  }

  find(param: any, orderby: string, from: number, limit: number, count: number) {
    let params: any = {};
    if (param) {
      params = param;
    }
    if (limit > 0) {
      params = {from: from, limit: limit, orderby: orderby, count: count, condiBean: params};
    }
    return webClient.send('/' + this.name + '/Find', params).then((response: any) => {
      const result = response.data;
      if (result) {
        let entities: any[] = result.data;
        for (let i = 0; i < entities.length; ++i) {
          let entity = entities[i];
          if (!entity.entityId) {
            entity.entityId = this.name + this.index++;
            entity.state = EntityState.None;
          }
        }
      }

      return result;
    }).catch((error: any) => {
      console.error(error);
    });
  }

  updateState(target: any, state: string) {
    let old = target.state;
    if (old === EntityState.New && state === EntityState.Modified) {
      return;
    }
    target.state = state;
  }

  add(data: any[], record?: any): any {
    let index = this.index++;
    if (!record) {
      record = {state: EntityState.New, entityId: this.name + index};
    } else {
      record.state = EntityState.New;
      record.entityId = this.name + index;
    }
    data.push(record);

    return record;
  }

  copy(data: any[], record: any): any {
    let index = this.index++;
    if (record) {
      let json = JSON.stringify(record);
      let c = JSON.parse(json);

      return this.add(data, c);
    }

    return undefined;
  }

  remove(data: any[], selected: any[]) {
    if (selected.length > 0) {
      for (let i = 0; i < selected.length; ++i) {
        if (selected[i].state === EntityState.New) {
          let index = data.indexOf(selected[i]);
          if (index > -1) {
            data.splice(index, 1);
          }
          selected.splice(i, 1);
        } else {
          selected[i].state = EntityState.Deleted;
        }
      }
    }
  }

  removeElement(data: any, target: any) {
    if (data instanceof Array) {
      let index = data.indexOf(target);
      if (index > -1) {
        data.splice(index, 1);
      }
    } else if (data instanceof Object && !(data instanceof Date)) {
      if (data.hasOwnProperty(target)) {
        delete target[target];
      }
    }
  }

  buildDataMap(data: any[], isState: boolean): any {
    let stateData: any[] = [];
    let dataMap = new Map();
    if (data.length > 0) {
      for (let i = 0; i < data.length; ++i) {
        if (isState === true) {
          if (data[i].state && data[i].state !== EntityState.None) {
            stateData.push(data[i]);
            dataMap.set(data[i].entityId, data[i]);
          }
        } else {
          stateData.push(data[i]);
          dataMap.set(data[i].entityId, data[i]);
        }
      }
    }

    return {dataMap: dataMap, stateData: stateData};
  }

  save(data: any[]) {
    let {dataMap, stateData} = this.buildDataMap(data, true);
    if (stateData.length > 0) {
      if (webClient) {
        return webClient.send('/' + this.name + '/Save', stateData).then((response: any) => {
          const resData = response.data;
          this.responseData(resData, data, dataMap);

          return resData;
        }).catch((error: any) => {
          console.error(error);
        });
      } else {
        throw new Error('No httpClient!');
      }
    }
  }

  responseData(resData: any[], data: any[], dataMap: Map<string, any>) {
    if (resData && resData.length > 0) {
      for (let i = 0; i < resData.length; ++i) {
        let entity = resData[i];
        let entityId = entity.entityId;
        if (dataMap.has(entityId)) {
          let stateEntity = dataMap.get(entityId);
          this.deepCopy(entity, stateEntity);
          if (entity.state === EntityState.Deleted) {
            this.removeElement(data, stateEntity);
          }
        } else {
          data.push(entity);
        }
      }
    }
  }

  deepCopy(src: any, target: any) {
    if (null == src || "object" != typeof src || src instanceof Date) return;

    // 源是数组
    if (src instanceof Array) {
      if (!target) {
        target = [];
      }
      if (!(target instanceof Array)) {
        throw new Error("target type is wrong");
      }
      for (let i = 0, len = src.length; i < len; i++) {
        // 数组元素是被删除的
        if (i < target.length) {
          let value = this.deepCopy(src[i], target[i]);
          if (value === null) {
            target.splice(i, 1);
          }
        } else {
          let value = this.deepCopy(src[i], null);
          if (value !== null) {
            target.push(value);
          }
        }
      }
      return target;
    }

    // 源是非日期对象
    if (src instanceof Object && !(src instanceof Date)) {
      // 源是被删除的，直接返回null
      if (src.state === EntityState.Deleted) {
        return null;
      }
      if (!target) {
        target = {};
      }
      if (!(target instanceof Object)) {
        throw new Error("target type is wrong");
      }

      // 源的每个属性
      for (var attr in src) {
        if (src.hasOwnProperty(attr)) {
          let value = src[attr];
          if (value) {
            // 源属性是普通值或者日期值，直接赋值
            if ("object" != typeof value || value instanceof Date) {
              target[attr] = value;
            } else {
              // 源属性是非日期对象
              if (target.hasOwnProperty(attr)) {
                let targetValue = this.deepCopy(src[attr], target[attr]);
                if (targetValue === null) {
                  delete target[attr];
                }
              } else {
                let targetValue = this.deepCopy(src[attr], null);
                if (targetValue !== null) {
                  target[attr] = targetValue;
                }
              }
            }
          } else {
            target[attr] = value;
          }
        }
      }
      target.state = EntityState.None;

      return target;
    }
    throw new Error("Unable to copy values! Its type isn't supported.");
  }

  insert(data: any[]) {
    let {dataMap, stateData} = this.buildDataMap(data, false);
    if (stateData.length > 0) {
      return webClient.send('/' + this.name + '/Insert', stateData).then((response: any) => {
        const resData = response.data;
        this.responseData(resData, data, dataMap);

        return resData;
      }).catch((error: any) => {
        console.error(error);
      });
    }
  }

  update(data: any[]) {
    let {dataMap, stateData} = this.buildDataMap(data, false);
    if (stateData.length > 0) {
      return webClient.send('/' + this.name + '/Update', stateData).then((response: any) => {
        const resData = response.data;
        this.responseData(resData, data, dataMap);

        return resData;
      }).catch((error: any) => {
        console.error(error);
      });
    }
  }

  delete(data: any[]) {
    return webClient.send('/' + this.name + '/Delete', data).then((response: any) => {
      const resData = response.data;
      if (resData && resData.length > 0) {
        data.splice(0, data.length);
      }
      return resData;
    }).catch((error: any) => {
      console.error(error);
    });
  }
}
