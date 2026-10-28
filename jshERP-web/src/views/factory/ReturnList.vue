<template>
 <a-card :bordered="false">
  <h2>客户退货申请与收货</h2>
  <p>原订单销售申请 → 任意一位配置领导批准 → 仓库核对实物收货 → 直接恢复可销售库存。数量单位：吨；退款、补发另行处理。</p>
  <a-button type="primary" @click="sourceVisible=true;sourcePage=1;loadSources()">选择已发货订单申请退货</a-button>
  <a-button v-if="options.canConfigure" style="margin-left:8px" @click="leaderIds=options.leaderIds.slice();configVisible=true">退货审批领导配置</a-button>
  <a-alert v-if="!options.leaderIds.length" message="请负责人配置退货审批领导，多位领导中任意一位批准即可。" type="info" show-icon style="margin:12px 0"/>
  <a-form layout="inline" style="margin:16px 0"><a-form-item label="原订单 / 客户"><a-input v-model="keyword" @pressEnter="load()"/></a-form-item><a-button @click="load()">查询</a-button><a-button @click="keyword='';load()" style="margin-left:8px">重置</a-button></a-form>
  <a-table :columns="columns" :data-source="rows" row-key="id" :pagination="pagination" :loading="loading" @change="onPage">
   <template slot="id" slot-scope="v">TH{{v}}</template><template slot="state" slot-scope="v">{{states[v]}}</template><a slot="action" slot-scope="_,r" @click="open(r.id)">查看 / 审批 / 收货</a>
  </a-table>
  <j-modal title="选择本人已发货订单" :visible="sourceVisible" :width="1000" :footer="null" @cancel="sourceVisible=false">
   <a-input-search v-model="sourceKeyword" placeholder="订单号或客户" @search="sourcePage=1;loadSources()"/>
   <a-table :columns="sourceColumns" :data-source="sources" row-key="head_id" :pagination="{current:sourcePage,pageSize:10,total:sourceTotal}" @change="sourcePage=$event.current;loadSources()"><a slot="action" slot-scope="_,r" @click="newReturn(r.head_id)">申请退货</a></a-table>
  </j-modal>
  <j-modal title="申请客户退货" :visible="createVisible" :width="1100" :confirm-loading="saving" @ok="createReturn" @cancel="createVisible=false">
   <p>原订单：{{source.number}}　客户：{{source.customer_name}}</p><p>可退数量已扣除待审批、待收货及已收货申请。只填写本次需要退回的明细，其余留空。</p>
   <div class="scroll"><table class="return-table"><thead><tr><th>产品 / 条码</th><th>原仓库 / 批号</th><th>原发货量</th><th>已申请量</th><th>剩余可退</th><th>本次退货</th></tr></thead><tbody><tr v-for="l in source.lines" :key="l.sourceItemId"><td>{{l.name}} / {{l.barCode}}<br>{{l.standard}} {{l.model}}</td><td>{{l.depotName}} / {{l.batchNumber}}</td><td>{{l.shippedQuantity}}</td><td>{{l.claimedQuantity}}</td><td>{{l.availableQuantity}}</td><td><a-input-number v-model="l.quantity" :min="0" :max="Number(l.availableQuantity)" :precision="6" :disabled="Number(l.availableQuantity)<=0"/></td></tr></tbody></table></div>
   <p>退货原因 *</p><a-textarea v-model="reason" :max-length="2000" :rows="3"/>
  </j-modal>
  <j-modal title="退货详情与处理" :visible="visible" :width="1100" :footer="null" @cancel="visible=false">
   <p>退货单：TH{{form.id}}　原订单：{{form.number}}　客户：{{form.customer_name}}　状态：{{states[form.workflow_status]}}</p><p>退货原因：{{form.reason}}</p>
   <p v-if="form.received_at">收货时间：{{form.received_at}}　实际收货仓库：{{form.receivedDepotName}}　库存单：KHTH{{form.id}}。已直接恢复可销售库存。</p>
   <div class="actions">
    <a-button v-if="options.isLeader&&form.workflow_status==='pending'" type="primary" @click="beginAction('approve')">批准退货</a-button>
    <a-button v-if="options.isLeader&&form.workflow_status==='pending'||options.isWarehouse&&form.workflow_status==='approved'" @click="beginAction('reject')">退回并填写原因</a-button>
    <a-button v-if="form.isOwner&&['pending','approved'].includes(form.workflow_status)" @click="beginAction('cancel')">撤销申请</a-button>
    <a-button v-if="options.isWarehouse&&form.workflow_status==='approved'" type="primary" @click="beginAction('receive')">确认实物收货</a-button>
    <a-button @click="open(form.id)">刷新</a-button>
   </div>
   <div class="scroll"><table class="return-table"><thead><tr><th>产品 / 条码</th><th>原发货仓库</th><th>批号</th><th>退货数量（吨）</th></tr></thead><tbody><tr v-for="l in form.lines" :key="l.sourceItemId"><td>{{l.name}} / {{l.barCode}}<br>{{l.standard}} {{l.model}}</td><td>{{l.sourceDepotName}}</td><td>{{l.batchNumber}}</td><td>{{l.quantity}}</td></tr></tbody></table></div>
   <h3>操作记录</h3><p v-for="(h,i) in form.history" :key="i">{{h.created_at}}　{{h.actor_name}}　{{actions[h.action]}}　{{h.comment}}</p>
  </j-modal>
  <j-modal :title="actions[actionForm.action]" :visible="actionVisible" :confirm-loading="saving" @ok="saveAction" @cancel="actionVisible=false">
   <template v-if="actionForm.action==='receive'"><a-alert type="warning" show-icon message="请核对全部退货实物与批准数量一致。确认后直接恢复可销售库存，不再质检或放行；不能直接修改或反审核。数量不符请退回，由销售重新申请。"/><p>实际收货仓库 *</p><a-select v-model="actionForm.depotId" style="width:100%" placeholder="请选择实际收货仓库"><a-select-option v-for="d in options.depots" :key="d.id" :value="d.id">{{d.name}}</a-select-option></a-select></template>
   <p>处理说明（退回、撤销时必填）</p><a-textarea v-model="actionForm.comment" :max-length="2000" :rows="3"/>
  </j-modal>
  <j-modal title="退货审批领导配置" :visible="configVisible" :confirm-loading="saving" @ok="saveConfig" @cancel="configVisible=false"><p>任意一位批准即可，不需要逐人会签。</p><a-select v-model="leaderIds" mode="multiple" style="width:100%" placeholder="请选择实际领导账号"><a-select-option v-for="u in options.users" :key="u.id" :value="u.id">{{u.username}}（{{u.login_name}}）</a-select-option></a-select></j-modal>
 </a-card>
</template>
<script>
import {getAction,postAction} from '@/api/manage'
export default {
 name:'ReturnList',
 data(){return {options:{leaderIds:[],users:[],depots:[]},rows:[],keyword:'',loading:false,saving:false,pagination:{current:1,pageSize:10,total:0},columns:[{title:'退货单',dataIndex:'id',scopedSlots:{customRender:'id'}},{title:'原销售订单',dataIndex:'number'},{title:'客户',dataIndex:'customer_name'},{title:'状态',dataIndex:'workflow_status',scopedSlots:{customRender:'state'}},{title:'申请时间',dataIndex:'created_at'},{title:'收货时间',dataIndex:'received_at'},{title:'操作',key:'action',scopedSlots:{customRender:'action'}}],sourceColumns:[{title:'销售订单',dataIndex:'number'},{title:'客户',dataIndex:'customer_name'},{title:'发货时间',dataIndex:'shipped_at'},{title:'操作',key:'action',scopedSlots:{customRender:'action'}}],sourceVisible:false,sources:[],sourceKeyword:'',sourcePage:1,sourceTotal:0,source:{lines:[]},createVisible:false,reason:'',visible:false,form:{lines:[],history:[]},actionVisible:false,actionForm:{},configVisible:false,leaderIds:[],states:{pending:'待领导审批',approved:'已批准，待仓库收货',rejected:'已退回',cancelled:'已撤销',received:'已收货，恢复可销售'},actions:{submit:'销售提交退货申请',approve:'领导批准退货',reject:'退回退货申请',cancel:'销售撤销申请',receive:'仓库确认收货并恢复可销售库存'}}},
 created(){this.initialize()},watch:{'$route.fullPath'(){this.fromProgress()}},
 methods:{
  async fromProgress(){if(this.$route.path!=='/factory/returns')return;const q=this.$route.query;if(q.returnId)await this.open(q.returnId);else if(q.orderNumber){this.keyword=q.orderNumber;await this.load()}},
  async api(path,body){const r=body===undefined?await getAction('/factoryReturns'+path):await postAction('/factoryReturns'+path,body);if(r.code!==200)throw new Error(r.message||(r.data&&r.data.message)||'操作失败');return r.data},
  error(e){this.$message.error(e.message||'请求失败')},
  async initialize(){try{this.options=await this.api('/options');await this.load();await this.fromProgress()}catch(e){this.error(e)}},
  async load(reset=true){if(reset)this.pagination.current=1;this.loading=true;try{const r=await this.api('/list?keyword='+encodeURIComponent(this.keyword)+'&page='+this.pagination.current);this.rows=r.rows;this.pagination.total=r.total}catch(e){this.error(e)}finally{this.loading=false}},
  onPage(p){this.pagination.current=p.current;this.load(false)},
  async loadSources(){try{const r=await this.api('/sources?keyword='+encodeURIComponent(this.sourceKeyword)+'&page='+this.sourcePage);this.sources=r.rows;this.sourceTotal=r.total}catch(e){this.error(e)}},
  async newReturn(id){try{this.source=await this.api('/source/'+id);this.source.lines=this.source.lines.map(l=>({...l,quantity:null}));this.reason='';this.createVisible=true}catch(e){this.error(e)}},
  async createReturn(){this.saving=true;try{const lines=this.source.lines.filter(l=>Number(l.quantity)>0).map(l=>({sourceItemId:l.sourceItemId,quantity:l.quantity}));if(!lines.length||!this.reason.trim())throw new Error('请填写本次退货数量和原因');const id=await this.api('/create',{sourceHeadId:this.source.head_id,reason:this.reason,lines});this.createVisible=false;this.sourceVisible=false;await this.load();await this.open(id);this.$message.success('退货申请已提交，等待任意一位配置领导批准')}catch(e){this.error(e)}finally{this.saving=false}},
  async open(id){try{this.form=await this.api('/'+id);this.visible=true}catch(e){this.error(e)}},
  beginAction(action){this.actionForm={action,comment:'',depotId:undefined};this.actionVisible=true},
  async saveAction(){this.saving=true;try{await this.api('/'+this.form.id+'/action',{...this.actionForm,version:this.form.version});this.actionVisible=false;await this.open(this.form.id);await this.load(false);this.$message.success('处理已保存')}catch(e){this.error(e)}finally{this.saving=false}},
  async saveConfig(){this.saving=true;try{await this.api('/config',{leaderIds:this.leaderIds});this.options=await this.api('/options');this.configVisible=false;this.$message.success('退货审批领导已配置')}catch(e){this.error(e)}finally{this.saving=false}}
 }
}
</script>
<style scoped>
.actions{display:flex;gap:8px;flex-wrap:wrap;margin:12px 0}.scroll{overflow-x:auto}.return-table{width:100%;border-collapse:collapse;margin:12px 0}.return-table td,.return-table th{border:1px solid #ddd;padding:8px;text-align:left}
</style>
