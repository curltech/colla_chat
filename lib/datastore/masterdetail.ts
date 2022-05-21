import { EntityState } from '@/libs/datastore/datastore'
import {  RemoteDbEntity } from '@/libs/datastore/remotedb'
import Vue from 'vue'

export class MasterDetailEntity {
	public masterEntity: RemoteDbEntity
	public detailEntity: RemoteDbEntity
	public relateKey: string
	constructor(master: string, detail: string, relateKey: string) {
		this.masterEntity = new RemoteDbEntity(master)
		this.detailEntity = new RemoteDbEntity(detail)
		this.relateKey = relateKey
	}

	async relate(current: any, orderby: string) {
    if (current && current[this.relateKey]) {
      let param: any = {}
      param[this.relateKey] = current[this.relateKey]
      let detailEntity = this.detailEntity
      if (detailEntity !== undefined) {
        let result = await detailEntity.find(param, orderby, 0, 0, 0)
        if (result) {
          current.details = result.data
        }
      }
    }
  }
}
