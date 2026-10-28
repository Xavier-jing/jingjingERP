"""Local regression for production reviewer reversal before workshop dispatch."""
from pathlib import Path
import json, uuid

root=Path(__file__).resolve().parents[2]
source=root/'jshERP-boot/tests/factory_sales_self_review.py'
scope={'__file__':str(source)}
exec(source.read_text(encoding='utf-8').split("marker='SELF-REVIEW-")[0],scope)
api,ok,query,login=(scope[k] for k in ('api','ok','query','login'))
manager=scope['manager'];owner=scope['owner']
leader=login('模拟审批领导','Simtest2026!')
coordinator=login('模拟生产统筹','Simtest2026!')
marker='PROD-REVERSE-'+uuid.uuid4().hex[:8]
product=customer=head=None
checks=[]
before=query('SELECT id,material_id,depot_id,current_number FROM jsh_material_current_stock ORDER BY id;')
def detail():return ok(api('/factoryProduction/'+str(head),token=leader))
def act(action,token=leader,comment='测试反审核原因',version=None):
    return api('/factoryProduction/'+str(head)+'/action',{'action':action,'comment':comment,'version':detail()['version'] if version is None else version},token)
try:
    ok(api('/material/add',{'name':marker,'materialKind':'product','unit':'吨','brand':'模拟牌号','standard':'回归规格','model':'测试','enableBatchNumber':'1','enableSerialNumber':'0','meList':[{'barCode':marker,'commodityUnit':'吨'}],'stock':[],'sortList':[]}))
    product=int(query("SELECT material_id FROM jsh_material_extend WHERE bar_code='"+marker+"';"))
    ok(api('/supplier/add',{'supplier':marker,'type':'客户','enabled':True,'beginNeedGet':0,'beginNeedPay':0}))
    customer=int(query("SELECT id FROM jsh_supplier WHERE tenant_id=327 AND supplier='"+marker+"';"))
    head=ok(api('/factorySales/save',{'customerId':customer,'deliveryDate':'2026-11-10','paymentTerms':'prepay','remark':marker,'lines':[{'barCode':marker,'quantity':'1','price':'1000'}]},manager))
    for action in ('submit','approve'):
        sales=ok(api('/factorySales/'+str(head),token=manager))
        ok(api('/factorySales/'+str(head)+'/action',{'action':action,'version':sales['version']},manager))
    stock=ok(api('/factoryStock/'+str(head)))
    ok(api('/factoryStock/'+str(head)+'/save',{'version':stock['version'],'confirmed':True,'allocations':[]}))
    payload={'taskTime':'2026-10-27T15:00','requirements':marker,'lines':[{'lineNo':0,'productionQuantity':'1','adjustReason':''}]}
    ok(api('/factoryProduction/'+str(head)+'/save',payload,manager))
    assert act('unapprove')['code']==409
    ok(act('submit',manager));ok(act('approve'))
    original=detail()
    for token in (manager,coordinator):assert act('unapprove',token)['code']==409
    for reason in ('','   '):assert act('unapprove',comment=reason)['code']==409
    assert act('unapprove',version=original['version']-1)['code']==409
    assert detail()['version']==original['version']
    checks.append('仅固定审批领导可操作；非已审核状态、空原因及旧版本均拒绝')
    ok(act('unapprove'))
    changed=detail()
    assert changed['workflow_status']=='draft' and changed['version']==original['version']+1
    assert changed['lines']==original['lines'] and changed['task_time']==original['task_time']
    assert any(h['action']=='unapprove' and h['comment']=='测试反审核原因' for h in changed['history'])
    sales=ok(api('/factorySales/'+str(head),token=manager))
    assert sales['workflow_status']=='approved' and any(h['action']=='production_unapprove' for h in sales['history'])
    checks.append('成功退回草稿，保留数量和任务时间，生产及订单履历记录原因')
    payload['version']=changed['version']
    ok(api('/factoryProduction/'+str(head)+'/save',payload,manager))
    ok(act('submit',manager));ok(act('approve'))
    checks.append('退回后销售可编辑、重新提交并由领导重新审核')
    query(f"INSERT INTO jsh_factory_production_start(tenant_id,head_id,workshop_no,line_no,stage_no,actual_start,actor_id,actor_name,comment) VALUES(327,{head},1,0,1,NOW(),333,'回归测试','{marker}');")
    try:
        response=act('unapprove');assert response['code']==409,response
        assert detail()['workflow_status']=='approved'
    finally:query(f'DELETE FROM jsh_factory_production_start WHERE tenant_id=327 AND head_id={head};')
    checks.append('即使状态仍为已审核，已有执行记录也拒绝反审核')
    ok(api('/factoryProduction/'+str(head)+'/distribute',{'version':detail()['version'],'routes':[{'lineNo':0,'stageNo':1,'workshopNo':1,'quantity':'1'}],'comment':'回归下发'},coordinator))
    assert act('unapprove')['code']==409
    assert detail()['workflow_status']=='distributed'
    checks.append('已下发车间但尚未接单也拒绝反审核')
finally:
    if head:
        # Only this run's temporary order is removed; real workflow records are untouched.
        query(f"DELETE FROM jsh_factory_workshop_task WHERE tenant_id=327 AND head_id={head}; DELETE FROM jsh_factory_production_history WHERE tenant_id=327 AND head_id={head}; DELETE FROM jsh_factory_production_task WHERE tenant_id=327 AND head_id={head};")
        sales=ok(api('/factorySales/'+str(head),token=manager))
        if sales['workflow_status']=='approved':ok(api('/factorySales/'+str(head)+'/action',{'action':'unapprove','version':sales['version']},manager))
        sales=ok(api('/factorySales/'+str(head),token=manager))
        ok(api('/factorySales/delete',{'orders':[{'id':head,'version':sales['version']}]},manager))
    if product:ok(api('/material/delete?id='+str(product),method='DELETE'))
    if customer:ok(api('/supplier/delete?id='+str(customer),method='DELETE'))
    assert before==query('SELECT id,material_id,depot_id,current_number FROM jsh_material_current_stock ORDER BY id;')
checks.append('临时测试数据清理完成，库存未改变')
result={'passed':checks,'count':len(checks)}
(root/'.quality-local/production-unapprove-tests.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(result,ensure_ascii=False,indent=2))
