from pathlib import Path
import json
root=Path(__file__).resolve().parents[2];scope={'__file__':str(root/'jshERP-boot/tests/factory_sales_self_review.py')}
exec((root/'jshERP-boot/tests/factory_sales_self_review.py').read_text(encoding='utf-8').split("marker='SELF-REVIEW-")[0],scope)
api,ok,query,login=(scope[k] for k in ('api','ok','query','login'))
chief=login('模拟一车间主任','Simtest2026!');other=login('模拟二车间主任','Simtest2026!')
before=query('SELECT id,current_number FROM jsh_material_current_stock ORDER BY id;')
checks=[]
for state in ('draft','pending','cancelled','returned'):
    i=ok(api('/factoryMaterial/save',{'taskId':667,'kind':'issue','lineNo':0,'stageNo':1,'workshopNo':1,'reason':'删除功能临时测试','lines':[{'barCode':'RAW-MOCK-A','depotId':19,'batchNumber':'SIM-RAW-20261026-A','quantity':0.01}]},chief))
    def detail():return ok(api('/factoryMaterial/'+str(i),token=chief))
    try:
        query(f"UPDATE jsh_factory_material_request SET workflow_status='{state}' WHERE tenant_id=327 AND id={i};")
        d=detail()
        assert api('/factoryMaterial/'+str(i)+'/delete',{'version':d['version']},other)['code']==409
        assert api('/factoryMaterial/'+str(i)+'/delete',{'version':d['version']-1},chief)['code']==409
        if state=='draft':
            query(f"UPDATE jsh_factory_material_request SET workflow_status='confirmed' WHERE tenant_id=327 AND id={i};")
            assert api('/factoryMaterial/'+str(i)+'/delete',{'version':d['version']},chief)['code']==409
            query(f"UPDATE jsh_factory_material_request SET workflow_status='draft',ledger_head_id=1 WHERE tenant_id=327 AND id={i};")
            assert api('/factoryMaterial/'+str(i)+'/delete',{'version':d['version']},chief)['code']==409
            query(f"UPDATE jsh_factory_material_request SET ledger_head_id=NULL WHERE tenant_id=327 AND id={i};")
        ok(api('/factoryMaterial/'+str(i)+'/delete',{'version':d['version']},chief))
        assert query(f'SELECT COUNT(*) FROM jsh_factory_material_request WHERE tenant_id=327 AND id={i};')=='0'
        assert query(f"SELECT COUNT(*) FROM jsh_factory_material_history WHERE tenant_id=327 AND request_id={i} AND action='delete';")=='1'
        checks.append(state+'删除成功，越权和旧版本拒绝')
    finally:
        query(f'DELETE FROM jsh_factory_material_request WHERE tenant_id=327 AND id={i};')
assert before==query('SELECT id,current_number FROM jsh_material_current_stock ORDER BY id;')
checks.extend(['已确认或关联库存流水不能删除','删除后单据不存在且保留审计','库存未变化'])
print(json.dumps(checks,ensure_ascii=False))
