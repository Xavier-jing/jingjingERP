CREATE TABLE jsh_factory_quality_config (
 tenant_id BIGINT PRIMARY KEY, director_id BIGINT NOT NULL, inspectors_json TEXT NOT NULL, updated_at DATETIME NOT NULL);
CREATE TABLE jsh_factory_quality_standard (
 id BIGINT AUTO_INCREMENT PRIMARY KEY, tenant_id BIGINT NOT NULL, bar_code VARCHAR(100) NOT NULL, stage_no INT NOT NULL,
 version INT NOT NULL, forms_json MEDIUMTEXT NOT NULL, updated_by BIGINT NOT NULL, updated_at DATETIME NOT NULL,
 UNIQUE KEY product_stage(tenant_id,bar_code,stage_no));
CREATE TABLE jsh_factory_inspection (
 id BIGINT AUTO_INCREMENT PRIMARY KEY, tenant_id BIGINT NOT NULL, head_id BIGINT NOT NULL, line_no INT NOT NULL,
 stage_no INT NOT NULL, workshop_no INT NOT NULL, batch_number VARCHAR(100) NOT NULL, quantity DECIMAL(18,6) NOT NULL,
 parent_id BIGINT NULL, standard_version INT NOT NULL, forms_json MEDIUMTEXT NOT NULL,
 workflow_status VARCHAR(20) NOT NULL, version INT NOT NULL DEFAULT 1, qualified_quantity DECIMAL(18,6) NULL,
 comment VARCHAR(2000) NOT NULL, created_by BIGINT NOT NULL, created_at DATETIME NOT NULL,
 confirmed_by BIGINT NULL, confirmed_at DATETIME NULL,
 INDEX task_batch(tenant_id,head_id,line_no,stage_no,workshop_no,batch_number), INDEX parent(tenant_id,parent_id));
CREATE TABLE jsh_factory_quality_transfer (
 id BIGINT AUTO_INCREMENT PRIMARY KEY, tenant_id BIGINT NOT NULL, inspection_id BIGINT NOT NULL, head_id BIGINT NOT NULL,
 line_no INT NOT NULL, stage_no INT NOT NULL, workshop_no INT NOT NULL, batch_number VARCHAR(100) NOT NULL,
 quantity DECIMAL(18,6) NOT NULL, workflow_status VARCHAR(20) NOT NULL, comment VARCHAR(2000) NOT NULL,
 created_by BIGINT NOT NULL, created_at DATETIME NOT NULL, received_by BIGINT NULL, received_at DATETIME NULL,
 INDEX inspection(tenant_id,inspection_id), INDEX destination(tenant_id,head_id,line_no,stage_no,workshop_no,batch_number));
CREATE TABLE jsh_factory_quality_history (
 id BIGINT AUTO_INCREMENT PRIMARY KEY, tenant_id BIGINT NOT NULL, inspection_id BIGINT NULL,
 action VARCHAR(30) NOT NULL, actor_id BIGINT NOT NULL, actor_name VARCHAR(100) NOT NULL,
 payload_json MEDIUMTEXT NOT NULL, created_at DATETIME NOT NULL, INDEX inspection(tenant_id,inspection_id));
INSERT INTO jsh_function(number,name,parent_number,url,component,state,sort,enabled,type,push_btn,icon,delete_flag)
 SELECT 'factory090104','半成品送检与流转','factory0901','/factory/quality_transfer','/factory/QualityTransferList',b'0','0434',b'1','电脑版','1','experiment','0'
 WHERE NOT EXISTS(SELECT 1 FROM jsh_function WHERE url='/factory/quality_transfer');
SET @qualityMenu=(SELECT id FROM jsh_function WHERE url='/factory/quality_transfer');
SET @productionMenu=(SELECT id FROM jsh_function WHERE url='/factory/production_task');
UPDATE jsh_user_business SET value=CONCAT(IFNULL(value,''),'[',@qualityMenu,']')
 WHERE type='RoleFunctions' AND value LIKE CONCAT('%[',@productionMenu,']%') AND value NOT LIKE CONCAT('%[',@qualityMenu,']%');
