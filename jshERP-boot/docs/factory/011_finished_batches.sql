ALTER TABLE jsh_factory_inspection ADD COLUMN inspection_kind VARCHAR(10) NOT NULL DEFAULT 'semi';
CREATE TABLE jsh_factory_release_config (
 tenant_id BIGINT PRIMARY KEY,leader_ids_json TEXT NOT NULL,updated_at DATETIME NOT NULL);
CREATE TABLE jsh_factory_finished_batch (
 id BIGINT AUTO_INCREMENT PRIMARY KEY,tenant_id BIGINT NOT NULL,head_id BIGINT NOT NULL,line_no INT NOT NULL,
 stage_no INT NOT NULL,material_id BIGINT NOT NULL,bar_code VARCHAR(100) NOT NULL,batch_number VARCHAR(100) NOT NULL,
 quantity DECIMAL(18,6) NOT NULL,root_inspection_id BIGINT NOT NULL,inspection_id BIGINT NOT NULL,
 version INT NOT NULL DEFAULT 1,depot_id BIGINT NULL,ledger_head_id BIGINT NULL,received_by BIGINT NULL,received_at DATETIME NULL,
 release_state VARCHAR(20) NOT NULL DEFAULT 'pending',released_by BIGINT NULL,released_at DATETIME NULL,
 UNIQUE KEY finished_lot(tenant_id,material_id,batch_number),UNIQUE KEY task_batch(tenant_id,head_id,line_no,batch_number));
ALTER TABLE jsh_factory_batch_quality MODIFY report_text MEDIUMTEXT NOT NULL;
INSERT INTO jsh_function(number,name,parent_number,url,component,state,sort,enabled,type,push_btn,icon,delete_flag)
 SELECT 'factory090105','成品质检入库与放行','factory0901','/factory/finished_product','/factory/FinishedProductList',b'0','0435',b'1','电脑版','1','safety-certificate','0'
 WHERE NOT EXISTS(SELECT 1 FROM jsh_function WHERE url='/factory/finished_product');
SET @finishedMenu=(SELECT id FROM jsh_function WHERE url='/factory/finished_product');
SET @qualityMenu=(SELECT id FROM jsh_function WHERE url='/factory/quality_transfer');
UPDATE jsh_user_business SET value=CONCAT(IFNULL(value,''),'[',@finishedMenu,']')
 WHERE type='RoleFunctions' AND value LIKE CONCAT('%[',@qualityMenu,']%') AND value NOT LIKE CONCAT('%[',@finishedMenu,']%');
