<template><a-card :bordered="false"><h2>产品质检标准</h2><quality-standard-editor v-if="ready" :options="options"/></a-card></template>
<script>
import {getAction} from '@/api/manage'
import QualityStandardEditor from './QualityStandardEditor'
export default {
 name:'QualityStandardList',components:{QualityStandardEditor},data(){return {ready:false,options:{}}},
 async created(){try{const r=await getAction('/factoryQuality/standardOptions');if(r.code!==200)throw new Error(r.message||'加载失败');this.options=r.data;this.ready=true}catch(e){this.$message.error(e.message)}}
}
</script>
