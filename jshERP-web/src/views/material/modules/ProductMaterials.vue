<template>
  <a-spin :spinning="loading">
    <a-alert type="info" show-icon message="关联原料及参考用量，仅用于资料配置，不会自动领料或扣减库存。未知用量可留空，请在备注说明用量口径。" />
    <p style="margin:12px 0">产品：{{ product.name }}　基本单位：{{ product.unit }}</p>
    <a-button v-if="canEdit" icon="plus" :disabled="!loaded || lines.length >= 100" @click="add">添加原料</a-button>
    <a-table style="margin-top:12px" :columns="columns" :data-source="lines" row-key="key" :pagination="false">
      <template slot="raw" slot-scope="text, record">
        <a-select :value="record.barCode" :disabled="!canEdit" show-search option-filter-prop="children" placeholder="选择原料" style="width:100%" @change="select(record, $event)">
          <a-select-option v-for="raw in options" :key="raw.barCode" :value="raw.barCode">{{ label(raw) }}</a-select-option>
          <a-select-option v-if="record.barCode && !options.some(raw => raw.barCode === record.barCode)" :value="record.barCode" disabled>{{ record.name }}（已停用，请重新选择）</a-select-option>
        </a-select>
      </template>
      <template slot="quantity" slot-scope="text, record">
        <a-input-number v-model="record.quantity" :disabled="!canEdit" :min="0.000001" :max="999999999999.999999" :precision="6" placeholder="未知可留空" style="width:100%" />
      </template>
      <template slot="remark" slot-scope="text, record">
        <a-input v-model="record.remark" :disabled="!canEdit" :max-length="500" placeholder="例如：模拟关联，用量待确认" />
      </template>
      <template slot="action" slot-scope="text, record"><a v-if="canEdit" @click="remove(record)">移除</a></template>
    </a-table>
    <a-button v-if="canEdit" type="primary" style="margin-top:12px" :loading="saving" :disabled="!loaded" @click="save">保存用料配置</a-button>
  </a-spin>
</template>

<script>
import { getAction, postAction } from '@/api/manage'

export default {
  name: 'ProductMaterials',
  props: { productId: { type: Number, required: true } },
  data() {
    return {
      product: {}, options: [], lines: [], version: 0, canEdit: false,
      loading: false, saving: false, loaded: false, nextKey: 0,
      columns: [
        { title: '关联原料', key: 'raw', width: '40%', scopedSlots: { customRender: 'raw' } },
        { title: '原料单位', dataIndex: 'unit', width: '10%' },
        { title: '参考用量', key: 'quantity', width: '18%', scopedSlots: { customRender: 'quantity' } },
        { title: '用料备注', key: 'remark', scopedSlots: { customRender: 'remark' } },
        { title: '操作', key: 'action', width: 70, scopedSlots: { customRender: 'action' } }
      ]
    }
  },
  created() { this.load() },
  methods: {
    label(raw) { return [raw.name, raw.standard, raw.model, raw.barCode].filter(Boolean).join(' / ') },
    add() { this.lines.push({ key: ++this.nextKey, barCode: undefined, quantity: null, remark: '', unit: '' }) },
    remove(record) { this.lines = this.lines.filter(row => row.key !== record.key) },
    select(record, code) {
      const raw = this.options.find(item => item.barCode === code)
      record.barCode = code
      record.name = raw.name
      record.unit = raw.unit
    },
    error(response) { return response.message || (response.data && response.data.message) || '操作失败，请重新打开核对' },
    async load() {
      this.loading = true
      this.loaded = false
      try {
        const response = await getAction('/material/' + this.productId + '/materials')
        if (response.code !== 200) throw new Error(this.error(response))
        const data = response.data
        this.product = data.product
        this.options = data.options
        this.canEdit = data.canEdit
        this.version = data.version
        this.lines = data.lines.map(row => ({ ...row, quantity: row.quantity == null ? null : row.quantity, key: ++this.nextKey }))
        this.loaded = true
      } catch (error) { this.$message.error(error.message) } finally { this.loading = false }
    },
    async save() {
      if (!this.canEdit || !this.loaded || this.saving) return
      if (this.lines.some(row => !row.barCode)) { this.$message.warning('请为每行选择原料'); return }
      this.saving = true
      try {
        const lines = this.lines.map(row => ({ barCode: row.barCode, quantity: row.quantity, remark: row.remark }))
        const response = await postAction('/material/' + this.productId + '/materials', { version: this.version, lines })
        if (response.code !== 200) throw new Error(this.error(response))
        this.$message.success('产品用料配置已保存')
        await this.load()
      } catch (error) { this.$message.error(error.message) } finally { this.saving = false }
    }
  }
}
</script>
