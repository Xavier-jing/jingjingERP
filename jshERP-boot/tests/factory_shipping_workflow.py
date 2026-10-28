"""Order shipping integration checks; uses only disposable products, photos and documents."""
from factory_workshop_helpers import *
from datetime import date,timedelta
import struct,zlib,sys

passed=[]
def check(name,valid=True):
 assert valid,name
 passed.append(name)
def quoted(v):return "'"+str(v).replace('\\','\\\\').replace("'","''")+"'"

with WorkshopFixture() as t:
 old=sql("SELECT JSON_OBJECT('finance_id',finance_id,'updated_at',DATE_FORMAT(updated_at,'%Y-%m-%d %H:%i:%s')) FROM jsh_factory_shipping_config WHERE tenant_id=63")
 role=None;photos=[];codes=[];items=[]
 def shipping(path,body=None,token=None):return api('/factoryShipping'+path,body,token or t.seller)
 def detail(i,token=None):return ok(shipping('/'+str(i),token=token))
 def act(i,action,token=None,**body):
  d=detail(i);payload=dict(action=action,version=(d['shipment'] or {}).get('version'),orderVersion=d['orderVersion']);payload.update(body);return shipping('/'+str(i)+'/action',payload,token)
 def order(terms='prepay',quantities=(10,3)):
  time.sleep(1.1);i=ok(api('/factorySales/save',dict(customerId=58,deliveryDate='2026-11-20',paymentTerms=terms,remark=t.marker,lines=[dict(barCode=codes[n],quantity=q,price=10 if n==0 else 20) for n,q in enumerate(quantities)]),t.seller));t.ids.append(i)
  sql(f"UPDATE jsh_factory_sales_order SET workflow_status='approved' WHERE tenant_id=63 AND head_id={i};UPDATE jsh_depot_head SET status='1' WHERE tenant_id=63 AND id={i}");return i
 def reserve(i,allocations):
  d=ok(api('/factoryStock/'+str(i),token=t.seller));return api('/factoryStock/'+str(i)+'/save',dict(version=d['version'],confirmed=True,allocations=allocations),t.seller)
 def allocation(line,depot,batch,q):return dict(lineNo=line,depotId=depot,batchNumber=batch,quantity=q)
 def receipt(code,depot,batch,qty,release='released'):
  time.sleep(1.1);number=t.marker+'-IN-'+uuid.uuid4().hex[:6]
  head=dict(number=number,type='入库',subType='其它',status='1',operTime=date.today().isoformat()+' 08:00:00',remark=t.marker,totalPrice=qty*2,discountLastMoney=qty*2,changeAmount=0,debt=0,discount=0,discountMoney=0,otherMoney=0)
  row=dict(barCode=code,unit='吨',depotId=depot,batchNumber=batch,operNumber=qty,unitPrice=2,allPrice=qty*2,taxRate=0,taxMoney=0,taxLastMoney=qty*2)
  r=api('/depotHead/addDepotHeadAndDetail',dict(info=json.dumps(head,ensure_ascii=False),rows=json.dumps([row],ensure_ascii=False)),t.seller);assert r['code']==200,r
  ledger=int(sql('SELECT id FROM jsh_depot_head WHERE tenant_id=63 AND number='+quoted(number)));t.receipts.append(ledger);item=int(sql(f'SELECT id FROM jsh_depot_item WHERE tenant_id=63 AND header_id={ledger}'));items.append(item)
  sql(f"INSERT INTO jsh_factory_batch_quality VALUES({item},63,'passed',{qty},'{release}',0,'SHIP-TEST','Shipping fixture only')");return item
 def upload(suffix,content):
  boundary='ShippingTest'+uuid.uuid4().hex;filename=t.marker+'-'+suffix+'.png'
  body=(f'--{boundary}\r\nContent-Disposition: form-data; name="biz"\r\n\r\nbill\r\n--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{filename}"\r\nContent-Type: image/png\r\n\r\n').encode()+content+f'\r\n--{boundary}--\r\n'.encode()
  req=urllib.request.Request('http://127.0.0.1:3000/jshERP-boot/systemConfig/upload',data=body,headers={'Content-Type':'multipart/form-data; boundary='+boundary,'X-Access-Token':t.chiefs[0]})
  with urllib.request.urlopen(req,timeout=20) as response:r=json.load(response)
  ref=ok(r);photos.append(ref);return ref
 def truck(plate,lines,pictures):return dict(plate=plate,driver='TEST DRIVER',phone='13000000000',lines=lines,photos=pictures)
 try:
  sql("INSERT INTO jsh_role(name,type,enabled,tenant_id,delete_flag) VALUES("+quoted(t.marker+' warehouse')+",'全部数据',1,63,'0')");role=int(sql('SELECT id FROM jsh_role WHERE tenant_id=63 AND name='+quoted(t.marker+' warehouse')))
  menus=sql("SELECT id FROM jsh_function WHERE url IN('/factory/shipping','/factory/stock_check','/factory/production_task')").split();functions=''.join('['+m+']' for m in menus)
  sql(f"INSERT INTO jsh_user_business(type,key_id,value,tenant_id,delete_flag) VALUES('RoleFunctions','{role}','{functions}',63,'0');UPDATE jsh_user_business SET value='[{role}]' WHERE tenant_id=63 AND type='UserRole' AND key_id='{t.user_ids[0]}'")
  denied(shipping('/options',token=t.admin));denied(shipping('/options',token=t.chiefs[1]));denied(shipping('/config',dict(financeId=t.user_ids[2]),t.chiefs[0]));denied(shipping('/config',dict(financeId=999999999)));ok(shipping('/config',dict(financeId=t.user_ids[2])))
  check('tenant, shipping, warehouse and finance-configuration permissions')
  for n in range(2):
   code='SHIPTEST-'+uuid.uuid4().hex[:12];codes.append(code)
   sql("INSERT INTO jsh_material(name,unit,enabled,tenant_id,delete_flag,enable_serial_number,enable_batch_number,brand,standard,model) VALUES("+quoted(t.marker)+",'吨',1,63,'0','0','1','TEST','Spec','Model')")
   material=int(sql('SELECT id FROM jsh_material WHERE tenant_id=63 AND name='+quoted(t.marker)+' ORDER BY id DESC LIMIT 1'));t.raw_ids.append(material)
   sql(f"INSERT INTO jsh_material_extend(material_id,bar_code,commodity_unit,default_flag,tenant_id,delete_flag) VALUES({material},'{code}','吨','1',63,'0')")
  batchA=t.marker+'-A';batchB=t.marker+'-B';batchC=t.marker+'-C'
  itemA=receipt(codes[0],14,batchA,7,'pending');receipt(codes[0],15,batchB,4);receipt(codes[1],14,batchC,3)
  main=order();other=order('credit',(1,));allocs=[allocation(0,14,batchA,6),allocation(0,15,batchB,4),allocation(1,14,batchC,3)]
  sql(f"UPDATE jsh_factory_sales_order SET workflow_status='draft',payment_terms='unconfirmed' WHERE tenant_id=63 AND head_id={main};UPDATE jsh_depot_head SET status='0' WHERE tenant_id=63 AND id={main}")
  sales=ok(api('/factorySales/'+str(main),token=t.seller));denied(api('/factorySales/'+str(main)+'/action',dict(action='submit',version=sales['version']),t.seller))
  sql(f"UPDATE jsh_factory_sales_order SET workflow_status='approved',payment_terms='prepay' WHERE tenant_id=63 AND head_id={main};UPDATE jsh_depot_head SET status='1' WHERE tenant_id=63 AND id={main}")
  check('sales approval submission requires an explicit payment term')
  denied(act(main,'request'));ok(reserve(main,allocs));ok(reserve(other,[allocation(0,14,batchA,1)]));denied(act(main,'request'))
  sql(f"UPDATE jsh_factory_batch_quality SET release_state='released' WHERE tenant_id=63 AND item_id={itemA}")
  denied(act(main,'request',t.chiefs[0]));ok(act(main,'request'));denied(act(main,'request'));denied(act(main,'request',paymentTerms='credit'))
  check('sales-only request requires whole order reservation and released batches; duplicate request denied')
  denied(reserve(main,allocs));stock=ok(api('/factoryStock/'+str(main),token=t.seller));denied(api('/factoryStock/'+str(main)+'/release',dict(version=stock['version']),t.seller));sd=ok(api('/factorySales/'+str(main),token=t.seller));denied(api('/factorySales/'+str(main)+'/action',dict(action='withdraw',version=sd['version']),t.seller))
  check('active shipment freezes reservations and order changes')
  # Existing order linking cannot bypass the shipping workflow.
  time.sleep(1.1);fakeHead=dict(number=t.marker+'-BYPASS',type='出库',subType='其它',status='1',linkNumber=detail(main)['number'],operTime=date.today().isoformat()+' 12:00:00',totalPrice=0,discountLastMoney=0,changeAmount=0,debt=0,discount=0,discountMoney=0,otherMoney=0)
  fakeRow=dict(barCode=codes[0],unit='吨',depotId=14,batchNumber=batchA,operNumber=1,unitPrice=0,allPrice=0,taxRate=0,taxMoney=0,taxLastMoney=0)
  denied(api('/depotHead/addDepotHeadAndDetail',dict(info=json.dumps(fakeHead),rows=json.dumps([fakeRow])),t.seller));check('legacy linked outbound cannot bypass application and unified confirmation')
  denied(act(main,'paid',t.chiefs[0],amount=160,paidDate=date.today().isoformat()));denied(act(main,'paid',amount=160,paidDate=date.today().isoformat()));denied(act(main,'paid',t.chiefs[2],amount=159,paidDate=date.today().isoformat()));denied(act(main,'paid',t.chiefs[2],amount=160,paidDate=(date.today()+timedelta(days=1)).isoformat()));ok(act(main,'paid',t.chiefs[2],amount=160,paidDate=date.today().isoformat()))
  check('only configured finance can confirm full payment; insufficient funds and future dates denied')
  denied(act(main,'cancel',comment=''));ok(act(main,'cancel',comment='Recheck transport'));ok(reserve(main,allocs));ok(act(main,'request'));check('cancel permits allocation review; reapplication resets prior payment confirmation',detail(main)['shipment']['paid_by'] is None)
  denied(act(main,'ship',t.chiefs[0]));check('prepayment gate is enforced before outbound')
  def chunk(kind,data):return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
  image=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',1,1,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(b'\x00\x00\x00\x00'))+chunk(b'IEND',b'')
  p1=upload('one',image);p2=upload('two',image);badPhoto=upload('invalid',b'Not a photo')
  one=truck('TEST-A',[allocation(0,14,batchA,6),allocation(1,14,batchC,1)],[p1,p2]);two=truck('TEST-B',[allocation(0,15,batchB,4),allocation(1,14,batchC,2)],[p2])
  denied(act(main,'trucks',t.chiefs[2],trucks=[one]));forbidden=json.loads(json.dumps(one));forbidden['photos']=['bill/999999999/test.png'];denied(act(main,'trucks',t.chiefs[0],trucks=[forbidden]));forbidden['photos']=['bill/63/../../credentials.png'];denied(act(main,'trucks',t.chiefs[0],trucks=[forbidden]));forbidden['photos']=[badPhoto];denied(act(main,'trucks',t.chiefs[0],trucks=[forbidden]))
  check('photo upload works; packing requires warehouse role and tenant-owned valid images')
  tooMuch=json.loads(json.dumps(two));tooMuch['lines'][0]['quantity']=5;denied(act(main,'trucks',t.chiefs[0],trucks=[one,tooMuch]));wrong=json.loads(json.dumps(two));wrong['lines'][0]['batchNumber']='UNRESERVED';denied(act(main,'trucks',t.chiefs[0],trucks=[one,wrong]));dup=json.loads(json.dumps(two));dup['plate']='TEST-A';denied(act(main,'trucks',t.chiefs[0],trucks=[one,dup]))
  check('per-product per-batch quantities, reserved lots and unique vehicles enforced')
  ok(act(main,'trucks',t.chiefs[0],trucks=[one]));ok(act(main,'paid',t.chiefs[2],amount=160,paidDate=date.today().isoformat()));denied(act(main,'ship',t.chiefs[0]));check('partial vehicle plans may be saved but cannot ship')
  noPhoto=json.loads(json.dumps(two));noPhoto['photos']=[];ok(act(main,'trucks',t.chiefs[0],trucks=[one,noPhoto]));denied(act(main,'ship',t.chiefs[0]));check('every vehicle requires loading photos at final confirmation')
  ok(act(main,'trucks',t.chiefs[0],trucks=[one,two]));before=detail(main)['shipment']['version'];denied(act(main,'unpaid',t.chiefs[2],comment=''));ok(act(main,'unpaid',t.chiefs[2],comment='Receipt under review'));denied(shipping('/'+str(main)+'/action',dict(action='ship',version=before),t.chiefs[0]));denied(act(main,'ship',t.chiefs[0]));ok(act(main,'paid',t.chiefs[2],amount=160,paidDate=date.today().isoformat()))
  check('finance revocation invalidates stale dispatch and immediately blocks shipping')
  wh=detail(main,t.chiefs[0]);check('warehouse views exclude order amounts and financial payloads','total_price' not in wh and 'paid_amount' not in wh['shipment'] and all('payload_json' not in h for h in wh['history']))
  # A real posting failure after reservation consumption must roll the transaction back.
  sql(f"UPDATE jsh_material SET unit='公斤' WHERE tenant_id=63 AND id={t.raw_ids[0]}")
  try:denied(act(main,'ship',t.chiefs[0]))
  finally:sql(f"UPDATE jsh_material SET unit='吨' WHERE tenant_id=63 AND id={t.raw_ids[0]}")
  check('failed outbound restores reservations and state',Decimal(sql(f'SELECT SUM(quantity) FROM jsh_factory_stock_reservation WHERE tenant_id=63 AND head_id={main}'))==13 and detail(main)['shipment']['workflow_status']=='requested' and detail(main)['shipment']['ledger_head_id'] is None)
  current=detail(main)['shipment'];payload=dict(action='ship',version=current['version'])
  with ThreadPoolExecutor(2) as pool:results=list(pool.map(lambda _:shipping('/'+str(main)+'/action',payload,t.chiefs[0]),range(2)))
  check('concurrent unified dispatch commits exactly once',sum(r['code']==200 for r in results)==1 and all(r['code'] in (200,409) for r in results))
  d=detail(main);ledger=d['shipment']['ledger_head_id'];check('one outbound ledger covers all vehicles; own reservations consumed',int(sql(f'SELECT COUNT(*) FROM jsh_depot_item WHERE tenant_id=63 AND header_id={ledger}'))==3 and sql(f'SELECT COUNT(*) FROM jsh_factory_stock_reservation WHERE tenant_id=63 AND head_id={main}')=='0' and Decimal(sql(f'SELECT SUM(quantity) FROM jsh_factory_stock_reservation WHERE tenant_id=63 AND head_id={other}'))==1)
  summary=ok(api('/factorySales/'+str(main),token=t.seller));check('sales sees shipped status and zero false production gap',summary['shipment'][0]['workflow_status']=='shipped' and summary['stock']['missing']==0 and summary['stock']['shipped']==13)
  denied(api('/depotHead/batchSetStatus',dict(ids=str(ledger),status='0'),t.seller));denied(api('/depotHead/delete?id='+str(ledger),token=t.seller,method='DELETE'));denied(act(main,'cancel',comment='Too late'));denied(act(main,'unpaid',t.chiefs[2],comment='Too late'));check('confirmed outbound and payment confirmation cannot be directly reversed')
  # Existing ERP logs prohibit two stock postings by the same user within one second.
  time.sleep(1.1)
  ok(act(other,'request'));credit=truck('TEST-C',[allocation(0,14,batchA,1)],[p1]);ok(act(other,'trucks',t.chiefs[0],trucks=[credit]));ok(act(other,'ship',t.chiefs[0]));check('credit order ships without advance payment and uses its own protected reservation',detail(other)['shipment']['paid_by'] is None)
  sql(f'UPDATE jsh_factory_shipment SET tenant_id=999999999 WHERE tenant_id=63 AND head_id={other}')
  try:denied(shipping('/'+str(other)+'/action',dict(action='cancel',version=1),t.chiefs[0]));check('shipment mutation isolates tenants')
  finally:sql(f'UPDATE jsh_factory_shipment SET tenant_id=63 WHERE tenant_id=999999999 AND head_id={other}')
  if '--returns' in sys.argv:
   from factory_return_checks import verify_returns
   verify_returns(t,main,order,reserve,allocation,codes,batchA,check)
  if '--preview' in sys.argv:print(json.dumps(dict(main=main,credit=other)),flush=True);input('Preview ready; press Enter to clean: ')
  print(json.dumps(dict(passed=passed,count=len(passed)),ensure_ascii=False,indent=2))
 finally:
  if t.ids:
   keys=','.join(map(str,t.ids));ledgers=sql(f'SELECT ledger_head_id FROM jsh_factory_shipment WHERE tenant_id=63 AND head_id IN({keys}) AND ledger_head_id IS NOT NULL').split()
   if ledgers:
    lk=','.join(ledgers);sql(f'DELETE FROM jsh_depot_item WHERE tenant_id=63 AND header_id IN({lk});DELETE FROM jsh_depot_head WHERE tenant_id=63 AND id IN({lk})')
   sql(f'DELETE FROM jsh_factory_shipping_history WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_shipment WHERE tenant_id=63 AND head_id IN({keys})')
  if items:sql('DELETE FROM jsh_factory_batch_quality WHERE tenant_id=63 AND item_id IN('+','.join(map(str,items))+')')
  sql("DELETE FROM jsh_factory_shipping_history WHERE tenant_id=63 AND head_id=0 AND action='configure' AND JSON_EXTRACT(payload_json,'$.financeId')="+str(t.user_ids[2]))
  sql('DELETE FROM jsh_factory_shipping_config WHERE tenant_id=63')
  if old:
   c=json.loads(old);sql(f"INSERT INTO jsh_factory_shipping_config VALUES(63,{int(c['finance_id'])},{quoted(c['updated_at'])})")
  if role:sql(f"DELETE FROM jsh_user_business WHERE tenant_id=63 AND type='RoleFunctions' AND key_id='{role}';DELETE FROM jsh_role WHERE tenant_id=63 AND id={role}")
  root=Path.cwd()/'.quality-local/upload/bill/63'
  for ref in photos:
   target=(Path.cwd()/'.quality-local/upload'/ref).resolve()
   assert root.resolve() in target.parents
   target.unlink(missing_ok=True)

