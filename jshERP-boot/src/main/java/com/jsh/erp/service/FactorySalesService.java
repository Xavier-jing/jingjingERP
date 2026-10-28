package com.jsh.erp.service;
import com.alibaba.fastjson.*;
import com.jsh.erp.datasource.entities.User;
import com.jsh.erp.exception.BusinessRunTimeException;
import org.springframework.stereotype.Service;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import java.math.*;
import java.time.*;
import java.util.*;
@Service
public class FactorySalesService {
 @Resource private JdbcTemplate jdbc;
 @Resource private UserService users;
 @Resource private DepotHeadService heads;
 @Resource private FactorySalesGuard guard;
 @Resource private FactoryStockService stock;
 @Resource private UserBusinessService business;
 private void require(boolean ok,String message){if(!ok)throw new BusinessRunTimeException(409,message);}
 public User actor() throws Exception {
  User u=users.getCurrentUser();require(u!=null && u.getTenantId()!=null && u.getTenantId()>0,"请使用业务租户账号操作");
  boolean allowed=u.getId().equals(u.getTenantId()) || u.getId().equals(reviewer(u.getTenantId()));
  if(!allowed)for(com.jsh.erp.datasource.entities.UserBusiness role:business.getBasicData(u.getId().toString(),"UserRole")){
   String id=role.getValue().replace("[", "").replace("]", "");
   for(com.jsh.erp.datasource.entities.UserBusiness f:business.getBasicData(id,"RoleFunctions"))if(f.getValue()!=null && f.getValue().contains("[242]"))allowed=true;
  }
  require(allowed,"没有销售订单访问权限");return u;
 }
 private Long reviewer(Long tenant){List<Long> ids=jdbc.queryForList("SELECT reviewer_id FROM jsh_factory_sales_config WHERE tenant_id=?",Long.class,tenant);return ids.isEmpty()?null:ids.get(0);}
 public Map<String,Object> options() throws Exception {
  User u=actor();Map<String,Object> o=new HashMap<>();o.put("currentUserId",u.getId());o.put("canConfigure",u.getId().equals(u.getTenantId()));o.put("reviewerId",reviewer(u.getTenantId()));
  o.put("users",jdbc.queryForList("SELECT id,username,login_name FROM jsh_user WHERE tenant_id=? AND status=0 AND IFNULL(delete_flag,'0')='0' ORDER BY id",u.getTenantId()));
  o.put("customers",jdbc.queryForList("SELECT id,supplier FROM jsh_supplier WHERE tenant_id=? AND type='客户' AND IFNULL(delete_flag,'0')='0' AND enabled=1 ORDER BY id",u.getTenantId()));
  o.put("products",jdbc.queryForList("SELECT m.id,m.name,IFNULL(m.brand,'') brand,IFNULL(m.standard,'') standard,IFNULL(m.model,'') model,e.bar_code barCode FROM jsh_material m JOIN jsh_material_extend e ON e.material_id=m.id AND e.tenant_id=m.tenant_id WHERE m.tenant_id=? AND m.enabled=1 AND m.material_kind='product' AND m.unit='吨' AND e.commodity_unit='吨' AND IFNULL(m.delete_flag,'0')='0' AND IFNULL(e.delete_flag,'0')='0' ORDER BY m.name,m.brand,m.standard,e.id",u.getTenantId()));return o;
 }
 @Transactional(rollbackFor=Exception.class)
 public void configure(Long id) throws Exception {
  User u=actor();require(u.getId().equals(u.getTenantId()),"仅租户负责人可配置固定审核人");
  jdbc.update("INSERT IGNORE INTO jsh_factory_sales_config VALUES(?,?,NOW())",u.getTenantId(),u.getId());
  jdbc.queryForList("SELECT tenant_id FROM jsh_factory_sales_config WHERE tenant_id=? FOR UPDATE",u.getTenantId());
  require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_sales_order WHERE tenant_id=? AND workflow_status='pending'",Integer.class,u.getTenantId())==0,"存在待审核订单，暂不能更换审核人");
  require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_user WHERE id=? AND tenant_id=? AND status=0 AND IFNULL(delete_flag,'0')='0'",Integer.class,id,u.getTenantId())==1,"请选择本租户的有效审核账号");
  jdbc.update("UPDATE jsh_factory_sales_config SET reviewer_id=?,updated_at=NOW() WHERE tenant_id=?",id,u.getTenantId());history(0L,u,"configure_reviewer","固定审核账号ID："+id);
 }
 public Map<String,Object> list(String keyword,String state,int page,int size,Map<String,String> filters) throws Exception {
  User u=actor();String k=keyword==null?"":keyword.trim();require(k.length()<=100,"搜索内容过长");require(page>0 && page<=100000 && size>0 && size<=100,"分页参数不合法");
  StringBuilder from=new StringBuilder(" FROM jsh_factory_sales_order f JOIN jsh_depot_head h ON h.id=f.head_id LEFT JOIN jsh_supplier s ON s.id=h.organ_id LEFT JOIN jsh_user u ON u.id=f.created_by LEFT JOIN jsh_account a ON a.id=h.account_id AND a.tenant_id=f.tenant_id WHERE f.tenant_id=? AND IFNULL(h.delete_flag,'0')='0'");
  List<Object> args=new ArrayList<>();args.add(u.getTenantId());
  if(!k.isEmpty()){from.append(" AND (h.number LIKE ? OR s.supplier LIKE ?)");args.add("%"+k+"%");args.add("%"+k+"%");}
  if(state!=null && !state.isEmpty()){from.append(" AND f.workflow_status=?");args.add(state);}
  for(String key:Arrays.asList("number","remark")){
   String value=filters.get(key);if(value!=null && !value.trim().isEmpty()){require(value.length()<=500,"查询内容过长");from.append(" AND h.").append(key).append(" LIKE ?");args.add("%"+value.trim()+"%");}
  }
  for(String key:Arrays.asList("customerId","creatorId")){
   String value=filters.get(key);if(value!=null && !value.isEmpty()){require(value.matches("[0-9]{1,18}"),"查询人员或客户编号无效");from.append(" AND ").append("customerId".equals(key)?"h.organ_id":"f.created_by").append("=?");args.add(Long.valueOf(value));}
  }
  String product=filters.get("material");
  if(product!=null && !product.trim().isEmpty()){
   require(product.length()<=100,"商品查询内容过长");
   from.append(" AND (JSON_SEARCH(f.lines_json,'one',?,NULL,'$[*].name','$[*].brand','$[*].standard','$[*].model','$[*].barCode') IS NOT NULL OR EXISTS (SELECT 1 FROM jsh_depot_item di JOIN jsh_material m ON m.id=di.material_id AND m.tenant_id=di.tenant_id WHERE di.header_id=f.head_id AND di.tenant_id=f.tenant_id AND IFNULL(di.delete_flag,'0')='0' AND m.mnemonic LIKE ?))");args.add("%"+product.trim()+"%");args.add("%"+product.trim()+"%");
  }
  LocalDate begin=null,end=null;
  try{if(filters.get("beginDate")!=null && !filters.get("beginDate").isEmpty())begin=LocalDate.parse(filters.get("beginDate"));if(filters.get("endDate")!=null && !filters.get("endDate").isEmpty())end=LocalDate.parse(filters.get("endDate"));}catch(Exception e){throw new BusinessRunTimeException(409,"单据日期格式不正确");}
  require(begin==null || end==null || !begin.isAfter(end),"开始日期不能晚于结束日期");
  if(begin!=null){from.append(" AND h.create_time>=?");args.add(begin.toString()+" 00:00:00");}
  if(end!=null){from.append(" AND h.create_time<?");args.add(end.plusDays(1).toString()+" 00:00:00");}
  Map<String,Object> result=new HashMap<>();result.put("total",jdbc.queryForObject("SELECT COUNT(*)"+from,Long.class,args.toArray()));
  args.add(size);args.add((page-1)*size);
  List<Map<String,Object>> resultRows=jdbc.queryForList("SELECT f.head_id,f.tenant_id,f.delivery_date,f.workflow_status,f.version,f.created_by,h.number,h.create_time order_date,h.organ_id,h.remark,h.total_price,h.discount,h.discount_money,h.discount_last_money,h.change_amount,h.last_deposit,a.name account_name,s.supplier customer_name,u.username creator_name,f.lines_json"+from+" ORDER BY f.head_id DESC LIMIT ? OFFSET ?",args.toArray());
  for(Map<String,Object> row:resultRows){JSONArray lines=JSONArray.parseArray(row.remove("lines_json").toString());BigDecimal quantity=BigDecimal.ZERO;List<String> products=new ArrayList<>();for(int n=0;n<lines.size();n++){JSONObject line=lines.getJSONObject(n);quantity=quantity.add(line.getBigDecimal("quantity"));products.add(line.getString("name")+" / "+line.getString("brand")+" / "+line.getString("standard")+" / "+line.getString("model"));}row.put("material_count",quantity);row.put("materials_list",String.join("；",products));}
  result.put("rows",resultRows);return result;
 }
 private Map<String,Object> lock(Long id,User u){
  List<Map<String,Object>> list=jdbc.queryForList("SELECT f.*,h.number,h.organ_id,h.remark,h.total_price FROM jsh_factory_sales_order f JOIN jsh_depot_head h ON h.id=f.head_id WHERE f.head_id=? AND f.tenant_id=? AND IFNULL(h.delete_flag,'0')='0' FOR UPDATE",id,u.getTenantId());
  require(!list.isEmpty(),"订单不存在或无权访问");return list.get(0);
 }
 public Map<String,Object> detail(Long id) throws Exception {
  User u=actor();List<Map<String,Object>> rows=jdbc.queryForList("SELECT f.*,h.number,h.organ_id,h.remark,h.total_price FROM jsh_factory_sales_order f JOIN jsh_depot_head h ON h.id=f.head_id WHERE f.head_id=? AND f.tenant_id=? AND IFNULL(h.delete_flag,'0')='0'",id,u.getTenantId());
  require(!rows.isEmpty(),"订单不存在或无权访问");Map<String,Object> result=rows.get(0);
  result.put("shipment",jdbc.queryForList("SELECT workflow_status,requested_at,shipped_at,ledger_head_id FROM jsh_factory_shipment WHERE tenant_id=? AND head_id=?",u.getTenantId(),id));
  List<Map<String,Object>> production=jdbc.queryForList("SELECT number,workflow_status,updated_at FROM jsh_factory_production_task WHERE head_id=? AND tenant_id=?",id,u.getTenantId());for(Map<String,Object> entry:production)entry.put("workshops",jdbc.queryForList("SELECT workshop_no,workflow_status FROM jsh_factory_workshop_task WHERE tenant_id=? AND head_id=? ORDER BY workshop_no",u.getTenantId(),id));result.put("production",production);result.put("stock",stock.salesSummary(id,u));result.put("lines",JSONArray.parseArray((String)result.remove("lines_json")));result.put("history",jdbc.queryForList("SELECT action,actor_name,comment,created_at FROM jsh_factory_sales_history WHERE head_id=? AND tenant_id=? ORDER BY id",id,u.getTenantId()));return result;
 }
 private String text(JSONObject b,String key,int max,boolean required){String s=b.getString(key);s=s==null?"":s.trim();require(!required||!s.isEmpty(),key+"不能为空");require(s.length()<=max,key+"内容过长");return s;}
 private void history(Long id,User u,String action,String comment){jdbc.update("INSERT INTO jsh_factory_sales_history(tenant_id,head_id,action,actor_id,actor_name,comment,created_at) VALUES(?,?,?,?,?,?,NOW())",u.getTenantId(),id,action,u.getId(),u.getUsername(),comment);}
 @Transactional(rollbackFor=Exception.class)
 public Long save(JSONObject b,HttpServletRequest request) throws Exception {
  User u=actor();stock.lockForInventoryMutation();Long id=b.getLong("id");Map<String,Object> old=null;
  if(id!=null){old=lock(id,u);require(u.getId().equals(((Number)old.get("created_by")).longValue()),"仅订单创建人可修改");require(Arrays.asList("draft","returned").contains(old.get("workflow_status")),"请先撤回，待审核或已通过订单不能直接修改");require(b.getInteger("version")!=null && b.getInteger("version").equals(old.get("version")),"订单已被更新，请刷新后再操作");}
  Long customer=b.getLong("customerId");require(customer!=null && jdbc.queryForObject("SELECT COUNT(*) FROM jsh_supplier WHERE id=? AND tenant_id=? AND type='客户' AND enabled=1 AND IFNULL(delete_flag,'0')='0'",Integer.class,customer,u.getTenantId())==1,"请选择有效客户");
  String delivery=text(b,"deliveryDate",10,true);try{LocalDate.parse(delivery);}catch(Exception e){throw new BusinessRunTimeException(409,"交货日期格式应为YYYY-MM-DD");}
  String requirements=text(b,"requirements",4000,false),remark=text(b,"remark",500,false);
  String terms=b.getString("paymentTerms");if(terms==null)terms=old==null?"unconfirmed":old.get("payment_terms").toString();require(Arrays.asList("unconfirmed","prepay","credit").contains(terms),"请选择款到发货或账期");
  JSONArray input=b.getJSONArray("lines");require(input!=null && input.size()>0 && input.size()<=100,"请填写1至100行产品明细");JSONArray lines=new JSONArray();BigDecimal total=BigDecimal.ZERO;
  for(int i=0;i<input.size();i++){
   JSONObject row=input.getJSONObject(i);String barCode=text(row,"barCode",100,true);
   List<Map<String,Object>> products=jdbc.queryForList("SELECT m.id,m.name,IFNULL(m.brand,'') brand,IFNULL(m.standard,'') standard,IFNULL(m.model,'') model FROM jsh_material m JOIN jsh_material_extend e ON e.material_id=m.id AND e.tenant_id=m.tenant_id WHERE e.bar_code=? AND m.tenant_id=? AND m.material_kind='product' AND m.unit='吨' AND e.commodity_unit='吨' AND m.enabled=1 AND IFNULL(m.delete_flag,'0')='0' AND IFNULL(e.delete_flag,'0')='0'",barCode,u.getTenantId());require(products.size()==1,"产品不存在、已停用或基本单位不是吨");
   BigDecimal qty=row.getBigDecimal("quantity"),price=row.getBigDecimal("price");require(qty!=null && qty.signum()>0 && qty.precision()-qty.scale()<=12 && qty.scale()<=6,"数量必须大于0，最多6位小数");require(price!=null && price.signum()>=0 && price.precision()-price.scale()<=12 && price.scale()<=6,"含税单价不可为负，最多6位小数");
   BigDecimal amount=qty.multiply(price).setScale(2,RoundingMode.HALF_UP);total=total.add(amount);Map<String,Object> product=products.get(0);require(!product.get("brand").toString().trim().isEmpty() && !(product.get("standard").toString()+product.get("model").toString()).trim().isEmpty(),"请先在商品档案维护牌号商标及规格型号");JSONObject line=new JSONObject(product);
   line.put("barCode",barCode);line.put("unit","吨");line.put("operNumber",qty);line.put("quantity",qty);line.put("price",price);line.put("unitPrice",price);line.put("allPrice",amount);line.put("taxLastMoney",amount);line.put("taxMoney",BigDecimal.ZERO);line.put("remark",text(row,"remark",500,false));lines.add(line);
  }
  require(total.precision()-total.scale()<=18,"订单总金额超过允许范围");
  JSONObject h=new JSONObject();String number=id==null?"XSDD"+LocalDate.now().toString().replace("-","")+UUID.randomUUID().toString().substring(0,12).toUpperCase():old.get("number").toString();
  h.put("number",number);h.put("type","其它");h.put("subType","销售订单");h.put("status","0");h.put("organId",customer);h.put("operTime",java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));h.put("remark",remark);h.put("totalPrice",total);h.put("discount",BigDecimal.ZERO);h.put("discountMoney",BigDecimal.ZERO);h.put("discountLastMoney",total);h.put("changeAmount",BigDecimal.ZERO);h.put("debt",BigDecimal.ZERO);h.put("otherMoney",BigDecimal.ZERO);h.put("payType","现付");
  guard.enter();try{
   if(id==null){heads.addDepotHeadAndDetail(h.toJSONString(),lines.toJSONString(),request);id=jdbc.queryForObject("SELECT id FROM jsh_depot_head WHERE number=? AND tenant_id=?",Long.class,number,u.getTenantId());jdbc.update("INSERT INTO jsh_factory_sales_order(head_id,tenant_id,delivery_date,requirements,workflow_status,version,lines_json,created_by,updated_at) VALUES(?,?,?,?,'draft',1,?,?,NOW())",id,u.getTenantId(),delivery,requirements,lines.toJSONString(),u.getId());}
   else{h.put("id",id);heads.updateDepotHeadAndDetail(h.toJSONString(),lines.toJSONString(),request);jdbc.update("UPDATE jsh_factory_sales_order SET delivery_date=?,requirements=?,lines_json=?,version=version+1,updated_at=NOW() WHERE head_id=? AND tenant_id=?",delivery,requirements,lines.toJSONString(),id,u.getTenantId());}
  }finally{guard.leave();}
  jdbc.update("UPDATE jsh_factory_sales_order SET payment_terms=? WHERE tenant_id=? AND head_id=?",terms,u.getTenantId(),id);history(id,u,old==null?"create":"edit", "保存含税订单；金额按明细计算");return id;
 }
 @Transactional(rollbackFor=Exception.class)
 public void action(Long id,JSONObject b) throws Exception {
  User u=actor();if(Arrays.asList("withdraw","unapprove","delete").contains(b.getString("action")))stock.lockForInventoryMutation();Map<String,Object> order=lock(id,u);require(b.getInteger("version")!=null && b.getInteger("version").equals(order.get("version")),"订单已更新，请刷新");String action=b.getString("action"),state=order.get("workflow_status").toString(),next=null;String comment=text(b,"comment",2000,false);
  boolean owner=u.getId().equals(((Number)order.get("created_by")).longValue());
  if(Arrays.asList("withdraw","unapprove","delete").contains(action))guard.checkOrderChange(id,u.getTenantId());
  if("submit".equals(action)){
   require(owner && Arrays.asList("draft","returned").contains(state),"仅创建人可提交草稿或退回订单");
   require(Arrays.asList("prepay","credit").contains(order.get("payment_terms")),"请先选择款到发货或账期，再提交订单审核");
   jdbc.queryForList("SELECT tenant_id FROM jsh_factory_sales_config WHERE tenant_id=? FOR UPDATE",u.getTenantId());
   Long reviewer=reviewer(u.getTenantId());require(reviewer!=null,"请先配置固定审核人");
   require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_user WHERE id=? AND tenant_id=? AND status=0 AND IFNULL(delete_flag,'0')='0'",Integer.class,reviewer,u.getTenantId())==1,"审核账号已停用，请重新配置");next="pending";
  }else if("approve".equals(action)||"return".equals(action)){
   require("pending".equals(state) && u.getId().equals(reviewer(u.getTenantId())),"仅固定审核人可审核待审核订单");
   require(!"return".equals(action)||!comment.isEmpty(),"退回必须填写原因");next="approve".equals(action)?"approved":"returned";
  }else if("delete".equals(action)){
   require(owner && Arrays.asList("draft","returned").contains(state),"仅创建人可删除草稿或已退回订单，请先完成撤回或反审核");
   requireNoFollowing(order,u);stock.releaseForOrder(id,u,"删除订单，释放预留");
   jdbc.update("UPDATE jsh_depot_item SET delete_flag='1' WHERE header_id=? AND tenant_id=?",id,u.getTenantId());
   jdbc.update("UPDATE jsh_depot_head SET delete_flag='1' WHERE id=? AND tenant_id=?",id,u.getTenantId());
   jdbc.update("UPDATE jsh_factory_sales_order SET version=version+1,updated_at=NOW() WHERE head_id=? AND tenant_id=?",id,u.getTenantId());history(id,u,action,"删除订单（保留操作记录）");return;
  }else if("unapprove".equals(action)){
   require("approved".equals(state) && u.getId().equals(reviewer(u.getTenantId())),"仅固定审核人可反审核已通过订单");
   requireNoFollowing(order,u);stock.releaseForOrder(id,u,"销售订单反审核，自动释放预留");next="draft";
  }else if("withdraw".equals(action)){
   require(owner && Arrays.asList("pending","approved").contains(state),"仅创建人可撤回待审核或已通过订单");
   require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_depot_head WHERE tenant_id=? AND (link_number=? OR link_apply=?) AND IFNULL(delete_flag,'0')='0'",Integer.class,u.getTenantId(),order.get("number"),order.get("number"))==0,"已关联后续业务，需审核人决定变更处理");requireNoProduction(id,u);stock.releaseForOrder(id,u,"销售撤回订单，自动释放预留");next="draft";
  }else throw new BusinessRunTimeException(409,"不支持的操作");
  jdbc.update("UPDATE jsh_factory_sales_order SET workflow_status=?,version=version+1,updated_at=NOW() WHERE head_id=? AND tenant_id=?",next,id,u.getTenantId());
  jdbc.update("UPDATE jsh_depot_head SET status=? WHERE id=? AND tenant_id=?","approved".equals(next)?"1":"pending".equals(next)?"9":"0",id,u.getTenantId());history(id,u,action,comment);
 }
 private void requireNoProduction(long id,User u){stock.requireNoShipment(id,u);require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_production_task WHERE head_id=? AND tenant_id=? AND workflow_status<>'cancelled'",Integer.class,id,u.getTenantId())==0,"已创建生产联系表，请先撤销联系表；已接单任务需与主任协调");}
 private void requireNoFollowing(Map<String,Object> order,User u){
  requireNoProduction(((Number)order.get("head_id")).longValue(),u);
  require(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_depot_head WHERE tenant_id=? AND (link_number=? OR link_apply=?) AND IFNULL(delete_flag,'0')='0'",Integer.class,u.getTenantId(),order.get("number"),order.get("number"))==0,"已关联后续业务，需先处理关联单据");
 }
 @Transactional(rollbackFor=Exception.class)
 public void deleteOrders(JSONArray rows) throws Exception {
  require(rows!=null && !rows.isEmpty() && rows.size()<=100,"请选择1至100张订单");
  List<JSONObject> sorted=new ArrayList<>();for(int n=0;n<rows.size();n++)sorted.add(rows.getJSONObject(n));sorted.sort(Comparator.comparingLong(row->row.getLongValue("id")));
  for(JSONObject row:sorted){row.put("action","delete");action(row.getLong("id"),row);}
 }
}
