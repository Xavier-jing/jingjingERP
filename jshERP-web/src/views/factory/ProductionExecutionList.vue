<template>
 <a-card :bordered="false">
  <h2>开工与生产日报</h2>
  <a-form layout="inline"><a-form-item label="联系表 / 订单 / 客户"><a-input v-model="keyword" placeholder="输入编号或客户" @pressEnter="load()"/></a-form-item><a-button type="primary" @click="load()">查询</a-button><a-button style="margin-left:8px" @click="keyword='';load()">重置</a-button></a-form>
  <p style="margin:16px 0">选择已排班的生产任务，查看实际进度、确认开工或录入日报。</p>
  <a-table :columns="columns" :data-source="rows" row-key="head_id" :loading="loading" :pagination="pagination" bordered @change="onPage">
   <template slot="workshops" slot-scope="_,r"><div v-for="w in r.workshops" :key="w.workshop_no">{{['一车间','二车间','三车间'][w.workshop_no-1]}}：{{states[w.workflow_status]}}</div></template>
   <template slot="action" slot-scope="_,r"><a @click="open(r)">开工 / 日报 / 进度</a></template>
  </a-table>
  <j-modal fullscreen switchFullscreen title="开工与生产日报" :visible="visible" :width="1200" :footer="null" @cancel="visible=false">
   <p>{{task.number}}　销售订单：{{task.order_number}}　客户：{{task.customer_name}}</p>
   <production-execution-panel v-if="visible" :task="task" :options="options" @saved="refreshTask"/>
  </j-modal>
 </a-card>
</template>
<script>
import {getAction} from '@/api/manage'
import ProductionExecutionPanel from './ProductionExecutionPanel'
export default {
 name:'ProductionExecutionList',components:{ProductionExecutionPanel},
 data(){return {keyword:'',rows:[],loading:false,visible:false,task:{},options:{workshopNos:[]},pagination:{current:1,pageSize:10,total:0},states:{pending:'待接单',accepted:'已接单',scheduled:'已排班'},columns:[{title:'联系表编号',dataIndex:'number'},{title:'销售订单',dataIndex:'order_number'},{title:'客户',dataIndex:'customer_name'},{title:'任务时间',dataIndex:'task_time',customRender:v=>v?v.replace('T',' '):''},{title:'各车间安排',key:'workshops',scopedSlots:{customRender:'workshops'}},{title:'操作',key:'action',scopedSlots:{customRender:'action'}}]}},
 created(){this.initialize()},
 watch:{'$route.fullPath'(){this.fromProgress()}},
 methods:{
 async fromProgress(){if(this.$route.path!=='/factory/production_execution')return;const id=this.$route.query.taskId;if(id)await this.open({head_id:id})},

 async request(path){const r=await getAction('/factoryProduction'+path);if(r.code!==200)throw new Error(r.message||(r.data&&r.data.message)||'查询失败');return r.data},
 error(e){this.$message.error(e.message||'请求失败')},
 async initialize(){try{this.options=await this.request('/options');await this.load();await this.fromProgress()}catch(e){this.error(e)}},
 async load(reset=true){if(reset)this.pagination.current=1;this.loading=true;try{const r=await this.request('/list?state=execution&keyword='+encodeURIComponent(this.keyword)+'&page='+this.pagination.current+'&size='+this.pagination.pageSize);this.rows=r.rows;this.pagination.total=r.total}catch(e){this.error(e)}finally{this.loading=false}},
 onPage(p){this.pagination.current=p.current;this.load(false)},
 async open(row){try{this.task=await this.request('/'+row.head_id);this.visible=true}catch(e){this.error(e)}},
 async refreshTask(){try{this.task=await this.request('/'+this.task.head_id)}catch(e){this.error(e)}}
 }
}
</script>
