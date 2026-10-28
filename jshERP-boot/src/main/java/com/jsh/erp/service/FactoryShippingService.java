package com.jsh.erp.service;

import com.alibaba.fastjson.*;
import com.jsh.erp.datasource.entities.User;
import com.jsh.erp.datasource.entities.UserBusiness;
import com.jsh.erp.exception.BusinessRunTimeException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.imageio.ImageIO;
import java.nio.file.*;
import java.math.*;
import java.time.*;
import java.util.*;

@Service
public class FactoryShippingService {
 @Resource private JdbcTemplate jdbc;
 @Resource private UserService users;
 @Resource private UserBusinessService business;
 @Resource private FactoryStockService stock;
 @Resource private DepotHeadService heads;
 @Resource private FactorySalesGuard guard;
 @Value("${file.path}") private String fileRoot;
 private void require(boolean valid,String message){if(!valid)throw new BusinessRunTimeException(409,message);}
 private long num(Object value){return ((Number)value).longValue();}
 private String text(JSONObject b,String key,int max,boolean required){String v=b.getString(key);v=v==null?"":v.trim();require((!required||!v.isEmpty())&&v.length()<=max,"请完整填写信息，且内容不能超过长度限制："+key);return v;}
 private Long finance(long tenant){return finance(tenant,false);}
 private Long finance(long tenant,boolean current){List<Long> ids=jdbc.queryForList("SELECT finance_id FROM jsh_factory_shipping_config WHERE tenant_id=?"+(current?" FOR UPDATE":""),Long.class,tenant);return ids.isEmpty()?null:ids.get(0);}
 private User actor()throws Exception{
  User u=users.getCurrentUser();require(u!=null&&u.getTenantId()!=null&&u.getTenantId()>0,"请使用业务租户账号");boolean allowed=u.getId().equals(u.getTenantId())||u.getId().equals(finance(u.getTenantId()))||stock.canManageWarehouse(u);
  List<Long> menus=jdbc.queryForList("SELECT id FROM jsh_function WHERE (url='/factory/shipping' OR id=242) AND enabled=1 AND IFNULL(delete_flag,'0')='0'",Long.class);
  for(UserBusiness role:business.getBasicData(u.getId().toString(),"UserRole"))for(UserBusiness functions:business.getBasicData(role.getValue().replace("[","").replace("]",""),"RoleFunctions"))for(Long menu:menus)if(functions.getValue()!=null&&functions.getValue().contains("["+menu+"]"))allowed=true;
  require(allowed,"没有发货模块权限");return u;
 }
 public Map<String,Object> options()throws Exception{
  User u=actor();Map<String,Object> r=new HashMap<>();r.put("currentUserId",u.getId());r.put("canConfigure",u.getId().equals(u.getTenantId()));r.put("financeId",finance(u.getTenantId()));r.put("isFinance",u.getId().equals(finance(u.getTenantId())));r.put("isWarehouse",stock.canManageWarehouse(u));r.put("users",jdbc.queryForList("SELECT id,username,login_name FROM jsh_user WHERE tenant_id=? AND status=0 AND IFNULL(delete_flag,'0')='0' ORDER BY id",u.getTenantId()));return r;
 }
 @Transactional(rollbackFor=Exception.class)
 public void configure(JSONObject b)throws Exception{
  User u=actor();require(u.getId().equals(u.getTenantId()),"仅租户负责人可配置到账确认财务账号");stock.lockForInventoryMutation();Long id=b.getLong("financeId");require(id!=null&&jdbc.queryForObject("SELECT COUNT(*) FROM jsh_user WHERE tenant_id=? AND id=? AND status=0 AND IFNULL(delete_flag,'0')='0'",Integer.class,u.getTenantId(),id)==1,"请选择本租户有效财务账号");jdbc.update("INSERT INTO jsh_factory_shipping_config VALUES(?,?,NOW()) ON DUPLICATE KEY UPDATE finance_id=VALUES(finance_id),updated_at=NOW()",u.getTenantId(),id);audit(u,0,"configure","配置到账确认财务账号",b);
 }
 private Map<String,Object> order(long id,User u,boolean lock){
  List<Map<String,Object>> rows=jdbc.queryForList("SELECT f.*,h.number,h.total_price,s.supplier customer_name FROM jsh_factory_sales_order f JOIN jsh_depot_head h ON h.id=f.head_id AND h.tenant_id=f.tenant_id LEFT JOIN jsh_supplier s ON s.id=h.organ_id AND s.tenant_id=f.tenant_id WHERE f.tenant_id=? AND f.head_id=? AND IFNULL(h.delete_flag,'0')='0'"+(lock?" FOR UPDATE":""),u.getTenantId(),id);require(!rows.isEmpty(),"销售订单不存在或无权访问");return rows.get(0);
 }
 private Map<String,Object> shipment(long id,User u,boolean lock){List<Map<String,Object>> rows=jdbc.queryForList("SELECT * FROM jsh_factory_shipment WHERE tenant_id=? AND head_id=?"+(lock?" FOR UPDATE":""),u.getTenantId(),id);return rows.isEmpty()?null:rows.get(0);}
 public Map<String,Object> list(String keyword,int page)throws Exception{
  User u=actor();require(keyword.length()<=100&&page>0&&page<=100000,"查询条件无效");String from=" FROM jsh_factory_sales_order f JOIN jsh_depot_head h ON h.id=f.head_id AND h.tenant_id=f.tenant_id LEFT JOIN jsh_supplier c ON c.id=h.organ_id AND c.tenant_id=f.tenant_id LEFT JOIN jsh_factory_shipment sh ON sh.head_id=f.head_id AND sh.tenant_id=f.tenant_id WHERE f.tenant_id=? AND f.workflow_status='approved' AND IFNULL(h.delete_flag,'0')='0' AND (h.number LIKE ? OR c.supplier LIKE ?)";Object[] args={u.getTenantId(),"%"+keyword+"%","%"+keyword+"%"};Map<String,Object> r=new HashMap<>();r.put("total",jdbc.queryForObject("SELECT COUNT(*)"+from,Long.class,args));List<Object> paged=new ArrayList<>(Arrays.asList(args));paged.add((page-1)*10);r.put("rows",jdbc.queryForList("SELECT f.head_id,f.created_by,f.payment_terms,h.number,c.supplier customer_name,sh.workflow_status,sh.requested_at,sh.shipped_at"+from+" ORDER BY f.head_id DESC LIMIT 10 OFFSET ?",paged.toArray()));return r;
 }
 public Map<String,Object> detail(long id)throws Exception{
  User u=actor();Map<String,Object> order=order(id,u,false),doc=shipment(id,u,false),r=new HashMap<>();r.put("head_id",id);r.put("number",order.get("number"));r.put("customer_name",order.get("customer_name"));r.put("payment_terms",order.get("payment_terms"));r.put("orderVersion",order.get("version"));r.put("isOwner",u.getId().longValue()==num(order.get("created_by")));r.put("orderState",order.get("workflow_status"));r.put("requirements",order.get("requirements"));
  boolean money=u.getId().equals(u.getTenantId())||u.getId().equals(finance(u.getTenantId()))||u.getId().longValue()==num(order.get("created_by"));if(money)r.put("total_price",order.get("total_price"));
  JSONArray lines=JSONArray.parseArray(order.get("lines_json").toString()),safe=new JSONArray();for(int i=0;i<lines.size();i++){JSONObject row=new JSONObject();row.put("lineNo",i);for(String key:Arrays.asList("id","name","brand","standard","model","barCode","quantity"))row.put(key,lines.getJSONObject(i).get(key));safe.add(row);}r.put("lines",safe);
  List<Map<String,Object>> allocations=jdbc.queryForList("SELECT a.line_no lineNo,a.depot_id depotId,d.name depotName,a.batch_number batchNumber,a.quantity FROM jsh_factory_stock_reservation a LEFT JOIN jsh_depot d ON d.id=a.depot_id AND d.tenant_id=a.tenant_id WHERE a.tenant_id=? AND a.head_id=? ORDER BY a.line_no,a.depot_id,a.batch_number",u.getTenantId(),id);r.put("allocations",allocations);
  if(doc!=null){doc.put("trucks",JSONArray.parseArray(doc.remove("trucks_json").toString()));if(!money)doc.remove("paid_amount");}r.put("shipment",doc);
  List<Map<String,Object>> history=jdbc.queryForList("SELECT action,actor_name,comment,payload_json,created_at FROM jsh_factory_shipping_history WHERE tenant_id=? AND head_id=? ORDER BY id",u.getTenantId(),id);if(!money)for(Map<String,Object> h:history)h.remove("payload_json");r.put("history",history);return r;
 }
 private void audit(User u,long id,String action,String comment,Object payload){
  jdbc.update("INSERT INTO jsh_factory_shipping_history(tenant_id,head_id,action,actor_id,actor_name,comment,payload_json,created_at) VALUES(?,?,?,?,?,?,?,NOW())",u.getTenantId(),id,action,u.getId(),u.getUsername(),comment,JSON.toJSONString(payload));
  if(id>0)jdbc.update("INSERT INTO jsh_factory_sales_history(tenant_id,head_id,action,actor_id,actor_name,comment,created_at) VALUES(?,?,?,?,?,?,NOW())",u.getTenantId(),id,"shipping_"+action,u.getId(),u.getUsername(),comment);
 }
 private String key(int line,Object depot,Object batch){return line+"|"+depot+"|"+batch;}
 private void photo(String ref,User u)throws Exception{
  require(ref!=null&&ref.length()<=500&&ref.startsWith("bill/"+u.getTenantId()+"/")&&!ref.contains("\\")&&ref.toLowerCase(Locale.ROOT).matches(".*\\.(png|jpg|jpeg|gif)$"),"装车照片须使用本租户上传的图片");Path root=Paths.get(fileRoot).toAbsolutePath().normalize().resolve("bill").resolve(u.getTenantId().toString()),path=Paths.get(fileRoot).toAbsolutePath().normalize().resolve(ref).normalize();require(path.startsWith(root)&&Files.isRegularFile(path)&&Files.size(path)<=10485760,"装车照片不存在、路径无效或超过10MB");try{require(ImageIO.read(path.toFile())!=null,"装车照片不是有效图片");}catch(java.io.IOException e){throw new BusinessRunTimeException(409,"照片无法读取，请重新上传有效装车照片");}
 }
 private JSONArray trucks(JSONArray input,List<Map<String,Object>> allocations,User u,boolean complete)throws Exception{
  require(input!=null&&!input.isEmpty()&&input.size()<=50,"请登记1至50辆车");Map<String,BigDecimal> quota=new HashMap<>(),used=new HashMap<>();Map<Long,String> depots=stock.depots(u);for(Map<String,Object> a:allocations)quota.put(key((int)num(a.get("lineNo")),a.get("depotId"),a.get("batchNumber")),(BigDecimal)a.get("quantity"));Set<String> plates=new HashSet<>();JSONArray result=new JSONArray();
  for(int t=0;t<input.size();t++){
   JSONObject raw=input.getJSONObject(t),truck=new JSONObject();String plate=text(raw,"plate",30,true).toUpperCase(Locale.ROOT);require(plates.add(plate),"同一车牌请合并装运明细");truck.put("plate",plate);truck.put("driver",text(raw,"driver",100,true));truck.put("phone",text(raw,"phone",50,true));JSONArray photos=raw.getJSONArray("photos");if(photos==null)photos=new JSONArray();require(photos.size()<=20&&(!complete||!photos.isEmpty()),"每辆车确认出库前须有1至20张装车照片");JSONArray pictures=new JSONArray();Set<String> uniquePhotos=new HashSet<>();for(int i=0;i<photos.size();i++){String ref=photos.getString(i);photo(ref,u);require(uniquePhotos.add(ref),"同车装车照片不能重复");pictures.add(ref);}truck.put("photos",pictures);
   JSONArray rows=raw.getJSONArray("lines"),lines=new JSONArray();require(rows!=null&&!rows.isEmpty()&&rows.size()<=500,"每辆车须填写装运产品及数量");Set<String> unique=new HashSet<>();
   for(int i=0;i<rows.size();i++){
    JSONObject row=rows.getJSONObject(i);Integer line=row.getInteger("lineNo");Long depot=row.getLong("depotId");String batch=text(row,"batchNumber",100,true);String k=key(line==null?-1:line,depot,batch);require(quota.containsKey(k)&&unique.add(k),"只能装运本订单已预留批次，同车同批次请合并数量");BigDecimal qty=row.getBigDecimal("quantity");require(qty!=null&&qty.signum()>0&&qty.scale()<=6&&qty.precision()-qty.scale()<=12,"装车数量须大于0且最多6位小数");BigDecimal total=used.getOrDefault(k,BigDecimal.ZERO).add(qty);require(total.compareTo(quota.get(k))<=0,"各车累计装运量不能超过该产品批次预留量");used.put(k,total);JSONObject clean=new JSONObject();clean.put("lineNo",line);clean.put("depotId",depot);clean.put("depotName",depots.get(depot));clean.put("batchNumber",batch);clean.put("quantity",qty);lines.add(clean);
   }truck.put("lines",lines);result.add(truck);
  }
  if(complete)for(String k:quota.keySet())require(used.getOrDefault(k,BigDecimal.ZERO).compareTo(quota.get(k))==0,"所有车辆装完后才能统一确认，各产品及批次数量须严格等于订单已预留量");return result;
 }
 @Transactional(rollbackFor=Exception.class)
 public void action(long id,JSONObject b,HttpServletRequest http)throws Exception{
  User u=actor();stock.lockForInventoryMutation();Map<String,Object> order=order(id,u,true);require("approved".equals(order.get("workflow_status")),"订单须先经领导审核");Map<String,Object> doc=shipment(id,u,true);String action=b.getString("action"),comment=text(b,"comment",2000,false);boolean owner=u.getId().longValue()==num(order.get("created_by"));
  if("request".equals(action)){
   guard.checkOrderChange(id,u.getTenantId());
   require(owner&&(doc==null||"cancelled".equals(doc.get("workflow_status"))),"仅销售订单创建人可提交尚未发货的申请");require(b.getInteger("orderVersion")!=null&&b.getInteger("orderVersion").equals(order.get("version")),"订单或预留已更新，请刷新核对");String terms=order.get("payment_terms").toString();if("unconfirmed".equals(terms))terms=text(b,"paymentTerms",20,true);require(Arrays.asList("prepay","credit").contains(terms),"请确认款到发货或账期");require(b.getString("paymentTerms")==null||terms.equals(b.getString("paymentTerms")),"付款条件须与已审核订单一致，变更请撤回订单重新审核");stock.shipmentAllocations(id,u,false);
   jdbc.update("UPDATE jsh_factory_sales_order SET payment_terms=?,version=version+1,updated_at=NOW() WHERE tenant_id=? AND head_id=?",terms,u.getTenantId(),id);
   jdbc.update("INSERT INTO jsh_factory_shipment(head_id,tenant_id,workflow_status,trucks_json,requested_by,requested_at) VALUES(?,?,'requested','[]',?,NOW()) ON DUPLICATE KEY UPDATE workflow_status='requested',version=version+1,trucks_json='[]',requested_by=VALUES(requested_by),requested_at=NOW(),paid_amount=NULL,paid_date=NULL,paid_by=NULL,paid_at=NULL",id,u.getTenantId(),u.getId());
  }else{
   require(doc!=null&&"requested".equals(doc.get("workflow_status")),"只有待装运发货申请可操作，已出库单据不能直接修改");require(b.getInteger("version")!=null&&b.getInteger("version").equals(doc.get("version")),"发货申请已更新，请重新打开");
   if("cancel".equals(action)){
    require(owner&&!comment.isEmpty(),"仅申请销售可填写原因后撤销发货申请");jdbc.update("UPDATE jsh_factory_shipment SET workflow_status='cancelled',version=version+1 WHERE tenant_id=? AND head_id=?",u.getTenantId(),id);
   }else if("paid".equals(action)||"unpaid".equals(action)){
    require(u.getId().equals(finance(u.getTenantId(),true))&&"prepay".equals(order.get("payment_terms")),"仅配置财务可确认或撤销款到发货订单的到账记录");
    if("unpaid".equals(action)){require(doc.get("paid_by")!=null&&!comment.isEmpty(),"撤销到账确认须填写原因");jdbc.update("UPDATE jsh_factory_shipment SET paid_amount=NULL,paid_date=NULL,paid_by=NULL,paid_at=NULL,version=version+1 WHERE tenant_id=? AND head_id=?",u.getTenantId(),id);}
    else{
     BigDecimal amount=b.getBigDecimal("amount");require(amount!=null&&amount.scale()<=2&&amount.precision()-amount.scale()<=18&&amount.compareTo((BigDecimal)order.get("total_price"))>=0,"确认到账金额须覆盖整单含税金额且最多2位小数");String date=text(b,"paidDate",10,true);try{require(!LocalDate.parse(date).isAfter(LocalDate.now()),"到账日期不能晚于今天");}catch(java.time.format.DateTimeParseException e){throw new BusinessRunTimeException(409,"到账日期格式无效");}jdbc.update("UPDATE jsh_factory_shipment SET paid_amount=?,paid_date=?,paid_by=?,paid_at=NOW(),version=version+1 WHERE tenant_id=? AND head_id=?",amount,date,u.getId(),u.getTenantId(),id);
    }
   }else if("trucks".equals(action)||"ship".equals(action)){
    require(stock.canManageWarehouse(u),"仅仓库人员可登记装车及统一确认出库");List<Map<String,Object>> allocations=stock.shipmentAllocations(id,u,true);
    if("trucks".equals(action)){JSONArray saved=trucks(b.getJSONArray("trucks"),allocations,u,false);jdbc.update("UPDATE jsh_factory_shipment SET trucks_json=?,version=version+1 WHERE tenant_id=? AND head_id=?",saved.toJSONString(),u.getTenantId(),id);}
    else{
     require(!"prepay".equals(order.get("payment_terms"))||doc.get("paid_by")!=null&&((BigDecimal)doc.get("paid_amount")).compareTo((BigDecimal)order.get("total_price"))>=0,"款到发货订单须先由财务确认整单款项到账");trucks(JSONArray.parseArray(doc.get("trucks_json").toString()),allocations,u,true);stock.consumeForShipment(id,u,allocations);post(id,order,allocations,u,http);jdbc.update("UPDATE jsh_factory_shipment SET workflow_status='shipped',shipped_by=?,shipped_at=NOW(),version=version+1 WHERE tenant_id=? AND head_id=?",u.getId(),u.getTenantId(),id);
    }
   }else throw new BusinessRunTimeException(409,"无效的发货操作");
  }
  audit(u,id,action,comment,b);
 }
 private void post(long id,Map<String,Object> order,List<Map<String,Object>> allocations,User u,HttpServletRequest http)throws Exception{
  JSONArray products=JSONArray.parseArray(order.get("lines_json").toString()),ledger=new JSONArray();Map<String,JSONObject> grouped=new LinkedHashMap<>();BigDecimal total=BigDecimal.ZERO;
  for(Map<String,Object> a:allocations){JSONObject p=products.getJSONObject((int)num(a.get("lineNo")));String key=a.get("materialId")+"|"+a.get("depotId")+"|"+a.get("batchNumber");JSONObject row=grouped.get(key);if(row==null){row=new JSONObject();row.put("barCode",p.get("barCode"));row.put("unit","吨");row.put("depotId",a.get("depotId"));row.put("batchNumber",a.get("batchNumber"));row.put("operNumber",BigDecimal.ZERO);List<BigDecimal> costs=jdbc.queryForList("SELECT current_unit_price FROM jsh_material_current_stock WHERE tenant_id=? AND material_id=? AND depot_id=? AND IFNULL(delete_flag,'0')='0'",BigDecimal.class,u.getTenantId(),a.get("materialId"),a.get("depotId"));row.put("unitPrice",costs.isEmpty()||costs.get(0)==null?BigDecimal.ZERO:costs.get(0));grouped.put(key,row);}row.put("operNumber",row.getBigDecimal("operNumber").add((BigDecimal)a.get("quantity")));}
  for(JSONObject row:grouped.values()){
   List<Long> material=jdbc.queryForList("SELECT m.id FROM jsh_material m JOIN jsh_material_extend e ON e.material_id=m.id AND e.tenant_id=m.tenant_id WHERE m.tenant_id=? AND e.bar_code=? AND m.enabled=1 AND m.unit='吨' AND e.commodity_unit='吨' AND m.enable_batch_number='1' AND IFNULL(m.delete_flag,'0')='0' AND IFNULL(e.delete_flag,'0')='0' FOR UPDATE",Long.class,u.getTenantId(),row.getString("barCode"));
   Long expected=null;for(Object value:products){JSONObject p=(JSONObject)value;if(row.getString("barCode").equals(p.getString("barCode")))expected=p.getLong("id");}require(material.size()==1&&Objects.equals(material.get(0),expected),"装运商品档案、批次设置或基本单位已变化，请先核实");
  }
  for(JSONObject row:grouped.values()){BigDecimal amount=row.getBigDecimal("operNumber").multiply(row.getBigDecimal("unitPrice")).setScale(2,RoundingMode.HALF_UP);row.put("allPrice",amount);row.put("taxLastMoney",amount);row.put("taxRate",BigDecimal.ZERO);row.put("taxMoney",BigDecimal.ZERO);row.put("remark","销售订单 "+order.get("number"));total=total.add(amount);ledger.add(row);}
  JSONObject head=new JSONObject();String number="DDCK"+id;head.put("number",number);head.put("type","出库");head.put("subType","其它");head.put("status","1");head.put("operTime",LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));head.put("remark","订单整单发货 "+order.get("number"));head.put("linkNumber",order.get("number"));head.put("payType","现付");head.put("totalPrice",total);head.put("discountLastMoney",total);for(String key:Arrays.asList("discount","discountMoney","changeAmount","debt","otherMoney"))head.put(key,BigDecimal.ZERO);
  guard.enter();try{heads.addDepotHeadAndDetail(head.toJSONString(),ledger.toJSONString(),http);}finally{guard.leave();}Long ledgerId=jdbc.queryForObject("SELECT id FROM jsh_depot_head WHERE tenant_id=? AND number=?",Long.class,u.getTenantId(),number);jdbc.update("UPDATE jsh_factory_shipment SET ledger_head_id=? WHERE tenant_id=? AND head_id=?",ledgerId,u.getTenantId(),id);
 }
}
