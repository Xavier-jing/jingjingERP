CREATE TABLE IF NOT EXISTS jsh_factory_stock_lock (tenant_id BIGINT PRIMARY KEY);
CREATE TABLE IF NOT EXISTS jsh_factory_stock_check (
 head_id BIGINT PRIMARY KEY,tenant_id BIGINT NOT NULL,note VARCHAR(2000) NOT NULL,
 checked_by BIGINT NOT NULL,checked_at DATETIME NOT NULL);
CREATE TABLE IF NOT EXISTS jsh_factory_stock_reservation (
 tenant_id BIGINT NOT NULL,head_id BIGINT NOT NULL,line_no INT NOT NULL,
 material_id BIGINT NOT NULL,depot_id BIGINT NOT NULL,batch_number VARCHAR(100) NOT NULL,
 quantity DECIMAL(24,6) NOT NULL,
 PRIMARY KEY(tenant_id,head_id,line_no,material_id,depot_id,batch_number),
 INDEX lot_reservation(tenant_id,material_id,depot_id,batch_number));
CREATE TABLE IF NOT EXISTS jsh_factory_stock_history (
 id BIGINT PRIMARY KEY AUTO_INCREMENT,tenant_id BIGINT NOT NULL,head_id BIGINT NOT NULL,
 action VARCHAR(30) NOT NULL,actor_name VARCHAR(100) NOT NULL,note VARCHAR(2000) NOT NULL,
 allocations_json MEDIUMTEXT NOT NULL,created_at DATETIME NOT NULL,INDEX(tenant_id,head_id));
-- Read-only quality projection for each inbound detail. Written by quality/return workflows,
-- never by warehouse allocation requests. Missing quality is not assumed to be passed.
CREATE TABLE IF NOT EXISTS jsh_factory_batch_quality (
 item_id BIGINT PRIMARY KEY,tenant_id BIGINT NOT NULL,
 qc_status VARCHAR(20) NOT NULL,qualified_quantity DECIMAL(24,6) NOT NULL,
 release_state VARCHAR(20) NOT NULL DEFAULT 'pending',return_released TINYINT NOT NULL DEFAULT 0,
 report_number VARCHAR(100) NOT NULL,report_text TEXT NOT NULL,INDEX(tenant_id));
INSERT INTO jsh_function(number,name,parent_number,url,component,state,sort,enabled,type,push_btn,icon,delete_flag)
 SELECT '080190','订单库存核查','0801','/factory/stock_check','/factory/StockCheckList',b'0','0421',b'1','电脑版','1','profile','0'
 WHERE NOT EXISTS(SELECT 1 FROM jsh_function WHERE url='/factory/stock_check');
SET @factoryStockMenu=(SELECT id FROM jsh_function WHERE url='/factory/stock_check');
UPDATE jsh_user_business SET value=CONCAT(IFNULL(value,''),'[',@factoryStockMenu,']')
 WHERE type='RoleFunctions' AND value LIKE '%[239]%' AND value NOT LIKE CONCAT('%[',@factoryStockMenu,']%');
