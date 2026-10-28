-- Previously saved testing forms have already started; preserve their lock and data.
UPDATE jsh_factory_inspection i
SET i.workflow_status='detecting',i.version=i.version+1
WHERE i.workflow_status='testing' AND EXISTS (
 SELECT 1 FROM jsh_factory_quality_history h
 WHERE h.tenant_id=i.tenant_id AND h.inspection_id=i.id AND h.action='form'
);
