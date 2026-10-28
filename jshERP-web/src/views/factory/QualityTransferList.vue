<template>
 <a-card :bordered="false">
  <p><router-link to="/factory/quality_standard">产品质检标准配置 →</router-link></p>
  <h2>{{finished?'成品质检入库与放行':'半成品送检与流转'}}</h2>
  <p>{{finished?'最终抽样送检 → 质检主任确认整批结果 → 仓库整批入库 → 任意一位配置领导整批放行。':'车间送样 → 填写检测分表 → 质检主任确认 → 原车间交接 → 接收车间确认。'}}数量单位：吨。</p>
  <a-button v-if="options.canConfigure" style="margin-bottom:12px" @click="openConfig">质检人员配置</a-button>
  <a-button v-if="finished&&options.canConfigure" style="margin:0 0 12px 8px" @click="leaderIds=options.leaderIds.slice();leadersVisible=true">放行领导配置</a-button>
  <a-alert v-if="!options.config.director_id" message="请租户负责人先配置质检主任和质检人员，再按产品、工序配置检测标准。" type="info" show-icon/>
  <a-alert v-if="finished&&!options.leaderIds.length" message="尚未配置放行领导，请租户负责人选择实际领导账号；任意一位批准即可整批放行。" type="info" show-icon style="margin-top:8px"/>
  <a-tabs default-active-key="tasks">
   <a-tab-pane key="tasks" :tab="finished?'成品送检、入库与放行':'送检与车间流转'">
    <a-form layout="inline"><a-form-item label="联系表 / 订单 / 客户"><a-input v-model="keyword" @pressEnter="load()"/></a-form-item><a-button type="primary" @click="load()">查询</a-button><a-button style="margin-left:8px" @click="keyword='';load()">重置</a-button></a-form>
    <a-table style="margin-top:16px" :columns="columns" :data-source="rows" row-key="head_id" :pagination="pagination" :loading="loading" @change="onPage"><a slot="action" slot-scope="_,r" @click="openTask(r)">{{finished?'送检 / 入库 / 放行':'送检 / 检测 / 交接'}}</a></a-table>
   </a-tab-pane>
   
  </a-tabs>
  <j-modal fullscreen switchFullscreen :title="finished?'成品质检入库与放行':'半成品送检与流转'" :visible="taskVisible" :width="1250" :footer="null" @cancel="taskVisible=false">
   <p>生产联系表：{{task.number}}</p>
   <h3>日报批次产出</h3>
   <div class="scroll"><table class="quality-table"><thead><tr><th>产品</th><th>工序 / 车间</th><th>批号</th><th>累计产出</th><th>已申请初检</th><th>操作</th></tr></thead><tbody>
    <tr v-for="b in batches" :key="b.key"><td>{{lineName(b.line_no)}}</td><td>{{b.stage_no}} / {{b.workshops.map(workshopName).join('、')}}</td><td>{{b.batch_number}}</td><td>{{b.output}}</td><td>{{b.requested}}</td><td><a v-if="applicantWorkshop(b)" @click="openRequest(b)">{{finished?'整批最终送检':'申请送检'}}</a></td></tr>
   </tbody></table></div>
   <h3>送检记录</h3>
   <div class="scroll"><table class="quality-table"><thead><tr><th>单号</th><th>产品 / 工序 / 车间</th><th>批号</th><th>代表数量</th><th>合格 / 不合格</th><th>状态</th><th>操作</th></tr></thead><tbody>
    <tr v-for="r in task.inspections" :key="r.id"><td>{{r.id}}<div v-if="r.parent_id">复检自 {{r.parent_id}}</div></td><td>{{lineName(r.line_no)}} / {{r.stage_no}} / {{workshopName(r.workshop_no)}}</td><td>{{r.batch_number}}</td><td>{{r.quantity}}</td><td>{{r.qualified_quantity==null?'待确认':r.qualified_quantity+' / '+subtract(r.quantity,r.qualified_quantity)}}</td><td>{{states[r.workflow_status]}}</td><td><a @click="openInspection(r.id)">检测 / 查看</a><template v-if="r.canMaintain"><a style="margin-left:12px" @click="editRequest(r)">修改送检</a><a style="margin-left:12px;color:#f5222d" @click="deleteRequest(r)">删除</a></template><template v-if="r.workflow_status==='approved' && owns(r.workshop_no)"><a v-if="!finished||Number(r.qualified_quantity)===0" style="margin-left:12px" @click="openRequest(r,true)">调整后复检</a><a v-if="!finished" style="margin-left:12px" @click="openTransfer(r)">交接</a></template></td></tr>
   </tbody></table></div>
   <template v-if="!finished"><h3>车间交接记录</h3>
   <div class="scroll"><table class="quality-table"><thead><tr><th>送检单</th><th>产品 / 批号</th><th>交出车间</th><th>接收工序 / 车间</th><th>数量</th><th>状态</th><th>接收时间</th><th>操作</th></tr></thead><tbody>
    <tr v-for="r in task.transfers" :key="r.id"><td><a @click="openInspection(r.inspection_id)">{{r.inspection_id}}</a></td><td>{{lineName(r.line_no)}} / {{r.batch_number}}</td><td>{{workshopName(r.source_workshop)}}</td><td>{{r.stage_no}} / {{workshopName(r.workshop_no)}}</td><td>{{r.quantity}}</td><td>{{r.workflow_status==='received'?'已接收':'待接收'}}</td><td>{{r.received_at||'—'}}</td><td><a v-if="r.workflow_status==='pending'&&owns(r.workshop_no)" @click="receive(r)">确认收到</a></td></tr>
   </tbody></table></div></template>
   <template v-else><h3>成品整批入库与领导放行</h3><p>待放行货物可预留，不能出库。点击检测报告可查看全部分表和处理意见。</p>
    <div class="scroll"><table class="quality-table"><thead><tr><th>产品 / 批号</th><th>整批数量</th><th>最终检测报告</th><th>仓库 / 入库记录</th><th>放行状态</th><th>处理领导 / 时间</th><th>操作</th></tr></thead><tbody>
     <tr v-for="r in task.finishedBatches" :key="r.id"><td>{{lineName(r.line_no)}} / {{r.batch_number}}</td><td>{{r.quantity}}</td><td><a @click="openInspection(r.inspection_id)">{{states[r.qc_state]}} / {{r.inspection_id}}</a><div v-if="r.qc_state==='approved'">{{Number(r.qualified_quantity)>0?'整批合格':'整批不合格'}}</div></td><td>{{r.ledger_head_id?(r.depot_name+' / CPRK'+r.id):'未入库'}}<div>{{r.received_name}} {{r.received_at}}</div></td><td>{{r.ledger_head_id?releaseStates[r.release_state]:'待质检合格入库'}}</td><td>{{r.released_name||'—'}} {{r.released_at}}</td><td>
      <a v-if="options.canWarehouse&&!r.ledger_head_id&&r.qc_state==='approved'&&Number(r.qualified_quantity)>0" @click="openFinishedAction(r,'receive')">整批入库</a>
      <template v-if="options.canRelease&&r.ledger_head_id&&r.release_state==='pending'"><a @click="openFinishedAction(r,'release')">整批放行</a><a style="margin-left:8px" @click="openFinishedAction(r,'hold')">不予放行</a></template>
      <a v-if="r.release_state==='held'&&owns(r.workshop_no)" @click="openFinishedAction(r,'resubmit')">记录处理结果并重新申请</a>
     </td></tr>
    </tbody></table></div>
   </template>
  </j-modal>
  <j-modal fullscreen switchFullscreen :ok-close="false" cancel-text="退出" title="质检人员配置" :visible="configVisible" :confirm-loading="saving" @ok="saveConfig" @cancel="configVisible=false">
   <div class="label">质检主任</div><a-select v-model="config.directorId" style="width:100%"><a-select-option v-for="u in options.users" :key="u.id">{{u.username}}（{{u.login_name}}）</a-select-option></a-select>
   <div class="label">检测分表填写人员</div><a-select v-model="config.inspectorIds" mode="multiple" style="width:100%"><a-select-option v-for="u in options.users" :key="u.id">{{u.username}}（{{u.login_name}}）</a-select-option></a-select>
  </j-modal>
  <j-modal fullscreen switchFullscreen :ok-close="false" cancel-text="退出" :title="request.id?'修改送检申请':request.parentId?'调整后申请复检':finished?'成品最终抽样送检':'申请半成品送检'" :visible="requestVisible" :confirm-loading="saving" @ok="saveRequest" @cancel="requestVisible=false">
   <p>{{lineName(request.lineNo)}} / 工序{{request.stageNo}} / {{workshopName(request.workshopNo)}} / 批号 {{request.batchNumber}}</p>
   <a-alert message="只送样品，实物留在车间。代表数量指本次样品所代表的生产数量。" type="info"/>
   <a-alert v-if="finished" message="请确认本批成品已全部生产完成。送检后整批数量固定，不能再追加本批成品日报产出。" type="warning" style="margin-top:8px"/>
   <a-alert v-if="request.id" message="保存后采用本产品、工序的最新质检标准；仅未开始检测的申请可修改。" type="info" style="margin-top:8px"/><div class="label">送检代表数量（吨）</div><a-input-number v-model="request.quantity" :disabled="finished" :min="0" :precision="6" style="width:100%"/>
   <div class="label">{{request.parentId?'调整及复检说明（必填）':'送检说明'}}</div><a-textarea v-model="request.comment" :max-length="2000"/>
  </j-modal>
  <j-modal fullscreen switchFullscreen title="检测分表与质检主任确认" :visible="inspectionVisible" :width="1100" :footer="null" @cancel="inspectionVisible=false">
   <p>送检单 {{inspection.id}}　批号 {{inspection.batch_number}}　代表数量 {{inspection.quantity}} 吨　状态：{{states[inspection.workflow_status]}}　标准版本 {{inspection.standard_version}}</p>
   <a-alert v-if="inspection.workflow_status==='testing'" type="info" show-icon message="查看不会锁单。质检员点击开始检测后，车间主任不能再修改或删除送检申请。" style="margin-bottom:12px"/>
   <a-button v-if="options.isInspector&&inspection.workflow_status==='testing'" type="primary" :loading="saving" style="margin-bottom:12px" @click="startInspection">开始检测</a-button>
   <p v-if="canFill">多名配置的质检员可按分表分工；请分别保存，提交前刷新并核对全部分表。</p>
   <p v-if="inspection.workflow_status==='approved'">质检主任确认：合格 {{inspection.qualified_quantity}} 吨，不合格 {{subtract(inspection.quantity,inspection.qualified_quantity)}} 吨。</p>
   <a-alert message="超出区间的数值标红；未设区间的指标由质检主任人工判定。最终合格数量由主任确认。" type="info"/>
   <a-card v-for="(form,fi) in inspection.forms" :key="fi" :title="form.name" style="margin:12px 0">
    <table class="quality-table"><thead><tr><th>指标</th><th>单位</th><th>标准区间（含边界）</th><th>检测值</th><th>提示</th></tr></thead><tbody><tr v-for="(item,ii) in form.items" :key="ii" :class="{abnormal:isAbnormal(item)}"><td>{{item.name}}</td><td>{{item.unit}}</td><td>{{range(item)}}</td><td><a-input v-if="canFill&&item.type==='text'" v-model="item.value" :max-length="500" :class="{abnormalInput:isAbnormal(item)}"/><a-input-number v-else-if="canFill" v-model="item.value" :precision="6" :class="{abnormalInput:isAbnormal(item)}"/><span v-else>{{item.value==null?'未填写':item.value}}</span></td><td>{{isAbnormal(item)?'超出标准':(item.type==='text'?!item.expected:item.min==null&&item.max==null)?'人工判定':''}}</td></tr></tbody></table>
    <p>录入人：{{form.actorName||'未填写'}}　时间：{{form.recordedAt||'—'}}</p>
    <a-textarea v-model="form.comment" :disabled="!canFill" placeholder="本表检测说明" :max-length="2000"/>
    <a-button v-if="canFill" style="margin-top:8px" :loading="saving" @click="saveForm(fi)">保存本张分表</a-button>
   </a-card>
   <a-alert v-if="canFill&&hasUnsavedForms" message="有检测分表尚未保存，请分别保存后再提交。" type="warning" style="margin-bottom:12px"/>
   <a-button v-if="canFill" type="primary" :loading="saving" :disabled="hasUnsavedForms" @click="submitInspection">提交质检主任确认</a-button>
   <template v-if="options.isDirector&&(inspection.workflow_status==='pending'||(inspection.workflow_status==='approved'&&correctingDecision))">
    <a-alert v-if="hasAbnormal" type="error" show-icon message="存在不合格指标，本次送检代表数量须判为不合格（合格数量为0）；车间调整后申请复检。" style="margin:12px 0"/><template v-if="inspection.inspection_kind==='finished'"><div class="label">最终抽样整批判定</div><a-radio-group v-model="qualifiedQuantity"><a-radio :value="inspection.quantity" :disabled="hasAbnormal">整批合格</a-radio><a-radio :value="0">整批不合格</a-radio></a-radio-group></template>
    <template v-else><div class="label">合格数量（吨，不合格数量自动计算）</div><a-input-number v-model="qualifiedQuantity" :min="0" :max="hasAbnormal?0:Number(inspection.quantity)" :disabled="hasAbnormal" :precision="6"/></template>
    <div class="label">判定及处理说明（有超标或不合格数量时必填）</div><a-textarea v-model="reviewComment" :max-length="2000"/>
    <a-button type="primary" :loading="saving" style="margin-top:12px" @click="review(correctingDecision?'correctDecision':'approve')">{{correctingDecision?'保存更正判定':'确认检测结论并返回车间'}}</a-button><a-button v-if="!correctingDecision" :loading="saving" style="margin-left:8px" @click="review('return')">退回补充检测数据</a-button>
   </template>
   <a-button v-if="options.isDirector&&inspection.workflow_status==='approved'&&!correctingDecision" style="margin-top:12px" @click="correctingDecision=true;qualifiedQuantity=hasAbnormal?0:null;reviewComment=''">更正判定（需填写原因）</a-button>
   <p style="margin-top:16px">主任意见 / 送检说明：{{inspection.comment||'—'}}</p>
   <h3>操作记录</h3><div v-for="(h,hi) in inspection.history" :key="hi" style="margin-bottom:8px">{{h.created_at}}　{{h.actor_name}}　{{actions[h.action]||h.action}}<div class="history">{{historyText(h)}}</div></div>
  </j-modal>
  <j-modal fullscreen switchFullscreen :ok-close="false" cancel-text="退出" title="安排合格半成品交接" :visible="transferVisible" :confirm-loading="saving" @ok="saveTransfer" @cancel="transferVisible=false">
   <p>送检单 {{transfer.inspectionId}}；下一工序：{{transfer.stageNo}}；批号沿用 {{transfer.batchNumber}}</p>
   <div class="label">接收车间（按统筹安排）</div><a-select v-model="transfer.workshopNo" style="width:100%"><a-select-option v-for="w in destinations" :key="w">{{workshopName(w)}}</a-select-option></a-select>
   <div class="label">交接数量（吨）</div><a-input-number v-model="transfer.quantity" :min="0" :precision="6" style="width:100%"/>
   <div class="label">交接说明</div><a-textarea v-model="transfer.comment" :max-length="2000"/>
  </j-modal>
  <j-modal fullscreen switchFullscreen :ok-close="false" cancel-text="退出" title="配置整批放行领导（任意一位批准即可）" :visible="leadersVisible" :confirm-loading="saving" @ok="saveLeaders" @cancel="leadersVisible=false"><a-select v-model="leaderIds" mode="multiple" style="width:100%"><a-select-option v-for="u in options.users" :key="u.id">{{u.username}}（{{u.login_name}}）</a-select-option></a-select></j-modal>
  <j-modal fullscreen switchFullscreen :ok-close="false" cancel-text="退出" :title="finishedActions[finishedOperation.action]" :visible="finishedActionVisible" :confirm-loading="saving" @ok="saveFinishedAction" @cancel="finishedActionVisible=false">
   <p>批号：{{finishedOperation.batchNumber}}；整批数量：{{finishedOperation.quantity}} 吨。</p>
   <template v-if="finishedOperation.action==='receive'"><div class="label">入库仓库</div><a-select v-model="finishedOperation.depotId" style="width:100%"><a-select-option v-for="d in options.depots" :key="d.id">{{d.name}}</a-select-option></a-select><p style="margin-top:12px">确认整批实物已到仓库。入库数量由最终抽样代表的整批数量带入。</p></template>
   <div class="label">{{['hold','resubmit'].includes(finishedOperation.action)?'处理意见 / 执行结果（必填）':'说明'}}</div><a-textarea v-model="finishedOperation.comment" :max-length="2000"/>
  </j-modal>
 </a-card>
</template>
<script>
import {getAction,postAction} from '@/api/manage'

export default {
 name:'QualityTransferList',props:{finished:{type:Boolean,default:false}},
 data(){return {leadersVisible:false,leaderIds:[],finishedActionVisible:false,finishedOperation:{},releaseStates:{pending:'待领导整批放行',held:'不予放行，待处理',released:'已整批放行'},finishedActions:{receive:'确认整批入库',release:'批准整批放行',hold:'不予放行',resubmit:'记录处理结果并重新申请'},options:{config:{},users:[],products:[],workshopNos:[],depots:[],leaderIds:[]},keyword:'',rows:[],loading:false,saving:false,pagination:{current:1,pageSize:10,total:0},columns:[{title:'联系表编号',dataIndex:'number'},{title:'销售订单',dataIndex:'order_number'},{title:'客户',dataIndex:'customer_name'},{title:'操作',key:'action',scopedSlots:{customRender:'action'}}],taskVisible:false,task:{lines:[],routes:[],reports:[],inspections:[],transfers:[],finishedBatches:[]},configVisible:false,config:{},requestVisible:false,request:{},inspectionVisible:false,inspection:{forms:[]},savedForms:[],qualifiedQuantity:0,reviewComment:'',correctingDecision:false,transferVisible:false,transfer:{},states:{testing:'待开始检测',detecting:'检测中',pending:'待质检主任确认',returned:'退回补充检测',approved:'主任已确认'},actions:{correctDecision:'更正检测判定',start:'开始检测',edit:'修改送检申请',delete:'删除送检申请',request:'申请送检',reinspect:'调整后复检',form:'保存检测分表',submit:'提交主任确认',return:'退回补充检测',approve:'确认检测结论',transfer:'安排交接',receive:'确认收到',finished_receive:'仓库整批入库',finished_release:'领导整批放行',finished_hold:'领导不予放行',finished_resubmit:'车间处理后重新申请'}}},
 computed:{
  hasAbnormal(){return this.inspection.forms.some(f=>f.items.some(i=>this.isAbnormal(i)))},
  hasUnsavedForms(){return this.inspection.forms.some((f,i)=>JSON.stringify(this.formContent(f))!==JSON.stringify(this.savedForms[i]))},
  canFill(){return this.options.isInspector&&['detecting','returned'].includes(this.inspection.workflow_status)},
  batches(){
   const groups={},last={};for(const r of this.task.routes)last[r.lineNo]=Math.max(last[r.lineNo]||0,r.stageNo)
   const key=r=>[r.line_no,r.stage_no,this.finished?'all':r.workshop_no,r.batch_number].join('|')
   for(const r of this.task.reports){if(this.finished?r.stage_no!==last[r.line_no]:r.stage_no===last[r.line_no])continue;const k=key(r);if(!groups[k])groups[k]={...r,key:k,output:0,requested:0,workshops:[]};groups[k].output+=Number(r.output_quantity);if(!groups[k].workshops.includes(r.workshop_no))groups[k].workshops.push(r.workshop_no)}
   for(const r of this.task.inspections)if(!r.parent_id&&groups[key(r)])groups[key(r)].requested+=Number(r.quantity)
   return Object.values(groups).map(r=>({...r,output:Number(r.output.toFixed(6)),requested:Number(r.requested.toFixed(6))}))
  },
  destinations(){return [...new Set(this.task.routes.filter(r=>r.lineNo===this.transfer.lineNo&&r.stageNo===this.transfer.stageNo).map(r=>r.workshopNo))]}
 },
 created(){this.initialize()},watch:{'$route.fullPath'(){this.fromProgress()}},
 methods:{
  async fromProgress(){if(this.$route.path!==(this.finished?'/factory/finished_product':'/factory/quality_transfer'))return;const id=this.$route.query.taskId;if(id)await this.openTask({head_id:id});if(this.$route.query.inspectionId)await this.openInspection(this.$route.query.inspectionId)},
  async api(path,body){const r=body===undefined?await getAction('/factoryQuality'+path):await postAction('/factoryQuality'+path,body);if(r.code!==200)throw new Error(r.message||(r.data&&r.data.message)||'操作失败');return r.data},
  error(e){this.$message.error(e.message||'请求失败')},
  async saveLeaders(){this.saving=true;try{await this.api('/leaders',{leaderIds:this.leaderIds});this.options=await this.api('/options');this.leadersVisible=false;this.$message.success('放行领导已配置')}catch(e){this.error(e)}finally{this.saving=false}},
  openFinishedAction(r,action){this.finishedOperation={id:r.id,version:r.version,action,batchNumber:r.batch_number,quantity:r.quantity,depotId:undefined,comment:''};this.finishedActionVisible=true},
  async saveFinishedAction(){this.saving=true;try{await this.api('/finished/'+this.finishedOperation.id+'/action',this.finishedOperation);this.finishedActionVisible=false;await this.refreshTask();this.$message.success('整批处理已完成')}catch(e){this.error(e)}finally{this.saving=false}},
  async initialize(){try{this.options=await this.api('/options');await this.load();await this.fromProgress()}catch(e){this.error(e)}},
  async load(reset=true){if(reset)this.pagination.current=1;this.loading=true;try{const r=await this.api('/tasks?keyword='+encodeURIComponent(this.keyword)+'&page='+this.pagination.current);this.rows=r.rows;this.pagination.total=r.total}catch(e){this.error(e)}finally{this.loading=false}},
  onPage(p){this.pagination.current=p.current;this.load(false)},
  applicantWorkshop(b){return (b.workshops||[b.workshop_no]).find(w=>this.owns(w))},
  owns(w){return this.options.workshopNos.includes(w)},
  workshopName(w){return ['一车间','二车间','三车间'][w-1]||''},
  lineName(i){const r=this.task.lines[i];return r?[r.name,r.brand,r.standard,r.model].filter(Boolean).join(' / '):''},
  subtract(a,b){return Number((Number(a)-Number(b)).toFixed(6))},
  async openTask(r){try{this.task=await this.api('/task/'+r.head_id+'?finished='+this.finished);this.taskVisible=true}catch(e){this.error(e)}},
  async refreshTask(){this.task=await this.api('/task/'+this.task.head_id+'?finished='+this.finished)},
  openConfig(){const c=this.options.config;this.config={directorId:c.director_id,inspectorIds:c.inspectors_json?JSON.parse(c.inspectors_json):[]};this.configVisible=true},
  async saveConfig(){this.saving=true;try{await this.api('/config',this.config);this.options=await this.api('/options');this.configVisible=false;this.$message.success('质检人员已配置')}catch(e){this.error(e)}finally{this.saving=false}},
  openRequest(r,retest=false){const used=retest?this.task.inspections.filter(i=>i.parent_id===r.id).reduce((sum,i)=>sum+Number(i.quantity),0):Number(r.requested);const available=retest?this.subtract(this.subtract(r.quantity,r.qualified_quantity),used):this.subtract(r.output,used);if(available<=0){this.$message.info(retest?'本单没有可复检数量':'该批次产出已全部申请送检');return}this.request={headId:this.task.head_id,lineNo:r.line_no,stageNo:r.stage_no,workshopNo:retest?r.workshop_no:this.applicantWorkshop(r),batchNumber:r.batch_number,finished:this.finished,quantity:available,parentId:retest?r.id:null,comment:''};this.requestVisible=true},
  async editRequest(r){try{const d=await this.api('/'+r.id);this.request={id:d.id,version:d.version,action:'edit',lineNo:d.line_no,stageNo:d.stage_no,workshopNo:d.workshop_no,batchNumber:d.batch_number,parentId:d.parent_id,quantity:d.quantity,comment:d.comment};this.requestVisible=true}catch(e){this.error(e)}},
  deleteRequest(r){this.$confirm({title:'删除送检单 '+r.id+'？',content:'仅未开始检测的申请可删除；删除后可重新按最新标准申请送检。',onOk:async()=>{try{await this.api('/'+r.id+'/request',{action:'delete',version:r.version});await this.refreshTask();this.$message.success('送检单已删除')}catch(e){this.error(e);throw e}}})},
  async saveRequest(){this.saving=true;try{await this.api(this.request.id?'/'+this.request.id+'/request':'/request',this.request);this.requestVisible=false;await this.refreshTask();this.$message.success('送检已提交')}catch(e){this.error(e)}finally{this.saving=false}},
  async openInspection(id){try{this.inspection=await this.api('/'+id);for(const f of this.inspection.forms){if(f.comment==null)this.$set(f,'comment','');for(const item of f.items)if(item.value==null)this.$set(item,'value',null)}this.savedForms=this.inspection.forms.map(f=>this.formContent(f));this.correctingDecision=false;this.qualifiedQuantity=this.hasAbnormal?0:null;this.reviewComment='';this.inspectionVisible=true}catch(e){this.error(e)}},
  formContent(f){return {values:f.items.map(i=>i.value),comment:f.comment||''}},
  isAbnormal(i){if(i.type==='text')return i.value!=null&&i.value!==''&&!!i.expected&&i.value!==i.expected;return i.value!=null&&i.value!==''&&((i.min!=null&&Number(i.value)<Number(i.min))||(i.max!=null&&Number(i.value)>Number(i.max)))},
  range(i){if(i.type==='text')return i.expected||'人工判定';return i.min==null&&i.max==null?'人工判定':(i.min==null?'不限':i.min)+' ～ '+(i.max==null?'不限':i.max)},
  historyText(h){
   const b=JSON.parse(h.payload_json);let message=''
   if(h.action==='form'){const form=this.inspection.forms[b.formIndex];message=(form?form.name:'检测分表')+'：'+(b.values||[]).map((v,i)=>(form&&form.items[i]?form.items[i].name:'指标')+' '+v.value).join('；')}
   else if(['approve','correctDecision'].includes(h.action))message='合格 '+b.qualifiedQuantity+' 吨'
   else if(h.action==='transfer')message='交往工序 '+b.stageNo+' / '+this.workshopName(b.workshopNo)+'，'+b.quantity+' 吨'
   else if(h.action==='receive')message='交接记录 '+b.transferId
   else if(h.action.startsWith('finished_'))message='批号 '+b.batchNumber+'，整批 '+b.quantity+' 吨'
   else if(['request','reinspect'].includes(h.action))message='批号 '+b.batchNumber+'，代表 '+b.quantity+' 吨'
   return [message,b.comment].filter(Boolean).join('；')
  },
  startInspection(){this.$confirm({title:'确认开始检测？',content:'开始后，车间主任将不能修改或删除这张送检申请。',onOk:async()=>{this.saving=true;try{await this.inspectionAction({action:'start'});this.$message.success('已开始检测，送检申请已锁定')}catch(e){this.error(e);throw e}finally{this.saving=false}}})},
  async inspectionAction(body){await this.api('/'+this.inspection.id+'/action',{...body,version:this.inspection.version});await this.openInspection(this.inspection.id);await this.refreshTask()},
  async saveForm(index){this.saving=true;try{const f=this.inspection.forms[index];await this.api('/'+this.inspection.id+'/action',{action:'form',version:this.inspection.version,formIndex:index,values:f.items.map(i=>({value:i.value})),comment:f.comment});this.inspection.version+=1;const fresh=await this.api('/'+this.inspection.id);if(fresh.version!==this.inspection.version)throw new Error('本表已保存，但其他数据也已更新，请重新打开送检单后继续');this.$set(this.inspection.forms,index,fresh.forms[index]);this.$set(this.savedForms,index,this.formContent(fresh.forms[index]));this.$message.success('本张分表已保存；其余分表请分别保存')}catch(e){this.error(e)}finally{this.saving=false}},
  async submitInspection(){this.saving=true;try{await this.inspectionAction({action:'submit'});this.$message.success('已提交质检主任确认')}catch(e){this.error(e)}finally{this.saving=false}},
  async review(action){this.saving=true;try{await this.inspectionAction({action,qualifiedQuantity:this.qualifiedQuantity,comment:this.reviewComment});this.$message.success('检测结果已处理')}catch(e){this.error(e)}finally{this.saving=false}},
  openTransfer(r){const used=this.task.transfers.filter(t=>t.inspection_id===r.id).reduce((sum,t)=>sum+Number(t.quantity),0);const available=this.subtract(r.qualified_quantity,used);if(available<=0){this.$message.info('本单没有可交接合格数量');return}this.transfer={inspectionId:r.id,version:r.version,lineNo:r.line_no,stageNo:r.stage_no+1,workshopNo:undefined,batchNumber:r.batch_number,quantity:available,comment:''};if(!this.destinations.length){this.$message.info('没有下一工序安排；最终成品需后续接入成品质检入库');return}this.transferVisible=true},
  async saveTransfer(){this.saving=true;try{await this.api('/'+this.transfer.inspectionId+'/action',{...this.transfer,action:'transfer'});this.transferVisible=false;await this.refreshTask();this.$message.success('交接已安排，等待接收车间确认')}catch(e){this.error(e)}finally{this.saving=false}},
  receive(r){this.$confirm({title:'确认已实际收到这批半成品？',content:this.workshopName(r.workshop_no)+' / 批号 '+r.batch_number+' / '+r.quantity+' 吨',onOk:async()=>{try{const i=await this.api('/'+r.inspection_id);await this.api('/'+r.inspection_id+'/action',{action:'receive',version:i.version,transferId:r.id});await this.refreshTask();this.$message.success('接收已确认')}catch(e){this.error(e);throw e}}})}
 }
}
</script>
<style scoped>
.scroll{overflow-x:auto}.quality-table{width:100%;border-collapse:collapse;margin:12px 0 20px}.quality-table th,.quality-table td{border:1px solid #ddd;padding:8px;text-align:left;min-width:90px}.label{margin:12px 0 6px}.abnormal{color:#cf1322;background:#fff1f0}.abnormalInput /deep/ input{color:#cf1322}.history{white-space:pre-wrap;max-height:240px;overflow:auto}
</style>


