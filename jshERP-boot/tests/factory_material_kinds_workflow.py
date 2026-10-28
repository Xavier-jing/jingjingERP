"""Local simulation integration checks; leaves existing business stock unchanged."""
import json
import os
import pathlib
import subprocess
import time
import uuid
from urllib.parse import urlencode

root = pathlib.Path(__file__).resolve().parents[2]
source = root / 'jshERP-boot/tests/factory_sales_workflow.py'
scope = {'__file__': str(source)}
exec(source.read_text(encoding='utf-8').split("seller=login('jsh')")[0], scope)
raw_api, ok = scope['api'], scope['ok']
token = scope['login'](os.environ.get('ERP_TEST_TENANT_LOGIN', 'jingjing'))
mysql = next((root / '.local-runtime/runtime/mysql').glob('*/bin/mysql.exe'))
def query(sql):
    result = subprocess.run([str(mysql),'--defaults-file='+str(root/'.quality-local/mysql-client.cnf'),'-N','-B','--raw','--default-character-set=utf8mb4','jsh_erp'],input=sql.encode(),capture_output=True,check=True)
    return result.stdout.decode('utf-8').strip()
def api(path, data=None, method=None):
    if data is not None or method == 'DELETE':
        time.sleep(2.1)
    return raw_api(path, data, token, method)
def listing(kind):
    data = ok(api('/material/list?'+urlencode({'search':json.dumps({'materialKind':kind}), 'currentPage':1,'pageSize':100})))
    assert all(row['materialKind']==kind for row in data['rows']), data
    return data['rows']

marker = 'KIND-TEST-' + uuid.uuid4().hex[:10]
ids, checks = [], []
before = query('SELECT id,material_id,depot_id,current_number FROM jsh_material_current_stock ORDER BY id;')
try:
    products, materials = listing('product'), listing('raw')
    assert any(p['mBarCode']=='ALD-MOCK-052-10G' for p in products)
    assert any(p['mBarCode']=='RAW-MOCK-A' for p in materials)
    checks.append('产品与原料列表和总数按类型隔离')
    sales = ok(api('/factorySales/options'))['products']
    assert all(p['barCode']!='RAW-MOCK-A' for p in sales)
    quality = ok(api('/factoryQuality/standardOptions'))['products']
    assert all(p['barCode']!='RAW-MOCK-A' for p in quality)
    raw_options = ok(api('/factoryMaterial/options'))['products']
    assert any(p['barCode']=='RAW-MOCK-A' for p in raw_options)
    assert all(p['barCode']!='ALD-MOCK-052-10G' for p in raw_options)
    checks.append('销售与质检只选产品，领补退料只选原料')
    wrong = api('/factoryMaterial/stock?barCode=ALD-MOCK-052-10G&depotId=19')
    assert wrong['code']==409, wrong
    checks.append('原料接口拒绝手工传入产品条码')
    for kind in ('product','raw'):
        code = marker + '-' + kind
        body = {'name':code,'materialKind':kind,'unit':'吨','brand':'模拟','standard':'测试规格','model':'测试型号','enableSerialNumber':'0','enableBatchNumber':'1','remark':'临时类型隔离检查，结束后删除','meList':[{'barCode':code,'commodityUnit':'吨'}],'stock':[],'sortList':[]}
        ok(api('/material/add',body))
        material_id = int(query("SELECT m.id FROM jsh_material m JOIN jsh_material_extend e ON e.material_id=m.id WHERE e.bar_code='"+code+"' AND IFNULL(m.delete_flag,'0')='0';"))
        ids.append(material_id)
        assert any(row['id']==material_id for row in listing(kind))
        other = 'raw' if kind=='product' else 'product'
        assert all(row['id']!=material_id for row in listing(other))
        rejected = api('/material/update',{'id':material_id,'materialKind':other},'PUT')
        assert rejected['code']==409, rejected
        assert query('SELECT material_kind FROM jsh_material WHERE id='+str(material_id))==kind
    checks.append('两种资料可新增且持久化，编辑不能跨类型转换')
    invalid = api('/material/add',{'name':marker+'-invalid','materialKind':'invalid'})
    assert invalid['code']==409, invalid
    checks.append('拒绝非法物料类型')
    raw_menu = query("SELECT id FROM jsh_function WHERE url='/material/raw_material' AND enabled=1 AND delete_flag='0';")
    assert raw_menu
    raw_buttons = query("SELECT COUNT(*) FROM jsh_user_business WHERE type='RoleFunctions' AND value LIKE '%["+raw_menu+"]%' AND JSON_VALID(btn_str);")
    assert int(raw_buttons)>=3
    checks.append('原料菜单及角色按钮继承已保存')
finally:
    for material_id in ids:
        ok(api('/material/delete?id='+str(material_id),method='DELETE'))
    assert query('SELECT id,material_id,depot_id,current_number FROM jsh_material_current_stock ORDER BY id;')==before
    api('/user/logout')
checks.append('临时资料已删除，原有库存保持一致')
print(json.dumps({'passed':checks,'count':len(checks)},ensure_ascii=False,indent=2))
(root/'.quality-local/material-kind-tests.json').write_text(json.dumps({'passed':checks},ensure_ascii=False,indent=2),encoding='utf-8')
