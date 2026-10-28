import os
import pathlib,json,urllib.request,urllib.error,socket,uuid,hashlib,time,subprocess
from decimal import Decimal,ROUND_HALF_UP
b=pathlib.Path(os.environ.get('ERP_WORK_DIR',str(pathlib.Path(__file__).resolve().parents[2]/'.local-runtime'))).resolve();creds=json.loads((b/'local/credentials.json').read_text());checks=[];ids=[]
def redis(*args):
 with socket.create_connection(('127.0.0.1',16379)) as s:
  f=s.makefile('rb')
  for parts in [('AUTH',creds['redis_password']),args]:
   vals=[str(x).encode() for x in parts];s.sendall(b'*'+str(len(vals)).encode()+b'\r\n'+b''.join(b'$'+str(len(v)).encode()+b'\r\n'+v+b'\r\n' for v in vals));line=f.readline();assert not line.startswith(b'-'),line

def api(path,data=None,token=None,method=None):
 if path=='/factorySales/save' and data is not None:data=dict(data);data.setdefault('paymentTerms','credit')
 headers={'Content-Type':'application/json'}
 if token:headers['X-Access-Token']=token
 req=urllib.request.Request('http://127.0.0.1:3000/jshERP-boot'+path,data=json.dumps(data).encode() if data is not None else None,headers=headers,method=method)
 try:
  with urllib.request.urlopen(req,timeout=20) as r:return json.load(r)
 except urllib.error.HTTPError as e:return {'code':e.code,'data':e.read().decode()}
def login(name):
 fixture=uuid.uuid4().hex;redis('SETEX','captcha_codes:'+fixture,60,'T3ST');r=api('/user/login',{'loginName':name,'password':hashlib.md5(b'123456').hexdigest(),'uuid':fixture,'code':'T3ST'});assert r['code']==200,r;return r['data']['token']
def ok(r):assert r['code']==200,r;return r['data']
def blocked(r):assert r['code']!=200,r
seller=login('jsh');reviewer=login('test123');admin=login('admin')
def detail(i):return ok(api('/factorySales/'+str(i),token=seller))
def action(i,act,token,comment='',version=None):
 d=detail(i);return api('/factorySales/'+str(i)+'/action',{'action':act,'comment':comment,'version':version or d['version']},token)
try:
 options=ok(api('/factorySales/options',token=seller));assert len(options['products'])>=3,options
 blocked(api('/factorySales/options',token=admin));checks.append('non-tenant access denied')
 ok(api('/factorySales/reviewer',{'reviewerId':131},seller));blocked(api('/factorySales/reviewer',{'reviewerId':63},reviewer));checks.append('fixed reviewer configuration permission')
 payload={'customerId':options['customers'][0]['id'],'deliveryDate':'2026-11-10','requirements':'【自动化测试】包装要求及检测指标','remark':'【自动化测试】执行完成后清理','lines':[{'barCode':options['products'][0]['barCode'],'quantity':'1.234567','price':'123.456789'},{'barCode':options['products'][1]['barCode'],'quantity':'2.5','price':'800'}]}
 bad=json.loads(json.dumps(payload));bad['lines'][0]['quantity']='-1';blocked(api('/factorySales/save',bad,seller));bad['lines'][0]['quantity']='0';blocked(api('/factorySales/save',bad,seller));checks.append('invalid quantity rejected')
 bad=json.loads(json.dumps(payload));bad['deliveryDate']='not-date';blocked(api('/factorySales/save',bad,seller));checks.append('date validation')
 i=ok(api('/factorySales/save',payload,seller));ids.append(i);d=detail(i)
 expected=(Decimal('1.234567')*Decimal('123.456789')).quantize(Decimal('.01'),rounding=ROUND_HALF_UP)+Decimal('2000')
 assert Decimal(str(d['total_price']))==expected,(d,expected);assert len(d['lines'])==2;listing=ok(api('/factorySales/list?page=1&size=1',token=seller));assert listing['total']>=1 and len(listing['rows'])==1;checks.append('multi-line tax-inclusive amount computed server-side')
 blocked(action(i,'approve',seller));ok(action(i,'submit',seller));blocked(action(i,'approve',seller));checks.append('submit and non-reviewer approval denied')
 pending=detail(i);stale=pending['version'];
 from urllib.parse import urlencode
 def filtered(**kw):return ok(api('/factorySales/list?'+urlencode(kw),token=seller))
 assert filtered(number=pending['number'])['total']==1
 assert filtered(number='NO-SUCH-ORDER-QUERY')['total']==0
 assert filtered(number=pending['number'],material='WHA-413')['total']==1
 assert filtered(number=pending['number'],material='NO-SUCH-PRODUCT-QUERY')['total']==0
 assert filtered(number=pending['number'],customerId=payload['customerId'],creatorId=63,state='pending',remark='自动化测试')['total']==1
 assert filtered(number=pending['number'],beginDate='2020-01-01',endDate='2030-01-01')['total']==1
 assert filtered(number=pending['number'],beginDate='2020-01-01',endDate='2020-01-01')['total']==0
 blocked(api('/factorySales/list?beginDate=2026-11-01&endDate=2026-10-01',token=seller))
 checks.append('number, product, date, customer, creator, status and remark filters')
 blocked(api('/factorySales/save',dict(payload,id=i,version=stale),seller));blocked(api('/depotHead/batchSetStatus',{'ids':str(i),'status':'1'},seller));blocked(api('/depotHead/delete?id='+str(i),token=seller,method='DELETE'));blocked(api('/depotHead/forceCloseBatch',{'ids':str(i)},seller));checks.append('pending edit and legacy approval/delete/force-close bypass denied')
 blocked(api('/factorySales/reviewer',{'reviewerId':63},seller));blocked(action(i,'return',reviewer));checks.append('pending reviewer change and empty return reason denied')
 ok(action(i,'return',reviewer,'请补充客户包装要求'));returned=detail(i);assert returned['workflow_status']=='returned';blocked(action(i,'approve',reviewer,version=stale));checks.append('return reason and optimistic concurrency')
 time.sleep(2.1);payload.update(id=i,version=returned['version']);payload['requirements']='【自动化测试】修改后的包装要求';ok(api('/factorySales/save',payload,seller));ok(action(i,'submit',seller));ok(action(i,'approve',reviewer));assert detail(i)['workflow_status']=='approved';checks.append('edit returned order, resubmit and approve')
 blocked(api('/factorySales/save',dict(payload,version=detail(i)['version']),seller));ok(action(i,'withdraw',seller));assert detail(i)['workflow_status']=='draft';assert len(detail(i)['history'])>=7;checks.append('approved immutable, withdraw and complete audit trail')
 print(json.dumps({'passed':checks,'testOrderIds':ids},ensure_ascii=False,indent=2))
 (b/'sales-test-result.json').write_text(json.dumps({'passed':checks},ensure_ascii=False,indent=2),encoding='utf-8')
finally:
 for t in [seller,reviewer,admin]:api('/user/logout',token=t)
 if ids:
  f=b/'local/test-cleanup.cnf';f.write_text('[client]\nuser='+creds['db_user']+'\npassword='+creds['db_password']+'\nhost=127.0.0.1\nport=13306\n')
  try:
   for i in ids:
    sql=f"START TRANSACTION; DELETE FROM jsh_factory_sales_history WHERE head_id={int(i)} AND tenant_id=63; DELETE FROM jsh_factory_sales_order WHERE head_id={int(i)} AND tenant_id=63; DELETE FROM jsh_depot_item WHERE header_id={int(i)} AND tenant_id=63; DELETE FROM jsh_depot_head WHERE id={int(i)} AND tenant_id=63 AND remark='【自动化测试】执行完成后清理'; COMMIT;"
    cli=next((b/'runtime/mysql').glob('*/bin/mysql.exe'));subprocess.run([str(cli),'--defaults-file='+str(f),'--default-character-set=utf8mb4','jsh_erp'],input=sql.encode(),check=True)
  finally:f.unlink(missing_ok=True)
