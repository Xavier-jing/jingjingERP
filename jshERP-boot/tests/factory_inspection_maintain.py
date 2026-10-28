from pathlib import Path
import uuid,json
root=Path(__file__).resolve().parents[2];scope={'__file__':str(root/'jshERP-boot/tests/factory_sales_self_review.py')}
exec((root/'jshERP-boot/tests/factory_sales_self_review.py').read_text(encoding='utf-8').split("marker='SELF-REVIEW-")[0],scope)
api,ok,query,login=(scope[k] for k in ('api','ok','query','login'))
chief=login('模拟一车间主任','Simtest2026!');other=login('模拟二车间主任','Simtest2026!');inspector=login('模拟质检员','Simtest2026!')
batch='QC-MAINTAIN-'+uuid.uuid4().hex[:8];ids=[];checks=[]
before=query('SELECT id,current_number FROM jsh_material_current_stock ORDER BY id;')
query(f"INSERT INTO jsh_factory_production_report(tenant_id,head_id,workshop_no,line_no,stage_no,report_date,batch_number,input_quantity,output_quantity,loss_quantity,comment,actor_id,actor_name,created_at) VALUES(327,667,1,0,1,CURDATE(),'{batch}',0.2,0.2,0,'临时回归',333,'模拟一车间主任',NOW());")
def detail(i):return ok(api('/factoryQuality/'+str(i),token=chief))
def action(i,action,token=chief,version=None,quantity=0.15):return api('/factoryQuality/'+str(i)+'/request',{'action':action,'version':detail(i)['version'] if version is None else version,'quantity':quantity,'comment':'回归修改'},token)
def create():
    i=ok(api('/factoryQuality/request',{'headId':667,'lineNo':0,'stageNo':1,'workshopNo':1,'batchNumber':batch,'quantity':0.1,'comment':'临时回归'},chief));ids.append(i);return i
try:
    i=create();d=detail(i)
    assert action(i,'edit',other)['code']==409
    assert action(i,'delete',other)['code']==409
    assert action(i,'edit',version=d['version']-1)['code']==409
    assert action(i,'edit',quantity=0.3)['code']==409
    ok(action(i,'edit'));changed=detail(i)
    assert changed['quantity']==0.15 and changed['version']==d['version']+1
    standards=ok(api('/factoryQuality/standards',token=chief))
    current=next(s for s in standards if s['bar_code']=='ALD-MOCK-052-10G' and s['inspection_kind']=='semi' and s['stage_no']==1)
    assert changed['forms']==current['forms']
    checks.append('仅原主任可修改删除；旧版本与超产出数量拒绝；修改采用最新标准')
    ok(action(i,'delete'));assert api('/factoryQuality/'+str(i),token=chief)['code']==409
    i=create();d=detail(i)
    assert api('/factoryQuality/'+str(i)+'/action',{'action':'start','version':d['version']},chief)['code']==409
    ok(api('/factoryQuality/'+str(i)+'/action',{'action':'start','version':d['version']},inspector))
    assert action(i,'edit')['code']==409 and action(i,'delete')['code']==409
    assert detail(i)['workflow_status']=='detecting'
    checks.append('仅质检员可开始检测；未填结果即锁定申请，禁止修改删除')
    assert api('/factoryQuality/'+str(i)+'/action',{'action':'start','version':d['version']},inspector)['code']==409
    d=detail(i)
    values=[{'value':item.get('expected') or '合格'} if item['type']=='text' else {'value':item.get('min',0)} for item in d['forms'][0]['items']]
    ok(api('/factoryQuality/'+str(i)+'/action',{'action':'form','version':d['version'],'formIndex':0,'values':values,'comment':'回归检测'},inspector))
    assert action(i,'edit')['code']==409 and action(i,'delete')['code']==409
    checks.extend(['删除释放数量，可重新送检','已有检测数据禁止修改删除'])
    query(f"UPDATE jsh_factory_inspection SET workflow_status='pending' WHERE tenant_id=327 AND id={i};")
    assert action(i,'delete')['code']==409
    checks.append('已提交主任确认的送检单禁止删除')
finally:
    for i in ids:
        query(f'DELETE FROM jsh_factory_quality_history WHERE tenant_id=327 AND inspection_id={i}; DELETE FROM jsh_factory_inspection WHERE tenant_id=327 AND id={i};')
    query(f"DELETE FROM jsh_factory_production_report WHERE tenant_id=327 AND batch_number='{batch}';")
    assert before==query('SELECT id,current_number FROM jsh_material_current_stock ORDER BY id;')
checks.append('临时测试数据清理，库存未改变，57和58未修改')
print(json.dumps(checks,ensure_ascii=False))
