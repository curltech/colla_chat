import { webClient } from '@/libs/transport/webclient'
/**
 * 保存基本编码用于下拉框
 */
export class BaseCode {
	private baseCodeMap = new Map()
	private valueMap = new Map()
	constructor() { }

	getBaseCode(baseCodeId: string): any {
		if (this.baseCodeMap.has(baseCodeId)) {
			return this.baseCodeMap.get(baseCodeId)
		}
		return webClient.send('/baseCode/GetBaseCode', { baseCodeId: baseCodeId }).then((response: any) => {
			const baseCode = response.data
			if (baseCode) {
				this.baseCodeMap.set(baseCodeId, baseCode)
				let codeDetails = baseCode.codeDetails
				for (let codeDetail of codeDetails) {
					let value = codeDetail.value
					let label = codeDetail.label
					let vMap = new Map()
					if (this.valueMap.has(baseCodeId)) {
						vMap = this.valueMap.get(baseCodeId)
					} else {
						vMap = new Map()
						this.valueMap.set(baseCodeId, vMap)
					}
					vMap.set(value, label)
				}
			}

			return baseCode
		}).catch((error: any) => {
			console.error(error)
		})
	}

	clearBaseCode(baseCodeId: string): any {
		if (this.baseCodeMap.has(baseCodeId)) {
			this.baseCodeMap.delete(baseCodeId)
		}
		if (this.valueMap.has(baseCodeId)) {
			this.baseCodeMap.delete(baseCodeId)
		}
	}

	async codeDetail(baseCodeId: string): Promise<any> {
		let baseCode = await this.getBaseCode(baseCodeId)
		if (baseCode) {
			return baseCode.codeDetails
		}

		return null
	}

	/**
	 * 可以注册成全局vue函数
	 * @param baseCodeId
	 * @param value
	 */
	async translate(baseCodeId: string, value: string): Promise<any> {
		let baseCode = await this.getBaseCode(baseCodeId)
		if (baseCode) {
			let vMap = this.valueMap.get(baseCodeId)
			if (vMap) {
				return vMap.get(value)
			}
		}

		return null
	}
}
export let baseCode = new BaseCode()
