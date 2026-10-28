CREATE TABLE jsh_factory_production_start (
 tenant_id BIGINT NOT NULL,head_id BIGINT NOT NULL,workshop_no INT NOT NULL,line_no INT NOT NULL,stage_no INT NOT NULL,
 actual_start DATETIME NOT NULL,actor_id BIGINT NOT NULL,actor_name VARCHAR(100) NOT NULL,comment VARCHAR(2000) NOT NULL,
 PRIMARY KEY(tenant_id,head_id,workshop_no,line_no,stage_no));
CREATE TABLE jsh_factory_production_report (
 id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,tenant_id BIGINT NOT NULL,head_id BIGINT NOT NULL,workshop_no INT NOT NULL,line_no INT NOT NULL,stage_no INT NOT NULL,
 report_date DATE NOT NULL,batch_number VARCHAR(100) NOT NULL,input_quantity DECIMAL(18,6) NOT NULL,output_quantity DECIMAL(18,6) NOT NULL,loss_quantity DECIMAL(18,6) NOT NULL,
 comment VARCHAR(2000) NOT NULL,actor_id BIGINT NOT NULL,actor_name VARCHAR(100) NOT NULL,created_at DATETIME NOT NULL,
 UNIQUE KEY daily_batch(tenant_id,head_id,workshop_no,line_no,stage_no,report_date,batch_number));
