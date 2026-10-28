<template>
 <a-card :bordered="false">
  <h2>生产中订单变更与取消</h2><p>销售申请 → 任意一位配置领导批准 → 生产统筹落实。待审批期间按原计划生产；批准后等待统筹核对计划，再继续生产或停产。</p>
  <a-button type="primary" @click="sourcesVisible=true;sourcePage=1;loadSources()">选择生产中订单申请</a-button><a-button v-if="options.canConfigure" style="margin-left:8px" @click="leaderIds=options.leaderIds.slice();configVisible=true">变更审批领导配置</a-button>
  <a-alert v-if="!options.leaderIds.length" message="请负责人配置实际变更审批领导，任意一位批准即可。" type="info" show-icon style="margin:12px 0"/>
  <a-form layout="inline" style="margin:16px 0"><a-form-item label="订单 / 客户"><a-input v-model="keyword" @pressEnter="load()"/></a-form-item><a-button @click="load()">查询</a-button><a-button @click="keyword='';load()" style="margin-left:8px">重置</a-button></a-form>
  <a-table :columns="columns" :data-source="rows" row-key="id" :pagination="pagination" :loading="loading" @change="onPage"><template slot="kind" slot-scope="v">{{kinds[v]}}</template><template slot="state" slot-scope="v">{{states[v]}}</template><a slot="action" slot-scope="_,r" @click="open(r.id)">查看 / 审批 / 统筹落实</a></a-table>
  <j-modal title="选择本人已排班的生产订单" :visible="sourcesVisible" :width="1000" :footer="null" @cancel="sourcesVisible=false"><a-input-search v-model="sourceKeyword" placeholder="订单号或客户" @search="sourcePage=1;loadSources()"/><a-table :columns="sourceColumns" :data-source="sources" row-key="head_id" :pagination="{current:sourcePage,pageSize:10,total:sourceTotal}" @change="sourcePage=$event.current;loadSources()"><a slot="action" slot-scope="_,r" @click="newChange(r.head_id)">申请变更 / 取消</a></a-table></j-modal>
  <j-modal title="订单变更 / 取消申请" :visible="createVisible" :width="1100" :confirm-loading="saving" @ok="createChange" @cancel="createVisible=false">
   <p>{{source.number}}　{{source.customer_name}}</p><a-radio-group v-model="draft.kind"><a-radio value="change">调整数量、交期或客户要求</a-radio><a-radio value="cancel">整单取消</a-radio></a-radio-group>
   <template v-if="draft.kind==='change'"><div class="scroll"><table class="change-table"><thead><tr><th>产品 / 条码</th><th>原数量（吨）</th><th>调整后数量（吨）</th></tr></thead><tbody><tr v-for="(l,i) in draft.lines" :key="l.lineNo"><td>{{l.name}} / {{l.barCode}}<br>{{l.standard}} {{l.model}}</td><td>{{source.order.lines[i].quantity}}</td><td><a-input-number v-model="l.quantity" :min="0" :precision="6"/></td></tr></tbody></table></div><p>交货日期</p><a-input type="date" v-model="draft.deliveryDate"/><p>客户要求</p><a-textarea v-model="draft.requirements" :max-length="4000"/></template>
   <a-alert v-else type="warning" show-icon message="整单取消需领导批准、统筹落实停产；已有领料、产出、质检和库存均保留，多余合格成品可供其他订单使用。" style="margin-top:12px"/>
   <p>申请原因 *</p><a-textarea v-model="draft.reason" :rows="3" :max-length="2000"/><p>不能更换产品、规格或单价。已申请发货须先撤销，已确认出库不可变更。落实后释放旧预留，须仓库重新核查。</p>
  </j-modal>
  <j-modal title="订单变更详情" :visible="visible" :width="1200" :footer="null" @cancel="visible=false">
   <p>申请 BG{{form.id}}　{{form.source.number}}　{{form.source.customer_name}}　{{kinds[form.kind]}}　{{states[form.workflow_status]}}</p><p>申请原因：{{form.reason}}</p>
   <div class="actions"><a-button v-if="options.isLeader&&form.workflow_status==='pending'" type="primary" @click="begin('approve')">批准，交统筹落实</a-button><a-button v-if="options.isLeader&&form.workflow_status==='pending'" @click="begin('reject')">退回</a-button><a-button v-if="form.isOwner&&form.workflow_status==='pending'" @click="begin('withdraw')">撤回申请</a-button><a-button v-if="options.isCoordinator&&form.workflow_status==='approved'" type="primary" @click="begin('apply')">统筹落实调整 / 停产</a-button><a-button @click="open(form.id)">刷新最新进度</a-button></div>
   <div class="scroll"><table class="change-table"><thead><tr><th>产品 / 条码</th><th>原数量（吨）</th><th>申请后数量（吨）</th></tr></thead><tbody><tr v-for="(l,i) in form.before.lines" :key="l.lineNo"><td>{{l.name}} / {{l.barCode}}<br>{{l.standard}} {{l.model}}</td><td>{{l.quantity}}</td><td>{{form.kind==='cancel'?'整单取消，历史数量保留':form.after.lines[i].quantity}}</td></tr></tbody></table></div>
   <p>交期：{{form.before.deliveryDate}} → {{form.after.deliveryDate}}</p><p>原客户要求：{{form.before.requirements||'—'}}</p><p>申请后要求：{{form.after.requirements||'—'}}</p>
   <h3>操作记录</h3><div v-for="(h,i) in form.history" :key="i"><p>{{h.created_at}}　{{h.actor_name}}　{{actions[h.action]}}　{{h.comment}}</p><template v-if="h.action==='apply'"><div class="scroll"><table class="change-table"><thead><tr><th>产品行 / 工序 / 车间</th><th>落实前累计计划（吨）</th><th>落实后累计计划（吨）</th></tr></thead><tbody><tr v-for="(p,j) in appliedPlan(h).afterPlan" :key="j"><td>产品{{p.lineNo+1}} / 工序{{p.stageNo}} / 车间{{p.workshopNo}}</td><td>{{appliedPlan(h).beforePlan[j].quantity}}</td><td>{{p.quantity}}</td></tr></tbody></table></div></template></div>
  </j-modal>
  <j-modal :title="actions[actionForm.action]" :visible="actionVisible" :width="actionForm.action==='apply'?1100:600" :confirm-loading="saving" @ok="saveAction" @cancel="actionVisible=false">
   <template v-if="actionForm.action==='apply'"><a-alert type="warning" show-icon message="请按最新实际进度核对。数量为含已生产的累计计划上限，不能低于已记录产出；产品工序车间沿用原安排。落实后释放旧预留，须仓库重新核查。取消时停止新增生产和领补料，但保留历史质检入库及退料。"/><div class="scroll"><table class="change-table"><thead><tr><th>产品 / 工序 / 车间</th><th>原累计计划（吨）</th><th>该组已记录产出（吨）</th><th>调整后累计计划（吨）</th></tr></thead><tbody><tr v-for="(p,i) in actionForm.plan" :key="i"><td>{{form.before.lines[p.lineNo].name}} / {{p.stageNo}} / {{p.workshopNo}}</td><td>{{form.source.plan[i].quantity}}</td><td>{{p.reportedOutput}}</td><td><span v-if="form.kind==='cancel'">停产，保留实际产出</span><a-input-number v-else v-model="p.quantity" :min="0" :precision="6"/></td></tr></tbody></table></div><p>调整量可保留已在制的额外产出，请在说明中注明处置安排。同组多条排班按合计数量校验。</p></template>
   <p>处理说明（退回、撤回、统筹落实时必填）</p><a-textarea v-model="actionForm.comment" :rows="3" :max-length="2000"/>
  </j-modal>
  <j-modal title="变更审批领导配置" :visible="configVisible" :confirm-loading="saving" @ok="saveConfig" @cancel="configVisible=false"><p>任意一位领导批准即可。</p><a-select mode="multiple" v-model="leaderIds" style="width:100%"><a-select-option v-for="u in options.users" :key="u.id" :value="u.id">{{u.username}}（{{u.login_name}}）</a-select-option></a-select></j-modal>
 </a-card>
</template>
<script>
import {getAction,postAction} from '@/api/manage'
export default {
 name:'OrderChangeList',
 data(){return {options:{users:[],leaderIds:[]},rows:[],keyword:'',loading:false,saving:false,pagination:{current:1,pageSize:10,total:0},columns:[{title:'申请ID',dataIndex:'id'},{title:'订单',dataIndex:'number'},{title:'客户',dataIndex:'customer_name'},{title:'类型',dataIndex:'kind',scopedSlots:{customRender:'kind'}},{title:'状态',dataIndex:'workflow_status',scopedSlots:{customRender:'state'}},{title:'申请时间',dataIndex:'created_at'},{title:'操作',key:'action',scopedSlots:{customRender:'action'}}],sourceColumns:[{title:'订单',dataIndex:'number'},{title:'客户',dataIndex:'customer_name'},{title:'操作',key:'action',scopedSlots:{customRender:'action'}}],sourcesVisible:false,sources:[],sourcePage:1,sourceTotal:0,sourceKeyword:'',source:{order:{lines:[]}},draft:{lines:[]},createVisible:false,form:{source:{plan:[]},before:{lines:[]},after:{lines:[]},history:[]},visible:false,actionForm:{},actionVisible:false,leaderIds:[],configVisible:false,kinds:{change:'订单变更',cancel:'整单取消'},states:{pending:'待领导审批，原计划继续',approved:'已批准，待统筹落实',applied:'已落实',rejected:'已退回',withdrawn:'已撤回'},actions:{submit:'销售提交申请',approve:'领导批准',reject:'领导退回',withdraw:'销售撤回申请',apply:'统筹落实调整 / 停产'}}},
 created(){this.initialize()},watch:{'$route.fullPath'(){this.fromProgress()}},
 methods:{
  async fromProgress(){if(this.$route.path!=='/factory/order_change')return;const q=this.$route.query;if(q.changeId)await this.open(q.changeId);else if(q.orderNumber){this.keyword=q.orderNumber;await this.load()}},
  async api(path,body){const r=body===undefined?await getAction('/factoryOrderChanges'+path):await postAction('/factoryOrderChanges'+path,body);if(r.code!==200)throw new Error(r.message||(r.data&&r.data.message)||'操作失败');return r.data},
  error(e){this.$message.error(e.message||'请求失败')},
  async initialize(){try{this.options=await this.api('/options');await this.load();await this.fromProgress()}catch(e){this.error(e)}},
  async load(reset=true){if(reset)this.pagination.current=1;this.loading=true;try{const r=await this.api('/list?keyword='+encodeURIComponent(this.keyword)+'&page='+this.pagination.current);this.rows=r.rows;this.pagination.total=r.total}catch(e){this.error(e)}finally{this.loading=false}},
  onPage(p){this.pagination.current=p.current;this.load(false)},
  async loadSources(){try{const r=await this.api('/sources?keyword='+encodeURIComponent(this.sourceKeyword)+'&page='+this.sourcePage);this.sources=r.rows;this.sourceTotal=r.total}catch(e){this.error(e)}},
  async newChange(id){try{this.source=await this.api('/source/'+id);this.draft={...JSON.parse(JSON.stringify(this.source.order)),headId:id,orderVersion:this.source.orderVersion,kind:'change',reason:''};this.createVisible=true}catch(e){this.error(e)}},
  async createChange(){this.saving=true;try{const id=await this.api('/create',{...this.draft,lines:this.draft.lines.map(l=>({lineNo:l.lineNo,quantity:l.quantity}))});this.createVisible=false;this.sourcesVisible=false;await this.load();await this.open(id);this.$message.success('申请已提交，待审批期间按原计划生产')}catch(e){this.error(e)}finally{this.saving=false}},
  async open(id){try{this.form=await this.api('/'+id);this.visible=true}catch(e){this.error(e)}},
  begin(action){this.actionForm={action,comment:'',plan:JSON.parse(JSON.stringify(this.form.source.plan))};this.actionVisible=true},
  async saveAction(){this.saving=true;try{await this.api('/'+this.form.id+'/action',{...this.actionForm,version:this.form.version,orderVersion:this.form.source.orderVersion,taskVersion:this.form.source.taskVersion});this.actionVisible=false;await this.open(this.form.id);await this.load(false);this.$message.success('处理已保存')}catch(e){this.error(e)}finally{this.saving=false}},
  appliedPlan(h){return JSON.parse(h.payload_json).productionAdjustment},
  async saveConfig(){this.saving=true;try{await this.api('/config',{leaderIds:this.leaderIds});this.options=await this.api('/options');this.configVisible=false;this.$message.success('变更审批领导已配置')}catch(e){this.error(e)}finally{this.saving=false}}
 }
}
</script>
<style scoped>.actions{display:flex;gap:8px;flex-wrap:wrap;margin:12px 0}.scroll{overflow-x:auto}.change-table{width:100%;border-collapse:collapse;margin:12px 0}.change-table td,.change-table th{border:1px solid #ddd;padding:8px;text-align:left}</style>
