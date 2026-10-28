CREATE TABLE IF NOT EXISTS jsh_factory_production_config (
 tenant_id BIGINT PRIMARY KEY,reviewer_id BIGINT NOT NULL,director_id BIGINT NOT NULL,updated_at DATETIME NOT NULL);
CREATE TABLE IF NOT EXISTS jsh_factory_production_task (
 head_id BIGINT PRIMARY KEY,tenant_id BIGINT NOT NULL,number VARCHAR(50) NOT NULL,
 workflow_status VARCHAR(20) NOT NULL,version INT NOT NULL DEFAULT 1,
 requirements TEXT NOT NULL,lines_json MEDIUMTEXT NOT NULL,plan_json MEDIUMTEXT NOT NULL,
 created_by BIGINT NOT NULL,created_at DATETIME NOT NULL,updated_at DATETIME NOT NULL,
 UNIQUE KEY production_number(tenant_id,number),INDEX(tenant_id,workflow_status));
CREATE TABLE IF NOT EXISTS jsh_factory_production_history (
 id BIGINT PRIMARY KEY AUTO_INCREMENT,tenant_id BIGINT NOT NULL,head_id BIGINT NOT NULL,
 action VARCHAR(30) NOT NULL,actor_id BIGINT NOT NULL,actor_name VARCHAR(100) NOT NULL,
 comment TEXT NOT NULL,payload_json MEDIUMTEXT NOT NULL,created_at DATETIME NOT NULL,INDEX(tenant_id,head_id));
INSERT INTO jsh_function(number,name,parent_number,url,component,state,sort,enabled,type,push_btn,icon,delete_flag)
 SELECT 'factory0901','生产管理','0','/factoryProduction','/layouts/TabLayout',b'0','0430',b'1','电脑版','1','tool','0'
 WHERE NOT EXISTS(SELECT 1 FROM jsh_function WHERE number='factory0901');
INSERT INTO jsh_function(number,name,parent_number,url,component,state,sort,enabled,type,push_btn,icon,delete_flag)
 SELECT 'factory090101','生产任务联系表','factory0901','/factory/production_task','/factory/ProductionTaskList',b'0','0431',b'1','电脑版','1','profile','0'
 WHERE NOT EXISTS(SELECT 1 FROM jsh_function WHERE url='/factory/production_task');
SET @productionRoot=(SELECT id FROM jsh_function WHERE number='factory0901');
SET @productionMenu=(SELECT id FROM jsh_function WHERE url='/factory/production_task');
UPDATE jsh_user_business SET value=CONCAT(IFNULL(value,''),'[',@productionRoot,'][',@productionMenu,']')
 WHERE type='RoleFunctions' AND (value LIKE '%[242]%' OR value LIKE '%[239]%') AND value NOT LIKE CONCAT('%[',@productionMenu,']%');
