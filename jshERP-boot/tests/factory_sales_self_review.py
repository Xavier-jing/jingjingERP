"""Local regression: configured sales reviewer can approve their own orders."""
from pathlib import Path
import hashlib, json, subprocess, time, uuid

root=Path(__file__).resolve().parents[2]
source=root/'jshERP-boot/tests/factory_sales_workflow.py'
scope={'__file__':str(source)}
exec(source.read_text(encoding='utf-8').split("seller=login('jsh')")[0],scope)
raw_api=scope['api']
def ok(response):
    assert response['code']==200,response
    return response.get('data')
def login(name,password):
    captcha=uuid.uuid4().hex
    scope['redis']('SETEX','captcha_codes:'+captcha,60,'T3ST')
    return ok(raw_api('/user/login',{'loginName':name,'password':hashlib.md5(password.encode()).hexdigest(),'uuid':captcha,'code':'T3ST'}))['token']
owner=login('jingjing','123456')
manager=login('模拟销售经理','Simtest2026!')
seller=login('模拟销售员','Simtest2026!')
def api(path,data=None,token=owner,method=None):
    if data is not None or method=='DELETE':time.sleep(2.1)
    return raw_api(path,data,token,method)
mysql=next((root/'.local-runtime/runtime/mysql').glob('*/bin/mysql.exe'))
def query(sql):
    r=subprocess.run([str(mysql),'--defaults-file='+str(root/'.quality-local/mysql-client.cnf'),'--default-character-set=utf8mb4','-N','-B','--raw','jsh_erp'],input=sql.encode(),capture_output=True,check=True)
    return r.stdout.decode('utf-8').strip()
marker='SELF-REVIEW-'+uuid.uuid4().hex[:8]
orders=[];product=None;customer=None;checks=[]
before=query('SELECT id,material_id,depot_id,current_number FROM jsh_material_current_stock ORDER BY id;')
def detail(i,token):return ok(api('/factorySales/'+str(i),token=token))
def action(i,act,token,version=None):
    return api('/factorySales/'+str(i)+'/action',{'action':act,'version':detail(i,token)['version'] if version is None else version},token)
try:
    options=ok(api('/factorySales/options',token=manager))
    assert options['reviewerId']==options['currentUserId'],'模拟销售经理不是当前固定审核人，未修改配置'
    ok(api('/material/add',{'name':marker,'materialKind':'product','unit':'吨','brand':'模拟牌号','standard':'审核回归规格','model':'模拟型号','enableBatchNumber':'1','enableSerialNumber':'0','meList':[{'barCode':marker,'commodityUnit':'吨'}],'stock':[],'sortList':[]}))
    product=int(query("SELECT m.id FROM jsh_material m JOIN jsh_material_extend e ON e.material_id=m.id WHERE e.bar_code='"+marker+"' AND IFNULL(m.delete_flag,'0')='0';"))
    ok(api('/supplier/add',{'supplier':marker,'type':'客户','enabled':True,'beginNeedGet':0,'beginNeedPay':0}))
    customer=int(query("SELECT id FROM jsh_supplier WHERE tenant_id=327 AND supplier='"+marker+"' AND IFNULL(delete_flag,'0')='0';"))
    def create(token):
        i=ok(api('/factorySales/save',{'customerId':customer,'deliveryDate':'2026-11-10','paymentTerms':'prepay','requirements':'临时审核规则回归','remark':marker,'lines':[{'barCode':marker,'quantity':'1','price':'1000'}]},token))
        orders.append((i,token));return i
    own=create(manager)
    assert action(own,'approve',manager)['code']==409
    ok(action(own,'submit',manager));assert detail(own,manager)['workflow_status']=='pending'
    checks.append('经理本人订单可提交，草稿不能跳过提交直接审核')
    assert action(own,'approve',seller)['code']==409
    ok(action(own,'approve',manager));d=detail(own,manager);assert d['workflow_status']=='approved'
    assert any(h['action']=='submit' for h in d['history']) and any(h['action']=='approve' for h in d['history'])
    checks.append('固定审核人可审核本人订单，保留提交及审核记录')
    assert action(own,'unapprove',seller)['code']==409
    ok(action(own,'unapprove',manager));assert detail(own,manager)['workflow_status']=='draft'
    checks.append('本人订单仍遵守反审核状态和审核人权限')
    employee=create(seller)
    assert action(employee,'approve',seller)['code']==409
    ok(action(employee,'submit',seller));pending=detail(employee,seller)
    assert action(employee,'approve',seller)['code']==409
    assert action(employee,'approve',manager,pending['version']-1)['code']==409
    assert detail(employee,seller)['workflow_status']=='pending'
    checks.append('销售员仍不能自审，旧版本审批被拒绝且状态不变')
    assert api('/depotHead/batchSetStatus',{'ids':str(employee),'status':'1'},seller)['code']==409
    checks.append('原库存单据审核接口不能绕过工厂订单审批')
    ok(api('/factorySales/'+str(employee)+'/action',{'action':'return','comment':'回归检查退回修改','version':detail(employee,manager)['version']},manager))
    assert detail(employee,seller)['workflow_status']=='returned'
    ok(action(employee,'submit',seller));ok(action(employee,'approve',manager))
    assert detail(employee,seller)['workflow_status']=='approved'
    checks.append('销售员订单退回、重提及销售经理审核保持正常')
finally:
    for i,creator in orders:
        d=detail(i,creator)
        if d['workflow_status']=='approved':ok(action(i,'unapprove',manager))
        elif d['workflow_status']=='pending':ok(action(i,'withdraw',creator))
        d=detail(i,creator)
        ok(api('/factorySales/delete',{'orders':[{'id':i,'version':d['version']}]},creator))
    if product:ok(api('/material/delete?id='+str(product),method='DELETE'))
    if customer:ok(api('/supplier/delete?id='+str(customer),method='DELETE'))
    for token in (owner,manager,seller):raw_api('/user/logout',token=token)
    assert before==query('SELECT id,material_id,depot_id,current_number FROM jsh_material_current_stock ORDER BY id;')
checks.append('临时订单、客户及产品已清理，库存未变')
print(json.dumps({'passed':checks,'count':len(checks)},ensure_ascii=False,indent=2))
(root/'.quality-local/sales-self-review-tests.json').write_text(json.dumps({'passed':checks},ensure_ascii=False,indent=2),encoding='utf-8')
