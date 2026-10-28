-- Back up the application database before applying this migration once.
ALTER TABLE jsh_material ADD COLUMN material_kind VARCHAR(16) NOT NULL DEFAULT 'product' COMMENT 'product=产品,raw=原料';

-- Preserve the known simulation material, its identifiers and existing stock ledger.
UPDATE jsh_material m JOIN jsh_material_extend e ON e.material_id=m.id AND e.tenant_id=m.tenant_id
 SET m.material_kind='raw' WHERE e.bar_code='RAW-MOCK-A';

UPDATE jsh_function SET name='产品信息' WHERE url='/material/material';
INSERT INTO jsh_function(number,name,parent_number,url,component,state,sort,enabled,type,push_btn,icon,delete_flag)
 SELECT 'factoryRawMaterial','原料信息','0101','/material/raw_material','/material/RawMaterialList',b'0','0101021',b'1','电脑版','1,3','database','0'
 WHERE NOT EXISTS(SELECT 1 FROM jsh_function WHERE url='/material/raw_material');

SET @rawMenu=(SELECT id FROM jsh_function WHERE url='/material/raw_material');
SET @productMenu=(SELECT id FROM jsh_function WHERE url='/material/material');
UPDATE jsh_user_business SET value=CONCAT(value,'[',@rawMenu,']')
 WHERE type='RoleFunctions' AND IFNULL(delete_flag,'0')='0'
 AND value LIKE CONCAT('%[',@productMenu,']%') AND value NOT LIKE CONCAT('%[',@rawMenu,']%');

-- Copy the existing product maintenance/export buttons to the separate raw-material menu.
UPDATE jsh_user_business b
JOIN (
 SELECT DISTINCT b2.id,jt.buttons FROM jsh_user_business b2
 JOIN JSON_TABLE(IF(JSON_VALID(b2.btn_str),b2.btn_str,'[]'),'$[*]'
 COLUMNS(menu_id BIGINT PATH '$.funId', buttons VARCHAR(50) PATH '$.btnStr')) jt
 ON jt.menu_id=@productMenu WHERE b2.type='RoleFunctions' AND IFNULL(b2.delete_flag,'0')='0'
) p ON p.id=b.id
 SET b.btn_str=JSON_ARRAY_APPEND(IF(JSON_VALID(b.btn_str),b.btn_str,'[]'),'$',JSON_OBJECT('funId',@rawMenu,'btnStr',p.buttons));
