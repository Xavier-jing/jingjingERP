<template>
 <a-card :bordered="false">
  <h2>发货申请与装车出库</h2>
  <p>销售核实后申请发货 → 财务核验款到发货条件 → 仓库登记所有车辆、装运明细及照片 → 整单统一确认出库。数量单位：吨。</p>
  <a-button v-if="options.canConfigure" @click="financeId=options.financeId;configVisible=true">到账确认财务账号</a-button>
  <a-alert v-if="!options.financeId" message="尚未配置到账确认财务账号，款到发货订单需先配置后才能出库。" type="info" show-icon style="margin:12px 0"/>
  <a-form layout="inline" style="margin:16px 0"><a-form-item label="订单 / 客户"><a-input v-model="keyword" @pressEnter="load()"/></a-form-item><a-button type="primary" @click="load()">查询</a-button><a-button style="margin-left:8px" @click="keyword='';load()">重置</a-button></a-form>
  <a-table :columns="columns" :data-source="rows" row-key="head_id" :pagination="pagination" :loading="loading" @change="onPage">
   <template slot="terms" slot-scope="v">{{termsNames[v]}}</template><template slot="state" slot-scope="v">{{states[v]||'未申请'}}</template><a slot="action" slot-scope="_,r" @click="open(r.head_id)">申请 / 装车 / 发货进度</a>
  </a-table>
  <j-modal title="订单发货与多车装运" :visible="visible" :width="1250" :footer="null" @cancel="visible=false">
   <p>订单：{{form.number}}　客户：{{form.customer_name}}　付款条件：{{termsNames[form.payment_terms]}}　状态：{{states[doc.workflow_status]||'未申请'}}</p>
   <p>客户要求：{{form.requirements||'—'}}</p><p v-if="form.total_price!=null">订单含税金额：{{form.total_price}} 元</p>
   <div class="actions">
    <a-button v-if="form.isOwner&&form.orderState==='approved'&&(!doc.workflow_status||doc.workflow_status==='cancelled')" type="primary" @click="requestTerms=form.payment_terms==='unconfirmed'?undefined:form.payment_terms;requestVisible=true">提交发货申请</a-button>
    <a-button v-if="form.isOwner&&doc.workflow_status==='requested'" @click="openAction('cancel')">撤销发货申请</a-button>
    <a-button v-if="options.isFinance&&doc.workflow_status==='requested'&&form.payment_terms==='prepay'" @click="openAction('paid')">确认整单款项到账</a-button>
    <a-button v-if="options.isFinance&&doc.workflow_status==='requested'&&doc.paid_by" @click="openAction('unpaid')">撤销到账确认</a-button>
    <a-button :disabled="dirty||uploading" @click="open(form.head_id)">刷新进度</a-button>
   </div>
   <a-alert v-if="form.payment_terms==='prepay'" :type="doc.paid_by?'success':'warning'" :message="doc.paid_by?'财务已确认整单款项到账，可在装车完成后统一出库。':'款到发货：尚未确认整单款项到账，不能出库。'"/>
   <p v-if="doc.paid_by">到账日期：{{doc.paid_date}}　确认时间：{{doc.paid_at}}<span v-if="doc.paid_amount!=null">　确认金额：{{doc.paid_amount}} 元</span></p>
   <p v-if="doc.workflow_status==='shipped'">全部车辆已统一确认出库：{{doc.shipped_at}}　库存单：DDCK{{form.head_id}}。订单预留已核销。</p>
   <h3>订单产品数量</h3><div v-for="l in form.lines" :key="l.lineNo">{{lineName(l.lineNo)}}：{{l.quantity}} 吨</div>
   <template v-if="doc.workflow_status!=='shipped'"><h3 style="margin-top:16px">当前已预留批次</h3><div v-for="a in form.allocations" :key="allocationKey(a)">{{allocationLabel(a)}}：{{a.quantity}} 吨</div></template>
   <h3 style="margin-top:20px">车辆装运明细</h3><p>每辆车可以装多个产品和批次。可逐步保存装运信息；全部车辆合计必须严格等于订单数量，最后统一出库。</p>
   <a-button v-if="canPack" @click="addTruck">增加车辆</a-button>
   <a-card v-for="(truck,ti) in trucks" :key="ti" style="margin-top:12px">
    <a-row :gutter="12"><a-col :span="8"><div class="label">车牌号 *</div><a-input v-model="truck.plate" :disabled="!canPack" :max-length="30"/></a-col><a-col :span="8"><div class="label">司机 *</div><a-input v-model="truck.driver" :disabled="!canPack" :max-length="100"/></a-col><a-col :span="8"><div class="label">联系电话 *</div><a-input v-model="truck.phone" :disabled="!canPack" :max-length="50"/></a-col></a-row>
    <div class="scroll"><table class="shipping-table"><thead><tr><th>产品 / 仓库 / 预留批次</th><th>装运数量（吨）</th><th v-if="canPack">操作</th></tr></thead><tbody><tr v-for="(line,li) in truck.lines" :key="li"><td>
     <a-select v-if="canPack" v-model="line.allocationKey" style="min-width:460px;width:100%" @change="chooseAllocation(line)"><a-select-option v-for="a in form.allocations" :key="allocationKey(a)">{{allocationLabel(a)}}（预留 {{a.quantity}} 吨）</a-select-option></a-select>
     <span v-else>{{lineName(line.lineNo)}} / {{line.depotName||line.depotId}} / {{line.batchNumber}}</span>
    </td><td><a-input-number v-model="line.quantity" :min="0" :precision="6" :disabled="!canPack"/></td><td v-if="canPack"><a @click="truck.lines.splice(li,1)">移除</a></td></tr></tbody></table></div>
    <a-button v-if="canPack" @click="truck.lines.push({allocationKey:undefined,quantity:null})">增加装运产品</a-button><a-button v-if="canPack" type="link" @click="trucks.splice(ti,1)">移除本车</a-button>
    <div class="label">本车装车照片（确认出库前至少1张，可多张）</div>
    <a-upload name="file" list-type="picture-card" :multiple="true" :action="uploadAction" :headers="uploadHeaders" :data="{biz:'bill'}" :file-list="truck.files" :disabled="!canPack" :before-upload="beforeUpload" @change="info=>photoChange(truck,info)" @preview="preview"><div v-if="canPack&&truck.files.length<20"><a-icon type="plus"/><div>上传装车照片</div></div></a-upload>
   </a-card>
   <div v-if="canPack" class="actions" style="margin-top:16px"><a-button type="primary" :loading="saving" :disabled="uploading" @click="saveTrucks">保存装车信息</a-button><a-button type="primary" :loading="saving" :disabled="dirty||uploading" @click="confirmShip">所有车辆装完，统一确认出库</a-button><span v-if="dirty">有未保存修改，请先保存。</span></div>
   <h3 style="margin-top:20px">操作记录</h3><div v-for="(h,i) in form.history" :key="i" style="margin-bottom:8px">{{h.created_at}}　{{h.actor_name}}　{{actionNames[h.action]||h.action}}<span v-if="h.comment">：{{h.comment}}</span></div>
  </j-modal>
  <a-modal title="到账确认财务账号" :visible="configVisible" :confirm-loading="saving" @ok="saveConfig" @cancel="configVisible=false"><p>仅该账号可以确认、撤销款到发货订单的到账记录。</p><a-select v-model="financeId" style="width:100%"><a-select-option v-for="u in options.users" :key="u.id">{{u.username}}（{{u.login_name}}）</a-select-option></a-select></a-modal>
  <a-modal title="销售提交发货申请" :visible="requestVisible" :confirm-loading="saving" @ok="requestShipment" @cancel="requestVisible=false"><p>请确认已与仓库线下核实。申请后锁定订单预留，全部装完后统一出库。</p><div class="label">付款条件 *</div><a-select v-model="requestTerms" :disabled="form.payment_terms!=='unconfirmed'" style="width:100%"><a-select-option value="prepay">款到发货</a-select-option><a-select-option value="credit">账期</a-select-option></a-select><p v-if="form.payment_terms==='unconfirmed'">旧订单尚未登记付款条件，请按原合同确认。</p></a-modal>
  <a-modal :title="actionNames[actionForm.action]" :visible="actionVisible" :confirm-loading="saving" @ok="saveAction" @cancel="actionVisible=false">
   <template v-if="actionForm.action==='paid'"><p>须确认整单含税款项 {{form.total_price}} 元已到账。</p><div class="label">实际到账金额（元）</div><a-input-number v-model="actionForm.amount" :min="0" :precision="2" style="width:100%"/><div class="label">到账日期</div><a-input v-model="actionForm.paidDate" type="date"/></template>
   <div class="label">{{['cancel','unpaid'].includes(actionForm.action)?'原因（必填）':'到账说明'}}</div><a-textarea v-model="actionForm.comment" :max-length="2000"/>
  </a-modal>
  <a-modal title="装车照片" :visible="previewVisible" :footer="null" :width="900" @cancel="previewVisible=false"><img :src="previewUrl" alt="装车照片" style="max-width:100%"/></a-modal>
 </a-card>
</template>
<script>
import Vue from 'vue'
import {getAction,postAction,getFileAccessHttpUrl} from '@/api/manage'
import {ACCESS_TOKEN} from '@/store/mutation-types'
export default {
 name:'ShipmentList',
 data(){return {options:{users:[]},keyword:'',rows:[],loading:false,saving:false,pagination:{current:1,pageSize:10,total:0},columns:[{title:'销售订单',dataIndex:'number'},{title:'客户',dataIndex:'customer_name'},{title:'付款条件',dataIndex:'payment_terms',scopedSlots:{customRender:'terms'}},{title:'发货状态',dataIndex:'workflow_status',scopedSlots:{customRender:'state'}},{title:'出库时间',dataIndex:'shipped_at'},{title:'操作',key:'action',scopedSlots:{customRender:'action'}}],visible:false,form:{lines:[],allocations:[],history:[]},trucks:[],savedTrucks:'[]',configVisible:false,financeId:undefined,requestVisible:false,requestTerms:undefined,actionVisible:false,actionForm:{},previewVisible:false,previewUrl:'',uploadAction:window._CONFIG.domianURL+'/systemConfig/upload',uploadHeaders:{'X-Access-Token':Vue.ls.get(ACCESS_TOKEN)},termsNames:{prepay:'款到发货',credit:'账期',unconfirmed:'待销售确认'},states:{requested:'已申请，待统一出库',cancelled:'申请已撤销',shipped:'整单已出库'},actionNames:{request:'销售申请发货',cancel:'撤销发货申请',trucks:'保存车辆装运',paid:'财务确认整单款项到账',unpaid:'撤销到账确认',ship:'仓库统一确认出库'}}},
 computed:{doc(){return this.form.shipment||{}},canPack(){return this.options.isWarehouse&&this.doc.workflow_status==='requested'},dirty(){return JSON.stringify(this.truckPayload())!==this.savedTrucks},uploading(){return this.trucks.some(t=>t.files.some(f=>f.status==='uploading'))}},
 watch:{'$route.query.orderId'(id){if(id)this.open(id)}},
 created(){this.initialize()},
 methods:{
  async api(path,body){const r=body===undefined?await getAction('/factoryShipping'+path):await postAction('/factoryShipping'+path,body);if(r.code!==200)throw new Error(r.message||(r.data&&r.data.message)||'操作失败');return r.data},
  error(e){this.$message.error(e.message||'请求失败')},
  async initialize(){try{this.options=await this.api('/options');await this.load();if(this.$route.query.orderId)await this.open(this.$route.query.orderId)}catch(e){this.error(e)}},
  async load(reset=true){if(reset)this.pagination.current=1;this.loading=true;try{const r=await this.api('/list?keyword='+encodeURIComponent(this.keyword)+'&page='+this.pagination.current);this.rows=r.rows;this.pagination.total=r.total}catch(e){this.error(e)}finally{this.loading=false}},
  onPage(p){this.pagination.current=p.current;this.load(false)},
  lineName(i){const p=this.form.lines[i];return p?[p.name,p.brand,p.standard,p.model].filter(Boolean).join(' / '):''},
  allocationKey(a){return [a.lineNo,a.depotId,a.batchNumber].join('|')},
  allocationLabel(a){return this.lineName(a.lineNo)+' / '+a.depotName+' / '+a.batchNumber},
  async open(id){try{this.form=await this.api('/'+id);this.trucks=(this.doc.trucks||[]).map(t=>({...t,lines:t.lines.map(l=>({...l,allocationKey:this.allocationKey(l)})),files:t.photos.map((p,i)=>({uid:String(i),name:p.split('/').pop(),status:'done',url:getFileAccessHttpUrl('systemConfig/static/'+p),response:{code:200,data:p}}))}));this.savedTrucks=JSON.stringify(this.truckPayload());this.visible=true}catch(e){this.error(e)}},
  addTruck(){this.trucks.push({plate:'',driver:'',phone:'',photos:[],files:[],lines:[{allocationKey:undefined,quantity:null}]})},
  chooseAllocation(line){const a=this.form.allocations.find(a=>this.allocationKey(a)===line.allocationKey);if(a){this.$set(line,'lineNo',a.lineNo);this.$set(line,'depotId',a.depotId);this.$set(line,'batchNumber',a.batchNumber)}},
  truckPayload(){return this.trucks.map(t=>({plate:t.plate,driver:t.driver,phone:t.phone,photos:t.photos,lines:t.lines.map(l=>({lineNo:l.lineNo,depotId:l.depotId,batchNumber:l.batchNumber,quantity:l.quantity}))}))},
  beforeUpload(file){const valid=/\.(png|jpe?g|gif)$/i.test(file.name)&&file.size<=10485760;if(!valid)this.$message.error('请上传10MB以内的PNG、JPG或GIF装车照片');return valid},
  photoChange(truck,info){truck.files=info.fileList.filter(f=>f.status!=='error'&&(!f.response||f.response.code===200));if(info.file.status==='done'&&info.file.response.code!==200)this.$message.error('照片上传失败');if(info.file.status==='error')this.$message.error('照片上传失败');truck.photos=truck.files.filter(f=>f.status==='done'&&f.response).map(f=>f.response.data)},
  preview(file){this.previewUrl=file.url||getFileAccessHttpUrl('systemConfig/static/'+file.response.data);this.previewVisible=true},
  async saveConfig(){this.saving=true;try{await this.api('/config',{financeId:this.financeId});this.options=await this.api('/options');this.configVisible=false;this.$message.success('财务账号已配置')}catch(e){this.error(e)}finally{this.saving=false}},
  async requestShipment(){this.saving=true;try{await this.api('/'+this.form.head_id+'/action',{action:'request',orderVersion:this.form.orderVersion,paymentTerms:this.requestTerms});this.requestVisible=false;await this.open(this.form.head_id);await this.load(false);this.$message.success('已申请发货，订单预留已锁定')}catch(e){this.error(e)}finally{this.saving=false}},
  async saveTrucks(){this.saving=true;try{await this.api('/'+this.form.head_id+'/action',{action:'trucks',version:this.doc.version,trucks:this.truckPayload()});await this.open(this.form.head_id);this.$message.success('装车信息已保存，全部装完后统一确认出库')}catch(e){this.error(e)}finally{this.saving=false}},
  openAction(action){const date=new Date();this.actionForm={action,comment:'',amount:this.form.total_price,paidDate:new Date(date.getTime()-date.getTimezoneOffset()*60000).toISOString().slice(0,10)};this.actionVisible=true},
  async saveAction(){this.saving=true;try{await this.api('/'+this.form.head_id+'/action',{...this.actionForm,version:this.doc.version});this.actionVisible=false;await this.open(this.form.head_id);await this.load(false);this.$message.success('处理已保存')}catch(e){this.error(e)}finally{this.saving=false}},
  confirmShip(){this.$confirm({title:'所有车辆已装完，确认整单统一出库？',content:'系统将严格核对订单、批次、装运数量、照片及付款条件，并同时扣库存、核销预留。确认后不能直接修改或反审核。',onOk:async()=>{this.saving=true;try{await this.api('/'+this.form.head_id+'/action',{action:'ship',version:this.doc.version});await this.open(this.form.head_id);await this.load(false);this.$message.success('所有车辆已统一确认出库')}catch(e){this.error(e);throw e}finally{this.saving=false}}})}
 }
}
</script>
<style scoped>
.actions{display:flex;gap:8px;margin:12px 0;flex-wrap:wrap}.label{margin:10px 0 6px}.scroll{overflow-x:auto}.shipping-table{width:100%;border-collapse:collapse;margin:12px 0}.shipping-table td,.shipping-table th{border:1px solid #ddd;padding:8px;text-align:left}
</style>
