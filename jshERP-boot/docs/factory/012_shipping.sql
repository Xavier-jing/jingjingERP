ALTER TABLE jsh_factory_sales_order ADD COLUMN payment_terms VARCHAR(20) NOT NULL DEFAULT 'unconfirmed';
CREATE TABLE jsh_factory_shipping_config(tenant_id BIGINT PRIMARY KEY,finance_id BIGINT NOT NULL,updated_at DATETIME NOT NULL);
CREATE TABLE jsh_factory_shipment(
 head_id BIGINT PRIMARY KEY,tenant_id BIGINT NOT NULL,workflow_status VARCHAR(20) NOT NULL,version INT NOT NULL DEFAULT 1,
 trucks_json MEDIUMTEXT NOT NULL,requested_by BIGINT NOT NULL,requested_at DATETIME NOT NULL,
 paid_amount DECIMAL(20,2) NULL,paid_date DATE NULL,paid_by BIGINT NULL,paid_at DATETIME NULL,
 ledger_head_id BIGINT NULL,shipped_by BIGINT NULL,shipped_at DATETIME NULL,
 INDEX(tenant_id,workflow_status));
CREATE TABLE jsh_factory_shipping_history(
 id BIGINT AUTO_INCREMENT PRIMARY KEY,tenant_id BIGINT NOT NULL,head_id BIGINT NOT NULL,action VARCHAR(30) NOT NULL,
 actor_id BIGINT NOT NULL,actor_name VARCHAR(100) NOT NULL,comment VARCHAR(2000) NOT NULL,payload_json MEDIUMTEXT NOT NULL,
 created_at DATETIME NOT NULL,INDEX(tenant_id,head_id));
INSERT INTO jsh_function(number,name,parent_number,url,component,state,sort,enabled,type,push_btn,icon,delete_flag)
 SELECT 'factoryShipping','发货申请与装车出库',parent_number,'/factory/shipping','/factory/ShipmentList',b'0','0329',b'1','电脑版','1','car','0'
 FROM jsh_function WHERE id=242 AND NOT EXISTS(SELECT 1 FROM jsh_function WHERE url='/factory/shipping');
SET @shippingMenu=(SELECT id FROM jsh_function WHERE url='/factory/shipping');
SET @stockMenu=(SELECT id FROM jsh_function WHERE url='/factory/stock_check');
SET @salesRoot=(SELECT id FROM jsh_function WHERE number=(SELECT parent_number FROM jsh_function WHERE id=242));
UPDATE jsh_user_business SET value=CONCAT(IFNULL(value,''),'[',@salesRoot,'][',@shippingMenu,']')
 WHERE type='RoleFunctions' AND (value LIKE '%[242]%' OR value LIKE CONCAT('%[',@stockMenu,']%')) AND value NOT LIKE CONCAT('%[',@shippingMenu,']%');
