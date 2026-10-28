<template>
 <a-card :bordered="false">
  <a-form layout="inline" class="table-page-search-wrapper" @keyup.enter.native="load()">
   <div class="query-row">
    <div class="query-field"><label>单据编号：</label><a-input v-model="query.number" placeholder="请输入单据编号" /></div>
    <div class="query-field"><label>商品信息：</label><a-input v-model="query.material" placeholder="名称、牌号商标、规格、型号、条码等" /></div>
    <div class="query-field"><label>单据日期：</label><a-range-picker v-model="query.dates" style="width:100%" :placeholder="['开始时间','结束时间']" /></div>
    <div class="query-buttons"><a-button type="primary" @click="load()">查询</a-button><a-button @click="resetQuery">重置</a-button><a @click="expanded=!expanded">{{expanded?'收起':'展开'}}<a-icon :type="expanded?'up':'down'" /></a></div>
   </div>
   <div v-if="expanded" class="expanded-query">
    <div class="query-field"><label>客户：</label><a-select v-model="query.customerId" show-search allow-clear option-filter-prop="children" placeholder="请选择客户"><a-select-option v-for="c in options.customers" :key="c.id" :value="c.id">{{c.supplier}}</a-select-option></a-select></div>
    <div class="query-field"><label>操作员：</label><a-select v-model="query.creatorId" show-search allow-clear option-filter-prop="children" placeholder="请选择操作员"><a-select-option v-for="u in options.users" :key="u.id" :value="u.id">{{u.username}}</a-select-option></a-select></div>
    <div class="query-field"><label>单据状态：</label><a-select v-model="state" allow-clear placeholder="请选择状态"><a-select-option v-for="(label,k) in labels" :key="k" :value="k">{{label}}</a-select-option></a-select></div>
    <div class="query-field"><label>单据备注：</label><a-input v-model="query.remark" placeholder="请输入单据备注" /></div>
   </div>
  </a-form>
  <div class="table-operator">
   <a-button type="primary" icon="plus" @click="create">新增</a-button>
   <a-button icon="delete" :disabled="!canDelete" @click="removeOrders(selectedOrders)">删除</a-button>
   <a-button icon="file-add" :disabled="!selectedOrder || selectedOrder.workflow_status!=='approved' || !isOwner(selectedOrder)" @click="goProduction(selectedOrder)">生产任务联系表</a-button>
   <a-button icon="dashboard" :disabled="!selectedOrder" @click="$router.push({path:'/factory/order_progress',query:{orderId:String(selectedOrder.head_id)}})">全过程进度</a-button>
   <a-button icon="edit" @click="$router.push('/factory/order_change')">订单变更 / 取消</a-button>
   <a-button icon="car" :disabled="!selectedOrder" @click="goShipping(selectedOrder)">发货申请 / 进度</a-button>
   <a-button icon="upload" :disabled="!canSubmit" @click="act(selectedOrder,'submit')">提交审核</a-button>
   <a-button icon="check" :disabled="!canReview" @click="act(selectedOrder,'approve')">审核</a-button>
   <a-button icon="rollback" :disabled="!canReview" @click="returnOrder(selectedOrder)">退回</a-button>
   <a-tooltip title="仅固定审核人可反审核已通过订单；有后续业务时需先处理关联单据"><span><a-button icon="stop" :disabled="!canUnapprove" @click="act(selectedOrder,'unapprove')">反审核</a-button></span></a-tooltip>
   <a-button icon="rollback" :disabled="!canWithdraw" @click="act(selectedOrder,'withdraw')">撤回修改</a-button>
   <a-popover trigger="click" placement="right"><template slot="content"><a-checkbox-group v-model="visibleColumnKeys" @change="saveColumns"><a-row style="width:500px"><a-col v-for="col in columnChoices" :key="col.dataIndex" :span="8"><a-checkbox :value="col.dataIndex">{{col.title}}</a-checkbox></a-col></a-row><a-row style="padding-top:10px">恢复默认列配置：<a-button type="link" size="small" @click="resetColumns">恢复默认</a-button></a-row></a-checkbox-group></template><a-button icon="setting">列设置</a-button></a-popover>
   <a-button v-if="options.canConfigure" @click="showSettings=true">固定审核人</a-button>
   <span class="reviewer-label">审核人：{{reviewerName}}</span>
  </div>
  <a-alert v-if="!options.reviewerId" type="warning" show-icon message="尚未配置固定审核人，请由租户负责人配置后提交订单。" style="margin-bottom:12px" />
  <a-table :columns="displayColumns" :row-selection="{type: 'radio',selectedRowKeys:selectedRowKeys,onChange:onSelect}" size="middle" bordered :data-source="orders" row-key="head_id" :loading="loading" :pagination="pagination" @change="onPage" :scroll="{x:1100}">
   <template slot="status" slot-scope="s"><a-tag :color="colors[s]">{{labels[s]}}</a-tag></template>
   <template slot="orderDate" slot-scope="v">{{date(v)}}</template>
   <template slot="money" slot-scope="v">{{money(v)}}</template>
   <template slot="actions" slot-scope="_,r">
    <a @click="open(r,true)">查看</a>
    <template v-if="deletable(r)"><a-divider type="vertical"/><a @click="open(r,false)">编辑</a></template><a-divider type="vertical"/><a :disabled="!deletable(r)" @click="deletable(r) && removeOrders([r])">删除</a>
   </template>
  </a-table>
  <j-modal :visible="visible" :title="readOnly?'查看销售订单':(form.id?'编辑销售订单':'新增销售订单')" fullscreen switchFullscreen :keyboard="false" :footer="null" @cancel="visible=false" :mask-closable="false">
   <a-spin :spinning="saving">
    <a-row :gutter="20">
     <a-col :span="12"><div class="field-label">客户 *</div><a-select v-model="form.customerId" :disabled="readOnly" show-search option-filter-prop="children" placeholder="选择客户" style="width:100%"><a-select-option v-for="c in options.customers" :key="c.id" :value="c.id">{{c.supplier}}</a-select-option></a-select></a-col>
     <a-col :span="12"><div class="field-label">统一交货日期 *</div><a-input v-model="form.deliveryDate" type="date" :disabled="readOnly" /></a-col>
    </a-row>
    <div class="field-label">付款条件 *</div><a-select v-model="form.paymentTerms" :disabled="readOnly" placeholder="选择款到发货或账期" style="width:260px"><a-select-option value="prepay">款到发货</a-select-option><a-select-option value="credit">账期</a-select-option><a-select-option v-if="readOnly&&form.paymentTerms==='unconfirmed'" value="unconfirmed">待销售确认</a-select-option></a-select>
    <div class="field-label">客户要求</div><a-textarea v-model="form.requirements" :disabled="readOnly" :max-length="4000" :rows="2" placeholder="包装、检测指标、指定批次等要求" />
    <div class="section-title">产品明细 <small>数量单位：吨　单价：元/吨　金额均含税</small></div>
    <div style="overflow-x:auto">
    <table class="lines"><thead><tr><th>产品名称 *</th><th>牌号商标 *</th><th>规格型号 *</th><th>数量（吨）*</th><th>含税单价 *</th><th>含税金额</th><th v-if="!readOnly">操作</th></tr></thead>
     <tbody><tr v-for="(line,i) in form.lines" :key="i">
      <td><span v-if="readOnly">{{line.name}}</span><a-select v-else v-model="line.name" :disabled="readOnly" style="width:185px" show-search @change="resetProduct(line)"><a-select-option v-for="n in productNames" :key="n" :value="n">{{n}}</a-select-option></a-select></td>
      <td><span v-if="readOnly">{{line.brand}}</span><a-select v-else v-model="line.brand" :disabled="readOnly || !line.name" style="width:145px" @change="resetVariant(line)"><a-select-option v-for="brand in brands(line)" :key="brand" :value="brand">{{brand || '未维护牌号'}}</a-select-option></a-select></td>
      <td><span v-if="readOnly">{{spec(line)}}</span><a-select v-else v-model="line.barCode" :disabled="readOnly || line.brand===undefined" style="width:160px" @change="chooseVariant(line)"><a-select-option v-for="p in variants(line)" :key="p.barCode" :value="p.barCode">{{spec(p)}}</a-select-option></a-select></td>
      <td><a-input-number v-model="line.quantity" :min="0" :precision="6" :disabled="readOnly" style="width:115px" /></td>
      <td><a-input-number v-model="line.price" :min="0" :precision="6" :disabled="readOnly" style="width:115px" /></td>
      <td>{{money(amount(line))}}</td><td v-if="!readOnly"><a @click="form.lines.splice(i,1)">移除</a></td>
     </tr></tbody>
    </table></div>
    <a-button v-if="!readOnly" icon="plus" style="margin-top:12px" @click="addLine">添加产品</a-button>
    <div class="total">订单含税总金额：¥ {{money(total)}}</div>
    <template v-if="readOnly && stockSummary"><h3 style="margin-top:20px">仓库核查结果</h3><p>需求 {{stockSummary.demand}} 吨　已预留 {{stockSummary.reserved}} 吨　缺口 {{stockSummary.missing}} 吨　<a @click="refreshStock">刷新核查结果</a></p><a-alert v-if="stockChanged" type="warning" show-icon message="预留或缺口已变化，请销售与车间主任核对；系统不会自动修改生产任务。"/><div v-for="l in stockSummary.lines" :key="l.lineNo">{{l.name}} / {{l.brand}} / {{l.standard}} {{l.model}}：需求 {{l.quantity}}，已预留 {{l.reserved}}，缺口 {{l.missing}} 吨</div></template>
    <template v-if="readOnly && productionInfo.length"><h3 style="margin-top:20px">生产任务进度</h3><p v-for="p in productionInfo" :key="p.number">{{p.number}}　{{productionStates[p.workflow_status]}}　<span v-for="w in p.workshops" :key="w.workshop_no">{{workshopNames[w.workshop_no-1]}}：{{workshopStates[w.workflow_status]}}　</span><a @click="goProduction({head_id:form.id},true)">查看联系表与车间安排</a></p></template>
    <p v-if="readOnly&&shipmentInfo.length">发货进度：{{shipmentInfo[0].workflow_status==='shipped'?'整单已出库':shipmentInfo[0].workflow_status==='requested'?'已申请，待统一出库':'申请已撤销'}}　{{shipmentInfo[0].shipped_at||''}}　<a @click="goShipping({head_id:form.id})">查看装车和发货记录</a></p>
    <div class="field-label">备注</div><a-textarea v-model="form.remark" :disabled="readOnly" :max-length="500" :rows="2" />
    <template v-if="history.length"><h3 style="margin-top:20px">操作记录</h3><a-timeline><a-timeline-item v-for="(h,i) in history" :key="i">{{date(h.created_at)}}　{{h.actor_name}}　{{actionLabels[h.action] || h.action}}<span v-if="h.comment">：{{h.comment}}</span></a-timeline-item></a-timeline></template>
    <div class="footer"><a-button @click="visible=false">关闭</a-button><a-button v-if="!readOnly" type="primary" :loading="saving" @click="save">保存草稿</a-button></div>
   </a-spin>
  </j-modal>
  <a-modal title="退回订单" :visible="!!returning" :confirm-loading="saving" @cancel="returning=null" @ok="confirmReturn"><a-textarea v-model="returnReason" :rows="4" :max-length="2000" placeholder="请填写退回原因，销售修改后再次提交" /></a-modal>
  <a-modal title="固定审核人" :visible="showSettings" @cancel="showSettings=false" @ok="configure" :confirm-loading="saving">
   <p>固定审核人可审核本人及销售员提交的订单。订单须先提交审核；存在待审核订单时不能更换审核人。</p>
   <a-select v-model="reviewerChoice" style="width:100%" placeholder="选择销售部高层账号"><a-select-option v-for="u in options.users" :key="u.id" :value="u.id">{{u.username}}（{{u.login_name}}）</a-select-option></a-select>
  </a-modal>
 </a-card>
</template>
<script>
import {getAction,postAction} from '@/api/manage'
import Vue from 'vue'
const defaultColumns=['actions','customer_name','number','materials_list','order_date','creator_name','material_count','total_price','tax_total','change_amount','last_deposit','workflow_status','delivery_date']
export default {
 name:'SalesOrderList',
 data(){return {options:{customers:[],products:[],users:[]},orders:[],pagination:{current:1,pageSize:10,total:0,showSizeChanger:true},query:{number:'',material:'',dates:[],customerId:undefined,creatorId:undefined,remark:''},state:undefined,expanded:false,selectedRowKeys:[],visibleColumnKeys:defaultColumns.slice(),loading:false,saving:false,visible:false,readOnly:false,form:{lines:[]},history:[],stockSummary:null,stockChanged:false,productionInfo:[],shipmentInfo:[],workshopNames:['一车间','二车间','三车间'],workshopStates:{pending:'待主任接单',accepted:'主任已接单',scheduled:'已排班'},productionStates:{draft:'草稿',pending:'待领导审核',returned:'已退回',approved:'待生产统筹分配',distributed:'各车间处理中',scheduled:'各车间已排班',cancelled:'已撤销'},showSettings:false,reviewerChoice:undefined,returning:null,returnReason:'',
 labels:{cancelled:'已取消',draft:'草稿',pending:'待审核',approved:'审核通过',returned:'已退回'},colors:{draft:'default',pending:'orange',approved:'green',returned:'red'},actionLabels:{change_submit:'申请订单变更',change_approve:'领导批准变更',change_reject:'领导退回变更',change_withdraw:'撤回变更申请',change_apply:'统筹落实变更或停产',production_create:'创建生产联系表',production_edit:'修改生产联系表',production_submit:'生产联系表提交审核',production_approve:'生产联系表审核通过',production_unapprove:'生产联系表反审核',production_return:'生产联系表退回',production_withdraw:'撤回生产联系表',production_cancel:'撤销生产联系表',production_accept:'车间主任接单',production_schedule:'车间安排与排班',create:'创建',edit:'修改',submit:'提交审核',approve:'审核通过',return:'退回修改',withdraw:'撤回修改',unapprove:'反审核',delete:'删除',stock_reserve:'仓库确认或调整预留',stock_release:'释放库存预留',stock_shipped:'整单出库核销预留',shipping_request:'销售申请发货',shipping_cancel:'撤销发货申请',shipping_trucks:'保存车辆装运',shipping_paid:'财务确认到账',shipping_unpaid:'撤销到账确认',shipping_ship:'仓库统一确认整单出库'},
 columns:[
 {title:'操作',dataIndex:'actions',scopedSlots:{customRender:'actions'},width:180},
 {title:'客户',dataIndex:'customer_name',width:120,ellipsis:true},{title:'单据编号',dataIndex:'number',width:230},
 {title:'商品信息',dataIndex:'materials_list',width:240,ellipsis:true},{title:'单据日期',dataIndex:'order_date',scopedSlots:{customRender:'orderDate'},width:170},
 {title:'操作员',dataIndex:'creator_name',width:100},{title:'数量（吨）',dataIndex:'material_count',width:110},
 {title:'金额合计',dataIndex:'total_price',scopedSlots:{customRender:'money'},width:120},
 {title:'含税合计',dataIndex:'tax_total',width:120,customRender:(_,r)=>Number(r.total_price||0).toFixed(2)},
 {title:'优惠率',dataIndex:'discount',width:90},{title:'收款优惠',dataIndex:'discount_money',width:100},
 {title:'优惠后金额',dataIndex:'discount_last_money',width:120},{title:'结算账户',dataIndex:'account_name',width:120},
 {title:'收取订金',dataIndex:'change_amount',width:100},{title:'剩余订金',dataIndex:'last_deposit',width:100},
 {title:'备注',dataIndex:'remark',width:200,ellipsis:true},{title:'状态',dataIndex:'workflow_status',scopedSlots:{customRender:'status'},width:110},
 {title:'统一交货日期',dataIndex:'delivery_date',width:130}] }},
 computed:{
  columnChoices(){return this.columns},
  displayColumns(){return this.columns.filter(c=>!c.dataIndex || this.visibleColumnKeys.includes(c.dataIndex))},
  selectedOrders(){return this.orders.filter(r=>this.selectedRowKeys.includes(r.head_id))},
  selectedOrder(){return this.selectedOrders.length===1?this.selectedOrders[0]:null},
  canDelete(){return this.selectedOrders.length>0 && this.selectedOrders.every(this.deletable)},
  canUnapprove(){return this.isReviewer && !!this.selectedOrder && this.selectedOrder.workflow_status==='approved'},
  canSubmit(){const r=this.selectedOrder;return !!r && this.isOwner(r) && ['draft','returned'].includes(r.workflow_status)},
  canReview(){const r=this.selectedOrder;return !!r && this.isReviewer && r.workflow_status==='pending'},
  canWithdraw(){const r=this.selectedOrder;return !!r && this.isOwner(r) && ['pending','approved'].includes(r.workflow_status)},
  productNames(){return [...new Set(this.options.products.map(p=>p.name))]},
  isReviewer(){return this.options.currentUserId===this.options.reviewerId},
  reviewerName(){const u=this.options.users.find(x=>x.id===this.options.reviewerId);return u?u.username+'（'+u.login_name+'）':'未配置'},
  total(){return this.form.lines.reduce((v,l)=>v+this.amount(l),0)}
 },
 created(){const saved=Vue.ls.get('factorySalesColumns');if(Array.isArray(saved))this.visibleColumnKeys=saved.filter(key=>this.columns.some(c=>c.dataIndex===key));this.initialize()},
 watch:{'$route.fullPath'(){this.fromProgress()}},
 methods:{
 async fromProgress(){if(this.$route.path!=='/bill/sale_order')return;const id=this.$route.query.orderId;if(id)await this.open({head_id:id},true)},

  goShipping(row){this.visible=false;this.$router.push({path:'/factory/shipping',query:{orderId:String(row.head_id)}})},
  goProduction(row,viewOnly=false){this.visible=false;this.$router.push({path:'/factory/production_task',query:viewOnly?{viewId:String(row.head_id)}:{orderId:String(row.head_id)}})},
  saveColumns(keys){Vue.ls.set('factorySalesColumns',keys)},
  resetColumns(){Vue.ls.remove('factorySalesColumns');this.visibleColumnKeys=defaultColumns.slice()},
  deletable(r){return this.isOwner(r) && ['draft','returned'].includes(r.workflow_status)},
  removeOrders(rows){this.$confirm({title:'确认删除选中的'+rows.length+'张订单？',content:'只能删除本人创建的草稿或已退回订单，操作记录会保留。',onOk:async()=>{try{await this.request('/delete',{orders:rows.map(r=>({id:r.head_id,version:r.version}))});this.$message.success('删除成功');await this.load()}catch(e){this.error(e)}}})},
  async request(p,data){const r=data===undefined?await getAction('/factorySales'+p):await postAction('/factorySales'+p,data);if(r.code!==200)throw new Error(r.message || (r.data&&r.data.message) || '操作失败');return r.data},
  error(e){this.$message.error(e.message || '请求失败，请稍后重试')},
  async initialize(){try{this.options=await this.request('/options');this.reviewerChoice=this.options.reviewerId;await this.load();await this.fromProgress()}catch(e){this.error(e)}},
  async load(reset=true){
   if(reset)this.pagination.current=1;
   this.loading=true;this.selectedRowKeys=[];
   const params={number:this.query.number,material:this.query.material,customerId:this.query.customerId,creatorId:this.query.creatorId,remark:this.query.remark,state:this.state,page:this.pagination.current,size:this.pagination.pageSize};
   if(this.query.dates.length===2){params.beginDate=this.query.dates[0].format('YYYY-MM-DD');params.endDate=this.query.dates[1].format('YYYY-MM-DD')}
   const query=Object.keys(params).filter(k=>params[k]!==undefined && params[k]!==null && params[k]!=='').map(k=>encodeURIComponent(k)+'='+encodeURIComponent(params[k])).join('&');
   try{const r=await this.request('/list?'+query);this.orders=r.rows;this.pagination.total=r.total}catch(e){this.error(e)}finally{this.loading=false}
  },
  resetQuery(){this.query={number:'',material:'',dates:[],customerId:undefined,creatorId:undefined,remark:''};this.state=undefined;this.load()},
  onSelect(keys){this.selectedRowKeys=keys},
  onPage(p){this.pagination.current=p.current;this.pagination.pageSize=p.pageSize;this.load(false)},
  money(v){return Number(v||0).toLocaleString('zh-CN',{minimumFractionDigits:2,maximumFractionDigits:2})},
  amount(l){return Math.round((Number(l.quantity)||0)*(Number(l.price)||0)*100)/100},
  isOwner(r){return r.created_by===this.options.currentUserId},
  date(v){return v?new Date(v).toLocaleString('zh-CN'):''},
  brands(l){return [...new Set(this.options.products.filter(p=>p.name===l.name).map(p=>p.brand))]},
  variants(l){return this.options.products.filter(p=>p.name===l.name && p.brand===l.brand)},
  spec(p){return [p.standard,p.model].filter(Boolean).join(' / ') || '未维护规格'},
  resetProduct(l){this.$set(l,'brand',undefined);this.$set(l,'barCode',undefined)},
  resetVariant(l){this.$set(l,'barCode',undefined)},
  chooseVariant(l){const p=this.options.products.find(p=>p.barCode===l.barCode);if(p){l.standard=p.standard;l.model=p.model}},
  addLine(){this.form.lines.push({name:undefined,brand:undefined,barCode:undefined,quantity:null,price:null})},
  create(){this.form={customerId:undefined,deliveryDate:'',paymentTerms:undefined,requirements:'',remark:'',lines:[]};this.addLine();this.history=[];this.stockSummary=null;this.stockChanged=false;this.readOnly=false;this.visible=true},
  async open(r,readOnly){try{const d=await this.request('/'+r.head_id);this.form={id:d.head_id,version:d.version,customerId:d.organ_id,deliveryDate:d.delivery_date,paymentTerms:d.payment_terms,requirements:d.requirements,remark:d.remark||'',lines:d.lines};this.history=d.history;this.shipmentInfo=d.shipment||[];this.productionInfo=d.production || [];this.stockSummary=d.stock;this.stockChanged=false;this.readOnly=readOnly;this.visible=true}catch(e){this.error(e)}},
  async refreshStock(){try{const d=await this.request('/'+this.form.id);this.stockChanged=this.stockSummary && (Number(this.stockSummary.reserved)!==Number(d.stock.reserved) || Number(this.stockSummary.missing)!==Number(d.stock.missing));this.stockSummary=d.stock;this.productionInfo=d.production || [];this.history=d.history;this.form.version=d.version}catch(e){this.error(e)}},
  async save(){if(!['prepay','credit'].includes(this.form.paymentTerms) || !this.form.customerId || !this.form.deliveryDate || !this.form.lines.length || this.form.lines.some(l=>!l.barCode || !(l.quantity>0) || l.price===null || l.price===undefined || l.price<0)){this.$message.warning('请选择付款条件、客户、交期及完整产品明细，数量须大于0，含税单价不可为空或负数');return}this.saving=true;try{await this.request('/save',this.form);this.visible=false;this.$message.success('订单已保存');await this.load()}catch(e){this.error(e)}finally{this.saving=false}},
  act(r,action){const names={submit:'提交审核',approve:'审核通过',withdraw:'撤回并重新编辑',unapprove:'反审核'};this.$confirm({title:'确认'+names[action]+'？',content:['withdraw','unapprove'].includes(action)?'操作后回到草稿并释放预留，需要重新提交审核；已有后续单据时需先处理关联单据。':r.number,onOk:async()=>{try{await this.request('/'+r.head_id+'/action',{action,version:r.version});this.$message.success('操作成功');await this.load()}catch(e){this.error(e)}}})},
  returnOrder(r){this.returning=r;this.returnReason=''},
  async confirmReturn(){if(!this.returnReason.trim()){this.$message.warning('请填写退回原因');return}this.saving=true;try{await this.request('/'+this.returning.head_id+'/action',{action:'return',version:this.returning.version,comment:this.returnReason});this.returning=null;await this.load()}catch(e){this.error(e)}finally{this.saving=false}},
  async configure(){if(!this.reviewerChoice){this.$message.warning('请选择审核人');return}this.saving=true;try{await this.request('/reviewer',{reviewerId:this.reviewerChoice});this.showSettings=false;await this.initialize()}catch(e){this.error(e)}finally{this.saving=false}}
 }
}
</script>
<style scoped>
.query-row{display:grid;grid-template-columns:repeat(3,minmax(180px,1fr)) auto;gap:16px;align-items:center}.query-field{display:flex;align-items:center;min-width:0}.query-field label{flex-shrink:0;white-space:nowrap;width:80px}.query-field .ant-input,.query-field .ant-select{flex:1;min-width:0}.query-buttons,.table-operator{display:flex;align-items:center;gap:8px;flex-wrap:wrap}.expanded-query{display:grid;grid-template-columns:repeat(3,minmax(180px,1fr));gap:16px;margin-top:16px}.table-operator{margin:14px 0}.reviewer-label{color:#888;margin-left:auto;font-size:12px}@media(max-width:1100px){.query-row,.expanded-query{grid-template-columns:repeat(2,minmax(180px,1fr))}}@media(max-width:650px){.query-row,.expanded-query{grid-template-columns:1fr}}.field-label{margin:12px 0 6px;font-weight:500}.section-title{margin:22px 0 12px;font-size:16px;font-weight:600}.section-title small{font-size:12px;color:#666;font-weight:400}.lines{width:100%;border-collapse:collapse;min-width:1000px}.lines th,.lines td{border:1px solid #e8e8e8;padding:9px}.lines th{background:#fafafa;text-align:left}.total{text-align:right;font-size:18px;font-weight:600;margin:16px 0}.footer{display:flex;justify-content:flex-end;gap:12px;margin-top:20px}
</style>
