"""Product-material configuration checks against the local simulation tenant."""
from pathlib import Path
import hashlib, json, subprocess, time, uuid
from urllib.parse import urlencode

root = Path(__file__).resolve().parents[2]
source = root/'jshERP-boot/tests/factory_sales_workflow.py'
scope = {'__file__':str(source)}
exec(source.read_text(encoding='utf-8').split("seller=login('jsh')")[0],scope)
raw_api = scope['api']
def ok(response):
    assert response['code']==200,response
    return response.get('data')
def login(name,password):
    captcha=uuid.uuid4().hex
    scope['redis']('SETEX','captcha_codes:'+captcha,60,'T3ST')
    return ok(raw_api('/user/login',{'loginName':name,'password':hashlib.md5(password.encode()).hexdigest(),'uuid':captcha,'code':'T3ST'}))['token']
owner=login('jingjing','123456')
def api(path,data=None,token=owner,method=None):
    if data is not None or method=='DELETE':time.sleep(2.1)
    return raw_api(path,data,token,method)
mysql=next((root/'.local-runtime/runtime/mysql').glob('*/bin/mysql.exe'))
def query(sql):
    r=subprocess.run([str(mysql),'--defaults-file='+str(root/'.quality-local/mysql-client.cnf'),'--default-character-set=utf8mb4','-N','-B','--raw','jsh_erp'],input=sql.encode(),capture_output=True,check=True)
    return r.stdout.decode().strip()
marker='PM-TEST-'+uuid.uuid4().hex[:8]
ids=[];checks=[];reader_role=None;reader_id=None;reader=None;seller=None
before=query('SELECT id,material_id,depot_id,current_number FROM jsh_material_current_stock ORDER BY id;')
try:
    for kind in ('product','raw','raw'):
        code=marker+'-'+str(len(ids))
        ok(api('/material/add',{'name':code,'materialKind':kind,'unit':'吨','brand':'模拟','standard':'测试规格','model':'测试型号','enableSerialNumber':'0','enableBatchNumber':'1','meList':[{'barCode':code,'commodityUnit':'吨'}],'stock':[],'sortList':[]}))
        mid=int(query("SELECT m.id FROM jsh_material m JOIN jsh_material_extend e ON e.material_id=m.id WHERE e.bar_code='"+code+"' AND IFNULL(m.delete_flag,'0')='0';"))
        ids.append(mid)
    path='/material/'+str(ids[0])+'/materials'
    initial=ok(api(path));assert initial['canEdit'] and initial['version']==0 and initial['lines']==[]
    assert all(row['materialId']!=ids[0] for row in initial['options'])
    checks.append('产品入口读取有效原料，原料档案不能作为产品配置')
    assert api('/material/'+str(ids[1])+'/materials')['code']==409
    lines=[{'barCode':marker+'-1','quantity':None,'remark':'未知用量待确认'},{'barCode':marker+'-2','quantity':'0.5','remark':'每吨产品参考用量，仅作模拟'}]
    ok(api(path,{'version':0,'lines':lines}))
    saved=ok(api(path));assert saved['version']==1 and len(saved['lines'])==2
    assert saved['lines'][0].get('quantity') is None and float(saved['lines'][1]['quantity'])==0.5
    assert saved['lines'][1]['unit']=='吨'
    checks.append('可关联多原料并保存空用量、数值、单位及备注')
    assert api(path,{'version':0,'lines':[]})['code']==409
    checks.append('旧版本保存被拒绝，避免覆盖他人修改')
    for invalid in ([lines[0],lines[0]],[{'barCode':marker+'-0','quantity':1}],[{'barCode':'NO-SUCH-RAW','quantity':1}],[{'barCode':marker+'-1','quantity':-1}]):
        assert api(path,{'version':1,'lines':invalid})['code']==409
    assert ok(api(path))['version']==1
    checks.append('拒绝重复原料、产品冒充原料、无效条码及负用量，失败不覆盖原配置')
    assert api('/material/delete?id='+str(ids[1]),method='DELETE')['code']==409
    checks.append('引用中的原料禁止删除')
    seller=login('模拟销售员','Simtest2026!')
    assert api(path,token=seller)['code']==409
    assert api(path,{'version':1,'lines':[]},seller)['code']==409
    checks.append('无产品菜单的销售账号不能读取或修改用料配置')
    # A separate read-only role checks the button boundary without changing real roles.
    ok(api('/role/add',{'name':marker,'type':'全部数据','priceLimit':'','description':'临时用料只读权限检查'}))
    reader_role=int(query("SELECT id FROM jsh_role WHERE name='"+marker+"' AND tenant_id=327 AND IFNULL(delete_flag,'0')='0';"))
    ok(api('/userBusiness/add',{'type':'RoleFunctions','keyId':str(reader_role),'value':'[21,23]','btnStr':'[]'}))
    ok(api('/user/addUser',{'loginName':marker,'username':marker,'password':hashlib.md5(b'Simtest2026!').hexdigest(),'roleId':reader_role,'leaderFlag':'0'}))
    reader_id=int(query("SELECT id FROM jsh_user WHERE login_name='"+marker+"' AND IFNULL(delete_flag,'0')='0';"))
    reader=login(marker,'Simtest2026!')
    assert ok(api(path,token=reader))['canEdit'] is False
    assert api(path,{'version':1,'lines':[]},reader)['code']==409
    checks.append('只读角色可查看，直接调用保存接口仍被拒绝')
    ok(api(path,{'version':1,'lines':[]}));assert ok(api(path))['lines']==[]
    checks.append('清空关联后可移除原料，配置不自动创建领料或扣库存')
finally:
    if ids:
        product=ids[0]
        current=raw_api('/material/'+str(product)+'/materials',token=owner)
        if current.get('code')==200 and current['data']['lines']:
            ok(api('/material/'+str(product)+'/materials',{'version':current['data']['version'],'lines':[]}))
    for mid in ids:ok(api('/material/delete?id='+str(mid),method='DELETE'))
    for token in (reader,seller):
        if token:raw_api('/user/logout',token=token)
    if reader_id:ok(api('/user/delete?id='+str(reader_id),method='DELETE'))
    if reader_role:ok(api('/role/delete?id='+str(reader_role),method='DELETE'))
    raw_api('/user/logout',token=owner)
    assert before==query('SELECT id,material_id,depot_id,current_number FROM jsh_material_current_stock ORDER BY id;')
checks.append('临时资料已删除，原有库存保持一致')
print(json.dumps({'passed':checks,'count':len(checks)},ensure_ascii=False,indent=2))
(root/'.quality-local/product-material-tests.json').write_text(json.dumps({'passed':checks},ensure_ascii=False,indent=2),encoding='utf-8')
