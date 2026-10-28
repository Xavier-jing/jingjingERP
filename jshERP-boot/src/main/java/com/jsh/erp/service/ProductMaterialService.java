package com.jsh.erp.service;

import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.jsh.erp.datasource.entities.User;
import com.jsh.erp.datasource.entities.UserBusiness;
import com.jsh.erp.exception.BusinessRunTimeException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.Resource;
import java.math.BigDecimal;
import java.util.*;

@Service
public class ProductMaterialService {
    @Resource private JdbcTemplate jdbc;
    @Resource private UserService users;
    @Resource private UserBusinessService business;
    @Resource private FactoryStockService stock;

    private void require(boolean valid, String message) {
        if (!valid) throw new BusinessRunTimeException(409, message);
    }

    private User actor() throws Exception {
        User user = users.getCurrentUser();
        require(user != null && user.getTenantId() != null && user.getTenantId() > 0, "请使用业务租户账号");
        return user;
    }

    private boolean allowed(User user, boolean edit) throws Exception {
        if (user.getId().equals(user.getTenantId())) return true;
        Long menu = jdbc.queryForObject("SELECT id FROM jsh_function WHERE url='/material/material' AND enabled=1 AND IFNULL(delete_flag,'0')='0'", Long.class);
        for (UserBusiness role : business.getBasicData(user.getId().toString(), "UserRole")) {
            String roleId = role.getValue().replace("[", "").replace("]", "");
            for (UserBusiness functions : business.getBasicData(roleId, "RoleFunctions")) {
                if (functions.getValue() == null || !functions.getValue().contains("[" + menu + "]")) continue;
                if (!edit) return true;
                JSONArray buttons = JSONArray.parseArray(functions.getBtnStr());
                if (buttons == null) continue;
                for (int i = 0; i < buttons.size(); i++) {
                    JSONObject button = buttons.getJSONObject(i);
                    String value = button.getString("btnStr");
                    if (menu.equals(button.getLong("funId")) && value != null && Arrays.asList(value.split(",")).contains("1")) return true;
                }
            }
        }
        return false;
    }

    private Map<String, Object> product(long id, User user) {
        List<Map<String, Object>> rows = jdbc.queryForList("SELECT m.id,m.name,COALESCE(NULLIF(m.unit,''),u.basic_unit) unit FROM jsh_material m LEFT JOIN jsh_unit u ON u.id=m.unit_id AND u.tenant_id=m.tenant_id WHERE m.id=? AND m.tenant_id=? AND m.material_kind='product' AND IFNULL(m.delete_flag,'0')='0'", id, user.getTenantId());
        require(rows.size() == 1, "产品不存在或无权访问");
        return rows.get(0);
    }

    private List<Map<String, Object>> rawMaterials(User user) {
        return jdbc.queryForList("SELECT m.id materialId,m.name,m.standard,m.model,e.bar_code barCode,e.commodity_unit unit FROM jsh_material m JOIN jsh_material_extend e ON e.material_id=m.id AND e.tenant_id=m.tenant_id LEFT JOIN jsh_unit u ON u.id=m.unit_id AND u.tenant_id=m.tenant_id WHERE m.tenant_id=? AND m.material_kind='raw' AND m.enabled=1 AND IFNULL(m.delete_flag,'0')='0' AND IFNULL(e.delete_flag,'0')='0' AND IFNULL(m.enable_serial_number,'0')='0' AND IFNULL(e.sku,'')='' AND NOT EXISTS(SELECT 1 FROM jsh_material_extend sx WHERE sx.material_id=m.id AND sx.tenant_id=m.tenant_id AND IFNULL(sx.delete_flag,'0')='0' AND IFNULL(sx.sku,'')<>'') AND e.commodity_unit=COALESCE(NULLIF(m.unit,''),u.basic_unit) ORDER BY m.name,e.id", user.getTenantId());
    }

    public Map<String, Object> get(long id) throws Exception {
        User user = actor();
        require(allowed(user, false), "没有产品信息查看权限");
        Map<String, Object> result = new HashMap<>();
        result.put("product", product(id, user));
        result.put("options", rawMaterials(user));
        result.put("canEdit", allowed(user, true));
        List<Map<String, Object>> configs = jdbc.queryForList("SELECT version,lines_json FROM jsh_factory_product_material WHERE tenant_id=? AND product_id=?", user.getTenantId(), id);
        result.put("version", configs.isEmpty() ? 0 : configs.get(0).get("version"));
        result.put("lines", configs.isEmpty() ? new JSONArray() : JSONArray.parseArray(configs.get(0).get("lines_json").toString()));
        return result;
    }

    @Transactional(rollbackFor = Exception.class)
    public void save(long id, JSONObject body) throws Exception {
        User user = actor();
        require(allowed(user, true), "没有产品用料编辑权限");
        stock.lockForInventoryMutation();
        product(id, user);
        JSONArray input = body.getJSONArray("lines");
        require(input != null && input.size() <= 100, "最多配置100种原料");
        List<Map<String, Object>> configs = jdbc.queryForList("SELECT version FROM jsh_factory_product_material WHERE tenant_id=? AND product_id=? FOR UPDATE", user.getTenantId(), id);
        int version = configs.isEmpty() ? 0 : ((Number) configs.get(0).get("version")).intValue();
        require(Objects.equals(body.getInteger("version"), version), "用料配置已更新，请重新打开后核对");
        Map<String, Map<String, Object>> options = new HashMap<>();
        for (Map<String, Object> raw : rawMaterials(user)) options.put(raw.get("barCode").toString(), raw);
        JSONArray lines = new JSONArray();
        Set<Long> selected = new HashSet<>();
        for (int i = 0; i < input.size(); i++) {
            JSONObject item = input.getJSONObject(i);
            Map<String, Object> raw = options.get(item.getString("barCode"));
            require(raw != null, "请选择本租户有效原料的基本单位条码");
            require(selected.add(((Number) raw.get("materialId")).longValue()), "同一种原料不能重复关联");
            BigDecimal quantity = item.getBigDecimal("quantity");
            require(quantity == null || (quantity.signum() > 0 && quantity.scale() <= 6 && quantity.precision() - quantity.scale() <= 12), "参考用量应大于0且最多6位小数；未知可留空");
            String remark = item.getString("remark");
            remark = remark == null ? "" : remark.trim();
            require(remark.length() <= 500, "用料备注不能超过500字");
            JSONObject line = new JSONObject(raw);
            line.put("quantity", quantity);
            line.put("remark", remark);
            lines.add(line);
        }
        if (version == 0) {
            jdbc.update("INSERT INTO jsh_factory_product_material(tenant_id,product_id,version,lines_json,updated_by,updated_at) VALUES(?,?,1,?,?,NOW())", user.getTenantId(), id, lines.toJSONString(), user.getId());
        } else {
            jdbc.update("UPDATE jsh_factory_product_material SET version=version+1,lines_json=?,updated_by=?,updated_at=NOW() WHERE tenant_id=? AND product_id=?", lines.toJSONString(), user.getId(), user.getTenantId(), id);
        }
    }

    public void checkDeletion(String ids) throws Exception {
        User user = actor();
        stock.lockForInventoryMutation();
        for (String value : ids.split(",")) {
            long id = Long.parseLong(value);
            int references = jdbc.queryForObject("SELECT COUNT(*) FROM jsh_factory_product_material c JOIN jsh_material p ON p.id=c.product_id AND p.tenant_id=c.tenant_id WHERE c.tenant_id=? AND IFNULL(p.delete_flag,'0')='0' AND JSON_CONTAINS(c.lines_json,JSON_OBJECT('materialId',?), '$')", Integer.class, user.getTenantId(), id);
            require(references == 0, "该原料已被产品用料配置引用，请先解除关联再删除");
        }
    }
}
