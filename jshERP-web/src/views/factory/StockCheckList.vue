<template>
 <a-card :bordered="false">
  <div class="table-page-search-wrapper">
   <a-form layout="inline" @keyup.enter.native="load()">
    <a-row :gutter="24">
     <a-col :md="6" :sm="24"><a-form-item label="单据编号" :labelCol="labelCol" :wrapperCol="wrapperCol"><a-input v-model="query.number" placeholder="请输入单据编号" /></a-form-item></a-col>
     <a-col :md="6" :sm="24"><a-form-item label="商品信息" :labelCol="labelCol" :wrapperCol="wrapperCol"><a-input v-model="query.material" placeholder="请输入条码、名称、助记码、规格、型号等信息" /></a-form-item></a-col>
     <a-col :md="6" :sm="24"><a-form-item label="单据日期" :labelCol="labelCol" :wrapperCol="wrapperCol"><a-range-picker v-model="query.dates" style="width:100%" format="YYYY-MM-DD" :placeholder="['开始时间','结束时间']" /></a-form-item></a-col>
     <span style="float:left;overflow:hidden" class="table-page-search-submitButtons"><a-col :md="6" :sm="24"><a-button type="primary" @click="load()">查询</a-button><a-button style="margin-left:8px" @click="resetQuery">重置</a-button><a style="margin-left:8px" @click="expanded=!expanded">{{expanded?'收起':'展开'}}<a-icon :type="expanded?'up':'down'" /></a></a-col></span>
    </a-row>
    <a-row v-if="expanded" :gutter="24">
     <a-col :md="6" :sm="24"><a-form-item label="客户" :labelCol="labelCol" :wrapperCol="wrapperCol"><a-select v-model="query.customerId" show-search allow-clear option-filter-prop="children" placeholder="请选择客户"><a-select-option v-for="c in options.customers" :key="c.id" :value="c.id">{{c.supplier}}</a-select-option></a-select></a-form-item></a-col>
     <a-col :md="6" :sm="24"><a-form-item label="预留仓库" :labelCol="labelCol" :wrapperCol="wrapperCol"><a-select v-model="query.depotId" show-search allow-clear option-filter-prop="children" placeholder="请选择已有预留的仓库"><a-select-option v-for="d in options.depots" :key="d.id" :value="d.id">{{d.name}}</a-select-option></a-select></a-form-item></a-col>
     <a-col :md="6" :sm="24"><a-form-item label="操作员" :labelCol="labelCol" :wrapperCol="wrapperCol"><a-select v-model="query.creatorId" show-search allow-clear option-filter-prop="children" placeholder="请选择订单操作员"><a-select-option v-for="u in options.users" :key="u.id" :value="u.id">{{u.username}}</a-select-option></a-select></a-form-item></a-col>
     <a-col :md="6" :sm="24"><a-form-item label="核查状态" :labelCol="labelCol" :wrapperCol="wrapperCol"><a-select v-model="query.stockState" allow-clear placeholder="请选择核查状态"><a-select-option v-for="(name,key) in stateNames" :key="key" :value="key">{{name}}</a-select-option></a-select></a-form-item></a-col>
     <a-col :md="6" :sm="24"><a-form-item label="单据备注" :labelCol="labelCol" :wrapperCol="wrapperCol"><a-input v-model="query.remark" placeholder="请输入单据备注" /></a-form-item></a-col>
    </a-row>
   </a-form>
  </div>
  <div class="operator"><a-button type="primary" icon="search" :disabled="!selected" @click="open(selected)">库存核查与预留</a-button><a-button icon="rollback" :disabled="!selected || selected.stockState==='unchecked'" @click="release(selected)">释放预留</a-button><a-button icon="reload" @click="load()">刷新</a-button><span>仅显示领导审核通过的订单，缺口按已确认预留量计算。</span></div>
  <a-table :columns="columns" :data-source="orders" row-key="head_id" size="middle" bordered :loading="loading" :pagination="pagination" :row-selection="{type:'radio',selectedRowKeys:selectedKeys,onChange:keys=>selectedKeys=keys}" :scroll="{x:1250}" @change="onPage">
   <template slot="state" slot-scope="_,r"><a-tag :color="stateColors[r.stockState]">{{stateNames[r.stockState]}}</a-tag></template>
   <template slot="qty" slot-scope="v">{{qty(v)}}</template>
   <template slot="action" slot-scope="_,r"><a @click="open(r)">核查 / 查看</a></template>
  </a-table>
  <j-modal :visible="visible" title="订单库存核查与预留" fullscreen switchFullscreen :keyboard="false" :footer="null" @cancel="visible=false">
   <a-spin :spinning="saving">
    <a-descriptions bordered size="small" :column="3"><a-descriptions-item label="订单编号">{{detail.number}}</a-descriptions-item><a-descriptions-item label="客户">{{detail.customer_name}}</a-descriptions-item><a-descriptions-item label="交货日期">{{detail.delivery_date}}</a-descriptions-item><a-descriptions-item label="客户要求" :span="3">{{detail.requirements || '未填写特殊要求'}}</a-descriptions-item></a-descriptions>
    <a-alert style="margin:14px 0" type="info" show-icon message="预留只占用库存，不扣实物。合格待放行可预留，但不可据此出库；预留调整不会自动修改生产任务。" />
    <section v-for="line in detail.lines" :key="line.lineNo" class="product-section">
     <div class="product-title">{{line.lineNo+1}}. {{line.name}}　{{line.brand}}　{{[line.standard,line.model].filter(Boolean).join(' / ')}}</div>
     <div class="line-summary">需求：<b>{{qty(line.quantity)}}</b> 吨　已确认预留：<b>{{qty(line.reserved)}}</b> 吨　当前编辑预留：<b>{{qty(editQuantity(line))}}</b> 吨　编辑后缺口：<b>{{qty(Math.max(0,Number(line.quantity)-editQuantity(line)))}}</b> 吨</div>
     <div style="overflow-x:auto"><table class="lots"><thead><tr><th>仓库</th><th>批号</th><th>实物库存（吨）</th><th>合格可预留（吨）</th><th>其他订单已预留</th><th>本单可分配上限</th><th>质检及放行</th><th>本行预留（吨）</th></tr></thead>
      <tbody><tr v-for="lot in line.lots" :key="lot.key"><td>{{lot.depotName}}</td><td>{{lot.batchNumber}}</td><td>{{qty(lot.physical)}}</td><td>{{qty(lot.eligible)}}</td><td>{{qty(lot.otherReserved)}}</td><td>{{qty(lot.available)}}</td><td><div v-for="(report,i) in lot.reports" :key="i"><a v-if="report.id" @click="showReport(report.id)">{{report.reportNumber || '查看检测报告'}}</a><span v-else>尚无质检档案</span> <a-tag :color="report.status==='passed' && !report.returnHeld?'green':'orange'">{{report.returnHeld?'退货待处理':qualityNames[report.status]}}</a-tag></div><small v-if="lot.hasPendingRelease">含合格待领导放行数量，仅可预留</small></td><td><a-input-number v-model="lot.editQuantity" :precision="6" :min="0" :disabled="Number(lot.eligible)<=0" style="width:130px" /></td></tr>
      <tr v-if="!line.lots.length"><td colspan="8">暂无可显示的批次库存。本次可记录缺口，不能把无质检记录的库存当作合格品预留。</td></tr></tbody>
     </table></div>
    </section>
    <a-checkbox v-model="confirmed">已核对订单客户要求及本次选择批次的质检结果</a-checkbox>
    <a-textarea v-model="note" :max-length="2000" :rows="2" style="margin-top:12px" placeholder="核查或调整说明（选填）" />
    <div class="footer"><a-button @click="visible=false">关闭</a-button><a-button type="primary" :loading="saving" @click="save">确认预留并更新缺口</a-button></div>
    <h3 v-if="detail.history && detail.history.length">预留调整记录</h3>
    <a-timeline><a-timeline-item v-for="(h,i) in detail.history" :key="i">{{date(h.created_at)}}　{{h.actor_name}}　{{h.action==='stock_release'?'释放预留':'确认 / 调整预留'}}　{{h.note}}<div v-for="(a,j) in parseAllocations(h.allocations_json)" :key="j">第 {{a.lineNo+1}} 行，仓库 #{{a.depotId}}，批次 {{a.batchNumber}}，{{qty(a.quantity)}} 吨</div></a-timeline-item></a-timeline>
   </a-spin>
  </j-modal>
  <a-modal :visible="!!report" title="批次检测报告" :width="850" :footer="null" @cancel="report=null"><template v-if="report"><a-descriptions bordered size="small" :column="2"><a-descriptions-item label="报告编号">{{report.report_number}}</a-descriptions-item><a-descriptions-item label="批号">{{report.batch_number}}</a-descriptions-item><a-descriptions-item label="检验结果">{{qualityNames[report.qc_status]}}</a-descriptions-item><a-descriptions-item label="合格入库数量">{{qty(report.qualified_quantity)}} 吨</a-descriptions-item><a-descriptions-item label="领导放行">{{report.release_state==='released'?'已放行':'待放行'}}</a-descriptions-item></a-descriptions><pre class="report-content">{{report.report_text}}</pre></template></a-modal>
 </a-card>
</template>
<script>
import {getAction,postAction} from '@/api/manage'
import moment from 'moment'
const emptyQuery=()=>({number:'',material:'',dates:[moment().subtract(3,'months'),moment()],customerId:undefined,depotId:undefined,creatorId:undefined,stockState:undefined,remark:''})
export default {
 name:'StockCheckList',
 data(){return {query:emptyQuery(),expanded:false,labelCol:{span:5},wrapperCol:{span:18,offset:1},options:{customers:[],depots:[],users:[]},orders:[],pagination:{current:1,pageSize:10,total:0,showSizeChanger:true},selectedKeys:[],loading:false,saving:false,visible:false,detail:{lines:[],history:[]},confirmed:false,note:'',report:null,
 stateNames:{shipped:'整单已出库',unchecked:'待核查',shortage:'无预留 / 待生产',partial:'部分预留 / 有缺口',ready:'整单已预留'},stateColors:{shipped:'green',unchecked:'default',shortage:'red',partial:'orange',ready:'green'},qualityNames:{unregistered:'未登记',pending:'待检',passed:'合格',failed:'不合格',return_hold:'退货待处理'},
 columns:[{title:'订单编号',dataIndex:'number',width:240},{title:'客户',dataIndex:'customer_name',width:150},{title:'交货日期',dataIndex:'delivery_date',width:130},{title:'需求量（吨）',dataIndex:'demand',scopedSlots:{customRender:'qty'},width:130},{title:'已预留（吨）',dataIndex:'reserved',scopedSlots:{customRender:'qty'},width:130},{title:'缺口（吨）',dataIndex:'missing',scopedSlots:{customRender:'qty'},width:130},{title:'核查状态',key:'state',scopedSlots:{customRender:'state'},width:180},{title:'操作',key:'action',scopedSlots:{customRender:'action'},width:120}] }},
 computed:{selected(){return this.orders.find(r=>r.head_id===this.selectedKeys[0])}},
 created(){this.initialize()},
 watch:{'$route.fullPath'(){this.fromProgress()}},
 methods:{
 async fromProgress(){if(this.$route.path!=='/factory/stock_check')return;const id=this.$route.query.orderId;if(id)await this.open({head_id:id})},

  async request(path,data){const r=data===undefined?await getAction('/factoryStock'+path):await postAction('/factoryStock'+path,data);if(r.code!==200)throw new Error(r.message || (r.data&&r.data.message) || '操作失败');return r.data},
  error(e){this.$message.error(e.message || '请求失败')},
  qty(v){return Number(v||0).toLocaleString('zh-CN',{maximumFractionDigits:6})},
  date(v){return v?new Date(v).toLocaleString('zh-CN'):''},
  parseAllocations(v){return JSON.parse(v)},
  async initialize(){try{this.options=await this.request('/options');await this.load();await this.fromProgress()}catch(e){this.error(e)}},
  resetQuery(){this.query=emptyQuery();this.load()},
  async load(reset=true){if(reset)this.pagination.current=1;this.loading=true;this.selectedKeys=[];const params={...this.query,page:this.pagination.current,size:this.pagination.pageSize};delete params.dates;if(this.query.dates && this.query.dates.length===2){params.beginDate=this.query.dates[0].format('YYYY-MM-DD');params.endDate=this.query.dates[1].format('YYYY-MM-DD')}const query=Object.keys(params).filter(key=>params[key]!==undefined && params[key]!==null && params[key]!=='').map(key=>encodeURIComponent(key)+'='+encodeURIComponent(params[key])).join('&');try{const r=await this.request('/list?'+query);this.orders=r.rows;this.pagination.total=r.total}catch(e){this.error(e)}finally{this.loading=false}},
  onPage(p){this.pagination.current=p.current;this.pagination.pageSize=p.pageSize;this.load(false)},
  async open(order){try{const d=await this.request('/'+order.head_id);d.lines.forEach(line=>{line.lots=d.lots.filter(lot=>Number(lot.materialId)===Number(line.id)).map(lot=>{const allocation=d.allocations.find(a=>Number(a.lineNo)===line.lineNo && Number(a.depotId)===Number(lot.depotId) && a.batchNumber===lot.batchNumber);return {...lot,key:lot.depotId+'|'+lot.batchNumber,editQuantity:allocation?Number(allocation.quantity):0}})});this.detail=d;this.confirmed=false;this.note=d.check.length?d.check[0].note:'';this.visible=true}catch(e){this.error(e)}},
  editQuantity(line){return line.lots.reduce((n,lot)=>n+(Number(lot.editQuantity)||0),0)},
  async save(){if(!this.confirmed){this.$message.warning('请先核对客户要求与质检结果');return}const allocations=[];for(const line of this.detail.lines){if(this.editQuantity(line)>Number(line.quantity)){this.$message.warning('第'+(line.lineNo+1)+'行预留不能超过需求');return}for(const lot of line.lots){if(Number(lot.editQuantity)<0){this.$message.warning('预留数量不能为负');return}if(Number(lot.editQuantity)>0)allocations.push({lineNo:line.lineNo,depotId:lot.depotId,batchNumber:lot.batchNumber,quantity:lot.editQuantity})}}this.saving=true;try{await this.request('/'+this.detail.head_id+'/save',{version:this.detail.version,confirmed:true,note:this.note,allocations});this.$message.success('已更新预留和缺口；生产任务未自动修改');this.visible=false;await this.load(false)}catch(e){this.error(e)}finally{this.saving=false}},
  release(order){this.$confirm({title:'释放这张订单的全部预留？',content:'实物库存不会减少，订单将回到待核查状态。',onOk:async()=>{try{await this.request('/'+order.head_id+'/release',{version:order.version});this.$message.success('预留已释放');await this.load(false)}catch(e){this.error(e)}}})},
  async showReport(id){try{this.report=await this.request('/report/'+id)}catch(e){this.error(e)}}
 }
}
</script>
<style scoped>
.operator{display:flex;align-items:center;gap:8px;flex-wrap:wrap}.operator{margin:14px 0}.operator span{font-size:12px;color:#888}.product-section{margin:22px 0}.product-title{font-size:16px;font-weight:600}.line-summary{margin:10px 0}.lots{width:100%;min-width:1100px;border-collapse:collapse}.lots th,.lots td{padding:9px;border:1px solid #e8e8e8;text-align:left}.lots th{background:#fafafa}.lots small{color:#ad6800}.footer{display:flex;justify-content:flex-end;gap:8px;margin:18px 0}.report-content{font-family:inherit;white-space:pre-wrap;margin-top:18px;line-height:1.8}
</style>
