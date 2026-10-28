CREATE TABLE jsh_factory_change_config(tenant_id BIGINT PRIMARY KEY,leader_ids TEXT NOT NULL);
CREATE TABLE jsh_factory_order_change(
 id BIGINT AUTO_INCREMENT PRIMARY KEY,tenant_id BIGINT NOT NULL,head_id BIGINT NOT NULL,
 kind VARCHAR(20) NOT NULL,workflow_status VARCHAR(20) NOT NULL,version INT NOT NULL DEFAULT 1,
 reason VARCHAR(2000) NOT NULL,before_json MEDIUMTEXT NOT NULL,after_json MEDIUMTEXT NOT NULL,
 created_by BIGINT NOT NULL,created_at DATETIME NOT NULL,approved_by BIGINT NULL,approved_at DATETIME NULL,
 applied_by BIGINT NULL,applied_at DATETIME NULL,INDEX(tenant_id,head_id,workflow_status));
CREATE TABLE jsh_factory_order_change_history(
 id BIGINT AUTO_INCREMENT PRIMARY KEY,tenant_id BIGINT NOT NULL,change_id BIGINT NOT NULL,
 action VARCHAR(20) NOT NULL,actor_name VARCHAR(100) NOT NULL,comment VARCHAR(2000) NOT NULL,
 payload_json MEDIUMTEXT NOT NULL,created_at DATETIME NOT NULL,INDEX(tenant_id,change_id));
INSERT INTO jsh_function(number,name,parent_number,url,component,state,sort,enabled,type,push_btn,icon,delete_flag)
 SELECT 'factoryOrderChange','生产中订单变更与取消',parent_number,'/factory/order_change','/factory/OrderChangeList',b'0','0335',b'1','电脑版','1','edit','0'
 FROM jsh_function WHERE id=242 AND NOT EXISTS(SELECT 1 FROM jsh_function WHERE url='/factory/order_change');
SET @changeMenu=(SELECT id FROM jsh_function WHERE url='/factory/order_change');
SET @productionMenu=(SELECT id FROM jsh_function WHERE url='/factory/production_task');
SET @salesRoot=(SELECT id FROM jsh_function WHERE number=(SELECT parent_number FROM jsh_function WHERE id=242));
UPDATE jsh_user_business SET value=CONCAT(IFNULL(value,''),'[',@salesRoot,'][',@changeMenu,']')
 WHERE type='RoleFunctions' AND (value LIKE '%[242]%' OR value LIKE CONCAT('%[',@productionMenu,']%'))
 AND value NOT LIKE CONCAT('%[',@changeMenu,']%');
