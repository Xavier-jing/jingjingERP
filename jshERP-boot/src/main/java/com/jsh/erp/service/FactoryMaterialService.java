package com.jsh.erp.service;

import com.alibaba.fastjson.*;
import com.jsh.erp.datasource.entities.User;
import com.jsh.erp.datasource.entities.UserBusiness;
import com.jsh.erp.exception.BusinessRunTimeException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.annotation.Isolation;
import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import java.math.*;
import java.time.*;
import java.util.*;

@Service
public class FactoryMaterialService {
 @Resource private JdbcTemplate jdbc;
 @Resource private UserService users;
 @Resource private UserBusinessService business;
 @Resource private FactoryStockService stock;
 @Resource private FactoryProductionService production;
 @Resource private DepotItemService items;
 @Resource private DepotHeadService heads;
 @Resource private FactorySalesGuard changeGuard;
 private void require(boolean value,String message){if(!value)throw new BusinessRunTimeException(409,message);}
 private long number(Object value){return ((Number)value).longValue();}
 private BigDecimal decimal(Object value){return value==null?BigDecimal.ZERO:new BigDecimal(value.toString());}
 private String text(JSONObject body,String key,int max,boolean required){String value=body.getString(key);value=value==null?"":value.trim();require(!required || !value.isEmpty(),key+"不能为空");require(value.length()<=max,key+"内容过长");return value;}
 private boolean permission(User user,String url) throws Exception {
  if(user.getId().equals(user.getTenantId()))return true;
  List<Long> menus=jdbc.queryForList("SELECT id FROM jsh_function WHERE url=? AND enabled=1 AND IFNULL(delete_flag,'0')='0'",Long.class,url);if(menus.isEmpty())return false;
  for(UserBusiness role:business.getBasicData(user.getId().toString(),"UserRole"))for(UserBusiness functions:business.getBasicData(role.getValue().replace("[","").replace("]",""),"RoleFunctions"))if(functions.getValue()!=null && functions.getValue().contains("["+menus.get(0)+"]"))return true;
  return false;
 }
 private boolean director(User user){return !production.workshopNos(user).isEmpty();}
 private boolean ownWorkshop(User user,int workshop){return production.managesWorkshop(user,workshop);}
 private void ready(long taskId,long tenant,int workshop){require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_workshop_task WHERE tenant_id=? AND head_id=? AND workshop_no=? AND workflow_status='scheduled'",Integer.class,tenant,taskId,workshop)==1,"请先由本车间主任接单并完成本车间排班");}

 private boolean warehouse(User user) throws Exception{return permission(user,"/factory/stock_check");}
 private User actor() throws Exception {
  User user=users.getCurrentUser();require(user!=null && user.getTenantId()!=null && user.getTenantId()>0,"请使用业务租户账号");require(director(user) || permission(user,"/factory/material_request") || warehouse(user),"没有领补退料访问权限");return user;
 }
 private Map<String,Object> task(long id,User user,boolean lock){List<Map<String,Object>> rows=jdbc.queryForList("SELECT head_id,number,workflow_status,plan_json,lines_json FROM jsh_factory_production_task WHERE head_id=? AND tenant_id=?"+(lock?" FOR UPDATE":""),id,user.getTenantId());require(!rows.isEmpty(),"生产任务不存在或无权访问");return rows.get(0);}
 private Map<String,Object> request(long id,User user,boolean lock){List<Map<String,Object>> rows=jdbc.queryForList("SELECT * FROM jsh_factory_material_request WHERE id=? AND tenant_id=?"+(lock?" FOR UPDATE":""),id,user.getTenantId());require(!rows.isEmpty(),"领补退料单不存在或无权访问");return rows.get(0);}
 private void version(Map<String,Object> row,JSONObject body){require(body.getInteger("version")!=null && body.getInteger("version").equals(row.get("version")),"单据已更新，请重新打开操作");}
 private Map<String,Object> product(String barcode,User user){
  List<Map<String,Object>> rows=jdbc.queryForList("SELECT m.id,m.name,m.brand,m.standard,m.model,m.enable_batch_number,e.bar_code barCode,e.commodity_unit unit FROM jsh_material m JOIN jsh_material_extend e ON e.material_id=m.id AND e.tenant_id=m.tenant_id LEFT JOIN jsh_unit u ON u.id=m.unit_id AND u.tenant_id=m.tenant_id WHERE m.material_kind='raw' AND m.tenant_id=? AND e.bar_code=? AND m.enabled=1 AND IFNULL(m.delete_flag,'0')='0' AND IFNULL(e.delete_flag,'0')='0' AND IFNULL(m.enable_serial_number,'0')='0' AND IFNULL(e.sku,'')='' AND NOT EXISTS(SELECT 1 FROM jsh_material_extend sx WHERE sx.material_id=m.id AND sx.tenant_id=m.tenant_id AND IFNULL(sx.delete_flag,'0')='0' AND IFNULL(sx.sku,'')<>'') AND e.commodity_unit=COALESCE(NULLIF(m.unit,''),u.basic_unit)",user.getTenantId(),barcode);
  require(rows.size()==1,"请选择有效原料的基本单位条码；本模块不处理序列号商品");return rows.get(0);
 }
 public Map<String,Object> options() throws Exception {
  User user=actor();Map<String,Object> result=new HashMap<>();result.put("canRequest",director(user));result.put("workshopNos",production.workshopNos(user));result.put("canConfirm",warehouse(user));
  result.put("products",jdbc.queryForList("SELECT m.name,m.brand,m.standard,m.model,e.bar_code barCode,e.commodity_unit unit,m.enable_batch_number FROM jsh_material m JOIN jsh_material_extend e ON e.material_id=m.id AND e.tenant_id=m.tenant_id LEFT JOIN jsh_unit u ON u.id=m.unit_id AND u.tenant_id=m.tenant_id WHERE m.material_kind='raw' AND m.tenant_id=? AND m.enabled=1 AND IFNULL(m.delete_flag,'0')='0' AND IFNULL(e.delete_flag,'0')='0' AND IFNULL(m.enable_serial_number,'0')='0' AND IFNULL(e.sku,'')='' AND NOT EXISTS(SELECT 1 FROM jsh_material_extend sx WHERE sx.material_id=m.id AND sx.tenant_id=m.tenant_id AND IFNULL(sx.delete_flag,'0')='0' AND IFNULL(sx.sku,'')<>'') AND e.commodity_unit=COALESCE(NULLIF(m.unit,''),u.basic_unit) ORDER BY m.name,e.id",user.getTenantId()));
  List<Map<String,Object>> depots=new ArrayList<>();for(Map.Entry<Long,String> depot:stock.depots(user).entrySet()){Map<String,Object> row=new HashMap<>();row.put("id",depot.getKey());row.put("name",depot.getValue());depots.add(row);}result.put("depots",depots);result.put("tasks",jdbc.queryForList("SELECT t.head_id,t.number,h.number order_number FROM jsh_factory_production_task t JOIN jsh_depot_head h ON h.id=t.head_id AND h.tenant_id=t.tenant_id WHERE t.tenant_id=? AND t.workflow_status IN('distributed','scheduled') AND IFNULL(h.delete_flag,'0')='0' AND EXISTS(SELECT 1 FROM jsh_factory_workshop_task w WHERE w.tenant_id=t.tenant_id AND w.head_id=t.head_id AND w.workflow_status='scheduled') ORDER BY t.head_id DESC",user.getTenantId()));return result;
 }
 public Map<String,Object> source(long id) throws Exception {
  User user=actor();Map<String,Object> result=task(id,user,false);result.put("plan",JSONArray.parseArray(result.remove("plan_json").toString()));result.put("lines",JSONArray.parseArray(result.remove("lines_json").toString()));result.put("workshops",jdbc.queryForList("SELECT workshop_no,workflow_status FROM jsh_factory_workshop_task WHERE tenant_id=? AND head_id=?",user.getTenantId(),id));return result;
 }
 private String key(JSONObject row){return row.getLong("materialId")+"|"+row.getLong("depotId")+"|"+row.getString("batchNumber");}
 private BigDecimal physical(JSONObject row) throws Exception {
  if(!row.getBooleanValue("batchEnabled"))return items.getStockByParam(row.getLong("depotId"),row.getLong("materialId"),null,null);
  List<Map<String,Object>> flags=jdbc.queryForList("SELECT force_approval_flag,in_out_manage_flag FROM jsh_system_config WHERE tenant_id=? AND IFNULL(delete_flag,'0')='0' ORDER BY id LIMIT 1",users.getCurrentUser().getTenantId());
  String query="SELECT IFNULL(SUM(CASE WHEN h.type='入库' THEN di.basic_number ELSE -di.basic_number END),0) FROM jsh_depot_head h JOIN jsh_depot_item di ON di.header_id=h.id AND di.tenant_id=h.tenant_id WHERE h.tenant_id=? AND di.material_id=? AND di.depot_id=? AND di.batch_number=? AND h.type IN('入库','出库') AND IFNULL(h.delete_flag,'0')='0' AND IFNULL(di.delete_flag,'0')='0' AND IFNULL(di.sku,'')=''";
  if(!flags.isEmpty() && "1".equals(flags.get(0).get("force_approval_flag")))query+=" AND h.status='1'";
  if(!flags.isEmpty() && "1".equals(flags.get(0).get("in_out_manage_flag")))query+=" AND h.sub_type NOT IN('采购','采购退货','销售','销售退货')";
  return jdbc.queryForObject(query,BigDecimal.class,users.getCurrentUser().getTenantId(),row.getLong("materialId"),row.getLong("depotId"),row.getString("batchNumber"));
 }
 private BigDecimal reserved(JSONObject row,long tenant){return jdbc.queryForObject("SELECT IFNULL(SUM(quantity),0) FROM jsh_factory_stock_reservation WHERE tenant_id=? AND material_id=? AND depot_id=? AND (?='' OR batch_number=?)",BigDecimal.class,tenant,row.getLong("materialId"),row.getLong("depotId"),row.getString("batchNumber"),row.getString("batchNumber"));}
 public List<Map<String,Object>> batches(String barcode,long depot) throws Exception {
  User user=actor();require(stock.depots(user).containsKey(depot),"没有对应仓库权限");Map<String,Object> p=product(barcode,user);List<Map<String,Object>> result=new ArrayList<>();
  if(!"1".equals(p.get("enable_batch_number")))return result;
  List<String> batches=jdbc.queryForList("SELECT DISTINCT di.batch_number FROM jsh_depot_item di JOIN jsh_depot_head h ON h.id=di.header_id AND h.tenant_id=di.tenant_id WHERE di.tenant_id=? AND di.material_id=? AND di.depot_id=? AND h.type='入库' AND IFNULL(h.delete_flag,'0')='0' AND IFNULL(di.delete_flag,'0')='0' AND IFNULL(di.batch_number,'')<>'' ORDER BY di.batch_number",String.class,user.getTenantId(),p.get("id"),depot);
  for(String batch:batches){Map<String,Object> row=stock(barcode,depot,batch);if(((BigDecimal)row.get("physical")).signum()>0){row.put("batchNumber",batch);result.add(row);}}
  return result;
 }
 public Map<String,Object> stock(String barcode,long depot,String batch) throws Exception {
  User user=actor();require(stock.depots(user).containsKey(depot),"没有对应仓库权限");Map<String,Object> p=product(barcode,user);JSONObject row=new JSONObject();row.put("barCode",barcode);row.put("materialId",p.get("id"));row.put("depotId",depot);row.put("batchNumber",batch);row.put("batchEnabled","1".equals(p.get("enable_batch_number")));Map<String,Object> result=new HashMap<>();BigDecimal quantity=physical(row),reserved=reserved(row,user.getTenantId());result.put("physical",quantity);result.put("reserved",reserved);result.put("available",quantity.subtract(reserved).max(BigDecimal.ZERO));result.put("unit",p.get("unit"));return result;
 }
 public Map<String,Object> list(long taskId,String keyword,String state,int page,int size) throws Exception {
  User user=actor();require(page>0 && page<=100000 && size>0 && size<=100 && keyword.length()<=100,"查询参数无效");String from=" FROM jsh_factory_material_request r JOIN jsh_factory_production_task t ON t.head_id=r.task_head_id AND t.tenant_id=r.tenant_id WHERE r.tenant_id=? AND (r.number LIKE ? OR t.number LIKE ?)";List<Object> args=new ArrayList<>(Arrays.asList(user.getTenantId(),"%"+keyword+"%","%"+keyword+"%"));if(taskId>0){from+=" AND r.task_head_id=?";args.add(taskId);}if(!state.isEmpty()){from+=" AND r.workflow_status=?";args.add(state);}List<Integer> mine=production.workshopNos(user);if(!mine.isEmpty() && !warehouse(user) && !production.coordinates(user)){from+=" AND r.workshop_no IN("+String.join(",",Collections.nCopies(mine.size(),"?"))+")";args.addAll(mine);}Map<String,Object> result=new HashMap<>();result.put("total",jdbc.queryForObject("SELECT COUNT(*)"+from,Long.class,args.toArray()));args.add(size);args.add((page-1)*size);result.put("rows",jdbc.queryForList("SELECT r.id,r.task_head_id,r.number,r.kind,r.reference_id,r.line_no,r.stage_no,r.workshop_no,r.workflow_status,r.version,r.ledger_head_id,t.number task_number"+from+" ORDER BY r.id DESC LIMIT ? OFFSET ?",args.toArray()));return result;
 }
 private Map<Integer,BigDecimal> returned(long referenceId,long tenant){
  Map<Integer,BigDecimal> result=new HashMap<>();for(Map<String,Object> row:jdbc.queryForList("SELECT lines_json FROM jsh_factory_material_request WHERE tenant_id=? AND reference_id=? AND kind='return' AND workflow_status='confirmed'",tenant,referenceId)){JSONArray lines=JSONArray.parseArray(row.get("lines_json").toString());for(int i=0;i<lines.size();i++){JSONObject line=lines.getJSONObject(i);int no=line.getIntValue("referenceLine");result.put(no,result.getOrDefault(no,BigDecimal.ZERO).add(line.getBigDecimal("quantity")));}}return result;
 }
 public Map<String,Object> detail(long id) throws Exception {
  User user=actor();Map<String,Object> result=request(id,user,false);result.put("lines",JSONArray.parseArray(result.remove("lines_json").toString()));if(result.get("reference_id")!=null)result.put("reference_number",jdbc.queryForObject("SELECT number FROM jsh_factory_material_request WHERE id=? AND tenant_id=?",String.class,result.get("reference_id"),user.getTenantId()));if(result.get("ledger_head_id")!=null)result.put("ledger_number",jdbc.queryForObject("SELECT number FROM jsh_depot_head WHERE id=? AND tenant_id=?",String.class,result.get("ledger_head_id"),user.getTenantId()));result.put("returned",returned(id,user.getTenantId()));result.put("task",source(number(result.get("task_head_id"))));result.put("history",jdbc.queryForList("SELECT action,actor_name,comment,payload_json,created_at FROM jsh_factory_material_history WHERE request_id=? AND tenant_id=? ORDER BY id DESC",id,user.getTenantId()));return result;
 }
 private void audit(long id,long taskId,User user,String action,String comment,Object payload){
  jdbc.update("INSERT INTO jsh_factory_material_history(tenant_id,request_id,action,actor_name,comment,payload_json,created_at) VALUES(?,?,?,?,?,?,NOW())",user.getTenantId(),id,action,user.getUsername(),comment,JSON.toJSONString(payload));
  jdbc.update("INSERT INTO jsh_factory_production_history(tenant_id,head_id,action,actor_id,actor_name,comment,payload_json,created_at) VALUES(?,?,?,?,?,?,?,NOW())",user.getTenantId(),taskId,"material_"+action,user.getId(),user.getUsername(),comment,JSON.toJSONString(payload));
 }
 @Transactional(rollbackFor=Exception.class)
 public void delete(long id,JSONObject body) throws Exception {
  User user=actor();stock.lockForInventoryMutation();Map<String,Object> doc=request(id,user,true);version(doc,body);
  require(ownWorkshop(user,(int)number(doc.get("workshop_no"))),"仅本车间主任可删除领补退料单");
  require(Arrays.asList("draft","returned","pending","cancelled").contains(doc.get("workflow_status")) && doc.get("ledger_head_id")==null,"已确认出入库的单据不能删除，请通过退料处理");
  require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_material_request WHERE tenant_id=? AND reference_id=?",Integer.class,user.getTenantId(),id)==0,"单据已被退料单引用，不能删除");
  audit(id,number(doc.get("task_head_id")),user,"delete","删除未确认单据 "+doc.get("number"),doc);
  jdbc.update("DELETE FROM jsh_factory_material_request WHERE tenant_id=? AND id=?",user.getTenantId(),id);
 }
 @Transactional(rollbackFor=Exception.class,isolation=Isolation.READ_COMMITTED)
 public long save(JSONObject body) throws Exception {
  User user=actor();require(director(user),"仅车间主任可开立或修改领补退料单");stock.lockForInventoryMutation();Long taskId=body.getLong("taskId");require(taskId!=null,"请选择生产任务");Map<String,Object> task=task(taskId,user,true);require(Arrays.asList("distributed","scheduled").contains(task.get("workflow_status")),"请先由统筹分配生产任务");
  Long id=body.getLong("id");Map<String,Object> old=id==null?null:request(id,user,true);if(old!=null){version(old,body);require(number(old.get("task_head_id"))==taskId && Arrays.asList("draft","returned").contains(old.get("workflow_status")),"仅可修改原任务的草稿或退回单据");}
  String kind=body.getString("kind");require(Arrays.asList("issue","supplement","return").contains(kind),"单据类型无效");if(!"return".equals(kind))changeGuard.checkProduction(taskId,user.getTenantId());if(old!=null)require(kind.equals(old.get("kind")),"不能改变已创建单据的类型");Integer lineNo=body.getInteger("lineNo"),stage=body.getInteger("stageNo"),workshop=body.getInteger("workshopNo");boolean route=false;JSONArray plan=JSONArray.parseArray(task.get("plan_json").toString());for(int i=0;i<plan.size();i++){JSONObject row=plan.getJSONObject(i);if(Objects.equals(lineNo,row.getInteger("lineNo")) && Objects.equals(stage,row.getInteger("stageNo")) && Objects.equals(workshop,row.getInteger("workshopNo")))route=true;}require(route,"请选择生产任务已经安排的产品、工序和车间");require(ownWorkshop(user,workshop),"仅本车间主任可开立或修改本车间领补退料单");if(old!=null)require(ownWorkshop(user,(int)number(old.get("workshop_no"))) && number(old.get("workshop_no"))==workshop,"不能修改其他车间单据或更换原单车间");ready(taskId,user.getTenantId(),workshop);String reason=text(body,"reason",2000,!"issue".equals(kind));
  Long reference=body.getLong("referenceId");Map<String,Object> original=null;if("return".equals(kind)){require(reference!=null,"退料需关联原领料或补料单");original=request(reference,user,true);require(number(original.get("task_head_id"))==taskId && "confirmed".equals(original.get("workflow_status")) && !"return".equals(original.get("kind")) && Objects.equals(original.get("line_no"),lineNo) && Objects.equals(original.get("stage_no"),stage) && Objects.equals(original.get("workshop_no"),workshop),"原领料单与任务、工序或车间不符，或尚未确认发料");}else require(reference==null,"领料或补料单无需关联退料来源");
  JSONArray input=body.getJSONArray("lines"),lines=new JSONArray();require(input!=null && !input.isEmpty() && input.size()<=100,"请填写1至100行原料");Set<String> unique=new HashSet<>();Set<Integer> returnedLines=new HashSet<>();
  for(int i=0;i<input.size();i++){
   JSONObject raw=input.getJSONObject(i),line=new JSONObject();Map<String,Object> product=product(text(raw,"barCode",100,true),user);Long depot=raw.getLong("depotId");require(depot!=null && stock.depots(user).containsKey(depot),"没有所选仓库的操作权限");String batch=text(raw,"batchNumber",100,false);boolean batchEnabled="1".equals(product.get("enable_batch_number"));require(batchEnabled?!batch.isEmpty():batch.isEmpty(),batchEnabled?"批次原料必须填写批号":"非批次原料请留空批号");BigDecimal qty=raw.getBigDecimal("quantity");require(qty!=null && qty.signum()>0 && qty.scale()<=6 && qty.precision()-qty.scale()<=12,"原料数量必须大于0且最多6位小数");
   line.put("barCode",product.get("barCode"));line.put("materialId",product.get("id"));line.put("name",product.get("name"));line.put("brand",product.get("brand"));line.put("standard",product.get("standard"));line.put("model",product.get("model"));line.put("unit",product.get("unit"));line.put("depotId",depot);line.put("batchNumber",batch);line.put("batchEnabled",batchEnabled);line.put("quantity",qty);if(original==null && batchEnabled)require(physical(line).signum()>0,"请选择所选原料和仓库中有实物库存的批次");require(unique.add(key(line)),"同一原料、仓库和批号请合并一行填写");
   if(original!=null){Integer no=raw.getInteger("referenceLine");JSONArray source=JSONArray.parseArray(original.get("lines_json").toString());require(no!=null && no>=0 && no<source.size() && returnedLines.add(no),"退料来源行无效或重复");JSONObject sourceLine=source.getJSONObject(no);require(line.getString("barCode").equals(sourceLine.getString("barCode")) && batch.equals(sourceLine.getString("batchNumber")),"退料原料和批号必须与原领料一致");line.put("referenceLine",no);require(qty.add(returned(reference,user.getTenantId()).getOrDefault(no,BigDecimal.ZERO)).compareTo(sourceLine.getBigDecimal("quantity"))<=0,"累计退料不能超过原单已领数量");}lines.add(line);
  }
  if(id==null){String code="CL"+LocalDate.now().toString().replace("-","")+UUID.randomUUID().toString().replace("-","").substring(0,12).toUpperCase();jdbc.update("INSERT INTO jsh_factory_material_request(tenant_id,task_head_id,number,kind,reference_id,line_no,stage_no,workshop_no,workflow_status,version,reason,lines_json,created_by,created_at,updated_at) VALUES(?,?,?,?,?,?,?,?,'draft',1,?,?,?,NOW(),NOW())",user.getTenantId(),taskId,code,kind,reference,lineNo,stage,workshop,reason,lines.toJSONString(),user.getId());id=jdbc.queryForObject("SELECT id FROM jsh_factory_material_request WHERE tenant_id=? AND number=?",Long.class,user.getTenantId(),code);}
  else jdbc.update("UPDATE jsh_factory_material_request SET reference_id=?,line_no=?,stage_no=?,workshop_no=?,reason=?,lines_json=?,version=version+1,workflow_status='draft',updated_at=NOW() WHERE id=? AND tenant_id=?",reference,lineNo,stage,workshop,reason,lines.toJSONString(),id,user.getTenantId());
  audit(id,taskId,user,old==null?"create":"edit","主任保存领补退料单",lines);return id;
 }
 @Transactional(rollbackFor=Exception.class,isolation=Isolation.READ_COMMITTED)
 public void action(long id,JSONObject body,HttpServletRequest http) throws Exception {
  User user=actor();stock.lockForInventoryMutation();Map<String,Object> doc=request(id,user,true);version(doc,body);Map<String,Object> task=task(number(doc.get("task_head_id")),user,true);require(Arrays.asList("distributed","scheduled").contains(task.get("workflow_status")),"关联生产任务当前不可执行领退料");String action=body.getString("action"),state=doc.get("workflow_status").toString(),next=null,comment=text(body,"comment",2000,false);
  if(!"return".equals(doc.get("kind"))&&Arrays.asList("submit","confirm").contains(action))changeGuard.checkProduction(number(doc.get("task_head_id")),user.getTenantId());
  if("submit".equals(action)){require(ownWorkshop(user,(int)number(doc.get("workshop_no"))) && Arrays.asList("draft","returned").contains(state),"仅主任可提交草稿或退回单据");ready(number(doc.get("task_head_id")),user.getTenantId(),(int)number(doc.get("workshop_no")));next="pending";}
  else if("withdraw".equals(action)||"cancel".equals(action)){require(ownWorkshop(user,(int)number(doc.get("workshop_no"))) && Arrays.asList("draft","returned","pending").contains(state),"仅主任可撤回或撤销尚未确认的单据");next="cancel".equals(action)?"cancelled":"draft";}
  else if("reject".equals(action)){require(warehouse(user) && "pending".equals(state) && !comment.isEmpty(),"仅仓库可退回待确认单据，且必须说明原因");next="returned";}
  else if("confirm".equals(action)){require(warehouse(user) && "pending".equals(state),"仅仓库可确认待处理单据");ready(number(doc.get("task_head_id")),user.getTenantId(),(int)number(doc.get("workshop_no")));post(doc,user,http);next="confirmed";}
  else throw new BusinessRunTimeException(409,"不支持的操作");
  jdbc.update("UPDATE jsh_factory_material_request SET workflow_status=?,version=version+1,updated_at=NOW() WHERE id=? AND tenant_id=?",next,id,user.getTenantId());audit(id,number(doc.get("task_head_id")),user,action,comment.isEmpty()?"领补退料状态更新":comment,Collections.singletonMap("status",next));
 }
 private void post(Map<String,Object> doc,User user,HttpServletRequest http) throws Exception {
  boolean returning="return".equals(doc.get("kind"));JSONArray lines=JSONArray.parseArray(doc.get("lines_json").toString()),ledger=new JSONArray();BigDecimal total=BigDecimal.ZERO;Map<String,Object> original=returning?request(number(doc.get("reference_id")),user,true):null;Map<Integer,BigDecimal> returned=returning?returned(number(doc.get("reference_id")),user.getTenantId()):new HashMap<>();
  for(int i=0;i<lines.size();i++){
   JSONObject line=lines.getJSONObject(i);Map<String,Object> p=product(line.getString("barCode"),user);require(stock.depots(user).containsKey(line.getLong("depotId")),"没有原料所在仓库权限");require(number(p.get("id"))==line.getLongValue("materialId") && Objects.equals(p.get("unit"),line.get("unit")) && "1".equals(p.get("enable_batch_number"))==line.getBooleanValue("batchEnabled"),"原料档案或基本单位已变化，请退回主任重新保存");BigDecimal qty=line.getBigDecimal("quantity"),price;
   if(returning){int no=line.getIntValue("referenceLine");JSONArray source=JSONArray.parseArray(original.get("lines_json").toString());require(returned.getOrDefault(no,BigDecimal.ZERO).add(qty).compareTo(source.getJSONObject(no).getBigDecimal("quantity"))<=0,"累计退料超过原单已领数量，请重新核对");JSONObject sourceLine=source.getJSONObject(no);List<BigDecimal> prices=jdbc.queryForList("SELECT unit_price FROM jsh_depot_item WHERE tenant_id=? AND header_id=? AND material_id=? AND depot_id=? AND IFNULL(batch_number,'')=? AND IFNULL(delete_flag,'0')='0'",BigDecimal.class,user.getTenantId(),original.get("ledger_head_id"),sourceLine.getLong("materialId"),sourceLine.getLong("depotId"),sourceLine.getString("batchNumber"));require(prices.size()==1,"原领料成本记录异常");price=decimal(prices.get(0));}
   else {require(physical(line).subtract(reserved(line,user.getTenantId())).compareTo(qty)>=0,"原料库存不足或已被订单预留，请核实到货后再确认");List<BigDecimal> prices=jdbc.queryForList("SELECT current_unit_price FROM jsh_material_current_stock WHERE tenant_id=? AND material_id=? AND depot_id=? AND IFNULL(delete_flag,'0')='0'",BigDecimal.class,user.getTenantId(),line.getLong("materialId"),line.getLong("depotId"));price=prices.isEmpty()?BigDecimal.ZERO:decimal(prices.get(0));}
   JSONObject row=new JSONObject(line);BigDecimal amount=qty.multiply(price).setScale(2,RoundingMode.HALF_UP);row.put("operNumber",qty);row.put("unitPrice",price);row.put("allPrice",amount);row.put("taxRate",BigDecimal.ZERO);row.put("taxMoney",BigDecimal.ZERO);row.put("taxLastMoney",amount);row.put("remark",doc.get("number"));ledger.add(row);total=total.add(amount);
  }
  JSONObject head=new JSONObject();String code=doc.get("number")+"-"+(returning?"IN":"OUT");head.put("number",code);head.put("type",returning?"入库":"出库");head.put("subType","其它");head.put("status","1");head.put("operTime",LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));head.put("remark","车间"+doc.get("number")+" / 生产任务#"+doc.get("task_head_id"));head.put("totalPrice",total);head.put("discountLastMoney",total);for(String key:Arrays.asList("discount","discountMoney","changeAmount","debt","otherMoney"))head.put(key,BigDecimal.ZERO);head.put("payType","现付");
  heads.addDepotHeadAndDetail(head.toJSONString(),ledger.toJSONString(),http);Long ledgerId=jdbc.queryForObject("SELECT id FROM jsh_depot_head WHERE tenant_id=? AND number=?",Long.class,user.getTenantId(),code);jdbc.update("UPDATE jsh_factory_material_request SET ledger_head_id=? WHERE id=? AND tenant_id=?",ledgerId,doc.get("id"),user.getTenantId());
 }
}
