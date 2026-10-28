package com.jsh.erp.service;

import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.jsh.erp.datasource.entities.User;
import com.jsh.erp.datasource.entities.UserBusiness;
import com.jsh.erp.exception.BusinessRunTimeException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationAdapter;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import javax.annotation.Resource;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;

@Service
public class FactoryStockService {
    @Resource private JdbcTemplate jdbc;
    @Resource private UserService users;
    @Resource private UserBusinessService business;

    private void require(boolean ok,String message) {
        if(!ok) throw new BusinessRunTimeException(409,message);
    }
    private long number(Object value) { return ((Number)value).longValue(); }
    private BigDecimal decimal(Object value) { return value==null?BigDecimal.ZERO:new BigDecimal(value.toString()); }
    private String lotKey(Object material,Object depot,Object batch) { return material+"|"+depot+"|"+batch; }

    private User actor() throws Exception {
        User user=users.getCurrentUser();
        require(user!=null && user.getTenantId()!=null && user.getTenantId()>0,"请使用业务租户账号");
        require(canManageWarehouse(user),"没有订单库存核查权限");return user;
    }
    boolean canManageWarehouse(User user) throws Exception {
        boolean permitted=user.getId().equals(user.getTenantId());
        Long menu=jdbc.queryForObject("SELECT id FROM jsh_function WHERE url='/factory/stock_check' AND enabled=1 AND IFNULL(delete_flag,'0')='0'",Long.class);
        for(UserBusiness role:business.getBasicData(user.getId().toString(),"UserRole")) {
            String id=role.getValue().replace("[","").replace("]","");
            for(UserBusiness functions:business.getBasicData(id,"RoleFunctions")) {
                if(functions.getValue()!=null && functions.getValue().contains("["+menu+"]")) permitted=true;
            }
        }
        return permitted;
    }

    // The existing app also writes stock. A small per-tenant transaction lock keeps those
    // writes and reservations in the same serialization boundary on this local server.
    public void lockForInventoryMutation() throws Exception {
        User user=users.getCurrentUser();
        require(user!=null && user.getTenantId()!=null && user.getTenantId()>0,"请使用业务租户账号操作库存");
        require(TransactionSynchronizationManager.isActualTransactionActive(),"库存修改需要事务");
        long tenant=user.getTenantId();
        // Acquire the exclusive row lock directly; INSERT IGNORE plus lock upgrade can deadlock.
        jdbc.update("INSERT INTO jsh_factory_stock_lock(tenant_id) VALUES(?) ON DUPLICATE KEY UPDATE tenant_id=VALUES(tenant_id)",tenant);
        for(TransactionSynchronization sync:TransactionSynchronizationManager.getSynchronizations()) {
            if(sync instanceof StockCheck && ((StockCheck)sync).tenant==tenant) return;
        }
        TransactionSynchronizationManager.registerSynchronization(new StockCheck(tenant));
    }
    private class StockCheck extends TransactionSynchronizationAdapter {
        private final long tenant;
        StockCheck(long tenant) { this.tenant=tenant; }
        @Override public void beforeCommit(boolean readOnly) {
            List<Map<String,Object>> flags=config(tenant,true);String effective="";
            if(!flags.isEmpty()&&"1".equals(flags.get(0).get("force_approval_flag")))effective+=" AND h.status='1'";
            if(!flags.isEmpty()&&"1".equals(flags.get(0).get("in_out_manage_flag")))effective+=" AND h.sub_type NOT IN ('采购','采购退货','销售','销售退货')";
            for(Map<String,Object> batch:jdbc.queryForList("SELECT material_id,batch_number,quantity,release_state FROM jsh_factory_finished_batch WHERE tenant_id=? AND ledger_head_id IS NOT NULL FOR UPDATE",tenant)){
                Map<String,Object> usage=jdbc.queryForMap("SELECT COALESCE(SUM(di.basic_number),0) quantity,COALESCE(SUM(di.basic_number<=0),0) invalid FROM jsh_depot_item di JOIN jsh_depot_head h ON h.id=di.header_id AND h.tenant_id=di.tenant_id WHERE di.tenant_id=? AND di.material_id=? AND di.batch_number=? AND h.type='出库' AND IFNULL(di.delete_flag,'0')='0' AND IFNULL(h.delete_flag,'0')='0'"+effective+" FOR UPDATE",tenant,batch.get("material_id"),batch.get("batch_number"));
                require(decimal(usage.get("invalid")).signum()==0,"成品批次出库数量必须大于0");BigDecimal out=decimal(usage.get("quantity"));
                require(out.signum()==0||"released".equals(batch.get("release_state")),"该成品批次尚未由领导整批放行，不能出库");
                BigDecimal returned=jdbc.queryForObject("SELECT COALESCE(SUM(l.quantity),0) FROM jsh_factory_customer_return_line l JOIN jsh_factory_customer_return r ON r.id=l.return_id AND r.tenant_id=l.tenant_id JOIN jsh_depot_item di ON di.id=l.source_item_id AND di.tenant_id=l.tenant_id WHERE r.tenant_id=? AND r.workflow_status='received' AND di.material_id=? AND di.batch_number=? FOR UPDATE",BigDecimal.class,tenant,batch.get("material_id"),batch.get("batch_number"));
                require(out.subtract(returned).compareTo(decimal(batch.get("quantity")))<=0,"该成品批次净出库不能超过整批放行数量（已扣除确认收货的客户退货）");
            }
            List<Map<String,Object>> reserved=jdbc.queryForList("SELECT material_id,depot_id,batch_number,quantity FROM jsh_factory_stock_reservation WHERE tenant_id=? FOR UPDATE",tenant);
            if(reserved.isEmpty()) return;
            Map<String,BigDecimal> totals=new HashMap<>();
            for(Map<String,Object> row:reserved) {
                String key=lotKey(row.get("material_id"),row.get("depot_id"),row.get("batch_number"));
                totals.put(key,totals.getOrDefault(key,BigDecimal.ZERO).add(decimal(row.get("quantity"))));
            }
            Map<String,Map<String,Object>> stock=stock(tenant,true);
            for(Map.Entry<String,BigDecimal> item:totals.entrySet()) {
                Map<String,Object> lot=stock.get(item.getKey());
                require(lot!=null && decimal(lot.get("eligible")).compareTo(item.getValue())>=0,
                    "操作会占用或减少已预留的合格库存，请先调整相关订单预留");
            }
        }
    }

    private List<Map<String,Object>> config(long tenant,boolean current) {
        return jdbc.queryForList("SELECT depot_flag,force_approval_flag,in_out_manage_flag FROM jsh_system_config WHERE tenant_id=? AND IFNULL(delete_flag,'0')='0' ORDER BY id LIMIT 1"+(current?" FOR UPDATE":""),tenant);
    }
    private Map<String,Map<String,Object>> stock(long tenant,boolean current) {
        List<Map<String,Object>> flags=config(tenant,current);
        boolean force=!flags.isEmpty() && "1".equals(flags.get(0).get("force_approval_flag"));
        boolean manage=!flags.isEmpty() && "1".equals(flags.get(0).get("in_out_manage_flag"));
        String sql="SELECT di.id,di.material_id,di.depot_id,di.batch_number,di.basic_number,dh.type,dh.sub_type,q.item_id quality_id,q.qc_status,q.qualified_quantity,q.release_state,q.return_released,q.report_number FROM jsh_depot_item di JOIN jsh_depot_head dh ON dh.id=di.header_id AND dh.tenant_id=di.tenant_id LEFT JOIN jsh_factory_batch_quality q ON q.item_id=di.id AND q.tenant_id=di.tenant_id WHERE di.tenant_id=? AND dh.type IN ('入库','出库') AND IFNULL(di.delete_flag,'0')='0' AND IFNULL(dh.delete_flag,'0')='0' AND IFNULL(di.batch_number,'')<>'' AND IFNULL(di.sku,'')=''";
        if(force) sql+=" AND dh.status='1'";
        if(manage) sql+=" AND dh.sub_type NOT IN ('采购','采购退货','销售','销售退货')";
        if(current) sql+=" FOR UPDATE";
        List<Map<String,Object>> rows=jdbc.queryForList(sql,tenant);
        Map<String,Map<String,Object>> result=new LinkedHashMap<>();
        for(Map<String,Object> row:rows) {
            String key=lotKey(row.get("material_id"),row.get("depot_id"),row.get("batch_number"));
            Map<String,Object> lot=result.computeIfAbsent(key,k->{
                Map<String,Object> l=new HashMap<>();l.put("materialId",row.get("material_id"));l.put("depotId",row.get("depot_id"));l.put("batchNumber",row.get("batch_number"));l.put("physical",BigDecimal.ZERO);l.put("eligible",BigDecimal.ZERO);l.put("hasPendingRelease",false);l.put("reports",new ArrayList<Map<String,Object>>());return l;
            });
            BigDecimal quantity=decimal(row.get("basic_number"));
            if("入库".equals(row.get("type"))) {
                lot.put("physical",decimal(lot.get("physical")).add(quantity));
                boolean returned="销售退货".equals(row.get("sub_type"));
                boolean allowed="passed".equals(row.get("qc_status")) && (!returned || Integer.valueOf(1).equals(row.get("return_released")));
                if(allowed) {
                    BigDecimal qualified=decimal(row.get("qualified_quantity")).max(BigDecimal.ZERO).min(quantity.max(BigDecimal.ZERO));
                    lot.put("eligible",decimal(lot.get("eligible")).add(qualified));
                    if(!"released".equals(row.get("release_state"))) lot.put("hasPendingRelease",true);
                }
                Map<String,Object> report=new HashMap<>();report.put("id",row.get("quality_id"));report.put("reportNumber",row.get("report_number"));report.put("status",row.get("qc_status")==null?"unregistered":row.get("qc_status"));report.put("qualifiedQuantity",row.get("qualified_quantity"));report.put("releaseState",row.get("release_state"));report.put("returnHeld",returned && !allowed);
                ((List<Map<String,Object>>)lot.get("reports")).add(report);
            } else {
                lot.put("physical",decimal(lot.get("physical")).subtract(quantity));
                lot.put("eligible",decimal(lot.get("eligible")).subtract(quantity));
            }
        }
        for(Map<String,Object> lot:result.values()) lot.put("eligible",decimal(lot.get("eligible")).max(BigDecimal.ZERO).min(decimal(lot.get("physical")).max(BigDecimal.ZERO)));
        return result;
    }
    Map<Long,String> depots(User user) throws Exception {
        List<Map<String,Object>> flags=config(user.getTenantId(),false);
        boolean restricted=!flags.isEmpty() && "1".equals(flags.get(0).get("depot_flag"));
        String permitted="";
        if(restricted) for(UserBusiness b:business.getBasicData(user.getId().toString(),"UserDepot")) permitted+=b.getValue();
        Map<Long,String> result=new LinkedHashMap<>();
        for(Map<String,Object> depot:jdbc.queryForList("SELECT id,name FROM jsh_depot WHERE tenant_id=? AND enabled=1 AND IFNULL(delete_flag,'0')='0' ORDER BY id",user.getTenantId())) {
            long id=number(depot.get("id"));
            if(!restricted || permitted.contains("["+id+"]")) result.put(id,depot.get("name").toString());
        }
        return result;
    }
    private Map<String,Object> order(long id,User user,boolean current) {
        List<Map<String,Object>> rows=jdbc.queryForList("SELECT f.*,h.number,s.supplier customer_name FROM jsh_factory_sales_order f JOIN jsh_depot_head h ON h.id=f.head_id AND h.tenant_id=f.tenant_id LEFT JOIN jsh_supplier s ON s.id=h.organ_id AND s.tenant_id=f.tenant_id WHERE f.head_id=? AND f.tenant_id=? AND IFNULL(h.delete_flag,'0')='0'"+(current?" FOR UPDATE":""),id,user.getTenantId());
        require(!rows.isEmpty(),"订单不存在或无权访问");
        require("approved".equals(rows.get(0).get("workflow_status")),"仅审核通过的订单可进行库存核查");return rows.get(0);
    }
    private List<Map<String,Object>> allocations(long tenant,long id,boolean current) {
        return jdbc.queryForList("SELECT line_no lineNo,material_id materialId,depot_id depotId,batch_number batchNumber,quantity FROM jsh_factory_stock_reservation WHERE tenant_id=? AND head_id=? ORDER BY line_no,depot_id,batch_number"+(current?" FOR UPDATE":""),tenant,id);
    }
    private JSONArray lines(Map<String,Object> order,List<Map<String,Object>> allocations) {
        JSONArray input=JSONArray.parseArray(order.get("lines_json").toString()),result=new JSONArray();
        boolean shipped=jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_shipment WHERE tenant_id=? AND head_id=? AND workflow_status='shipped'",Integer.class,order.get("tenant_id"),order.get("head_id"))>0;
        boolean cancelled=jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_sales_order WHERE tenant_id=? AND head_id=? AND workflow_status='cancelled'",Integer.class,order.get("tenant_id"),order.get("head_id"))>0;
        for(int i=0;i<input.size();i++) {
            JSONObject original=input.getJSONObject(i),line=new JSONObject();
            for(String field:Arrays.asList("id","name","brand","standard","model","barCode","quantity")) line.put(field,original.get(field));
            line.put("lineNo",i);BigDecimal reserved=BigDecimal.ZERO;
            for(Map<String,Object> a:allocations) if(number(a.get("lineNo"))==i) reserved=reserved.add(decimal(a.get("quantity")));
            line.put("reserved",reserved);line.put("cancelled",cancelled);line.put("shipped",shipped?original.getBigDecimal("quantity"):BigDecimal.ZERO);line.put("missing",shipped||cancelled?BigDecimal.ZERO:original.getBigDecimal("quantity").subtract(reserved).max(BigDecimal.ZERO));result.add(line);
        }
        return result;
    }
    private void summary(Map<String,Object> order) {
        JSONArray lines=lines(order,allocations(number(order.get("tenant_id")),number(order.get("head_id")),false));
        BigDecimal demand=BigDecimal.ZERO,reserved=BigDecimal.ZERO,missing=BigDecimal.ZERO;
        for(Object value:lines) {JSONObject line=(JSONObject)value;demand=demand.add(line.getBigDecimal("quantity"));reserved=reserved.add(line.getBigDecimal("reserved"));missing=missing.add(line.getBigDecimal("missing"));}
        order.put("demand",demand);order.put("reserved",reserved);order.put("missing",missing);
        boolean checked=jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_stock_check WHERE head_id=? AND tenant_id=?",Integer.class,order.get("head_id"),order.get("tenant_id"))>0;
        boolean shipped=!lines.isEmpty()&&lines.getJSONObject(0).getBigDecimal("shipped").signum()>0;order.put("shipped",shipped?demand:BigDecimal.ZERO);order.put("stockState",!lines.isEmpty()&&lines.getJSONObject(0).getBooleanValue("cancelled")?"cancelled":shipped?"shipped":!checked?"unchecked":missing.signum()==0?"ready":reserved.signum()>0?"partial":"shortage");order.remove("lines_json");
    }
    public Map<String,Object> options() throws Exception {
        User user=actor();Map<String,Object> result=new HashMap<>();
        result.put("customers",jdbc.queryForList("SELECT id,supplier FROM jsh_supplier WHERE tenant_id=? AND type='客户' AND enabled=1 AND IFNULL(delete_flag,'0')='0' ORDER BY id",user.getTenantId()));
        result.put("users",jdbc.queryForList("SELECT id,username FROM jsh_user WHERE tenant_id=? AND status=0 AND IFNULL(delete_flag,'0')='0' ORDER BY id",user.getTenantId()));
        List<Map<String,Object>> warehouses=new ArrayList<>();for(Map.Entry<Long,String> depot:depots(user).entrySet()){Map<String,Object> row=new HashMap<>();row.put("id",depot.getKey());row.put("name",depot.getValue());warehouses.add(row);}result.put("depots",warehouses);return result;
    }
    public Map<String,Object> list(String keyword,int page,int size,Map<String,String> filters) throws Exception {
        User user=actor();require(page>0 && page<=100000 && size>0 && size<=100,"分页参数无效");require(keyword.length()<=100,"查询内容过长");
        StringBuilder from=new StringBuilder(" FROM jsh_factory_sales_order f JOIN jsh_depot_head h ON h.id=f.head_id AND h.tenant_id=f.tenant_id LEFT JOIN jsh_supplier s ON s.id=h.organ_id AND s.tenant_id=f.tenant_id WHERE f.tenant_id=? AND f.workflow_status='approved' AND IFNULL(h.delete_flag,'0')='0' AND (h.number LIKE ? OR s.supplier LIKE ?)");
        List<Object> args=new ArrayList<>(Arrays.asList(user.getTenantId(),"%"+keyword+"%","%"+keyword+"%"));
        for(String key:Arrays.asList("number","remark")){
            String value=filters.get(key);if(value!=null && !value.trim().isEmpty()){require(value.length()<=500,"查询内容过长");from.append(" AND h.").append(key).append(" LIKE ?");args.add("%"+value.trim()+"%");}
        }
        for(String key:Arrays.asList("customerId","creatorId","depotId")){
            String value=filters.get(key);if(value==null || value.isEmpty())continue;require(value.matches("[0-9]{1,18}"),"筛选编号无效");long id=Long.parseLong(value);
            if("depotId".equals(key)){
                require(depots(user).containsKey(id),"没有对应仓库的访问权限");
                from.append(" AND EXISTS(SELECT 1 FROM jsh_factory_stock_reservation r WHERE r.tenant_id=f.tenant_id AND r.head_id=f.head_id AND r.depot_id=?)");
            }else from.append("customerId".equals(key)?" AND h.organ_id=?":" AND f.created_by=?");args.add(id);
        }
        String product=filters.get("material");
        if(product!=null && !product.trim().isEmpty()){
            require(product.length()<=100,"商品查询内容过长");
            from.append(" AND (JSON_SEARCH(f.lines_json,'one',?,NULL,'$[*].name','$[*].brand','$[*].standard','$[*].model','$[*].barCode') IS NOT NULL OR EXISTS(SELECT 1 FROM jsh_depot_item di JOIN jsh_material m ON m.id=di.material_id AND m.tenant_id=di.tenant_id WHERE di.header_id=f.head_id AND di.tenant_id=f.tenant_id AND IFNULL(di.delete_flag,'0')='0' AND m.mnemonic LIKE ?))");args.add("%"+product.trim()+"%");args.add("%"+product.trim()+"%");
        }
        LocalDate begin=null,end=null;
        try{if(filters.get("beginDate")!=null && !filters.get("beginDate").isEmpty())begin=LocalDate.parse(filters.get("beginDate"));if(filters.get("endDate")!=null && !filters.get("endDate").isEmpty())end=LocalDate.parse(filters.get("endDate"));}catch(Exception e){throw new BusinessRunTimeException(409,"单据日期格式不正确");}
        require(begin==null || end==null || !begin.isAfter(end),"开始日期不能晚于结束日期");
        if(begin!=null){from.append(" AND h.create_time>=?");args.add(begin.toString()+" 00:00:00");}
        if(end!=null){from.append(" AND h.create_time<?");args.add(end.plusDays(1).toString()+" 00:00:00");}
        String state=filters.get("stockState");
        if(state!=null && !state.isEmpty()){
            require(Arrays.asList("unchecked","ready","partial","shortage","shipped").contains(state),"核查状态无效");
            String reserved="(SELECT IFNULL(SUM(r.quantity),0) FROM jsh_factory_stock_reservation r WHERE r.tenant_id=f.tenant_id AND r.head_id=f.head_id)";
            String demand="(SELECT IFNULL(SUM(di.basic_number),0) FROM jsh_depot_item di WHERE di.tenant_id=f.tenant_id AND di.header_id=f.head_id AND IFNULL(di.delete_flag,'0')='0')";
            from.append(" AND (CASE WHEN EXISTS(SELECT 1 FROM jsh_factory_shipment sh WHERE sh.tenant_id=f.tenant_id AND sh.head_id=f.head_id AND sh.workflow_status='shipped') THEN 'shipped' WHEN NOT EXISTS(SELECT 1 FROM jsh_factory_stock_check c WHERE c.tenant_id=f.tenant_id AND c.head_id=f.head_id) THEN 'unchecked' WHEN ").append(reserved).append(">=").append(demand).append(" THEN 'ready' WHEN ").append(reserved).append(">0 THEN 'partial' ELSE 'shortage' END)=?");args.add(state);
        }
        Map<String,Object> result=new HashMap<>();result.put("total",jdbc.queryForObject("SELECT COUNT(*)"+from,Long.class,args.toArray()));
        List<Object> paged=new ArrayList<>(args);paged.add(size);paged.add((page-1)*size);
        List<Map<String,Object>> rows=jdbc.queryForList("SELECT f.head_id,f.tenant_id,f.version,f.delivery_date,f.requirements,f.lines_json,h.number,s.supplier customer_name"+from+" ORDER BY f.head_id DESC LIMIT ? OFFSET ?",paged.toArray());
        for(Map<String,Object> row:rows) summary(row);result.put("rows",rows);return result;
    }
    public Map<String,Object> detail(long id) throws Exception {
        User user=actor();Map<String,Object> result=order(id,user,false);List<Map<String,Object>> own=allocations(user.getTenantId(),id,false);
        JSONArray lines=lines(result,own);Map<Long,String> allowed=depots(user);
        Map<String,BigDecimal> totals=new HashMap<>();
        for(Map<String,Object> a:jdbc.queryForList("SELECT material_id,depot_id,batch_number,SUM(quantity) quantity FROM jsh_factory_stock_reservation WHERE tenant_id=? GROUP BY material_id,depot_id,batch_number",user.getTenantId())) totals.put(lotKey(a.get("material_id"),a.get("depot_id"),a.get("batch_number")),decimal(a.get("quantity")));
        List<Map<String,Object>> lots=new ArrayList<>();
        for(Map.Entry<String,Map<String,Object>> entry:stock(user.getTenantId(),false).entrySet()) {
            Map<String,Object> lot=entry.getValue();if(!allowed.containsKey(number(lot.get("depotId")))) continue;
            BigDecimal mine=BigDecimal.ZERO;for(Map<String,Object> a:own) if(entry.getKey().equals(lotKey(a.get("materialId"),a.get("depotId"),a.get("batchNumber")))) mine=mine.add(decimal(a.get("quantity")));
            if(decimal(lot.get("physical")).signum()<=0 && mine.signum()==0) continue;
            BigDecimal other=totals.getOrDefault(entry.getKey(),BigDecimal.ZERO).subtract(mine);
            lot.put("otherReserved",other);lot.put("available",decimal(lot.get("eligible")).subtract(other).max(BigDecimal.ZERO));lot.put("depotName",allowed.get(number(lot.get("depotId"))));lots.add(lot);
        }
        summary(result);result.put("lines",lines);result.put("allocations",own);result.put("lots",lots);
        result.put("check",jdbc.queryForList("SELECT note,checked_at FROM jsh_factory_stock_check WHERE tenant_id=? AND head_id=?",user.getTenantId(),id));
        result.put("history",jdbc.queryForList("SELECT action,actor_name,note,allocations_json,created_at FROM jsh_factory_stock_history WHERE tenant_id=? AND head_id=? ORDER BY id DESC",user.getTenantId(),id));return result;
    }
    public Map<String,Object> report(long item) throws Exception {
        User user=actor();List<Map<String,Object>> rows=jdbc.queryForList("SELECT q.*,di.depot_id,di.batch_number FROM jsh_factory_batch_quality q JOIN jsh_depot_item di ON di.id=q.item_id AND di.tenant_id=q.tenant_id WHERE q.item_id=? AND q.tenant_id=?",item,user.getTenantId());
        require(!rows.isEmpty() && depots(user).containsKey(number(rows.get(0).get("depot_id"))),"报告不存在或无仓库访问权限");return rows.get(0);
    }
    private void audit(long id,User user,String action,String note,List<Map<String,Object>> allocations) {
        jdbc.update("INSERT INTO jsh_factory_stock_history(tenant_id,head_id,action,actor_name,note,allocations_json,created_at) VALUES(?,?,?,?,?,?,NOW())",user.getTenantId(),id,action,user.getUsername(),note,JSONArray.toJSONString(allocations));
        jdbc.update("INSERT INTO jsh_factory_sales_history(tenant_id,head_id,action,actor_id,actor_name,comment,created_at) VALUES(?,?,?,?,?,?,NOW())",user.getTenantId(),id,action,user.getId(),user.getUsername(),note);
    }
    private void editable(long id,User user,JSONObject body) throws Exception {
        requireNoShipment(id,user);
        Map<String,Object> order=order(id,user,true);require(body.getInteger("version")!=null && body.getInteger("version").equals(order.get("version")),"订单或预留已更新，请重新打开后操作");
        Map<Long,String> allowed=depots(user);
        for(Map<String,Object> old:allocations(user.getTenantId(),id,true)) require(user.getId().equals(user.getTenantId()) || allowed.containsKey(number(old.get("depotId"))),"此订单含无权操作仓库的预留，请联系负责人");
    }
    @Transactional(rollbackFor=Exception.class)
    public void save(long id,JSONObject body) throws Exception {
        User user=actor();lockForInventoryMutation();editable(id,user,body);
        require(Boolean.TRUE.equals(body.getBoolean("confirmed")),"请先核对客户要求与质检报告并确认");
        String note=body.getString("note");note=note==null?"":note.trim();require(note.length()<=2000,"备注最多2000字");
        JSONArray input=body.getJSONArray("allocations");require(input!=null && input.size()<=500,"预留明细无效或超过500行");
        JSONArray lines=JSONArray.parseArray(order(id,user,true).get("lines_json").toString());Map<Long,String> allowed=depots(user);
        List<Map<String,Object>> proposed=new ArrayList<>();Set<String> unique=new HashSet<>();Map<Integer,BigDecimal> lineTotals=new HashMap<>();Map<String,BigDecimal> lotTotals=new HashMap<>();
        Map<String,Map<String,Object>> stock=stock(user.getTenantId(),true);
        Map<String,BigDecimal> others=new HashMap<>();
        for(Map<String,Object> row:jdbc.queryForList("SELECT material_id,depot_id,batch_number,quantity FROM jsh_factory_stock_reservation WHERE tenant_id=? AND head_id<>? FOR UPDATE",user.getTenantId(),id)) {
            String key=lotKey(row.get("material_id"),row.get("depot_id"),row.get("batch_number"));others.put(key,others.getOrDefault(key,BigDecimal.ZERO).add(decimal(row.get("quantity"))));
        }
        for(Object value:input) {
            JSONObject row=(JSONObject)com.alibaba.fastjson.JSON.toJSON(value);Integer lineNo=row.getInteger("lineNo");Long depot=row.getLong("depotId");String batch=row.getString("batchNumber");BigDecimal quantity=row.getBigDecimal("quantity");
            require(lineNo!=null && lineNo>=0 && lineNo<lines.size(),"订单产品行无效");require(depot!=null && allowed.containsKey(depot),"没有对应仓库的操作权限");require(batch!=null && !batch.trim().isEmpty() && batch.length()<=100,"批号不能为空且最多100字");
            require(quantity!=null && quantity.signum()>0 && quantity.scale()<=6 && quantity.precision()-quantity.scale()<=12,"预留数量必须大于0且最多6位小数");
            long material=lines.getJSONObject(lineNo).getLongValue("id");String key=lotKey(material,depot,batch);
            require(unique.add(lineNo+"|"+key),"同一产品行的批次不能重复填写");Map<String,Object> lot=stock.get(key);require(lot!=null,"批次库存不存在");
            BigDecimal lineSum=lineTotals.getOrDefault(lineNo,BigDecimal.ZERO).add(quantity);require(lineSum.compareTo(lines.getJSONObject(lineNo).getBigDecimal("quantity"))<=0,"预留量不能超过该行订单需求");lineTotals.put(lineNo,lineSum);
            BigDecimal lotSum=lotTotals.getOrDefault(key,BigDecimal.ZERO).add(quantity);require(lotSum.add(others.getOrDefault(key,BigDecimal.ZERO)).compareTo(decimal(lot.get("eligible")))<=0,"批次合格可用量不足，或已被其他订单预留");lotTotals.put(key,lotSum);
            Map<String,Object> a=new HashMap<>();a.put("lineNo",lineNo);a.put("materialId",material);a.put("depotId",depot);a.put("batchNumber",batch);a.put("quantity",quantity);proposed.add(a);
        }
        jdbc.update("DELETE FROM jsh_factory_stock_reservation WHERE tenant_id=? AND head_id=?",user.getTenantId(),id);
        for(Map<String,Object> a:proposed) jdbc.update("INSERT INTO jsh_factory_stock_reservation(tenant_id,head_id,line_no,material_id,depot_id,batch_number,quantity) VALUES(?,?,?,?,?,?,?)",user.getTenantId(),id,a.get("lineNo"),a.get("materialId"),a.get("depotId"),a.get("batchNumber"),a.get("quantity"));
        jdbc.update("INSERT INTO jsh_factory_stock_check(head_id,tenant_id,note,checked_by,checked_at) VALUES(?,?,?,?,NOW()) ON DUPLICATE KEY UPDATE note=VALUES(note),checked_by=VALUES(checked_by),checked_at=NOW()",id,user.getTenantId(),note,user.getId());
        jdbc.update("UPDATE jsh_factory_sales_order SET version=version+1,updated_at=NOW() WHERE head_id=? AND tenant_id=?",id,user.getTenantId());
        audit(id,user,"stock_reserve",note.isEmpty()?"仓库确认预留及缺口；未自动修改生产任务":note,proposed);
    }
    @Transactional(rollbackFor=Exception.class)
    public void release(long id,JSONObject body) throws Exception {
        User user=actor();lockForInventoryMutation();editable(id,user,body);releaseForOrder(id,user,"仓库释放预留");
        jdbc.update("UPDATE jsh_factory_sales_order SET version=version+1,updated_at=NOW() WHERE head_id=? AND tenant_id=?",id,user.getTenantId());
    }
    public void releaseForOrder(long id,User user,String note) {
        requireNoShipment(id,user);
        List<Map<String,Object>> previous=allocations(user.getTenantId(),id,true);
        boolean checked=jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_stock_check WHERE head_id=? AND tenant_id=?",Integer.class,id,user.getTenantId())>0;
        jdbc.update("DELETE FROM jsh_factory_stock_reservation WHERE tenant_id=? AND head_id=?",user.getTenantId(),id);
        jdbc.update("DELETE FROM jsh_factory_stock_check WHERE tenant_id=? AND head_id=?",user.getTenantId(),id);
        if(checked || !previous.isEmpty()) audit(id,user,"stock_release",note,previous);
    }
    public Map<String,Object> salesSummary(long id,User user) {
        List<Map<String,Object>> rows=jdbc.queryForList("SELECT head_id,tenant_id,lines_json FROM jsh_factory_sales_order WHERE head_id=? AND tenant_id=?",id,user.getTenantId());require(!rows.isEmpty(),"订单不存在");Map<String,Object> result=rows.get(0);List<Map<String,Object>> allocations=allocations(user.getTenantId(),id,false);JSONArray lines=lines(result,allocations);summary(result);result.put("lines",lines);return result;
    }
    // Production writes hold the shared tenant lock; use current reads after waiting for it.
    JSONArray productionLines(long id,User user){
        List<Map<String,Object>> rows=jdbc.queryForList("SELECT head_id,tenant_id,lines_json FROM jsh_factory_sales_order WHERE head_id=? AND tenant_id=? FOR UPDATE",id,user.getTenantId());
        require(!rows.isEmpty(),"订单不存在");return lines(rows.get(0),allocations(user.getTenantId(),id,true));
    }

    void requireNoShipment(long id,User user){require(jdbc.queryForList("SELECT head_id FROM jsh_factory_shipment WHERE tenant_id=? AND head_id=? AND workflow_status<>'cancelled' FOR UPDATE",Long.class,user.getTenantId(),id).isEmpty(),"已有发货申请或已出库，不能修改订单或预留；未出库请先由销售撤销发货申请");}
    List<Map<String,Object>> shipmentAllocations(long id,User user,boolean warehouse)throws Exception{
        Map<String,Object> order=order(id,user,true);JSONArray lines=JSONArray.parseArray(order.get("lines_json").toString());List<Map<String,Object>> own=allocations(user.getTenantId(),id,true);Map<String,Map<String,Object>> lots=stock(user.getTenantId(),true);Map<Integer,BigDecimal> totals=new HashMap<>();Map<Long,String> allowed=depots(user);
        for(Map<String,Object> a:own){int line=(int)number(a.get("lineNo"));require(line>=0&&line<lines.size()&&number(a.get("materialId"))==lines.getJSONObject(line).getLongValue("id"),"预留产品已变化，请核实订单");require(!warehouse||allowed.containsKey(number(a.get("depotId"))),"没有装运仓库的操作权限");Map<String,Object> lot=lots.get(lotKey(a.get("materialId"),a.get("depotId"),a.get("batchNumber")));require(lot!=null&&decimal(lot.get("eligible")).compareTo(decimal(a.get("quantity")))>=0,"已预留批次合格库存不足");
            for(Map<String,Object> report:(List<Map<String,Object>>)lot.get("reports"))require("passed".equals(report.get("status"))&&"released".equals(report.get("releaseState"))&&!Boolean.TRUE.equals(report.get("returnHeld")),"所选批次尚未全部质检合格并放行，不能申请或确认发货");totals.put(line,totals.getOrDefault(line,BigDecimal.ZERO).add(decimal(a.get("quantity"))));
        }
        for(int i=0;i<lines.size();i++)require(totals.getOrDefault(i,BigDecimal.ZERO).compareTo(lines.getJSONObject(i).getBigDecimal("quantity"))==0,"订单须整单备齐并全量预留后发货");return own;
    }
    void consumeForShipment(long id,User user,List<Map<String,Object>> used){
        jdbc.update("DELETE FROM jsh_factory_stock_reservation WHERE tenant_id=? AND head_id=?",user.getTenantId(),id);audit(id,user,"stock_shipped","整单统一出库，核销对应预留",used);
        jdbc.update("UPDATE jsh_factory_sales_order SET version=version+1,updated_at=NOW() WHERE tenant_id=? AND head_id=?",user.getTenantId(),id);
    }

}

