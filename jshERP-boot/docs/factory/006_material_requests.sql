CREATE TABLE IF NOT EXISTS jsh_factory_material_request (
 id BIGINT PRIMARY KEY AUTO_INCREMENT,tenant_id BIGINT NOT NULL,task_head_id BIGINT NOT NULL,
 number VARCHAR(50) NOT NULL,kind VARCHAR(16) NOT NULL,reference_id BIGINT NULL,
 line_no INT NOT NULL,stage_no INT NOT NULL,workshop_no INT NOT NULL,
 workflow_status VARCHAR(16) NOT NULL,version INT NOT NULL DEFAULT 1,reason TEXT NOT NULL,
 lines_json MEDIUMTEXT NOT NULL,created_by BIGINT NOT NULL,ledger_head_id BIGINT NULL,
 created_at DATETIME NOT NULL,updated_at DATETIME NOT NULL,
 UNIQUE KEY request_number(tenant_id,number),UNIQUE KEY request_ledger(ledger_head_id),INDEX(tenant_id,task_head_id));
CREATE TABLE IF NOT EXISTS jsh_factory_material_history (
 id BIGINT PRIMARY KEY AUTO_INCREMENT,tenant_id BIGINT NOT NULL,request_id BIGINT NOT NULL,
 action VARCHAR(20) NOT NULL,actor_name VARCHAR(100) NOT NULL,comment TEXT NOT NULL,
 payload_json MEDIUMTEXT NOT NULL,created_at DATETIME NOT NULL,INDEX(tenant_id,request_id));
INSERT INTO jsh_function(number,name,parent_number,url,component,state,sort,enabled,type,push_btn,icon,delete_flag)
 SELECT 'factory090102','车间领补退料','factory0901','/factory/material_request','/factory/MaterialRequestList',b'0','0432',b'1','电脑版','1','profile','0'
 WHERE NOT EXISTS(SELECT 1 FROM jsh_function WHERE url='/factory/material_request');
SET @materialMenu=(SELECT id FROM jsh_function WHERE url='/factory/material_request');
SET @productionRoot=(SELECT id FROM jsh_function WHERE number='factory0901');
UPDATE jsh_user_business SET value=CONCAT(IFNULL(value,''),'[',@materialMenu,']')
 WHERE type='RoleFunctions' AND value LIKE CONCAT('%[',@productionRoot,']%') AND value NOT LIKE CONCAT('%[',@materialMenu,']%');
