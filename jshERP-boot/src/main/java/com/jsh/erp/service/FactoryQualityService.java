package com.jsh.erp.service;

import com.alibaba.fastjson.*;
import com.jsh.erp.datasource.entities.User;
import com.jsh.erp.datasource.entities.UserBusiness;
import com.jsh.erp.exception.BusinessRunTimeException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import javax.annotation.Resource;
import java.math.BigDecimal;
import java.util.*;
import javax.servlet.http.HttpServletRequest;

@Service
public class FactoryQualityService {
    @Resource private JdbcTemplate jdbc;
    @Resource private UserService users;
    @Resource private UserBusinessService business;
    @Resource private FactoryProductionService production;
    @Resource private FactoryStockService stock;
    @Resource private DepotHeadService heads;

    private void require(boolean valid,String message){if(!valid)throw new BusinessRunTimeException(409,message);}
    private long num(Object v){return ((Number)v).longValue();}
    private String text(JSONObject b,String key,int max,boolean required){String v=b.getString(key);v=v==null?"":v.trim();require((!required||!v.isEmpty())&&v.length()<=max,key+"不能为空或内容过长");return v;}
    private BigDecimal decimal(JSONObject b,String key,boolean required){BigDecimal v=b.getBigDecimal(key);require(!required||v!=null,key+"不能为空");if(v!=null)require(v.scale()<=6&&v.precision()-v.scale()<=12,key+"最多6位小数、12位整数");return v;}
    private BigDecimal quantity(JSONObject b,String key){BigDecimal v=decimal(b,key,true);require(v.signum()>=0,"数量不能为负数");return v;}
    private Map<String,Object> config(long tenant){List<Map<String,Object>> rows=jdbc.queryForList("SELECT * FROM jsh_factory_quality_config WHERE tenant_id=?",tenant);return rows.isEmpty()?new HashMap<>():rows.get(0);}
    private boolean director(User u){Object id=config(u.getTenantId()).get("director_id");return id!=null&&num(id)==u.getId();}
    private boolean inspector(User u){Object ids=config(u.getTenantId()).get("inspectors_json");return ids!=null&&JSONArray.parseArray(ids.toString()).toJavaList(Long.class).contains(u.getId());}
    private JSONArray leaders(long tenant){List<String> rows=jdbc.queryForList("SELECT leader_ids_json FROM jsh_factory_release_config WHERE tenant_id=?",String.class,tenant);return rows.isEmpty()?new JSONArray():JSONArray.parseArray(rows.get(0));}
    private boolean releaseLeader(User u){return leaders(u.getTenantId()).toJavaList(Long.class).contains(u.getId());}
    private User actor()throws Exception{return actor(false);}
    private User actor(boolean standardAccess)throws Exception{
        User u=users.getCurrentUser();require(u!=null&&u.getTenantId()!=null&&u.getTenantId()>0,"请使用业务租户账号");
        boolean allowed=u.getId().equals(u.getTenantId())||director(u)||inspector(u)||!production.workshopNos(u).isEmpty()||production.coordinates(u)||releaseLeader(u)||stock.canManageWarehouse(u);
        List<Long> menus=jdbc.queryForList("SELECT id FROM jsh_function WHERE (url IN('/factory/quality_transfer','/factory/finished_product') OR (? AND url='/factory/quality_standard')) AND enabled=1 AND IFNULL(delete_flag,'0')='0'",Long.class,standardAccess);
        for(UserBusiness binding:business.getBasicData(u.getId().toString(),"UserRole")){
            String id=binding.getValue().replace("[","").replace("]","");
            for(UserBusiness functions:business.getBasicData(id,"RoleFunctions"))for(Long menu:menus)if(functions.getValue()!=null&&functions.getValue().contains("["+menu+"]"))allowed=true;
        }
        require(allowed,"没有半成品送检与流转权限");return u;
    }
    private void validUser(User u,Long id){require(id!=null&&jdbc.queryForObject("SELECT COUNT(*) FROM jsh_user WHERE tenant_id=? AND id=? AND status=0 AND IFNULL(delete_flag,'0')='0'",Integer.class,u.getTenantId(),id)==1,"请选择本租户有效人员");}
    public Map<String,Object> options()throws Exception{
        User u=actor();Map<String,Object> r=new HashMap<>();r.put("config",config(u.getTenantId()));r.put("canConfigure",u.getId().equals(u.getTenantId()));r.put("isDirector",director(u));r.put("isInspector",inspector(u));r.put("workshopNos",production.workshopNos(u));
        r.put("leaderIds",leaders(u.getTenantId()));r.put("canRelease",releaseLeader(u));r.put("canWarehouse",stock.canManageWarehouse(u));List<Map<String,Object>> depots=new ArrayList<>();for(Map.Entry<Long,String> d:stock.depots(u).entrySet()){Map<String,Object> row=new HashMap<>();row.put("id",d.getKey());row.put("name",d.getValue());depots.add(row);}r.put("depots",depots);
        r.put("users",jdbc.queryForList("SELECT id,username,login_name FROM jsh_user WHERE tenant_id=? AND status=0 AND IFNULL(delete_flag,'0')='0' ORDER BY id",u.getTenantId()));
        r.put("products",products(u));return r;
    }
    private List<Map<String,Object>> products(User u){return jdbc.queryForList("SELECT e.bar_code barCode,m.name,m.brand,m.standard,m.model FROM jsh_material m JOIN jsh_material_extend e ON e.material_id=m.id AND e.tenant_id=m.tenant_id WHERE m.tenant_id=? AND m.enabled=1 AND m.material_kind='product' AND m.unit='吨' AND e.commodity_unit='吨' AND IFNULL(m.delete_flag,'0')='0' AND IFNULL(e.delete_flag,'0')='0' ORDER BY m.name,e.id",u.getTenantId());}
    public Map<String,Object> standardOptions()throws Exception{
        User u=actor(true);Map<String,Object> r=new HashMap<>();r.put("canConfigure",u.getId().equals(u.getTenantId()));r.put("isDirector",director(u));r.put("products",products(u));return r;
    }
    @Transactional(rollbackFor=Exception.class)
    public void configure(JSONObject b)throws Exception{
        User u=actor();require(u.getId().equals(u.getTenantId()),"仅租户负责人可配置质检人员");stock.lockForInventoryMutation();
        Long id=b.getLong("directorId");validUser(u,id);JSONArray ids=b.getJSONArray("inspectorIds");require(ids!=null&&!ids.isEmpty()&&ids.size()<=100,"请选择质检人员");Set<Long> unique=new LinkedHashSet<>();for(int i=0;i<ids.size();i++){Long person=ids.getLong(i);validUser(u,person);unique.add(person);}
        jdbc.update("INSERT INTO jsh_factory_quality_config VALUES(?,?,?,NOW()) ON DUPLICATE KEY UPDATE director_id=VALUES(director_id),inspectors_json=VALUES(inspectors_json),updated_at=NOW()",u.getTenantId(),id,JSON.toJSONString(unique));audit(u,null,"configure",b);
    }
    public List<Map<String,Object>> standards()throws Exception{
        User u=actor(true);List<Map<String,Object>> rows=jdbc.queryForList("SELECT s.*,t.name template_name,t.version template_version,t.forms_json template_forms FROM jsh_factory_quality_standard s LEFT JOIN jsh_factory_quality_template t ON t.id=s.template_id AND t.tenant_id=s.tenant_id WHERE s.tenant_id=? ORDER BY s.bar_code,s.inspection_kind,s.stage_no",u.getTenantId());
        for(Map<String,Object> r:rows){Object own=r.remove("forms_json"),shared=r.remove("template_forms");r.put("forms",JSONArray.parseArray((r.get("template_id")==null?own:shared).toString()));}return rows;
    }
    public List<Map<String,Object>> templates()throws Exception{
        User u=actor(true);List<Map<String,Object>> rows=jdbc.queryForList("SELECT t.*, (SELECT COUNT(*) FROM jsh_factory_quality_standard s WHERE s.tenant_id=t.tenant_id AND s.template_id=t.id) binding_count FROM jsh_factory_quality_template t WHERE t.tenant_id=? ORDER BY t.name",u.getTenantId());
        for(Map<String,Object> r:rows)r.put("forms",JSONArray.parseArray(r.remove("forms_json").toString()));return rows;
    }
    @Transactional(rollbackFor=Exception.class)
    public long saveTemplate(JSONObject b)throws Exception{
        User u=actor(true);require(u.getId().equals(u.getTenantId())||director(u),"仅质检主任或租户负责人可维护模板");stock.lockForInventoryMutation();
        String name=text(b,"name",100,true);JSONArray forms=cleanForms(b.getJSONArray("forms"));Long id=b.getLong("id");
        require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_quality_template WHERE tenant_id=? AND name=? AND (? IS NULL OR id<>?)",Integer.class,u.getTenantId(),name,id,id)==0,"模板名称已存在");
        if(id==null){jdbc.update("INSERT INTO jsh_factory_quality_template(tenant_id,name,forms_json,updated_by,updated_at) VALUES(?,?,?,?,NOW())",u.getTenantId(),name,forms.toJSONString(),u.getId());id=jdbc.queryForObject("SELECT LAST_INSERT_ID()",Long.class);}
        else{
            List<Map<String,Object>> old=jdbc.queryForList("SELECT version FROM jsh_factory_quality_template WHERE tenant_id=? AND id=? FOR UPDATE",u.getTenantId(),id);
            require(!old.isEmpty(),"模板不存在或无权访问");require(Objects.equals(b.getInteger("version"),old.get(0).get("version")),"模板已更新，请刷新后操作");
            jdbc.update("UPDATE jsh_factory_quality_template SET name=?,forms_json=?,version=version+1,updated_by=?,updated_at=NOW() WHERE tenant_id=? AND id=?",name,forms.toJSONString(),u.getId(),u.getTenantId(),id);
        }
        JSONObject event=new JSONObject(b);event.put("id",id);audit(u,null,"quality_template",event);return id;
    }
    private JSONArray cleanForms(JSONArray input){
        require(input!=null&&!input.isEmpty()&&input.size()<=20,"请配置1至20张检测分表");JSONArray forms=new JSONArray();Set<String> names=new HashSet<>();
        for(int i=0;i<input.size();i++){
            JSONObject raw=input.getJSONObject(i),form=new JSONObject();String name=text(raw,"name",100,true);require(names.add(name),"检测分表名称不能重复");form.put("name",name);JSONArray items=raw.getJSONArray("items"),clean=new JSONArray();require(items!=null&&!items.isEmpty()&&items.size()<=100,"每张分表请配置1至100项指标");Set<String> itemNames=new HashSet<>();
            for(int j=0;j<items.size();j++){
                JSONObject item=items.getJSONObject(j),row=new JSONObject();String itemName=text(item,"name",100,true);require(itemNames.add(itemName),"同一分表指标不能重名");String type=item.getString("type");if(type==null)type="number";require(Arrays.asList("number","text").contains(type),"指标类型无效");row.put("type",type);row.put("name",itemName);row.put("unit",text(item,"unit",30,false));
                if("text".equals(type))row.put("expected",text(item,"expected",500,false));
                else{BigDecimal min=decimal(item,"min",false),max=decimal(item,"max",false);require(min==null||max==null||min.compareTo(max)<=0,"指标下限不能大于上限");row.put("min",min);row.put("max",max);}clean.add(row);
            }form.put("items",clean);forms.add(form);
        }return forms;
    }
    @Transactional(rollbackFor=Exception.class)
    public void saveStandard(JSONObject b)throws Exception{
        User u=actor(true);require(u.getId().equals(u.getTenantId())||director(u),"仅质检主任或租户负责人可配置检测标准");stock.lockForInventoryMutation();String code=text(b,"barCode",100,true);Integer stage=b.getInteger("stageNo");require(stage!=null&&stage>=("finished".equals(b.getString("inspectionKind"))?0:1)&&stage<=10,"工序须为1至10");
        require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_material_extend e JOIN jsh_material m ON m.id=e.material_id AND m.tenant_id=e.tenant_id WHERE e.tenant_id=? AND e.bar_code=? AND m.material_kind='product' AND m.enabled=1 AND IFNULL(m.delete_flag,'0')='0' AND IFNULL(e.delete_flag,'0')='0'",Integer.class,u.getTenantId(),code)==1,"产品不存在或已停用");
        String kind=b.getString("inspectionKind");if(kind==null)kind="semi";require(Arrays.asList("semi","finished").contains(kind),"检测阶段无效");if("finished".equals(kind))stage=0;
        Long template=b.getLong("templateId");JSONArray forms;
        if(template==null)forms=cleanForms(b.getJSONArray("forms"));
        else{require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_quality_template WHERE tenant_id=? AND id=?",Integer.class,u.getTenantId(),template)==1,"模板不存在或无权访问");forms=new JSONArray();}
        List<Map<String,Object>> old=jdbc.queryForList("SELECT version FROM jsh_factory_quality_standard WHERE tenant_id=? AND bar_code=? AND inspection_kind=? AND stage_no=? FOR UPDATE",u.getTenantId(),code,kind,stage);
        require(old.isEmpty()?b.getInteger("version")==null:Objects.equals(b.getInteger("version"),old.get(0).get("version")),"标准已被更新，请刷新后操作");
        jdbc.update("INSERT INTO jsh_factory_quality_standard(tenant_id,bar_code,stage_no,inspection_kind,template_id,version,forms_json,updated_by,updated_at) VALUES(?,?,?,?,?,1,?,?,NOW()) ON DUPLICATE KEY UPDATE version=version+1,template_id=VALUES(template_id),forms_json=VALUES(forms_json),updated_by=VALUES(updated_by),updated_at=NOW()",u.getTenantId(),code,stage,kind,template,forms.toJSONString(),u.getId());audit(u,null,"standard",b);
    }

    public Map<String,Object> tasks(String keyword,int page)throws Exception{
        User u=actor();require(keyword.length()<=100&&page>0&&page<=100000,"查询条件无效");String from=" FROM jsh_factory_production_task t JOIN jsh_depot_head h ON h.id=t.head_id AND h.tenant_id=t.tenant_id LEFT JOIN jsh_supplier s ON s.id=h.organ_id AND s.tenant_id=h.tenant_id WHERE t.tenant_id=? AND t.workflow_status IN('distributed','scheduled') AND IFNULL(h.delete_flag,'0')='0' AND (t.number LIKE ? OR h.number LIKE ? OR s.supplier LIKE ?)";
        Object[] args={u.getTenantId(),"%"+keyword+"%","%"+keyword+"%","%"+keyword+"%"};Map<String,Object> r=new HashMap<>();r.put("total",jdbc.queryForObject("SELECT COUNT(*)"+from,Long.class,args));List<Object> list=new ArrayList<>(Arrays.asList(args));list.add((page-1)*10);r.put("rows",jdbc.queryForList("SELECT t.head_id,t.number,h.number order_number,s.supplier customer_name"+from+" ORDER BY t.head_id DESC LIMIT 10 OFFSET ?",list.toArray()));return r;
    }
    private Map<String,Object> task(long id,User u,boolean lock){List<Map<String,Object>> rows=jdbc.queryForList("SELECT t.* FROM jsh_factory_production_task t JOIN jsh_depot_head h ON h.id=t.head_id AND h.tenant_id=t.tenant_id WHERE t.tenant_id=? AND t.head_id=? AND IFNULL(h.delete_flag,'0')='0'"+(lock?" FOR UPDATE":""),u.getTenantId(),id);require(!rows.isEmpty(),"生产任务不存在或无权访问");return rows.get(0);}
    public Map<String,Object> taskDetail(long id,boolean finished)throws Exception{
        User u=actor();Map<String,Object> t=task(id,u,false),r=new HashMap<>();r.put("head_id",id);r.put("number",t.get("number"));JSONArray lines=JSONArray.parseArray(t.get("lines_json").toString()),products=new JSONArray();for(int i=0;i<lines.size();i++){JSONObject product=new JSONObject();for(String key:Arrays.asList("name","brand","standard","model","barCode"))product.put(key,lines.getJSONObject(i).get(key));products.add(product);}r.put("lines",products);r.put("routes",JSONArray.parseArray(t.get("route_json").toString()));
        r.put("reports",jdbc.queryForList("SELECT id,line_no,stage_no,workshop_no,batch_number,report_date,output_quantity FROM jsh_factory_production_report WHERE tenant_id=? AND head_id=? ORDER BY id DESC",u.getTenantId(),id));
        r.put("inspections",jdbc.queryForList("SELECT id,line_no,stage_no,workshop_no,batch_number,quantity,parent_id,inspection_kind,workflow_status,qualified_quantity,version,created_at FROM jsh_factory_inspection WHERE tenant_id=? AND head_id=? AND inspection_kind=? ORDER BY id DESC",u.getTenantId(),id,finished?"finished":"semi"));
        for(Map<String,Object> row:(List<Map<String,Object>>)r.get("inspections"))row.put("canMaintain",!finished&&"testing".equals(row.get("workflow_status"))&&production.managesWorkshop(u,(int)num(row.get("workshop_no")))&&jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_inspection i WHERE i.tenant_id=? AND i.id=? AND i.created_by=? AND NOT EXISTS(SELECT 1 FROM jsh_factory_quality_history h WHERE h.tenant_id=i.tenant_id AND h.inspection_id=i.id AND h.action IN('start','form','submit','return','approve'))",Integer.class,u.getTenantId(),row.get("id"),u.getId())==1);
        r.put("finishedBatches",jdbc.queryForList("SELECT f.*,i.workflow_status qc_state,i.qualified_quantity,i.workshop_no,d.name depot_name,ru.username received_name,lu.username released_name FROM jsh_factory_finished_batch f JOIN jsh_factory_inspection i ON i.id=f.inspection_id AND i.tenant_id=f.tenant_id LEFT JOIN jsh_depot d ON d.id=f.depot_id AND d.tenant_id=f.tenant_id LEFT JOIN jsh_user ru ON ru.id=f.received_by AND ru.tenant_id=f.tenant_id LEFT JOIN jsh_user lu ON lu.id=f.released_by AND lu.tenant_id=f.tenant_id WHERE f.tenant_id=? AND f.head_id=? ORDER BY f.id DESC",u.getTenantId(),id));
        r.put("transfers",jdbc.queryForList("SELECT tr.*,i.workshop_no source_workshop FROM jsh_factory_quality_transfer tr JOIN jsh_factory_inspection i ON i.id=tr.inspection_id AND i.tenant_id=tr.tenant_id WHERE tr.tenant_id=? AND tr.head_id=? ORDER BY tr.id DESC",u.getTenantId(),id));return r;
    }
    private Map<String,Object> inspection(long id,User u,boolean lock){List<Map<String,Object>> rows=jdbc.queryForList("SELECT * FROM jsh_factory_inspection WHERE tenant_id=? AND id=?"+(lock?" FOR UPDATE":""),u.getTenantId(),id);require(!rows.isEmpty(),"送检单不存在或无权访问");return rows.get(0);}
    private void audit(User u,Long id,String action,Object payload){jdbc.update("INSERT INTO jsh_factory_quality_history(tenant_id,inspection_id,action,actor_id,actor_name,payload_json,created_at) VALUES(?,?,?,?,?,?,NOW())",u.getTenantId(),id,action,u.getId(),u.getUsername(),JSON.toJSONString(payload));}
    private int finalStage(Map<String,Object> task,int line){int last=0;for(Object value:JSONArray.parseArray(task.get("route_json").toString())){JSONObject route=(JSONObject)value;if(route.getIntValue("lineNo")==line)last=Math.max(last,route.getIntValue("stageNo"));}return last;}
    @Transactional(rollbackFor=Exception.class)
    public long request(JSONObject b)throws Exception{
        User u=actor();stock.lockForInventoryMutation();Long head=b.getLong("headId");require(head!=null,"请选择生产任务");Map<String,Object> task=task(head,u,true);Integer line=b.getInteger("lineNo"),stage=b.getInteger("stageNo"),workshop=b.getInteger("workshopNo");JSONArray lines=JSONArray.parseArray(task.get("lines_json").toString());
        require(line!=null&&line>=0&&line<lines.size()&&stage!=null&&stage>=1&&stage<=10&&workshop!=null&&production.managesWorkshop(u,workshop),"仅本车间主任可申请本人车间产品工序送检");
        String batch=text(b,"batchNumber",100,true);boolean finished=b.getBooleanValue("finished");BigDecimal qty=finished?BigDecimal.ZERO:quantity(b,"quantity");Long parent=b.getLong("parentId");
        if(!finished&&parent==null)require(stage<finalStage(task,line),"最后一道工序产出请从成品模块申请最终抽样送检");
        if(finished){
            require(stage==finalStage(task,line),"成品送检只能选择该产品最后一道工序");
            require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_production_report WHERE tenant_id=? AND head_id=? AND line_no=? AND stage_no=? AND workshop_no=? AND batch_number=? AND output_quantity>0",Integer.class,u.getTenantId(),head,line,stage,workshop,batch)>0,"仅该批成品实际产出车间主任可送检");
            if(parent==null){
                qty=jdbc.queryForObject("SELECT COALESCE(SUM(output_quantity),0) FROM jsh_factory_production_report WHERE tenant_id=? AND head_id=? AND line_no=? AND stage_no=? AND batch_number=? FOR UPDATE",BigDecimal.class,u.getTenantId(),head,line,stage,batch);
                require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_finished_batch WHERE tenant_id=? AND material_id=? AND batch_number=?",Integer.class,u.getTenantId(),lines.getJSONObject(line).getLong("id"),batch)==0,"该产品批号已最终送检，请查看原批次或从不合格单整批复检");
            }else{
                Map<String,Object> p=inspection(parent,u,true);require("finished".equals(p.get("inspection_kind"))&&"approved".equals(p.get("workflow_status"))&&((BigDecimal)p.get("qualified_quantity")).signum()==0,"仅整批不合格的成品可调整后复检");
                List<Map<String,Object>> batches=jdbc.queryForList("SELECT * FROM jsh_factory_finished_batch WHERE tenant_id=? AND inspection_id=? FOR UPDATE",u.getTenantId(),parent);require(!batches.isEmpty()&&batches.get(0).get("ledger_head_id")==null,"该批不是当前待复检批次，或已经入库");qty=(BigDecimal)batches.get(0).get("quantity");
            }
        }
        require(qty.signum()>0,"送检代表数量须大于0");
        if(parent==null){
            BigDecimal output=jdbc.queryForObject("SELECT COALESCE(SUM(output_quantity),0) FROM jsh_factory_production_report WHERE tenant_id=? AND head_id=? AND line_no=? AND stage_no=? AND workshop_no=? AND batch_number=? FOR UPDATE",BigDecimal.class,u.getTenantId(),head,line,stage,workshop,batch);
            BigDecimal used=jdbc.queryForObject("SELECT COALESCE(SUM(quantity),0) FROM jsh_factory_inspection WHERE tenant_id=? AND head_id=? AND line_no=? AND stage_no=? AND workshop_no=? AND batch_number=? AND parent_id IS NULL AND inspection_kind='semi'",BigDecimal.class,u.getTenantId(),head,line,stage,workshop,batch);if(!finished)require(used.add(qty).compareTo(output)<=0,"送检总量不能超过该批次日报产出；不合格数量请从原单申请复检");
        }else{
            Map<String,Object> p=inspection(parent,u,true);require((finished?"finished":"semi").equals(p.get("inspection_kind")),"不能改变原送检类型");require(num(p.get("head_id"))==head&&num(p.get("line_no"))==line&&num(p.get("stage_no"))==stage&&num(p.get("workshop_no"))==workshop&&batch.equals(p.get("batch_number"))&&"approved".equals(p.get("workflow_status")),"复检必须关联同任务、工序、车间及批号的已确认送检单");require(!text(b,"comment",2000,true).isEmpty(),"请填写调整与复检说明");
            BigDecimal used=jdbc.queryForObject("SELECT COALESCE(SUM(quantity),0) FROM jsh_factory_inspection WHERE tenant_id=? AND parent_id=?",BigDecimal.class,u.getTenantId(),parent);require(used.add(qty).compareTo(((BigDecimal)p.get("quantity")).subtract((BigDecimal)p.get("qualified_quantity")))<=0,"复检总量不能超过原单不合格数量");
        }
        require(!config(u.getTenantId()).isEmpty(),"请先配置质检主任和质检人员");String code=lines.getJSONObject(line).getString("barCode");List<Map<String,Object>> standards=jdbc.queryForList("SELECT CASE WHEN s.template_id IS NULL THEN s.version ELSE t.version END version,CASE WHEN s.template_id IS NULL THEN s.forms_json ELSE t.forms_json END forms_json FROM jsh_factory_quality_standard s LEFT JOIN jsh_factory_quality_template t ON t.id=s.template_id AND t.tenant_id=s.tenant_id WHERE s.tenant_id=? AND s.bar_code=? AND s.inspection_kind=? AND s.stage_no=? FOR UPDATE",u.getTenantId(),code,finished?"finished":"semi",finished?0:stage);require(!standards.isEmpty(),"该产品检测阶段未配置标准，请在商品管理的产品质检标准中配置");Map<String,Object> standard=standards.get(0);
        jdbc.update("INSERT INTO jsh_factory_inspection(tenant_id,head_id,line_no,stage_no,workshop_no,batch_number,quantity,parent_id,standard_version,forms_json,inspection_kind,workflow_status,comment,created_by,created_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,'testing',?,?,NOW())",u.getTenantId(),head,line,stage,workshop,batch,qty,parent,standard.get("version"),standard.get("forms_json"),finished?"finished":"semi",text(b,"comment",2000,false),u.getId());long id=jdbc.queryForObject("SELECT LAST_INSERT_ID()",Long.class);
        if(finished){if(parent==null)jdbc.update("INSERT INTO jsh_factory_finished_batch(tenant_id,head_id,line_no,stage_no,material_id,bar_code,batch_number,quantity,root_inspection_id,inspection_id) VALUES(?,?,?,?,?,?,?,?,?,?)",u.getTenantId(),head,line,stage,lines.getJSONObject(line).getLong("id"),code,batch,qty,id,id);else jdbc.update("UPDATE jsh_factory_finished_batch SET inspection_id=?,version=version+1 WHERE tenant_id=? AND inspection_id=?",id,u.getTenantId(),parent);}
        JSONObject event=new JSONObject(b);event.put("quantity",qty);audit(u,id,parent==null?"request":"reinspect",event);return id;
    }
    public Map<String,Object> detail(long id)throws Exception{User u=actor();Map<String,Object> r=inspection(id,u,false);r.put("forms",JSONArray.parseArray(r.remove("forms_json").toString()));r.put("history",jdbc.queryForList("SELECT action,actor_name,payload_json,created_at FROM jsh_factory_quality_history WHERE tenant_id=? AND inspection_id=? ORDER BY id",u.getTenantId(),id));return r;}
    private boolean abnormal(JSONObject item){if("text".equals(item.getString("type"))){String value=item.getString("value"),expected=item.getString("expected");return value!=null&&expected!=null&&!expected.isEmpty()&&!expected.equals(value);}BigDecimal v=item.getBigDecimal("value"),min=item.getBigDecimal("min"),max=item.getBigDecimal("max");return v!=null&&(min!=null&&v.compareTo(min)<0||max!=null&&v.compareTo(max)>0);}
    @Transactional(rollbackFor=Exception.class)
    public void maintainRequest(long id,JSONObject b)throws Exception{
        User u=actor();stock.lockForInventoryMutation();Map<String,Object> r=inspection(id,u,true),t=task(num(r.get("head_id")),u,true);
        require(Objects.equals(b.getInteger("version"),r.get("version")),"送检单已更新，请重新打开");
        require(num(r.get("created_by"))==u.getId()&&production.managesWorkshop(u,(int)num(r.get("workshop_no"))),"仅原送检车间主任可修改或删除");
        require("semi".equals(r.get("inspection_kind"))&&"testing".equals(r.get("workflow_status")),"仅未开始检测的半成品送检单可修改或删除");
        require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_quality_history WHERE tenant_id=? AND inspection_id=? AND action IN('start','form','submit','return','approve')",Integer.class,u.getTenantId(),id)==0,"已经填写或处理检测结果，不能修改或删除");
        for(Object value:JSONArray.parseArray(r.get("forms_json").toString()))for(Object item:((JSONObject)value).getJSONArray("items"))require(((JSONObject)item).get("value")==null,"已经填写检测数据，不能修改或删除");
        require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_quality_transfer WHERE tenant_id=? AND inspection_id=?",Integer.class,u.getTenantId(),id)==0&&jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_inspection WHERE tenant_id=? AND parent_id=?",Integer.class,u.getTenantId(),id)==0,"已有交接或复检记录，不能修改或删除");
        String action=b.getString("action");
        if("delete".equals(action)){
            audit(u,id,"delete",r);jdbc.update("DELETE FROM jsh_factory_inspection WHERE tenant_id=? AND id=?",u.getTenantId(),id);return;
        }
        require("edit".equals(action),"不支持的送检操作");BigDecimal qty=quantity(b,"quantity");require(qty.signum()>0,"送检代表数量须大于0");
        BigDecimal limit,used;
        if(r.get("parent_id")==null){
            limit=jdbc.queryForObject("SELECT COALESCE(SUM(output_quantity),0) FROM jsh_factory_production_report WHERE tenant_id=? AND head_id=? AND line_no=? AND stage_no=? AND workshop_no=? AND batch_number=?",BigDecimal.class,u.getTenantId(),r.get("head_id"),r.get("line_no"),r.get("stage_no"),r.get("workshop_no"),r.get("batch_number"));
            used=jdbc.queryForObject("SELECT COALESCE(SUM(quantity),0) FROM jsh_factory_inspection WHERE tenant_id=? AND head_id=? AND line_no=? AND stage_no=? AND workshop_no=? AND batch_number=? AND parent_id IS NULL AND inspection_kind='semi' AND id<>?",BigDecimal.class,u.getTenantId(),r.get("head_id"),r.get("line_no"),r.get("stage_no"),r.get("workshop_no"),r.get("batch_number"),id);
        }else{
            Map<String,Object> p=inspection(num(r.get("parent_id")),u,true);limit=((BigDecimal)p.get("quantity")).subtract((BigDecimal)p.get("qualified_quantity"));
            used=jdbc.queryForObject("SELECT COALESCE(SUM(quantity),0) FROM jsh_factory_inspection WHERE tenant_id=? AND parent_id=? AND id<>?",BigDecimal.class,u.getTenantId(),r.get("parent_id"),id);
        }
        require(used.add(qty).compareTo(limit)<=0,"累计送检数量超过批次可送检数量");
        String code=JSONArray.parseArray(t.get("lines_json").toString()).getJSONObject((int)num(r.get("line_no"))).getString("barCode");
        List<Map<String,Object>> standards=jdbc.queryForList("SELECT CASE WHEN s.template_id IS NULL THEN s.version ELSE tp.version END version,CASE WHEN s.template_id IS NULL THEN s.forms_json ELSE tp.forms_json END forms_json FROM jsh_factory_quality_standard s LEFT JOIN jsh_factory_quality_template tp ON tp.id=s.template_id AND tp.tenant_id=s.tenant_id WHERE s.tenant_id=? AND s.bar_code=? AND s.inspection_kind='semi' AND s.stage_no=? FOR UPDATE",u.getTenantId(),code,r.get("stage_no"));
        require(!standards.isEmpty(),"请先配置本产品工序的质检标准");Map<String,Object> standard=standards.get(0);String comment=text(b,"comment",2000,r.get("parent_id")!=null);
        jdbc.update("UPDATE jsh_factory_inspection SET quantity=?,comment=?,standard_version=?,forms_json=?,version=version+1 WHERE tenant_id=? AND id=?",qty,comment,standard.get("version"),standard.get("forms_json"),u.getTenantId(),id);
        JSONObject event=new JSONObject();event.put("before",r);event.put("quantity",qty);event.put("comment",comment);event.put("forms",standard.get("forms_json"));audit(u,id,"edit",event);
    }
    @Transactional(rollbackFor=Exception.class)
    public void action(long id,JSONObject b)throws Exception{
        User u=actor();stock.lockForInventoryMutation();Map<String,Object> r=inspection(id,u,true);task(num(r.get("head_id")),u,true);require(b.getInteger("version")!=null&&b.getInteger("version").equals(r.get("version")),"送检单已更新，请重新打开");String action=b.getString("action"),state=r.get("workflow_status").toString();JSONArray forms=JSONArray.parseArray(r.get("forms_json").toString());
        if("start".equals(action)){
            require(inspector(u)&&"testing".equals(state),"仅配置的质检员可开始待检测送检单");
            jdbc.update("UPDATE jsh_factory_inspection SET workflow_status='detecting',version=version+1 WHERE tenant_id=? AND id=?",u.getTenantId(),id);
        }else if("form".equals(action)){
            require(inspector(u)&&Arrays.asList("detecting","returned").contains(state),"请由质检员先开始检测，再填写分表");Integer index=b.getInteger("formIndex");require(index!=null&&index>=0&&index<forms.size(),"检测分表不存在");JSONObject form=forms.getJSONObject(index);JSONArray items=form.getJSONArray("items"),values=b.getJSONArray("values");require(values!=null&&values.size()==items.size(),"请填写本表全部检测数据");
            for(int j=0;j<items.size();j++){JSONObject item=items.getJSONObject(j);item.put("value","text".equals(item.getString("type"))?text(values.getJSONObject(j),"value",500,true):decimal(values.getJSONObject(j),"value",true));}form.put("comment",text(b,"comment",2000,false));form.put("actorName",u.getUsername());form.put("recordedAt",java.time.LocalDateTime.now().toString());
            jdbc.update("UPDATE jsh_factory_inspection SET forms_json=?,version=version+1 WHERE tenant_id=? AND id=?",forms.toJSONString(),u.getTenantId(),id);
        }else if("submit".equals(action)){
            require(inspector(u)&&Arrays.asList("detecting","returned").contains(state),"仅质检人员可提交检测结果");for(int i=0;i<forms.size();i++){JSONArray items=forms.getJSONObject(i).getJSONArray("items");for(int j=0;j<items.size();j++)require(items.getJSONObject(j).get("value")!=null&&!items.getJSONObject(j).getString("value").trim().isEmpty(),"请先完成全部检测分表");}
            jdbc.update("UPDATE jsh_factory_inspection SET workflow_status='pending',version=version+1 WHERE tenant_id=? AND id=?",u.getTenantId(),id);
        }else if("return".equals(action)||"approve".equals(action)||"correctDecision".equals(action)){
            boolean correcting="correctDecision".equals(action);
            require(director(u)&&(correcting?"approved":"pending").equals(state),"仅质检主任可确认待审核结果或更正已确认判定");
            if(correcting){
                require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_quality_transfer WHERE tenant_id=? AND inspection_id=?",Integer.class,u.getTenantId(),id)==0&&jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_inspection WHERE tenant_id=? AND parent_id=?",Integer.class,u.getTenantId(),id)==0,"已有交接或复检，不能直接更正判定");
                require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_finished_batch WHERE tenant_id=? AND (inspection_id=? OR root_inspection_id=?) AND (ledger_head_id IS NOT NULL OR inspection_id<>?)",Integer.class,u.getTenantId(),id,id,id)==0,"成品已经入库或复检，不能直接更正判定");
                b.put("previousQualifiedQuantity",r.get("qualified_quantity"));b.put("previousComment",r.get("comment"));b.put("previousConfirmedBy",r.get("confirmed_by"));b.put("previousConfirmedAt",r.get("confirmed_at"));
            }
            String comment=text(b,"comment",2000,correcting||"return".equals(action));
            if("return".equals(action))jdbc.update("UPDATE jsh_factory_inspection SET workflow_status='returned',comment=?,version=version+1 WHERE tenant_id=? AND id=?",comment,u.getTenantId(),id);
            else{
                BigDecimal qualified=quantity(b,"qualifiedQuantity");require(qualified.compareTo((BigDecimal)r.get("quantity"))<=0,"合格数量不能超过送检代表数量");boolean abnormal=false;for(int i=0;i<forms.size();i++)for(Object item:forms.getJSONObject(i).getJSONArray("items"))abnormal|=abnormal((JSONObject)item);
                if("finished".equals(r.get("inspection_kind")))require(qualified.signum()==0||qualified.compareTo((BigDecimal)r.get("quantity"))==0,"成品抽样结果须判定整批合格或整批不合格，不能拆分数量");
                require(!abnormal||qualified.signum()==0,"存在不合格指标，本次送检代表数量须判为不合格，合格数量必须为0");require(!abnormal||!comment.isEmpty(),"存在超标指标，请填写判定及处理说明");require(qualified.compareTo((BigDecimal)r.get("quantity"))==0||!comment.isEmpty(),"存在不合格数量，请填写处理说明");
                jdbc.update("UPDATE jsh_factory_inspection SET workflow_status='approved',qualified_quantity=?,comment=?,confirmed_by=?,confirmed_at=NOW(),version=version+1 WHERE tenant_id=? AND id=?",qualified,comment,u.getId(),u.getTenantId(),id);
            }
        }else if("transfer".equals(action)){
            require(!"finished".equals(r.get("inspection_kind")),"成品请从成品模块整批入库，不能作为半成品交接");
            require("approved".equals(state)&&production.managesWorkshop(u,(int)num(r.get("workshop_no"))),"仅原车间主任可交接已确认的合格数量");Integer stage=b.getInteger("stageNo"),workshop=b.getInteger("workshopNo");require(stage!=null&&stage==num(r.get("stage_no"))+1&&workshop!=null&&workshop>=1&&workshop<=3,"请选择下一工序的接收车间");BigDecimal qty=quantity(b,"quantity");require(qty.signum()>0,"交接数量须大于0");
            BigDecimal used=jdbc.queryForObject("SELECT COALESCE(SUM(quantity),0) FROM jsh_factory_quality_transfer WHERE tenant_id=? AND inspection_id=?",BigDecimal.class,u.getTenantId(),id);require(used.add(qty).compareTo((BigDecimal)r.get("qualified_quantity"))<=0,"交接总量不能超过本单合格数量");
            Map<String,Object> task=task(num(r.get("head_id")),u,true);JSONArray routes=JSONArray.parseArray(task.get("route_json").toString());BigDecimal quota=BigDecimal.ZERO;for(int i=0;i<routes.size();i++){JSONObject route=routes.getJSONObject(i);if(route.getIntValue("lineNo")==num(r.get("line_no"))&&route.getIntValue("stageNo")==stage&&route.getIntValue("workshopNo")==workshop)quota=quota.add(route.getBigDecimal("quantity"));}
            BigDecimal assigned=jdbc.queryForObject("SELECT COALESCE(SUM(quantity),0) FROM jsh_factory_quality_transfer WHERE tenant_id=? AND head_id=? AND line_no=? AND stage_no=? AND workshop_no=?",BigDecimal.class,u.getTenantId(),r.get("head_id"),r.get("line_no"),stage,workshop);require(assigned.add(qty).compareTo(quota)<=0,"交接量超过统筹分配给下一车间工序的数量");
            jdbc.update("INSERT INTO jsh_factory_quality_transfer(tenant_id,inspection_id,head_id,line_no,stage_no,workshop_no,batch_number,quantity,workflow_status,comment,created_by,created_at) VALUES(?,?,?,?,?,?,?,?,'pending',?,?,NOW())",u.getTenantId(),id,r.get("head_id"),r.get("line_no"),stage,workshop,r.get("batch_number"),qty,text(b,"comment",2000,false),u.getId());
            jdbc.update("UPDATE jsh_factory_inspection SET version=version+1 WHERE tenant_id=? AND id=?",u.getTenantId(),id);
        }else if("receive".equals(action)){
            Long transfer=b.getLong("transferId");List<Map<String,Object>> transfers=jdbc.queryForList("SELECT * FROM jsh_factory_quality_transfer WHERE tenant_id=? AND inspection_id=? AND id=? FOR UPDATE",u.getTenantId(),id,transfer);require(!transfers.isEmpty(),"交接记录不存在");Map<String,Object> tr=transfers.get(0);require(production.managesWorkshop(u,(int)num(tr.get("workshop_no")))&&"pending".equals(tr.get("workflow_status")),"仅接收车间主任可确认待接收记录");
            jdbc.update("UPDATE jsh_factory_quality_transfer SET workflow_status='received',received_by=?,received_at=NOW() WHERE tenant_id=? AND id=?",u.getId(),u.getTenantId(),transfer);jdbc.update("UPDATE jsh_factory_inspection SET version=version+1 WHERE tenant_id=? AND id=?",u.getTenantId(),id);
        }else throw new BusinessRunTimeException(409,"无效的质检操作");audit(u,id,action,b);
    }
    @Transactional(rollbackFor=Exception.class)
    public void configureLeaders(JSONObject b)throws Exception{
        User u=actor();require(u.getId().equals(u.getTenantId()),"仅租户负责人可配置放行领导");stock.lockForInventoryMutation();JSONArray ids=b.getJSONArray("leaderIds");require(ids!=null&&!ids.isEmpty()&&ids.size()<=100,"请选择至少一位放行领导");Set<Long> unique=new LinkedHashSet<>();for(int i=0;i<ids.size();i++){Long id=ids.getLong(i);validUser(u,id);unique.add(id);}jdbc.update("INSERT INTO jsh_factory_release_config VALUES(?,?,NOW()) ON DUPLICATE KEY UPDATE leader_ids_json=VALUES(leader_ids_json),updated_at=NOW()",u.getTenantId(),JSON.toJSONString(unique));audit(u,null,"release_config",b);
    }
    @Transactional(rollbackFor=Exception.class)
    public void finishedAction(long id,JSONObject b,HttpServletRequest http)throws Exception{
        User u=actor();stock.lockForInventoryMutation();List<Map<String,Object>> rows=jdbc.queryForList("SELECT * FROM jsh_factory_finished_batch WHERE tenant_id=? AND id=? FOR UPDATE",u.getTenantId(),id);require(!rows.isEmpty(),"成品批次不存在或无权访问");Map<String,Object> batch=rows.get(0);require(b.getInteger("version")!=null&&b.getInteger("version").equals(batch.get("version")),"成品批次已更新，请重新打开");Map<String,Object> qc=inspection(num(batch.get("inspection_id")),u,true);String action=b.getString("action"),comment=text(b,"comment",2000,false);boolean received=batch.get("ledger_head_id")!=null;
        require("approved".equals(qc.get("workflow_status"))&&((BigDecimal)qc.get("qualified_quantity")).compareTo((BigDecimal)batch.get("quantity"))==0,"请先由质检主任确认最终抽样整批合格");
        if("receive".equals(action)){
            require(stock.canManageWarehouse(u)&&!received,"仅仓库人员可确认尚未入库的整批成品");Long depot=b.getLong("depotId");require(depot!=null&&stock.depots(u).containsKey(depot),"请选择有权限的有效仓库");
            List<Map<String,Object>> products=jdbc.queryForList("SELECT m.id,m.unit,m.enable_batch_number,e.bar_code FROM jsh_material m JOIN jsh_material_extend e ON e.material_id=m.id AND e.tenant_id=m.tenant_id WHERE m.tenant_id=? AND m.id=? AND e.bar_code=? AND m.enabled=1 AND m.material_kind='product' AND m.unit='吨' AND e.commodity_unit='吨' AND IFNULL(m.delete_flag,'0')='0' AND IFNULL(e.delete_flag,'0')='0'",u.getTenantId(),batch.get("material_id"),batch.get("bar_code"));require(products.size()==1&&"1".equals(products.get(0).get("enable_batch_number")),"成品须为启用批次管理、基本单位为吨的有效商品");
            require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_depot_item di JOIN jsh_depot_head h ON h.id=di.header_id AND h.tenant_id=di.tenant_id WHERE di.tenant_id=? AND di.material_id=? AND di.batch_number=? AND IFNULL(di.delete_flag,'0')='0' AND IFNULL(h.delete_flag,'0')='0'",Integer.class,u.getTenantId(),batch.get("material_id"),batch.get("batch_number"))==0,"仓库已有该产品同批号收发记录，请核实批号，不能混入另一批库存");
            JSONObject line=new JSONObject();line.put("barCode",batch.get("bar_code"));line.put("unit","吨");line.put("depotId",depot);line.put("batchNumber",batch.get("batch_number"));line.put("operNumber",batch.get("quantity"));for(String key:Arrays.asList("unitPrice","allPrice","taxRate","taxMoney","taxLastMoney"))line.put(key,BigDecimal.ZERO);line.put("remark","成品最终抽样送检#"+qc.get("id"));JSONArray ledger=new JSONArray();ledger.add(line);
            JSONObject head=new JSONObject();String number="CPRK"+id;head.put("number",number);head.put("type","入库");head.put("subType","其它");head.put("status","1");head.put("operTime",java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));head.put("remark","成品整批入库 / 生产任务#"+batch.get("head_id"));head.put("payType","现付");for(String key:Arrays.asList("totalPrice","discountLastMoney","discount","discountMoney","changeAmount","debt","otherMoney"))head.put(key,BigDecimal.ZERO);
            heads.addDepotHeadAndDetail(head.toJSONString(),ledger.toJSONString(),http);Long ledgerId=jdbc.queryForObject("SELECT id FROM jsh_depot_head WHERE tenant_id=? AND number=?",Long.class,u.getTenantId(),number);Long itemId=jdbc.queryForObject("SELECT id FROM jsh_depot_item WHERE tenant_id=? AND header_id=? AND IFNULL(delete_flag,'0')='0'",Long.class,u.getTenantId(),ledgerId);
            jdbc.update("INSERT INTO jsh_factory_batch_quality(item_id,tenant_id,qc_status,qualified_quantity,release_state,return_released,report_number,report_text) VALUES(?,?,'passed',?,'pending',0,?,?)",itemId,u.getTenantId(),batch.get("quantity"),"CPZJ"+qc.get("id"),report(qc));
            jdbc.update("UPDATE jsh_factory_finished_batch SET depot_id=?,ledger_head_id=?,received_by=?,received_at=NOW(),version=version+1 WHERE tenant_id=? AND id=?",depot,ledgerId,u.getId(),u.getTenantId(),id);
        }else if("release".equals(action)||"hold".equals(action)){
            require(releaseLeader(u)&&received&&"pending".equals(batch.get("release_state")),"仅配置的任意一位领导可处理已入库待放行批次");require(!"hold".equals(action)||!comment.isEmpty(),"不予放行须填写处理意见");String next="release".equals(action)?"released":"held";
            jdbc.update("UPDATE jsh_factory_finished_batch SET release_state=?,released_by=?,released_at=NOW(),version=version+1 WHERE tenant_id=? AND id=?",next,u.getId(),u.getTenantId(),id);jdbc.update("UPDATE jsh_factory_batch_quality q JOIN jsh_depot_item di ON di.id=q.item_id AND di.tenant_id=q.tenant_id SET q.release_state=? WHERE q.tenant_id=? AND di.header_id=?",next,u.getTenantId(),batch.get("ledger_head_id"));
        }else if("resubmit".equals(action)){
            require(received&&"held".equals(batch.get("release_state"))&&production.managesWorkshop(u,(int)num(qc.get("workshop_no")))&&!comment.isEmpty(),"仅原车间主任可填写处理结果后重新申请放行");
            jdbc.update("UPDATE jsh_factory_finished_batch SET release_state='pending',released_by=NULL,released_at=NULL,version=version+1 WHERE tenant_id=? AND id=?",u.getTenantId(),id);jdbc.update("UPDATE jsh_factory_batch_quality q JOIN jsh_depot_item di ON di.id=q.item_id AND di.tenant_id=q.tenant_id SET q.release_state='pending' WHERE q.tenant_id=? AND di.header_id=?",u.getTenantId(),batch.get("ledger_head_id"));
        }else throw new BusinessRunTimeException(409,"无效的成品操作");JSONObject event=new JSONObject(b);event.put("quantity",batch.get("quantity"));event.put("batchNumber",batch.get("batch_number"));audit(u,num(qc.get("id")),"finished_"+action,event);
    }
    private String report(Map<String,Object> qc){
        StringBuilder text=new StringBuilder("成品最终抽样质检汇总\n批号：").append(qc.get("batch_number")).append("\n整批数量（吨）：").append(qc.get("quantity")).append("\n确认人账号：").append(qc.get("confirmed_by")).append("\n确认时间：").append(qc.get("confirmed_at")).append("\n判定说明：").append(qc.get("comment"));
        for(Object value:JSONArray.parseArray(qc.get("forms_json").toString())){JSONObject form=(JSONObject)value;text.append("\n\n").append(form.getString("name")).append(" / 录入人：").append(form.getString("actorName"));for(Object raw:form.getJSONArray("items")){JSONObject item=(JSONObject)raw;text.append("\n").append(item.getString("name")).append("：").append(item.get("value")).append(" ").append(item.getString("unit")).append("；标准：").append("text".equals(item.getString("type"))?(item.getString("expected")==null||item.getString("expected").isEmpty()?"人工判定":item.getString("expected")):(item.get("min")==null?"不限":item.get("min"))+"～"+(item.get("max")==null?"不限":item.get("max")));}text.append("\n检测说明：").append(form.getString("comment"));}return text.toString();
    }
}
