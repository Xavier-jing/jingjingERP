CREATE TABLE jsh_factory_quality_template (
 id BIGINT AUTO_INCREMENT PRIMARY KEY, tenant_id BIGINT NOT NULL, name VARCHAR(100) NOT NULL,
 version INT NOT NULL DEFAULT 1, forms_json MEDIUMTEXT NOT NULL, updated_by BIGINT NOT NULL, updated_at DATETIME NOT NULL,
 UNIQUE KEY tenant_name(tenant_id,name));
ALTER TABLE jsh_factory_quality_standard
 DROP INDEX product_stage,
 ADD COLUMN inspection_kind VARCHAR(20) NOT NULL DEFAULT 'semi',
 ADD COLUMN template_id BIGINT NULL,
 ADD UNIQUE KEY product_kind_stage(tenant_id,bar_code,inspection_kind,stage_no);
-- Existing standards served both inspection types. Preserve the latest operation
-- as the initial finished-product standard; existing inspection snapshots stay intact.
INSERT INTO jsh_factory_quality_standard(tenant_id,bar_code,stage_no,inspection_kind,version,forms_json,updated_by,updated_at)
 SELECT s.tenant_id,s.bar_code,0,'finished',s.version,s.forms_json,s.updated_by,s.updated_at
 FROM jsh_factory_quality_standard s
 JOIN (SELECT tenant_id,bar_code,MAX(stage_no) last_stage FROM jsh_factory_quality_standard GROUP BY tenant_id,bar_code) p
 ON p.tenant_id=s.tenant_id AND p.bar_code=s.bar_code AND p.last_stage=s.stage_no;
INSERT INTO jsh_function(number,name,parent_number,url,component,state,sort,enabled,type,push_btn,icon,delete_flag)
 SELECT 'factoryQualityStandard','产品质检标准','0101','/factory/quality_standard','/factory/QualityStandardList',b'0','0625',b'1','电脑版','1','experiment','0'
 WHERE NOT EXISTS(SELECT 1 FROM jsh_function WHERE url='/factory/quality_standard');
SET @standardMenu=(SELECT id FROM jsh_function WHERE url='/factory/quality_standard');
SET @materialRoot=(SELECT id FROM jsh_function WHERE number='0101');
SET @qualityMenu=(SELECT id FROM jsh_function WHERE url='/factory/quality_transfer');
UPDATE jsh_user_business SET value=CONCAT(IFNULL(value,''),'[',@standardMenu,']')
 WHERE type='RoleFunctions' AND value LIKE CONCAT('%[',@qualityMenu,']%') AND value NOT LIKE CONCAT('%[',@standardMenu,']%');
UPDATE jsh_user_business SET value=CONCAT(IFNULL(value,''),'[',@materialRoot,']')
 WHERE type='RoleFunctions' AND value LIKE CONCAT('%[',@standardMenu,']%') AND value NOT LIKE CONCAT('%[',@materialRoot,']%');
