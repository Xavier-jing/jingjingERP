CREATE TABLE jsh_factory_return_config(tenant_id BIGINT PRIMARY KEY,leader_ids TEXT NOT NULL);
CREATE TABLE jsh_factory_customer_return(
 id BIGINT AUTO_INCREMENT PRIMARY KEY,tenant_id BIGINT NOT NULL,source_head_id BIGINT NOT NULL,
 workflow_status VARCHAR(20) NOT NULL,version INT NOT NULL DEFAULT 1,reason VARCHAR(2000) NOT NULL,
 created_by BIGINT NOT NULL,created_at DATETIME NOT NULL,approved_by BIGINT NULL,approved_at DATETIME NULL,
 received_by BIGINT NULL,received_at DATETIME NULL,ledger_head_id BIGINT NULL,
 INDEX(tenant_id,source_head_id,workflow_status));
CREATE TABLE jsh_factory_customer_return_line(
 id BIGINT AUTO_INCREMENT PRIMARY KEY,return_id BIGINT NOT NULL,tenant_id BIGINT NOT NULL,
 source_item_id BIGINT NOT NULL,quantity DECIMAL(24,6) NOT NULL,INDEX(tenant_id,return_id));
CREATE TABLE jsh_factory_customer_return_history(
 id BIGINT AUTO_INCREMENT PRIMARY KEY,tenant_id BIGINT NOT NULL,return_id BIGINT NOT NULL,
 action VARCHAR(30) NOT NULL,actor_id BIGINT NOT NULL,actor_name VARCHAR(100) NOT NULL,
 comment VARCHAR(2000) NOT NULL,created_at DATETIME NOT NULL,INDEX(tenant_id,return_id));
UPDATE jsh_function SET name='客户退货申请与收货',url='/factory/returns',component='/factory/ReturnList',icon='rollback'
 WHERE url='/bill/sale_back';
SET @returnMenu=(SELECT id FROM jsh_function WHERE url='/factory/returns');
SET @stockMenu=(SELECT id FROM jsh_function WHERE url='/factory/stock_check');
SET @salesRoot=(SELECT id FROM jsh_function WHERE number=(SELECT parent_number FROM jsh_function WHERE id=242));
UPDATE jsh_user_business SET value=CONCAT(IFNULL(value,''),'[',@salesRoot,'][',@returnMenu,']')
 WHERE type='RoleFunctions' AND (value LIKE '%[242]%' OR value LIKE CONCAT('%[',@stockMenu,']%'))
 AND value NOT LIKE CONCAT('%[',@returnMenu,']%');
