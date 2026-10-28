<template>
 <div>
  <a-button v-if="editable" @click="forms.push({name:'',items:[newItem()]})">增加分表</a-button>
  <a-card v-for="(form,fi) in forms" :key="fi" style="margin:12px 0">
   <a-input v-model="form.name" :disabled="!editable" placeholder="分表名称" :max-length="100" style="width:280px"/>
   <a-button v-if="editable" type="link" @click="forms.splice(fi,1)">删除分表</a-button>
   <div style="overflow-x:auto"><table class="quality-table"><thead><tr><th>指标名称</th><th>单位</th><th>类型</th><th>合格标准（数值含边界）</th><th v-if="editable">操作</th></tr></thead>
    <tbody><tr v-for="(item,ii) in form.items" :key="ii"><td><a-input v-model="item.name" :disabled="!editable" :max-length="100"/></td><td><a-input v-model="item.unit" :disabled="!editable" :max-length="30"/></td><td><a-select v-model="item.type" :disabled="!editable" style="width:100px"><a-select-option value="number">数值</a-select-option><a-select-option value="text">文字</a-select-option></a-select></td><td><a-input v-if="item.type==='text'" v-model="item.expected" :disabled="!editable" :max-length="500" placeholder="合格文字；留空由主任人工判定"/><template v-else><a-input-number v-model="item.min" :disabled="!editable" :precision="6" placeholder="下限"/> ～ <a-input-number v-model="item.max" :disabled="!editable" :precision="6" placeholder="上限"/></template></td><td v-if="editable"><a @click="form.items.splice(ii,1)">删除</a></td></tr></tbody>
   </table></div>
   <a-button v-if="editable" @click="form.items.push(newItem())">增加指标</a-button>
  </a-card>
  <a-empty v-if="!forms.length" description="暂无检测分表"/>
 </div>
</template>
<script>
export default {
 props:{forms:{type:Array,required:true},editable:{type:Boolean,default:false}},
 methods:{newItem(){return {name:'',unit:'',type:'number',min:null,max:null,expected:''}}}
}
</script>
<style scoped>.quality-table{width:100%;min-width:760px;margin:12px 0;border-collapse:collapse}.quality-table th,.quality-table td{border:1px solid #ddd;padding:8px;text-align:left}.quality-table td:first-child{min-width:170px}</style>
