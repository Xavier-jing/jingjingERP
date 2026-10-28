package com.jsh.erp.service;

import com.alibaba.fastjson.*;
import com.jsh.erp.datasource.entities.User;
import com.jsh.erp.datasource.entities.UserBusiness;
import com.jsh.erp.exception.BusinessRunTimeException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import java.math.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
public class FactoryReturnService {
 @Resource private JdbcTemplate jdbc;
 @Resource private UserService users;
 @Resource private UserBusinessService business;
 @Resource private FactoryStockService stock;
 @Resource private DepotHeadService heads;
 @Resource private FactorySalesGuard guard;

 private void require(boolean valid,String message){if(!valid)throw new BusinessRunTimeException(409,message);}
 private long num(Object value){return ((Number)value).longValue();}
 private String comment(JSONObject b,String key){String s=b.getString(key);s=s==null?"":s.trim();require(s.length()<=2000,"说明不能超过2000字");return s;}
 private List<Long> leaders(long tenant){return leaders(tenant,false);}
 private List<Long> leaders(long tenant,boolean current){List<String> rows=jdbc.queryForList("SELECT leader_ids FROM jsh_factory_return_config WHERE tenant_id=?"+(current?" FOR UPDATE":""),String.class,tenant);return rows.isEmpty()?Collections.emptyList():JSON.parseArray(rows.get(0),Long.class);}
 private User actor()throws Exception{
  User u=users.getCurrentUser();require(u!=null&&u.getTenantId()!=null&&u.getTenantId()>0,"请使用业务租户账号");
  boolean allowed=u.getId().equals(u.getTenantId())||leaders(u.getTenantId()).contains(u.getId())||stock.canManageWarehouse(u);
  List<Long> menus=jdbc.queryForList("SELECT id FROM jsh_function WHERE url IN('/factory/returns','/bill/sale_order') AND enabled=1 AND IFNULL(delete_flag,'0')='0'",Long.class);
  for(UserBusiness role:business.getBasicData(u.getId().toString(),"UserRole"))for(UserBusiness f:business.getBasicData(role.getValue().replace("[","").replace("]",""),"RoleFunctions"))for(Long menu:menus)if(f.getValue()!=null&&f.getValue().contains("["+menu+"]"))allowed=true;
  require(allowed,"没有客户退货权限");return u;
 }
 public Map<String,Object> options()throws Exception{
  User u=actor();Map<String,Object> r=new HashMap<>();r.put("canConfigure",u.getId().equals(u.getTenantId()));r.put("isWarehouse",stock.canManageWarehouse(u));r.put("isLeader",leaders(u.getTenantId()).contains(u.getId()));r.put("leaderIds",leaders(u.getTenantId()));
  r.put("users",jdbc.queryForList("SELECT id,username,login_name FROM jsh_user WHERE tenant_id=? AND status=0 AND IFNULL(delete_flag,'0')='0' ORDER BY id",u.getTenantId()));
  List<Map<String,Object>> depots=new ArrayList<>();for(Map.Entry<Long,String> d:stock.depots(u).entrySet()){Map<String,Object> row=new HashMap<>();row.put("id",d.getKey());row.put("name",d.getValue());depots.add(row);}r.put("depots",depots);return r;
 }
 @Transactional(rollbackFor=Exception.class)
 public void configure(JSONObject b)throws Exception{
  User u=actor();require(u.getId().equals(u.getTenantId()),"仅租户负责人可配置退货审批领导");stock.lockForInventoryMutation();JSONArray input=b.getJSONArray("leaderIds");require(input!=null&&!input.isEmpty()&&input.size()<=30,"请选择1至30位审批领导");Set<Long> ids=new LinkedHashSet<>();
  for(int i=0;i<input.size();i++){Long id=input.getLong(i);require(id!=null&&ids.add(id)&&jdbc.queryForObject("SELECT COUNT(*) FROM jsh_user WHERE tenant_id=? AND id=? AND status=0 AND IFNULL(delete_flag,'0')='0'",Integer.class,u.getTenantId(),id)==1,"请选择本租户有效且不重复的领导账号");}
  jdbc.update("INSERT INTO jsh_factory_return_config VALUES(?,?) ON DUPLICATE KEY UPDATE leader_ids=VALUES(leader_ids)",u.getTenantId(),JSON.toJSONString(ids));audit(u,0,"configure","审批领导账号："+JSON.toJSONString(ids));
 }
 private Map<String,Object> source(long id,User u,boolean lock){
  List<Map<String,Object>> rows=jdbc.queryForList("SELECT sh.head_id,sh.ledger_head_id,f.created_by,h.number,c.supplier customer_name FROM jsh_factory_shipment sh JOIN jsh_factory_sales_order f ON f.head_id=sh.head_id AND f.tenant_id=sh.tenant_id JOIN jsh_depot_head h ON h.id=f.head_id AND h.tenant_id=f.tenant_id LEFT JOIN jsh_supplier c ON c.id=h.organ_id AND c.tenant_id=h.tenant_id WHERE sh.tenant_id=? AND sh.head_id=? AND sh.workflow_status='shipped' AND IFNULL(h.delete_flag,'0')='0'"+(lock?" FOR UPDATE":""),u.getTenantId(),id);
  require(!rows.isEmpty(),"原订单不存在或尚未完成发货");return rows.get(0);
 }
 private List<Map<String,Object>> sourceLines(Map<String,Object> source,User u,boolean current){
  List<Map<String,Object>> rows=jdbc.queryForList("SELECT di.id sourceItemId,di.material_id materialId,m.name,m.standard,m.model,e.bar_code barCode,di.batch_number batchNumber,di.depot_id depotId,d.name depotName,di.basic_number shippedQuantity FROM jsh_depot_item di JOIN jsh_material m ON m.id=di.material_id AND m.tenant_id=di.tenant_id JOIN jsh_material_extend e ON e.id=di.material_extend_id AND e.tenant_id=di.tenant_id LEFT JOIN jsh_depot d ON d.id=di.depot_id AND d.tenant_id=di.tenant_id WHERE di.tenant_id=? AND di.header_id=? AND IFNULL(di.delete_flag,'0')='0' ORDER BY di.id",u.getTenantId(),source.get("ledger_head_id"));
  for(Map<String,Object> row:rows){BigDecimal used=jdbc.queryForObject("SELECT COALESCE(SUM(l.quantity),0) FROM jsh_factory_customer_return_line l JOIN jsh_factory_customer_return r ON r.id=l.return_id AND r.tenant_id=l.tenant_id WHERE l.tenant_id=? AND l.source_item_id=? AND r.workflow_status IN('pending','approved','received')"+(current?" FOR UPDATE":""),BigDecimal.class,u.getTenantId(),row.get("sourceItemId"));row.put("claimedQuantity",used);row.put("availableQuantity",((BigDecimal)row.get("shippedQuantity")).subtract(used));}return rows;
 }
 public Map<String,Object> source(long id)throws Exception{User u=actor();Map<String,Object> r=source(id,u,false);r.put("isOwner",num(r.get("created_by"))==u.getId());r.put("lines",sourceLines(r,u,false));return r;}
 public Map<String,Object> sources(String keyword,int page)throws Exception{
  User u=actor();page(keyword,page);String from=" FROM jsh_factory_shipment sh JOIN jsh_factory_sales_order f ON f.head_id=sh.head_id AND f.tenant_id=sh.tenant_id JOIN jsh_depot_head h ON h.id=sh.head_id AND h.tenant_id=sh.tenant_id LEFT JOIN jsh_supplier c ON c.id=h.organ_id AND c.tenant_id=h.tenant_id WHERE sh.tenant_id=? AND sh.workflow_status='shipped' AND f.created_by=? AND IFNULL(h.delete_flag,'0')='0' AND (h.number LIKE ? OR c.supplier LIKE ?)";Object[] args={u.getTenantId(),u.getId(),"%"+keyword+"%","%"+keyword+"%"};return paged("SELECT sh.head_id,h.number,c.supplier customer_name,sh.shipped_at",from,args,page);
 }
 private void page(String keyword,int page){require(keyword.length()<=100&&page>0&&page<=100000,"查询条件无效");}
 private Map<String,Object> paged(String select,String from,Object[] args,int page){Map<String,Object> r=new HashMap<>();r.put("total",jdbc.queryForObject("SELECT COUNT(*)"+from,Long.class,args));List<Object> values=new ArrayList<>(Arrays.asList(args));values.add((page-1)*10);r.put("rows",jdbc.queryForList(select+from+" ORDER BY 1 DESC LIMIT 10 OFFSET ?",values.toArray()));return r;}
 public Map<String,Object> list(String keyword,int page)throws Exception{
  User u=actor();page(keyword,page);String from=" FROM jsh_factory_customer_return r JOIN jsh_depot_head h ON h.id=r.source_head_id AND h.tenant_id=r.tenant_id LEFT JOIN jsh_supplier c ON c.id=h.organ_id AND c.tenant_id=h.tenant_id WHERE r.tenant_id=? AND (h.number LIKE ? OR c.supplier LIKE ?)";return paged("SELECT r.id,r.source_head_id,h.number,c.supplier customer_name,r.workflow_status,r.reason,r.created_at,r.received_at",from,new Object[]{u.getTenantId(),"%"+keyword+"%","%"+keyword+"%"},page);
 }
 @Transactional(rollbackFor=Exception.class)
 public long create(JSONObject b)throws Exception{
  User u=actor();stock.lockForInventoryMutation();Long sourceId=b.getLong("sourceHeadId");require(sourceId!=null,"请选择原发货订单");Map<String,Object> source=source(sourceId,u,true);require(num(source.get("created_by"))==u.getId(),"仅原订单销售人员可申请退货");require(!leaders(u.getTenantId(),true).isEmpty(),"请先配置退货审批领导");String reason=comment(b,"reason");require(!reason.isEmpty(),"请填写退货原因");JSONArray input=b.getJSONArray("lines");require(input!=null&&!input.isEmpty()&&input.size()<=500,"请填写退货产品和数量");
  Map<Long,BigDecimal> available=new HashMap<>();for(Map<String,Object> row:sourceLines(source,u,true))available.put(num(row.get("sourceItemId")),(BigDecimal)row.get("availableQuantity"));Set<Long> unique=new HashSet<>();
  for(int i=0;i<input.size();i++){JSONObject line=input.getJSONObject(i);Long item=line.getLong("sourceItemId");BigDecimal qty=line.getBigDecimal("quantity");require(item!=null&&unique.add(item)&&available.containsKey(item),"只能选择原发货明细且不能重复");require(qty!=null&&qty.signum()>0&&qty.scale()<=6&&qty.precision()-qty.scale()<=12&&qty.compareTo(available.get(item))<=0,"退货数量须大于0、最多6位小数，且累计不能超过原发货量（含待审批、待收货）");}
  jdbc.update("INSERT INTO jsh_factory_customer_return(tenant_id,source_head_id,workflow_status,reason,created_by,created_at) VALUES(?,?,'pending',?,?,NOW())",u.getTenantId(),sourceId,reason,u.getId());long id=jdbc.queryForObject("SELECT LAST_INSERT_ID()",Long.class);
  for(int i=0;i<input.size();i++){JSONObject line=input.getJSONObject(i);jdbc.update("INSERT INTO jsh_factory_customer_return_line(return_id,tenant_id,source_item_id,quantity) VALUES(?,?,?,?)",id,u.getTenantId(),line.getLong("sourceItemId"),line.getBigDecimal("quantity"));}audit(u,id,"submit",reason);return id;
 }
 private Map<String,Object> doc(long id,User u,boolean lock){List<Map<String,Object>> rows=jdbc.queryForList("SELECT * FROM jsh_factory_customer_return WHERE tenant_id=? AND id=?"+(lock?" FOR UPDATE":""),u.getTenantId(),id);require(!rows.isEmpty(),"退货单不存在或无权访问");return rows.get(0);}
 private List<Map<String,Object>> lines(long id,User u){return jdbc.queryForList("SELECT l.source_item_id sourceItemId,l.quantity,di.material_id materialId,e.bar_code barCode,di.batch_number batchNumber,m.name,m.standard,m.model,d.name sourceDepotName FROM jsh_factory_customer_return_line l JOIN jsh_depot_item di ON di.id=l.source_item_id AND di.tenant_id=l.tenant_id JOIN jsh_material m ON m.id=di.material_id AND m.tenant_id=di.tenant_id JOIN jsh_material_extend e ON e.id=di.material_extend_id AND e.tenant_id=di.tenant_id LEFT JOIN jsh_depot d ON d.id=di.depot_id AND d.tenant_id=di.tenant_id WHERE l.tenant_id=? AND l.return_id=? ORDER BY l.id",u.getTenantId(),id);}
 public Map<String,Object> detail(long id)throws Exception{
  User u=actor();Map<String,Object> r=doc(id,u,false),s=source(num(r.get("source_head_id")),u,false);
  r.put("number",s.get("number"));r.put("customer_name",s.get("customer_name"));r.put("isOwner",num(r.get("created_by"))==u.getId());r.put("lines",lines(id,u));
  if(r.get("ledger_head_id")!=null){List<String> depots=jdbc.queryForList("SELECT DISTINCT d.name FROM jsh_depot_item di JOIN jsh_depot d ON d.id=di.depot_id AND d.tenant_id=di.tenant_id WHERE di.tenant_id=? AND di.header_id=?",String.class,u.getTenantId(),r.get("ledger_head_id"));r.put("receivedDepotName",String.join("、",depots));}
  r.put("history",jdbc.queryForList("SELECT action,actor_name,comment,created_at FROM jsh_factory_customer_return_history WHERE tenant_id=? AND return_id=? ORDER BY id",u.getTenantId(),id));return r;
 }
 @Transactional(rollbackFor=Exception.class)
 public void action(long id,JSONObject b,HttpServletRequest http)throws Exception{
  User u=actor();stock.lockForInventoryMutation();Map<String,Object> r=doc(id,u,true);require(b.getInteger("version")!=null&&b.getInteger("version").equals(r.get("version")),"退货单已更新，请重新打开");String state=r.get("workflow_status").toString(),action=b.getString("action"),comment=comment(b,"comment");boolean owner=num(r.get("created_by"))==u.getId();
  if("cancel".equals(action)){require(owner&&Arrays.asList("pending","approved").contains(state)&&!comment.isEmpty(),"仅申请销售可填写原因后撤销尚未收货的退货单");state="cancelled";}
  else if("approve".equals(action)||"reject".equals(action)){
   boolean leader=leaders(u.getTenantId(),true).contains(u.getId());require("pending".equals(state)&&leader||"approved".equals(state)&&"reject".equals(action)&&stock.canManageWarehouse(u),"仅配置领导可审批待审退货，仓库可退回尚未收货的已批退货");
   if("approve".equals(action)){state="approved";jdbc.update("UPDATE jsh_factory_customer_return SET approved_by=?,approved_at=NOW() WHERE tenant_id=? AND id=?",u.getId(),u.getTenantId(),id);}else{require(!comment.isEmpty(),"退回须填写原因");state="rejected";}
  }else if("receive".equals(action)){
   require("approved".equals(state)&&stock.canManageWarehouse(u),"仅仓库可确认领导批准后的退货收货");Long depot=b.getLong("depotId");require(depot!=null&&stock.depots(u).containsKey(depot),"请选择有权限的有效收货仓库");source(num(r.get("source_head_id")),u,true);receive(id,r,depot,u,http);state="received";
  }else throw new BusinessRunTimeException(409,"无效的退货操作");
  jdbc.update("UPDATE jsh_factory_customer_return SET workflow_status=?,version=version+1 WHERE tenant_id=? AND id=?",state,u.getTenantId(),id);audit(u,id,action,comment);
 }
 private void receive(long id,Map<String,Object> doc,long depot,User u,HttpServletRequest http)throws Exception{
  List<Map<String,Object>> rows=lines(id,u);require(!rows.isEmpty(),"退货明细为空");JSONArray ledger=new JSONArray();BigDecimal total=BigDecimal.ZERO;
  for(Map<String,Object> line:rows){Long material=num(line.get("materialId"));require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_material m JOIN jsh_material_extend e ON e.material_id=m.id AND e.tenant_id=m.tenant_id WHERE m.tenant_id=? AND m.id=? AND e.bar_code=? AND m.enabled=1 AND m.unit='吨' AND e.commodity_unit='吨' AND m.enable_batch_number='1' AND IFNULL(m.delete_flag,'0')='0' AND IFNULL(e.delete_flag,'0')='0'",Integer.class,u.getTenantId(),material,line.get("barCode"))==1,"产品档案、单位或批次设置已变更，请核对后再收货");
   BigDecimal cost=jdbc.queryForObject("SELECT unit_price FROM jsh_depot_item WHERE tenant_id=? AND id=?",BigDecimal.class,u.getTenantId(),line.get("sourceItemId"));require(cost!=null,"原出库成本缺失，请核对");BigDecimal amount=((BigDecimal)line.get("quantity")).multiply(cost).setScale(2,RoundingMode.HALF_UP);total=total.add(amount);JSONObject row=new JSONObject();row.put("barCode",line.get("barCode"));row.put("unit","吨");row.put("depotId",depot);row.put("batchNumber",line.get("batchNumber"));row.put("operNumber",line.get("quantity"));row.put("unitPrice",cost);row.put("allPrice",amount);row.put("taxLastMoney",amount);row.put("taxRate",0);row.put("taxMoney",0);ledger.add(row);
  }
  JSONObject head=new JSONObject();String number="KHTH"+id;head.put("number",number);head.put("type","入库");head.put("subType","其它");head.put("status","1");head.put("operTime",LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));head.put("remark","客户退货免复检恢复可销售库存 / 原销售订单#"+doc.get("source_head_id"));head.put("payType","现付");head.put("totalPrice",total);head.put("discountLastMoney",total);for(String key:Arrays.asList("discount","discountMoney","changeAmount","debt","otherMoney"))head.put(key,0);
  guard.enter();try{heads.addDepotHeadAndDetail(head.toJSONString(),ledger.toJSONString(),http);}finally{guard.leave();}
  Long ledgerId=jdbc.queryForObject("SELECT id FROM jsh_depot_head WHERE tenant_id=? AND number=?",Long.class,u.getTenantId(),number);
  for(Map<String,Object> item:jdbc.queryForList("SELECT id,basic_number FROM jsh_depot_item WHERE tenant_id=? AND header_id=?",u.getTenantId(),ledgerId))jdbc.update("INSERT INTO jsh_factory_batch_quality(item_id,tenant_id,qc_status,qualified_quantity,release_state,return_released,report_number,report_text) VALUES(?,?,'passed',?,'released',1,?,?)",item.get("id"),u.getTenantId(),item.get("basic_number"),number,"退货业务恢复销售资格，无新增检测：领导批准，仓库核对实物收货；原订单#"+doc.get("source_head_id")+"，退货单#"+id);
  jdbc.update("UPDATE jsh_factory_customer_return SET ledger_head_id=?,received_by=?,received_at=NOW() WHERE tenant_id=? AND id=?",ledgerId,u.getId(),u.getTenantId(),id);
 }
 private void audit(User u,long id,String action,String comment){jdbc.update("INSERT INTO jsh_factory_customer_return_history(tenant_id,return_id,action,actor_id,actor_name,comment,created_at) VALUES(?,?,?,?,?,?,NOW())",u.getTenantId(),id,action,u.getId(),u.getUsername(),comment);}
}
