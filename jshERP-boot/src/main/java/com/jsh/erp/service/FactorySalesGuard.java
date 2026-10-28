package com.jsh.erp.service;
import org.springframework.stereotype.Component;
import org.springframework.jdbc.core.JdbcTemplate;
import com.jsh.erp.exception.BusinessRunTimeException;
import javax.annotation.Resource;
@Component
public class FactorySalesGuard {
 @Resource private JdbcTemplate jdbc;
 @Resource private UserService users;
 private final ThreadLocal<Boolean> internal = new ThreadLocal<>();
 public void enter(){internal.set(true);}
 public void leave(){internal.remove();}
 public void checkOrderChange(long head,long tenant){
  if(!jdbc.queryForList("SELECT id FROM jsh_factory_order_change WHERE tenant_id=? AND head_id=? AND workflow_status IN('pending','approved') FOR UPDATE",Long.class,tenant,head).isEmpty())throw new BusinessRunTimeException(409,"订单存在待处理变更，请先完成变更流程后再申请发货或撤回订单");
 }
 public void checkProduction(long head,long tenant){
  if(!jdbc.queryForList("SELECT head_id FROM jsh_factory_sales_order WHERE tenant_id=? AND head_id=? AND workflow_status='cancelled' FOR UPDATE",Long.class,tenant,head).isEmpty())throw new BusinessRunTimeException(409,"订单已取消并停产，只能继续处理历史质检、入库和退料");
  if(!jdbc.queryForList("SELECT id FROM jsh_factory_order_change WHERE tenant_id=? AND head_id=? AND workflow_status='approved' FOR UPDATE",Long.class,tenant,head).isEmpty())throw new BusinessRunTimeException(409,"订单变更已批准，待生产统筹落实后才能继续新增生产和领补料");
 }
 public void check(Long id){
  if(id!=null && jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_customer_return WHERE ledger_head_id=?",Integer.class,id)>0)throw new BusinessRunTimeException(409,"客户退货收货库存单不能直接修改、删除或反审核，请从退货模块处理");
  if(id!=null && jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_shipment WHERE ledger_head_id=?",Integer.class,id)>0)throw new BusinessRunTimeException(409,"整单发货库存单不能直接修改、删除或反审核，请从发货模块处理");
  if(id!=null && jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_finished_batch WHERE ledger_head_id=?",Integer.class,id)>0)throw new BusinessRunTimeException(409,"成品整批入库单不能直接修改、删除或反审核，请从成品模块处理");
  if(id!=null && jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_material_request WHERE ledger_head_id=?",Integer.class,id)>0)throw new BusinessRunTimeException(409,"车间领退料库存单不能直接修改、删除或反审核，请从领补退料模块处理");
  if(id!=null && !Boolean.TRUE.equals(internal.get()) && jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_sales_order WHERE head_id=?",Integer.class,id)>0)
   throw new BusinessRunTimeException(409,"工厂销售订单请从销售订单页面操作，不能绕过提交审核流程");
 }
 public void checkIds(String ids){if(ids!=null)for(String id:ids.split(","))check(Long.valueOf(id.trim()));}
 public void checkLinks(String... links)throws Exception{
  if(Boolean.TRUE.equals(internal.get()))return;
  com.jsh.erp.datasource.entities.User user=users.getCurrentUser();if(user==null||user.getTenantId()==null)return;
  for(String link:links)if(link!=null)for(String number:link.split(","))if(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_shipment sh JOIN jsh_depot_head h ON h.id=sh.ledger_head_id AND h.tenant_id=sh.tenant_id WHERE sh.tenant_id=? AND h.number=?",Integer.class,user.getTenantId(),number.trim())>0)throw new BusinessRunTimeException(409,"工厂发货退货必须从客户退货申请与收货模块处理");
  for(String link:links)if(link!=null)for(String number:link.split(","))if(jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_sales_order f JOIN jsh_depot_head h ON h.id=f.head_id AND h.tenant_id=f.tenant_id WHERE f.tenant_id=? AND h.number=? AND IFNULL(h.delete_flag,'0')='0'",Integer.class,user.getTenantId(),number.trim())>0)throw new BusinessRunTimeException(409,"工厂订单发货必须从发货申请与装车出库模块统一确认，不能直接创建关联出库单");
 }
}
