from pathlib import Path
import json,uuid
root=Path(__file__).resolve().parents[2];scope={'__file__':str(root/'jshERP-boot/tests/factory_sales_self_review.py')}
exec((root/'jshERP-boot/tests/factory_sales_self_review.py').read_text(encoding='utf-8').split("marker='SELF-REVIEW-")[0],scope)
api,ok,query,login=(scope[k] for k in ('api','ok','query','login'))
chief=login('模拟一车间主任','Simtest2026!');director=login('模拟质检主任','Simtest2026!')
batch='QC-DECISION-'+uuid.uuid4().hex[:8];ids=[];checks=[]
before=query('SELECT id,current_number FROM jsh_material_current_stock ORDER BY id;')
query(f"INSERT INTO jsh_factory_production_report(tenant_id,head_id,workshop_no,line_no,stage_no,report_date,batch_number,input_quantity,output_quantity,loss_quantity,comment,actor_id,actor_name,created_at) VALUES(327,667,1,0,1,CURDATE(),'{batch}',1,1,0,'临时判定回归',333,'模拟一车间主任',NOW());")
def detail(i):return ok(api('/factoryQuality/'+str(i),token=director))
def action(i,name,qty=0,comment='判定回归原因',token=director,version=None):return api('/factoryQuality/'+str(i)+'/action',{'action':name,'version':detail(i)['version'] if version is None else version,'qualifiedQuantity':qty,'comment':comment},token)
def create(parent=None):
    i=ok(api('/factoryQuality/request',{'headId':667,'lineNo':0,'stageNo':1,'workshopNo':1,'batchNumber':batch,'quantity':0.1,'parentId':parent,'comment':'临时回归复检'},chief));ids.append(i);return i
try:
    i=create()
    forms=json.dumps([{'name':'测试数值','items':[{'name':'孔容积','type':'number','min':0.4,'value':0.3}]}],ensure_ascii=False)
    query(f"UPDATE jsh_factory_inspection SET forms_json='{forms}',workflow_status='pending' WHERE tenant_id=327 AND id={i};")
    assert action(i,'approve',0.1)['code']==409
    assert action(i,'approve',0.05)['code']==409
    assert detail(i)['workflow_status']=='pending'
    ok(action(i,'approve'))
    checks.append('数值不合格时全部及部分合格均拒绝，0合格可确认')
    query(f'UPDATE jsh_factory_inspection SET qualified_quantity=0.1 WHERE tenant_id=327 AND id={i};')
    d=detail(i)
    assert action(i,'correctDecision',token=chief)['code']==409
    assert action(i,'correctDecision',version=d['version']-1)['code']==409
    assert action(i,'correctDecision',comment='')['code']==409
    assert action(i,'correctDecision',0.1)['code']==409
    ok(action(i,'correctDecision'))
    d=detail(i);assert d['qualified_quantity']==0
    event=next(h for h in d['history'] if h['action']=='correctDecision')
    assert json.loads(event['payload_json'])['previousQualifiedQuantity']==0.1
    checks.append('仅主任可带原因更正判定，保存旧判定并校验版本及异常值')
    child=create(i)
    assert action(i,'correctDecision')['code']==409
    checks.append('有复检下游时禁止更正判定；更正后可申请复检')
    forms=json.dumps([{'name':'测试文字','items':[{'name':'颜色','type':'text','expected':'白色','value':'黑色'}]}],ensure_ascii=False)
    query(f"UPDATE jsh_factory_inspection SET forms_json='{forms}',workflow_status='pending' WHERE tenant_id=327 AND id={child};")
    assert action(child,'approve',0.1)['code']==409
    ok(action(child,'approve'))
    checks.append('文字指标不合格也必须判为0合格')
    normal=create()
    forms=json.dumps([{'name':'正常数值','items':[{'name':'孔容积','type':'number','min':0.4,'value':0.5}]}],ensure_ascii=False)
    query(f"UPDATE jsh_factory_inspection SET forms_json='{forms}',workflow_status='pending' WHERE tenant_id=327 AND id={normal};")
    assert action(normal,'approve',None)['code']==409
    ok(action(normal,'approve',0.1))
    checks.append('合格指标正常确认；不填写合格数量不能提交')
finally:
    for i in reversed(ids):query(f'DELETE FROM jsh_factory_quality_history WHERE tenant_id=327 AND inspection_id={i}; DELETE FROM jsh_factory_inspection WHERE tenant_id=327 AND id={i};')
    query(f"DELETE FROM jsh_factory_production_report WHERE tenant_id=327 AND batch_number='{batch}';")
    assert before==query('SELECT id,current_number FROM jsh_material_current_stock ORDER BY id;')
checks.append('临时测试数据清理，库存未改变')
print(json.dumps(checks,ensure_ascii=False))
