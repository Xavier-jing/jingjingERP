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
import java.time.LocalDate;
import java.util.*;

@Service
public class FactoryProductionService {
    @Resource private JdbcTemplate jdbc;
    @Resource private UserService users;
    @Resource private UserBusinessService business;
    @Resource private FactorySalesService sales;
    @Resource private FactoryStockService stock;
    @Resource private FactorySalesGuard changeGuard;

    private void require(boolean valid,String message){if(!valid)throw new BusinessRunTimeException(409,message);}
    private long number(Object value){return ((Number)value).longValue();}
    private String text(JSONObject body,String key,int max,boolean required){String value=body.getString(key);value=value==null?"":value.trim();require(!required || !value.isEmpty(),key+"不能为空");require(value.length()<=max,key+"内容过长");return value;}
    private BigDecimal quantity(JSONObject row,String key){BigDecimal value=row.getBigDecimal(key);require(value!=null && value.signum()>=0 && value.scale()<=6 && value.precision()-value.scale()<=12,"生产数量须为非负数且最多6位小数");return value;}
    private Map<String,Object> config(long tenant){return config(tenant,false);}
    private Map<String,Object> config(long tenant,boolean current){List<Map<String,Object>> rows=jdbc.queryForList("SELECT reviewer_id,coordinator_id,workshop1_director_id,workshop2_director_id,workshop3_director_id FROM jsh_factory_production_config WHERE tenant_id=?"+(current?" FOR UPDATE":""),tenant);return rows.isEmpty()?new HashMap<>():rows.get(0);}
    private boolean role(User user,Map<String,Object> config,String key){return config.get(key)!=null && user.getId().longValue()==number(config.get(key));}
    private List<Integer> workshopNos(User user,Map<String,Object> config){
        List<Integer> result=new ArrayList<>();for(int i=1;i<=3;i++)if(role(user,config,"workshop"+i+"_director_id"))result.add(i);return result;
    }
    boolean coordinates(User user){return role(user,config(user.getTenantId()),"coordinator_id");}
    List<Integer> workshopNos(User user){return workshopNos(user,config(user.getTenantId()));}
    boolean managesWorkshop(User user,int workshop){return workshopNos(user).contains(workshop);}
    private List<Map<String,Object>> workshops(long id,User user,boolean lock){
        return jdbc.queryForList("SELECT workshop_no,workflow_status,accepted_by,accepted_at FROM jsh_factory_workshop_task WHERE tenant_id=? AND head_id=? ORDER BY workshop_no"+(lock?" FOR UPDATE":""),user.getTenantId(),id);
    }
    private User actor() throws Exception {
        User user=users.getCurrentUser();require(user!=null && user.getTenantId()!=null && user.getTenantId()>0,"请使用业务租户账号");
        Map<String,Object> config=config(user.getTenantId());boolean allowed=user.getId().equals(user.getTenantId()) || role(user,config,"reviewer_id") || role(user,config,"coordinator_id") || !workshopNos(user,config).isEmpty();
        Long menu=jdbc.queryForObject("SELECT id FROM jsh_function WHERE url='/factory/production_task' AND enabled=1 AND IFNULL(delete_flag,'0')='0'",Long.class);
        for(UserBusiness binding:business.getBasicData(user.getId().toString(),"UserRole")){
            String id=binding.getValue().replace("[","").replace("]","");
            for(UserBusiness functions:business.getBasicData(id,"RoleFunctions"))if(functions.getValue()!=null && functions.getValue().contains("["+menu+"]"))allowed=true;
        }
        require(allowed,"没有生产任务联系表权限");return user;
    }
    private void validUser(long tenant,Long id){require(id!=null && jdbc.queryForObject("SELECT COUNT(*) FROM jsh_user WHERE tenant_id=? AND id=? AND status=0 AND IFNULL(delete_flag,'0')='0'",Integer.class,tenant,id)==1,"请选择本租户有效人员账号");}
    public Map<String,Object> options() throws Exception {
        User user=actor();Map<String,Object> result=config(user.getTenantId());result.put("currentUserId",user.getId());result.put("canConfigure",user.getId().equals(user.getTenantId()));result.put("isCoordinator",role(user,result,"coordinator_id"));result.put("workshopNos",workshopNos(user,result));
        result.put("users",jdbc.queryForList("SELECT id,username,login_name FROM jsh_user WHERE tenant_id=? AND status=0 AND IFNULL(delete_flag,'0')='0' ORDER BY id",user.getTenantId()));return result;
    }
    @Transactional(rollbackFor=Exception.class)
    public void configure(JSONObject body) throws Exception {
        User user=actor();require(user.getId().equals(user.getTenantId()),"仅租户负责人可配置生产审核人及主任");stock.lockForInventoryMutation();
        Long reviewer=body.getLong("reviewerId"),coordinator=body.getLong("coordinatorId");validUser(user.getTenantId(),reviewer);validUser(user.getTenantId(),coordinator);
        Long[] directors={body.getLong("workshop1DirectorId"),body.getLong("workshop2DirectorId"),body.getLong("workshop3DirectorId")};
        for(Long director:directors)validUser(user.getTenantId(),director);
        require(new HashSet<>(Arrays.asList(directors)).size()==3,"三个车间主任请分别选择不同账号");
        require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_production_task WHERE tenant_id=? AND workflow_status='pending'",Integer.class,user.getTenantId())==0,"存在待审核联系表，请先完成审核再修改配置");
        jdbc.update("INSERT INTO jsh_factory_production_config(tenant_id,reviewer_id,coordinator_id,workshop1_director_id,workshop2_director_id,workshop3_director_id,updated_at) VALUES(?,?,?,?,?,?,NOW()) ON DUPLICATE KEY UPDATE reviewer_id=VALUES(reviewer_id),coordinator_id=VALUES(coordinator_id),workshop1_director_id=VALUES(workshop1_director_id),workshop2_director_id=VALUES(workshop2_director_id),workshop3_director_id=VALUES(workshop3_director_id),updated_at=NOW()",user.getTenantId(),reviewer,coordinator,directors[0],directors[1],directors[2]);
    }
    private Map<String,Object> order(long id,User user,boolean lock){
        if(lock)changeGuard.checkProduction(id,user.getTenantId());
        List<Map<String,Object>> rows=jdbc.queryForList("SELECT f.head_id,f.created_by,f.workflow_status,f.delivery_date,f.requirements,h.number order_number,s.supplier customer_name FROM jsh_factory_sales_order f JOIN jsh_depot_head h ON h.id=f.head_id AND h.tenant_id=f.tenant_id LEFT JOIN jsh_supplier s ON s.id=h.organ_id AND s.tenant_id=f.tenant_id WHERE f.head_id=? AND f.tenant_id=? AND IFNULL(h.delete_flag,'0')='0'"+(lock?" FOR UPDATE":""),id,user.getTenantId());
        require(!rows.isEmpty(),"销售订单不存在或无权访问");Map<String,Object> order=rows.get(0);require("approved".equals(order.get("workflow_status")),"销售订单需先通过领导审核");return order;
    }
    private void checked(long id,User user){require(!jdbc.queryForList("SELECT head_id FROM jsh_factory_stock_check WHERE head_id=? AND tenant_id=?"+(org.springframework.transaction.support.TransactionSynchronizationManager.isActualTransactionActive()?" FOR UPDATE":""),id,user.getTenantId()).isEmpty(),"请先由仓库完成库存核查并确认缺口");}
    private List<Map<String,Object>> taskRows(long id,User user,boolean lock){return jdbc.queryForList("SELECT * FROM jsh_factory_production_task WHERE head_id=? AND tenant_id=?"+(lock?" FOR UPDATE":""),id,user.getTenantId());}
    private Map<String,Object> task(long id,User user,boolean lock){List<Map<String,Object>> rows=taskRows(id,user,lock);require(!rows.isEmpty(),"生产联系表不存在或无权访问");return rows.get(0);}
    private void version(Map<String,Object> task,JSONObject body){require(body.getInteger("version")!=null && body.getInteger("version").equals(task.get("version")),"联系表已被更新，请重新打开后操作");}
    private boolean gapChanged(JSONArray saved,JSONArray current){
        if(saved.size()!=current.size())return true;
        for(int i=0;i<saved.size();i++)if(saved.getJSONObject(i).getBigDecimal("reserved").compareTo(current.getJSONObject(i).getBigDecimal("reserved"))!=0)return true;
        return false;
    }
    public Map<String,Object> source(long id) throws Exception {
        User user=actor();Map<String,Object> result=order(id,user,false);List<Map<String,Object>> tasks=taskRows(id,user,false);if(tasks.isEmpty() || "cancelled".equals(tasks.get(0).get("workflow_status")))checked(id,user);result.put("stock",stock.salesSummary(id,user));result.put("task",tasks);return result;
    }
    public Map<String,Object> list(String keyword,String state,int page,int size) throws Exception {
        User user=actor();require(page>0 && page<=100000 && size>0 && size<=100 && keyword.length()<=100,"查询参数无效");
        String from=" FROM jsh_factory_production_task t JOIN jsh_depot_head h ON h.id=t.head_id AND h.tenant_id=t.tenant_id JOIN jsh_factory_sales_order f ON f.head_id=t.head_id AND f.tenant_id=t.tenant_id LEFT JOIN jsh_supplier s ON s.id=h.organ_id AND s.tenant_id=t.tenant_id WHERE t.tenant_id=? AND IFNULL(h.delete_flag,'0')='0' AND (t.number LIKE ? OR h.number LIKE ? OR s.supplier LIKE ?)";
        List<Object> args=new ArrayList<>(Arrays.asList(user.getTenantId(),"%"+keyword+"%","%"+keyword+"%","%"+keyword+"%"));if("execution".equals(state)){from+=" AND EXISTS(SELECT 1 FROM jsh_factory_workshop_task ew WHERE ew.tenant_id=t.tenant_id AND ew.head_id=t.head_id AND ew.workflow_status='scheduled')";}else if(!state.isEmpty()){from+=" AND t.workflow_status=?";args.add(state);}
        List<Integer> mine=workshopNos(user);Map<String,Object> ownConfig=config(user.getTenantId());
        if(!mine.isEmpty() && !user.getId().equals(user.getTenantId()) && !role(user,ownConfig,"coordinator_id") && !role(user,ownConfig,"reviewer_id")){
            from+=" AND (f.created_by=? OR EXISTS(SELECT 1 FROM jsh_factory_workshop_task w WHERE w.tenant_id=t.tenant_id AND w.head_id=t.head_id AND w.workshop_no IN("+String.join(",",Collections.nCopies(mine.size(),"?"))+")))";args.add(user.getId());args.addAll(mine);
        }
        Map<String,Object> result=new HashMap<>();result.put("total",jdbc.queryForObject("SELECT COUNT(*)"+from,Long.class,args.toArray()));args.add(size);args.add((page-1)*size);
        result.put("rows",jdbc.queryForList("SELECT t.head_id,t.number,t.workflow_status,t.version,t.created_by,t.updated_at,t.task_time,h.number order_number,s.supplier customer_name,f.delivery_date"+from+" ORDER BY t.head_id DESC LIMIT ? OFFSET ?",args.toArray()));
        for(Map<String,Object> row:(List<Map<String,Object>>)result.get("rows"))row.put("workshops",workshops(number(row.get("head_id")),user,false));return result;
    }
    public Map<String,Object> detail(long id) throws Exception {
        User user=actor();Map<String,Object> result=task(id,user,false);List<Map<String,Object>> order=jdbc.queryForList("SELECT h.number order_number,s.supplier customer_name,f.delivery_date,f.workflow_status order_state FROM jsh_depot_head h JOIN jsh_factory_sales_order f ON f.head_id=h.id AND f.tenant_id=h.tenant_id LEFT JOIN jsh_supplier s ON s.id=h.organ_id AND s.tenant_id=h.tenant_id WHERE h.id=? AND h.tenant_id=? AND IFNULL(h.delete_flag,'0')='0'",id,user.getTenantId());require(!order.isEmpty(),"关联订单不存在");result.putAll(order.get(0));
        JSONArray lines=JSONArray.parseArray(result.remove("lines_json").toString());result.put("lines",lines);result.put("plan",JSONArray.parseArray(result.remove("plan_json").toString()));result.put("routes",JSONArray.parseArray(result.remove("route_json").toString()));result.put("workshops",workshops(id,user,false));Map<String,Object> current=stock.salesSummary(id,user);result.put("stock",current);result.put("gapChanged",gapChanged(lines,(JSONArray)current.get("lines")));
        result.put("orderChanges",jdbc.queryForList("SELECT id,kind,workflow_status FROM jsh_factory_order_change WHERE tenant_id=? AND head_id=? ORDER BY id DESC LIMIT 1",user.getTenantId(),id));
        result.put("receivedBatches",jdbc.queryForList("SELECT line_no,stage_no,workshop_no,batch_number,SUM(quantity) received FROM jsh_factory_quality_transfer WHERE tenant_id=? AND head_id=? AND workflow_status='received' GROUP BY line_no,stage_no,workshop_no,batch_number ORDER BY batch_number",user.getTenantId(),id));
        result.put("reportLocks",jdbc.queryForList("SELECT DISTINCT line_no,stage_no,workshop_no,batch_number,inspection_kind FROM jsh_factory_inspection WHERE tenant_id=? AND head_id=?",user.getTenantId(),id));
        result.put("starts",jdbc.queryForList("SELECT * FROM jsh_factory_production_start WHERE tenant_id=? AND head_id=? ORDER BY workshop_no,line_no,stage_no",user.getTenantId(),id));result.put("reports",jdbc.queryForList("SELECT * FROM jsh_factory_production_report WHERE tenant_id=? AND head_id=? ORDER BY report_date DESC,id DESC",user.getTenantId(),id));result.put("materials",jdbc.queryForList("SELECT id,number,kind,workflow_status,line_no,stage_no,workshop_no,ledger_head_id FROM jsh_factory_material_request WHERE tenant_id=? AND task_head_id=? ORDER BY id DESC",user.getTenantId(),id));result.put("history",jdbc.queryForList("SELECT action,actor_name,comment,payload_json,created_at FROM jsh_factory_production_history WHERE head_id=? AND tenant_id=? ORDER BY id DESC",id,user.getTenantId()));return result;
    }
    private void audit(long id,User user,String action,String comment,Object payload){
        jdbc.update("INSERT INTO jsh_factory_production_history(tenant_id,head_id,action,actor_id,actor_name,comment,payload_json,created_at) VALUES(?,?,?,?,?,?,?,NOW())",user.getTenantId(),id,action,user.getId(),user.getUsername(),comment,JSON.toJSONString(payload));
        jdbc.update("INSERT INTO jsh_factory_sales_history(tenant_id,head_id,action,actor_id,actor_name,comment,created_at) VALUES(?,?,?,?,?,?,NOW())",user.getTenantId(),id,"production_"+action,user.getId(),user.getUsername(),comment);
    }
    @Transactional(rollbackFor=Exception.class)
    public void save(long id,JSONObject body) throws Exception {
        User user=sales.actor();stock.lockForInventoryMutation();Map<String,Object> order=order(id,user,true);require(user.getId().longValue()==number(order.get("created_by")),"仅订单创建人可开立或修改联系表");checked(id,user);
        List<Map<String,Object>> tasks=taskRows(id,user,true);Map<String,Object> old=tasks.isEmpty()?null:tasks.get(0);
        if(old!=null){version(old,body);require(Arrays.asList("draft","returned","cancelled").contains(old.get("workflow_status")),"请先撤回联系表，已接单或已排产的任务需与主任协调");}
        JSONArray current=stock.productionLines(id,user),input=body.getJSONArray("lines");require(input!=null && input.size()==current.size(),"产品明细与销售订单不一致，请重新打开");
        JSONArray lines=new JSONArray();boolean positive=false;
        for(int i=0;i<current.size();i++){
            JSONObject row=input.getJSONObject(i),line=current.getJSONObject(i);require(row.getInteger("lineNo")!=null && row.getIntValue("lineNo")==i,"产品行顺序无效");BigDecimal qty=quantity(row,"productionQuantity");String reason=text(row,"adjustReason",500,false);
            require(qty.compareTo(line.getBigDecimal("missing"))==0 || !reason.isEmpty(),"第"+(i+1)+"行生产数量与当前缺口不同，请填写调整原因");line.put("productionQuantity",qty);line.put("adjustReason",reason);lines.add(line);positive|=qty.signum()>0;
        }
        require(positive,"整单没有需要生产的数量，无需开生产联系表");String requirements=text(body,"requirements",4000,false),taskTime=text(body,"taskTime",16,true);
        try{require(taskTime.length()==16,"任务时间须精确到分钟");java.time.LocalDateTime.parse(taskTime);}catch(java.time.format.DateTimeParseException e){throw new BusinessRunTimeException(409,"任务时间格式无效，请选择日期和时间");}
        if(old==null)jdbc.update("INSERT INTO jsh_factory_production_task(head_id,tenant_id,number,workflow_status,version,requirements,lines_json,plan_json,created_by,created_at,updated_at,task_time,route_json) VALUES(?,?,?,'draft',1,?,?,'[]',?,NOW(),NOW(),?,'[]')",id,user.getTenantId(),"SCLX"+LocalDate.now().toString().replace("-","")+UUID.randomUUID().toString().replace("-","").substring(0,12).toUpperCase(),requirements,lines.toJSONString(),user.getId(),taskTime);
        else jdbc.update("UPDATE jsh_factory_production_task SET workflow_status='draft',version=version+1,requirements=?,lines_json=?,task_time=?,plan_json='[]',route_json='[]',updated_at=NOW() WHERE head_id=? AND tenant_id=?",requirements,lines.toJSONString(),taskTime,id,user.getTenantId());
        JSONObject saved=new JSONObject();saved.put("taskTime",taskTime);saved.put("requirements",requirements);saved.put("lines",lines);audit(id,user,old==null?"create":"edit","保存生产任务联系表",saved);
    }
    @Transactional(rollbackFor=Exception.class)
    public void action(long id,JSONObject body) throws Exception {
        User user=actor();stock.lockForInventoryMutation();order(id,user,true);Map<String,Object> task=task(id,user,true);version(task,body);String action=body.getString("action"),state=task.get("workflow_status").toString(),next=null,comment=text(body,"comment",2000,false);Map<String,Object> config=config(user.getTenantId(),true);boolean owner=user.getId().longValue()==number(task.get("created_by"));
        if(Arrays.asList("submit","approve","accept").contains(action))require(task.get("task_time")!=null && !task.get("task_time").toString().isEmpty(),"请先由销售补充任务时间");
        if("submit".equals(action)){
            require(owner && Arrays.asList("draft","returned").contains(state),"仅创建人可提交草稿或退回联系表");checked(id,user);validUser(user.getTenantId(),config.get("reviewer_id")==null?null:number(config.get("reviewer_id")));validUser(user.getTenantId(),config.get("coordinator_id")==null?null:number(config.get("coordinator_id")));require(!role(user,config,"reviewer_id"),"创建人与审核人必须使用不同账号");
            require(!gapChanged(JSONArray.parseArray(task.get("lines_json").toString()),stock.productionLines(id,user)),"仓库预留已变化，请重新编辑并保存联系表后提交");next="pending";
        }else if("approve".equals(action)||"return".equals(action)){
            require("pending".equals(state) && role(user,config,"reviewer_id") && !owner,"仅生产固定审核人可审核待审核联系表");require(!"return".equals(action) || !comment.isEmpty(),"请填写退回原因");
            if("approve".equals(action)){checked(id,user);require(!gapChanged(JSONArray.parseArray(task.get("lines_json").toString()),stock.productionLines(id,user)),"仓库预留已变化，请退回销售重新核对");}next="approve".equals(action)?"approved":"returned";
        }else if("unapprove".equals(action)){
            require("approved".equals(state) && role(user,config,"reviewer_id"),"仅生产固定审核人可反审核尚未下发车间的已审核联系表");
            require(!comment.isEmpty(),"请填写反审核原因");
            requireBeforeDispatch(id,user,task);
            next="draft";
        }else if("accept".equals(action)){
            Integer workshop=body.getInteger("workshopNo");require(workshop!=null && workshop>=1 && workshop<=3 && role(user,config,"workshop"+workshop+"_director_id"),"仅对应车间主任可接收本人车间任务");
            require(Arrays.asList("distributed","scheduled").contains(state),"请先由生产统筹分配车间");
            List<Map<String,Object>> assigned=jdbc.queryForList("SELECT workflow_status FROM jsh_factory_workshop_task WHERE tenant_id=? AND head_id=? AND workshop_no=? FOR UPDATE",user.getTenantId(),id,workshop);
            require(!assigned.isEmpty() && "pending".equals(assigned.get(0).get("workflow_status")),"该车间没有待接单任务");confirmGap(task,id,user,body,comment);
            jdbc.update("UPDATE jsh_factory_workshop_task SET workflow_status='accepted',accepted_by=?,accepted_at=NOW(),updated_at=NOW() WHERE tenant_id=? AND head_id=? AND workshop_no=?",user.getId(),user.getTenantId(),id,workshop);
            jdbc.update("UPDATE jsh_factory_production_task SET version=version+1,updated_at=NOW() WHERE head_id=? AND tenant_id=?",id,user.getTenantId());audit(id,user,"accept","车间"+workshop+"接单；"+comment,Collections.singletonMap("workshopNo",workshop));return;
        }else if("withdraw".equals(action)||"cancel".equals(action)){
            require(owner && Arrays.asList("draft","returned","pending","approved").contains(state),"仅创建人可撤回或撤销尚未接单的任务，已接单请与主任协调");next="cancel".equals(action)?"cancelled":"draft";
        }else throw new BusinessRunTimeException(409,"不支持的操作");
        jdbc.update("UPDATE jsh_factory_production_task SET workflow_status=?,version=version+1,updated_at=NOW() WHERE head_id=? AND tenant_id=?",next,id,user.getTenantId());audit(id,user,action,comment.isEmpty()?"生产任务状态更新":comment,Collections.singletonMap("state",next));
    }
    private void requireBeforeDispatch(long id,User user,Map<String,Object> task){
        require(JSONArray.parseArray(task.get("route_json").toString()).isEmpty() && JSONArray.parseArray(task.get("plan_json").toString()).isEmpty(),"联系表已有工序分配或排班，不能反审核");
        long tenant=user.getTenantId();
        for(String table:Arrays.asList("jsh_factory_workshop_task","jsh_factory_production_start","jsh_factory_production_report","jsh_factory_inspection","jsh_factory_quality_transfer","jsh_factory_finished_batch")){
            require(jdbc.queryForObject("SELECT COUNT(*) FROM "+table+" WHERE tenant_id=? AND head_id=?",Integer.class,tenant,id)==0,"联系表已有车间任务或执行记录，不能反审核");
        }
        require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_material_request WHERE tenant_id=? AND task_head_id=?",Integer.class,tenant,id)==0,"联系表已有领补退料记录，不能反审核");
        require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_production_history WHERE tenant_id=? AND head_id=? AND action='distribute'",Integer.class,tenant,id)==0,"联系表已有下发车间记录，不能反审核");
    }

    private void confirmGap(Map<String,Object> task,long id,User user,JSONObject body,String note){
        boolean changed=gapChanged(JSONArray.parseArray(task.get("lines_json").toString()),stock.productionLines(id,user));
        require(!changed || Boolean.TRUE.equals(body.getBoolean("confirmedGap")) && !note.isEmpty(),"库存缺口已变化，请与销售协调后勾选确认并填写说明；生产数量不会自动修改");
    }
    private String routeKey(JSONObject row){return row.getIntValue("lineNo")+"|"+row.getIntValue("stageNo")+"|"+row.getIntValue("workshopNo");}
    private Map<String,BigDecimal> routeTotals(JSONArray rows,Integer workshop){
        Map<String,BigDecimal> result=new TreeMap<>();for(int i=0;i<rows.size();i++){JSONObject row=rows.getJSONObject(i);if(workshop!=null && row.getIntValue("workshopNo")!=workshop)continue;String key=routeKey(row);result.put(key,result.getOrDefault(key,BigDecimal.ZERO).add(row.getBigDecimal("quantity")));}return result;
    }
    private boolean sameRoutes(Map<String,BigDecimal> a,Map<String,BigDecimal> b){if(!a.keySet().equals(b.keySet()))return false;for(String key:a.keySet())if(a.get(key).compareTo(b.get(key))!=0)return false;return true;}
    private void updateOverall(long id,User user){
        List<Map<String,Object>> current=workshops(id,user,true);
        boolean finished=!current.isEmpty();for(Map<String,Object> row:current)finished&="scheduled".equals(row.get("workflow_status"));
        jdbc.update("UPDATE jsh_factory_production_task SET workflow_status=?,version=version+1,updated_at=NOW() WHERE head_id=? AND tenant_id=?",finished?"scheduled":"distributed",id,user.getTenantId());
    }
    @Transactional(rollbackFor=Exception.class)
    public void distribute(long id,JSONObject body) throws Exception {
        User user=actor();stock.lockForInventoryMutation();order(id,user,true);Map<String,Object> task=task(id,user,true),config=config(user.getTenantId(),true);version(task,body);
        require(role(user,config,"coordinator_id") && Arrays.asList("approved","distributed","scheduled").contains(task.get("workflow_status")),"仅生产统筹可分配已审核任务的车间和工序");
        String comment=text(body,"comment",2000,false);confirmGap(task,id,user,body,comment);JSONArray input=body.getJSONArray("routes"),routes=new JSONArray(),lines=JSONArray.parseArray(task.get("lines_json").toString());require(input!=null && !input.isEmpty() && input.size()<=300,"请填写1至300行产品车间分配");
        Map<Integer,Map<Integer,BigDecimal>> totals=new HashMap<>();Set<Integer> used=new HashSet<>();
        for(int i=0;i<input.size();i++){
            JSONObject raw=input.getJSONObject(i);Integer line=raw.getInteger("lineNo"),stage=raw.getInteger("stageNo"),workshop=raw.getInteger("workshopNo");require(line!=null && line>=0 && line<lines.size() && lines.getJSONObject(line).getBigDecimal("productionQuantity").signum()>0,"请选择需要生产的产品");require(stage!=null && stage>=1 && stage<=10 && workshop!=null && workshop>=1 && workshop<=3,"工序须为1至10，车间须为1至3");validUser(user.getTenantId(),config.get("workshop"+workshop+"_director_id")==null?null:number(config.get("workshop"+workshop+"_director_id")));BigDecimal qty=quantity(raw,"quantity");require(qty.signum()>0,"分配数量必须大于0");
            JSONObject row=new JSONObject();row.put("lineNo",line);row.put("stageNo",stage);row.put("workshopNo",workshop);row.put("quantity",qty);routes.add(row);used.add(workshop);Map<Integer,BigDecimal> stages=totals.computeIfAbsent(line,k->new HashMap<>());stages.put(stage,stages.getOrDefault(stage,BigDecimal.ZERO).add(qty));
        }
        for(int i=0;i<lines.size();i++){
            BigDecimal qty=lines.getJSONObject(i).getBigDecimal("productionQuantity");if(qty.signum()==0)continue;Map<Integer,BigDecimal> stages=totals.get(i);require(stages!=null,"第"+(i+1)+"行产品尚未分配车间");for(int stage=1;stage<=Collections.max(stages.keySet());stage++)require(stages.containsKey(stage) && stages.get(stage).compareTo(qty)==0,"第"+(i+1)+"行各工序总量须等于生产量，工序须从1连续填写");
        }
        JSONArray oldRoutes=JSONArray.parseArray(task.get("route_json").toString()),oldPlan=JSONArray.parseArray(task.get("plan_json").toString()),keptPlan=new JSONArray();Map<Integer,String> states=new HashMap<>();for(Map<String,Object> row:workshops(id,user,true))states.put((int)number(row.get("workshop_no")),row.get("workflow_status").toString());
        for(int workshop=1;workshop<=3;workshop++){
            boolean changed=!sameRoutes(routeTotals(oldRoutes,workshop),routeTotals(routes,workshop));if(!changed)continue;
            require(!states.containsKey(workshop) || "pending".equals(states.get(workshop)),"车间"+workshop+"已经接单或排班，不能直接修改其分配数量和路线");
            require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_material_request WHERE tenant_id=? AND task_head_id=? AND workshop_no=? AND workflow_status<>'cancelled'",Integer.class,user.getTenantId(),id,workshop)==0,"该车间已有领补退料记录，不能直接修改路线");
            if(!used.contains(workshop))jdbc.update("DELETE FROM jsh_factory_workshop_task WHERE tenant_id=? AND head_id=? AND workshop_no=?",user.getTenantId(),id,workshop);
        }
        for(int i=0;i<oldPlan.size();i++){JSONObject row=oldPlan.getJSONObject(i);int workshop=row.getIntValue("workshopNo");if(sameRoutes(routeTotals(oldRoutes,workshop),routeTotals(routes,workshop)))keptPlan.add(row);}
        for(Integer workshop:used)jdbc.update("INSERT IGNORE INTO jsh_factory_workshop_task(tenant_id,head_id,workshop_no,workflow_status,updated_at) VALUES(?,?,?,'pending',NOW())",user.getTenantId(),id,workshop);
        jdbc.update("UPDATE jsh_factory_production_task SET route_json=?,plan_json=? WHERE head_id=? AND tenant_id=?",routes.toJSONString(),keptPlan.toJSONString(),id,user.getTenantId());updateOverall(id,user);audit(id,user,"distribute",comment.isEmpty()?"生产统筹分配产品、工序及车间":comment,routes);
    }
    @Transactional(rollbackFor=Exception.class)
    public void plan(long id,JSONObject body) throws Exception {
        User user=actor();stock.lockForInventoryMutation();order(id,user,true);Map<String,Object> task=task(id,user,true),config=config(user.getTenantId(),true);version(task,body);Integer workshop=body.getInteger("workshopNo");require(workshop!=null && workshop>=1 && workshop<=3 && role(user,config,"workshop"+workshop+"_director_id"),"仅对应车间主任可安排本人车间的人员和班次");
        List<Map<String,Object>> own=jdbc.queryForList("SELECT workflow_status FROM jsh_factory_workshop_task WHERE tenant_id=? AND head_id=? AND workshop_no=? FOR UPDATE",user.getTenantId(),id,workshop);require(!own.isEmpty() && Arrays.asList("accepted","scheduled").contains(own.get(0).get("workflow_status")),"请先接收本人车间任务");String comment=text(body,"comment",2000,false);confirmGap(task,id,user,body,comment);
        require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_production_start WHERE tenant_id=? AND head_id=? AND workshop_no=?",Integer.class,user.getTenantId(),id,workshop)==0,"本车间已经实际开工，不能直接覆盖原排班");
        JSONArray input=body.getJSONArray("plan"),plan=new JSONArray(),routes=JSONArray.parseArray(task.get("route_json").toString());require(input!=null && !input.isEmpty() && input.size()<=300,"请填写本人车间的排班");Map<String,BigDecimal> quotas=routeTotals(routes,workshop);
        for(int i=0;i<input.size();i++){
            JSONObject raw=input.getJSONObject(i);require(raw.getInteger("lineNo")!=null && raw.getInteger("stageNo")!=null && workshop.equals(raw.getInteger("workshopNo")) && quotas.containsKey(routeKey(raw)),"不能修改其他车间或统筹未分配的工序");BigDecimal qty=quantity(raw,"quantity");require(qty.signum()>0,"排班数量必须大于0");String start=text(raw,"startDate",10,true),end=text(raw,"endDate",10,true);try{require(!LocalDate.parse(start).isAfter(LocalDate.parse(end)),"计划结束日期不能早于开工日期");}catch(java.time.format.DateTimeParseException e){throw new BusinessRunTimeException(409,"排班日期格式无效");}
            JSONObject row=new JSONObject();row.put("lineNo",raw.getInteger("lineNo"));row.put("stageNo",raw.getInteger("stageNo"));row.put("workshopNo",workshop);row.put("quantity",qty);row.put("startDate",start);row.put("endDate",end);row.put("leader",text(raw,"leader",100,true));row.put("staff",text(raw,"staff",1000,true));row.put("shift",text(raw,"shift",200,true));plan.add(row);
        }
        require(sameRoutes(quotas,routeTotals(plan,workshop)),"本人车间各产品工序的排班数量须等于统筹分配数量");JSONArray merged=new JSONArray(),old=JSONArray.parseArray(task.get("plan_json").toString());for(int i=0;i<old.size();i++)if(old.getJSONObject(i).getIntValue("workshopNo")!=workshop)merged.add(old.getJSONObject(i));merged.addAll(plan);
        jdbc.update("UPDATE jsh_factory_production_task SET plan_json=? WHERE head_id=? AND tenant_id=?",merged.toJSONString(),id,user.getTenantId());jdbc.update("UPDATE jsh_factory_workshop_task SET workflow_status='scheduled',updated_at=NOW() WHERE tenant_id=? AND head_id=? AND workshop_no=?",user.getTenantId(),id,workshop);updateOverall(id,user);audit(id,user,"schedule","车间"+workshop+"主任排班；"+comment,plan);
    }
    @Transactional(rollbackFor=Exception.class)
    public void execution(long id,JSONObject body) throws Exception {
        User user=actor();stock.lockForInventoryMutation();order(id,user,true);Map<String,Object> task=task(id,user,true);version(task,body);
        Integer workshop=body.getInteger("workshopNo"),line=body.getInteger("lineNo"),stage=body.getInteger("stageNo");
        require(workshop!=null && workshopNos(user,config(user.getTenantId(),true)).contains(workshop),"仅对应车间主任可记录实际生产");
        require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_workshop_task WHERE tenant_id=? AND head_id=? AND workshop_no=? AND workflow_status='scheduled'",Integer.class,user.getTenantId(),id,workshop)==1,"请先完成本车间接单排班");
        JSONObject route=new JSONObject();route.put("lineNo",line);route.put("stageNo",stage);route.put("workshopNo",workshop);
        Map<String,BigDecimal> quotas=routeTotals(JSONArray.parseArray(task.get("route_json").toString()),workshop);require(line!=null && stage!=null && quotas.containsKey(routeKey(route)),"请选择本车间已分配的产品工序");
        String action=body.getString("action"),comment=text(body,"comment",2000,false);
        List<Map<String,Object>> starts=jdbc.queryForList("SELECT * FROM jsh_factory_production_start WHERE tenant_id=? AND head_id=? AND workshop_no=? AND line_no=? AND stage_no=? FOR UPDATE",user.getTenantId(),id,workshop,line,stage);
        if("start".equals(action)){
            require(starts.isEmpty(),"该产品工序已经开工，请刷新查看");require(body.getBooleanValue("materialsReady"),"请确认原料已齐套");
            if(stage>1)require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_quality_transfer WHERE tenant_id=? AND head_id=? AND line_no=? AND stage_no=? AND workshop_no=? AND workflow_status='received'",Integer.class,user.getTenantId(),id,line,stage,workshop)>0,"请先接收上一工序质检合格的半成品");
            String actual=text(body,"actualStart",16,true);java.time.LocalDateTime time;
            try{time=java.time.LocalDateTime.parse(actual);}catch(java.time.format.DateTimeParseException e){throw new BusinessRunTimeException(409,"实际开工时间格式无效");}
            require(!time.isAfter(java.time.LocalDateTime.now()),"实际开工时间不能晚于当前时间");
            jdbc.update("INSERT INTO jsh_factory_production_start(tenant_id,head_id,workshop_no,line_no,stage_no,actual_start,actor_id,actor_name,comment) VALUES(?,?,?,?,?,?,?,?,?)",user.getTenantId(),id,workshop,line,stage,java.sql.Timestamp.valueOf(time),user.getId(),user.getUsername(),comment);
        }else{
            boolean correcting="correctReport".equals(action);
            require("report".equals(action)||correcting,"无效的生产操作");require(!starts.isEmpty(),"请先确认该产品工序开工");
            Map<String,Object> before=null;long reportId=0;String reason="";
            if(correcting){
                Long selected=body.getLong("reportId");require(selected!=null,"请选择需要更正的日报");
                List<Map<String,Object>> reports=jdbc.queryForList("SELECT * FROM jsh_factory_production_report WHERE tenant_id=? AND head_id=? AND id=? AND workshop_no=? AND line_no=? AND stage_no=? FOR UPDATE",user.getTenantId(),id,selected,workshop,line,stage);
                require(!reports.isEmpty(),"日报不存在或不属于当前车间产品工序");before=reports.get(0);reportId=selected;reason=text(body,"reason",2000,true);
                requireReportEditable(id,line,stage,workshop,before.get("batch_number").toString(),user);
            }
            String day=text(body,"reportDate",10,true),batch=text(body,"batchNumber",100,true);LocalDate date;
            if(correcting)requireReportEditable(id,line,stage,workshop,batch,user);
            require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_finished_batch WHERE tenant_id=? AND head_id=? AND line_no=? AND stage_no=? AND batch_number=?",Integer.class,user.getTenantId(),id,line,stage,batch)==0,"该批次已最终送检，整批数量已固定，不能继续追加该批成品产出");
            try{date=LocalDate.parse(day);}catch(java.time.format.DateTimeParseException e){throw new BusinessRunTimeException(409,"日报日期格式无效");}
            LocalDate start=((java.time.LocalDateTime)starts.get(0).get("actual_start")).toLocalDate();require(!date.isBefore(start) && !date.isAfter(LocalDate.now()),"日报日期须在实际开工日至今天之间");
            BigDecimal input=quantity(body,"inputQuantity"),output=quantity(body,"outputQuantity"),loss=quantity(body,"lossQuantity");require(input.signum()>0 && input.compareTo(output.add(loss))>=0,"投入须大于0，产出与损耗合计不能超过投入");
            if(stage>1){
                BigDecimal received=jdbc.queryForObject("SELECT COALESCE(SUM(quantity),0) FROM jsh_factory_quality_transfer WHERE tenant_id=? AND head_id=? AND line_no=? AND stage_no=? AND workshop_no=? AND batch_number=? AND workflow_status='received' FOR UPDATE",BigDecimal.class,user.getTenantId(),id,line,stage,workshop,batch);
                BigDecimal used=jdbc.queryForObject("SELECT COALESCE(SUM(input_quantity),0) FROM jsh_factory_production_report WHERE tenant_id=? AND head_id=? AND line_no=? AND stage_no=? AND workshop_no=? AND batch_number=? AND id<>? FOR UPDATE",BigDecimal.class,user.getTenantId(),id,line,stage,workshop,batch,reportId);
                require(used.add(input).compareTo(received)<=0,"该批次累计投入不能超过上一工序已确认接收数量，请核对批号及交接记录");
            }
            require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_production_report WHERE tenant_id=? AND head_id=? AND workshop_no=? AND line_no=? AND stage_no=? AND report_date=? AND batch_number=? AND id<>? FOR UPDATE",Integer.class,user.getTenantId(),id,workshop,line,stage,day,batch,reportId)==0,"同日同工序同批号日报已存在，请勿重复录入");
            BigDecimal total=jdbc.queryForObject("SELECT COALESCE(SUM(output_quantity),0) FROM jsh_factory_production_report WHERE tenant_id=? AND head_id=? AND workshop_no=? AND line_no=? AND stage_no=? AND id<>? FOR UPDATE",BigDecimal.class,user.getTenantId(),id,workshop,line,stage,reportId);
            require(total.add(output).compareTo(quotas.get(routeKey(route)))<=0,"累计产出不能超过该车间工序分配数量");
            if(correcting){
                jdbc.update("UPDATE jsh_factory_production_report SET report_date=?,batch_number=?,input_quantity=?,output_quantity=?,loss_quantity=?,comment=? WHERE tenant_id=? AND head_id=? AND id=?",day,batch,input,output,loss,comment,user.getTenantId(),id,reportId);
                Map<String,Object> after=jdbc.queryForMap("SELECT * FROM jsh_factory_production_report WHERE tenant_id=? AND head_id=? AND id=?",user.getTenantId(),id,reportId);
                before.put("report_date",before.get("report_date").toString());after.put("report_date",after.get("report_date").toString());
                JSONObject change=new JSONObject();change.put("reportId",reportId);change.put("reason",reason);change.put("before",before);change.put("after",after);body=change;comment=reason;
            }else jdbc.update("INSERT INTO jsh_factory_production_report(tenant_id,head_id,workshop_no,line_no,stage_no,report_date,batch_number,input_quantity,output_quantity,loss_quantity,comment,actor_id,actor_name,created_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,NOW())",user.getTenantId(),id,workshop,line,stage,day,batch,input,output,loss,comment,user.getId(),user.getUsername());
        }
        jdbc.update("UPDATE jsh_factory_production_task SET version=version+1,updated_at=NOW() WHERE tenant_id=? AND head_id=?",user.getTenantId(),id);audit(id,user,"correctReport".equals(action)?"report_correct":"execution_"+action,comment,body);
    }

    private void requireReportEditable(long head,int line,int stage,int workshop,String batch,User user){
        // Inspection represents the whole batch output, not an individual day's report.
        require(jdbc.queryForList("SELECT id FROM jsh_factory_inspection WHERE tenant_id=? AND head_id=? AND line_no=? AND stage_no=? AND batch_number=? AND (workshop_no=? OR inspection_kind='finished') FOR UPDATE",Long.class,user.getTenantId(),head,line,stage,batch,workshop).isEmpty(),"该日报批次已送检或进入工序交接，不能直接更正");
        require(jdbc.queryForList("SELECT id FROM jsh_factory_finished_batch WHERE tenant_id=? AND head_id=? AND line_no=? AND stage_no=? AND batch_number=? FOR UPDATE",Long.class,user.getTenantId(),head,line,stage,batch).isEmpty(),"该日报批次已最终送检或成品入库，不能直接更正");
    }

}
