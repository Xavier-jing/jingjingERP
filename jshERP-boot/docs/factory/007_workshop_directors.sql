ALTER TABLE jsh_factory_production_config
 CHANGE COLUMN director_id coordinator_id BIGINT NOT NULL,
 ADD COLUMN workshop1_director_id BIGINT NULL,
 ADD COLUMN workshop2_director_id BIGINT NULL,
 ADD COLUMN workshop3_director_id BIGINT NULL;
ALTER TABLE jsh_factory_production_task ADD COLUMN route_json MEDIUMTEXT NULL;
UPDATE jsh_factory_production_task SET route_json=CASE WHEN workflow_status='scheduled' THEN plan_json ELSE '[]' END;
CREATE TABLE jsh_factory_workshop_task (
 tenant_id BIGINT NOT NULL,head_id BIGINT NOT NULL,workshop_no INT NOT NULL,
 workflow_status VARCHAR(16) NOT NULL,accepted_by BIGINT NULL,accepted_at DATETIME NULL,
 updated_at DATETIME NOT NULL,PRIMARY KEY(tenant_id,head_id,workshop_no));
INSERT INTO jsh_factory_workshop_task(tenant_id,head_id,workshop_no,workflow_status,updated_at)
 SELECT DISTINCT t.tenant_id,t.head_id,j.workshop_no,'pending',NOW()
 FROM jsh_factory_production_task t JOIN JSON_TABLE(t.route_json,'$[*]' COLUMNS(workshop_no INT PATH '$.workshopNo')) j
 WHERE t.workflow_status='scheduled';
INSERT INTO jsh_factory_production_history(tenant_id,head_id,action,actor_id,actor_name,comment,payload_json,created_at)
 SELECT tenant_id,head_id,'flow_upgrade',0,'系统升级','升级为统筹分配、各车间分别确认；原排班保留',JSON_OBJECT('previousState',workflow_status),NOW()
 FROM jsh_factory_production_task WHERE workflow_status IN('accepted','scheduled');
UPDATE jsh_factory_production_task SET workflow_status=CASE WHEN workflow_status='accepted' THEN 'approved' ELSE 'distributed' END,version=version+1,updated_at=NOW()
 WHERE workflow_status IN('accepted','scheduled');
