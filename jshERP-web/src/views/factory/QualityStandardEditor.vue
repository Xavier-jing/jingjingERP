<template>
 <div>
  <a-alert type="info" show-icon message="新送检单使用当前标准，历史单据保留原标准。超标值照实保存并标红，最终结论由质检主任确认。"/>
  <p style="margin-top:12px">数值上下限包含边界，留空的一侧不限；文字按填写的合格文字比较，未设标准时人工判定。仅质检主任或租户负责人可维护。</p>
  <a-tabs default-active-key="products">
   <a-tab-pane key="products" tab="产品标准配置">
    <a-form layout="inline">
     <a-form-item label="产品 / 型号"><a-select v-model="barCode" show-search option-filter-prop="children" style="width:380px" @change="select"><a-select-option v-for="p in options.products" :key="p.barCode">{{product(p)}}</a-select-option></a-select></a-form-item>
     <a-form-item label="检测阶段"><a-select v-model="inspectionKind" style="width:130px" @change="select"><a-select-option value="semi">半成品</a-select-option><a-select-option value="finished">成品</a-select-option></a-select></a-form-item>
     <a-form-item v-if="inspectionKind==='semi'" label="工序"><a-input-number v-model="stageNo" :min="1" :max="10" :precision="0" @change="select"/></a-form-item>
    </a-form>
    <p v-if="barCode">{{version?'配置版本：'+version:'尚未配置'}} <span v-if="selectedTemplate"> / 模板版本：{{selectedTemplate.version}}</span></p>
    <a-radio-group v-model="mode" :disabled="!editable" @change="switchMode"><a-radio value="custom">本产品独立标准</a-radio><a-radio value="shared">共用模板</a-radio></a-radio-group>
    <p v-if="mode==='shared'" style="margin-top:12px"><a-select v-model="templateId" :disabled="!editable" show-search option-filter-prop="children" placeholder="选择检测模板" style="width:340px"><a-select-option v-for="t in templates" :key="t.id">{{t.name}}（版本{{t.version}}）</a-select-option></a-select>　模板更新后，所有引用产品的新送检单一起使用新标准。</p>
    <p v-else style="margin-top:12px"><a-select v-model="copyId" :disabled="!editable" show-search option-filter-prop="children" placeholder="从模板复制分表" style="width:300px"><a-select-option v-for="t in templates" :key="t.id">{{t.name}}</a-select-option></a-select> <a-button v-if="editable" :disabled="!copyId" @click="copyForms">复制为独立标准</a-button></p>
    <quality-form-fields :forms="mode==='shared'?(selectedTemplate?selectedTemplate.forms:[]):forms" :editable="editable&&mode==='custom'"/>
    <a-button v-if="editable" type="primary" :disabled="!barCode||(mode==='shared'&&!templateId)" :loading="saving" @click="save">保存产品标准</a-button>
   </a-tab-pane>
   <a-tab-pane key="templates" tab="共用检测模板">
    <a-select v-model="editingId" show-search option-filter-prop="children" placeholder="选择模板" style="width:340px" @change="selectTemplate"><a-select-option v-for="t in templates" :key="t.id">{{t.name}}（{{t.binding_count}}处引用）</a-select-option></a-select>
    <a-button v-if="editable" style="margin-left:8px" @click="newTemplate">新建模板</a-button><a-button v-if="editable" :disabled="!editingId" @click="duplicateTemplate">复制为新模板</a-button>
    <p style="margin-top:12px">模板名称：<a-input v-model="templateName" :disabled="!editable" :max-length="100" style="width:340px"/>　{{templateVersion?'版本：'+templateVersion:''}}</p>
    <a-alert v-if="editingId" type="warning" :message="'修改此模板将用于引用它的 '+bindingCount+' 处产品配置的新送检单；历史送检单不变。'" style="margin-bottom:12px"/>
    <quality-form-fields :forms="templateForms" :editable="editable"/>
    <a-button v-if="editable" type="primary" :loading="saving" @click="saveTemplate">保存检测模板</a-button>
   </a-tab-pane>
  </a-tabs>
 </div>
</template>
<script>
import {getAction,postAction} from '@/api/manage'
import QualityFormFields from './QualityFormFields'
export default {
 components:{QualityFormFields},props:{options:{type:Object,required:true}},
 data(){return {standards:[],templates:[],barCode:undefined,inspectionKind:'semi',stageNo:1,version:null,forms:[],saving:false,mode:'custom',templateId:undefined,copyId:undefined,editingId:undefined,templateName:'',templateVersion:null,templateForms:[],bindingCount:0}},
 computed:{editable(){return this.options.canConfigure||this.options.isDirector},selectedTemplate(){return this.templates.find(t=>t.id===this.templateId)}},
 created(){this.load()},
 methods:{
  product(p){return [p.name,p.brand,p.standard,p.model,p.barCode].filter(Boolean).join(' / ')},
  clone(forms){return JSON.parse(JSON.stringify(forms)).map(f=>({...f,items:f.items.map(i=>({type:'number',min:null,max:null,expected:'',...i}))}))},
  async api(path,body){const r=body?await postAction('/factoryQuality'+path,body):await getAction('/factoryQuality'+path);if(r.code!==200)throw new Error(r.message||(r.data&&r.data.message)||'操作失败');return r.data},
  async load(){try{this.standards=await this.api('/standards');this.templates=await this.api('/templates');this.select();if(this.editingId)this.selectTemplate()}catch(e){this.$message.error(e.message)}},
  select(){const stage=this.inspectionKind==='finished'?0:this.stageNo;const r=this.standards.find(s=>s.bar_code===this.barCode&&s.inspection_kind===this.inspectionKind&&s.stage_no===stage);this.version=r?r.version:null;this.forms=r?this.clone(r.forms):[];this.templateId=r&&r.template_id?r.template_id:undefined;this.mode=this.templateId?'shared':'custom'},
  switchMode(){if(this.mode==='custom'&&this.selectedTemplate)this.forms=this.clone(this.selectedTemplate.forms)},
  copyForms(){const t=this.templates.find(t=>t.id===this.copyId);if(t)this.forms=this.clone(t.forms)},
  async save(){this.saving=true;try{await this.api('/standards',{barCode:this.barCode,inspectionKind:this.inspectionKind,stageNo:this.inspectionKind==='finished'?0:this.stageNo,version:this.version,templateId:this.mode==='shared'?this.templateId:null,forms:this.forms});this.$message.success('产品质检标准已保存');await this.load()}catch(e){this.$message.error(e.message)}finally{this.saving=false}},
  newTemplate(){this.editingId=undefined;this.templateName='';this.templateVersion=null;this.templateForms=[];this.bindingCount=0},
  selectTemplate(){const t=this.templates.find(t=>t.id===this.editingId);if(!t)return;this.templateName=t.name;this.templateVersion=t.version;this.templateForms=this.clone(t.forms);this.bindingCount=t.binding_count},
  duplicateTemplate(){this.editingId=undefined;this.templateVersion=null;this.templateName=this.templateName+' 副本';this.bindingCount=0},
  async saveTemplate(){this.saving=true;try{this.editingId=await this.api('/templates',{id:this.editingId,name:this.templateName,version:this.templateVersion,forms:this.templateForms});this.$message.success('检测模板已保存');await this.load()}catch(e){this.$message.error(e.message)}finally{this.saving=false}}
 }
}
</script>
