from pathlib import Path
exec(Path(__file__).with_name('factory_sales_workflow.py').read_text(encoding='utf-8').split("seller=login('jsh')")[0])
from concurrent.futures import ThreadPoolExecutor
f=Path(os.environ.get('ERP_TEST_MYSQL_CONFIG',str(b/'local/stock-test.cnf')));f.write_text('[client]\nuser='+creds['db_user']+'\npassword='+creds['db_password']+'\nhost=127.0.0.1\nport=13306\ndefault-character-set=utf8mb4\n')
cli=next((b/'runtime/mysql').glob('*/bin/mysql.exe'))
def sql(s):
 r=subprocess.run([str(cli),'--defaults-file='+str(f),'-N','-B','jsh_erp'],input=s.encode(),capture_output=True,check=True);return r.stdout.decode().strip()
seller=login('jsh');admin=login('admin');receipt_ids=[];batch='TEST-'+uuid.uuid4().hex[:8];marker='STOCK-TEST-'+uuid.uuid4().hex[:8]
def detail(i):return ok(api('/factoryStock/'+str(i),token=seller))
def save(i,alloc,version=None):return api('/factoryStock/'+str(i)+'/save',{'version':detail(i)['version'] if version is None else version,'confirmed':True,'allocations':alloc},seller)
def alloc(q,depot=14,suffix='P',line=0):return {'lineNo':line,'depotId':depot,'batchNumber':batch+suffix,'quantity':str(q)}
def order(q=10):
 time.sleep(1.1)
 i=ok(api('/factorySales/save',dict(customerId=58,deliveryDate='2026-11-10',remark=marker,requirements='Test',lines=[dict(barCode='FACTORY-DEMO-620',quantity=str(q),price='10')]),seller));ids.append(i)
 blocked(api('/factoryStock/'+str(i),token=seller))
 # Test fixture: do not change the real configured reviewer or any real order.
 sql(f"UPDATE jsh_factory_sales_order SET workflow_status='approved' WHERE head_id={i}; UPDATE jsh_depot_head SET status='1' WHERE id={i}")
 return i

def movement(q,typ='入库',depot=14,suffix='P',quality='passed'):
 time.sleep(1.1)
 number=marker+'-'+uuid.uuid4().hex[:8]
 head=dict(type=typ,subType='其它',number=number,operTime='2026-10-23 12:00:00',status='1',remark=marker,totalPrice=0,changeAmount=0,debt=0,discount=0,discountMoney=0,discountLastMoney=0,otherMoney=0)
 row=dict(barCode='FACTORY-DEMO-620',unit='吨',operNumber=q,depotId=depot,batchNumber=batch+suffix,unitPrice=0,allPrice=0,taxRate=0,taxMoney=0,taxLastMoney=0)
 r=api('/depotHead/addDepotHeadAndDetail',dict(info=json.dumps(head,ensure_ascii=False),rows=json.dumps([row],ensure_ascii=False)),seller)
 if r['code']==200:
  i=int(sql("SELECT id FROM jsh_depot_head WHERE number='"+number+"' AND tenant_id=63"));receipt_ids.append(i)
  if typ=='入库' and quality:
   sql(f"INSERT INTO jsh_factory_batch_quality SELECT id,63,'{quality}',basic_number,'pending',0,'TEST-REPORT','Test report only' FROM jsh_depot_item WHERE header_id={i}")
 r.setdefault('data',None);return r
try:
 blocked(api('/factoryStock/list',token=admin));checks.append('non-business account denied')
 i=order();assert any(x['head_id']==i for x in ok(api('/factoryStock/list',token=seller))['rows']);checks.append('approved orders appear; drafts excluded')
 ok(movement(8));ok(movement(5,depot=15,suffix='B'));ok(movement(3,suffix='F',quality='failed'));ok(movement(2,suffix='U',quality=None))
 ok(movement(5,suffix='H'));sql(f"UPDATE jsh_factory_batch_quality q JOIN jsh_depot_item di ON di.id=q.item_id SET q.qualified_quantity=2 WHERE di.header_id={receipt_ids[-1]} AND q.tenant_id=63")
 ok(movement(4,suffix='R'));sql(f"UPDATE jsh_depot_head SET sub_type='销售退货' WHERE id={receipt_ids[-1]} AND tenant_id=63")
 d=detail(i);assert next(x for x in d['lots'] if x['batchNumber']==batch+'H')['eligible']==2
 assert next(x for x in d['lots'] if x['batchNumber']==batch+'R')['eligible']==0
 blocked(save(i,[alloc(1,suffix='R')]))
 sql(f"UPDATE jsh_factory_batch_quality q JOIN jsh_depot_item di ON di.id=q.item_id SET q.return_released=1 WHERE di.header_id={receipt_ids[-1]} AND q.tenant_id=63")
 assert next(x for x in detail(i)['lots'] if x['batchNumber']==batch+'R')['eligible']==4
 checks.append('partial qualified quantity and return disposition respected')
 d=detail(i);assert any(x['batchNumber']==batch+'P' and x['eligible']==8 and x['hasPendingRelease'] for x in d['lots']),d
 report=next(x for x in d['lots'] if x['batchNumber']==batch+'P')['reports'][0];assert ok(api('/factoryStock/report/'+str(report['id']),token=seller))['report_text']=='Test report only';checks.append('passed pending-release stock and report visible')
 for a in [alloc(1,suffix='F'),alloc(1,suffix='U'),alloc(1,depot=999999),alloc(11),alloc(-1)]:blocked(save(i,[a]))
 checks.append('failed, unregistered, wrong depot and invalid quantities denied')
 version=d['version'];ok(save(i,[alloc(6)]));assert detail(i)['missing']==4
 sd=ok(api('/factorySales/'+str(i),token=seller));assert sd['stock']['missing']==4;blocked(save(i,[alloc(5)],version));checks.append('confirmed reservation visible to sales; stale writes denied')
 ok(save(i,[alloc(6),alloc(4,depot=15,suffix='B')]));assert detail(i)['stockState']=='ready';checks.append('multi-warehouse lots meet full order demand')
 blocked(movement(3,typ='出库'));assert next(x for x in detail(i)['lots'] if x['batchNumber']==batch+'P')['physical']==8
 ok(movement(1,typ='出库'));checks.append('legacy stock mutation cannot consume reserved inventory; unreserved stock allowed')
 ok(api('/factoryStock/'+str(i)+'/release',{'version':detail(i)['version']},seller));assert detail(i)['reserved']==0 and len(detail(i)['history'])>=3;checks.append('manual adjustment, release and audit trail')
 j=order();k=order();
 with ThreadPoolExecutor(2) as pool:results=list(pool.map(lambda h:save(h,[alloc(6)]),[j,k]))
 assert sum(r['code']==200 for r in results)==1 and all(r['code'] in (200,409) for r in results),results;checks.append('concurrent orders cannot over-reserve same lot')
 winner=[j,k][next(n for n,r in enumerate(results) if r['code']==200)]
 sd=ok(api('/factorySales/'+str(winner),token=seller));ok(api('/factorySales/'+str(winner)+'/action',{'action':'withdraw','version':sd['version']},seller));assert ok(api('/factorySales/'+str(winner),token=seller))['stock']['reserved']==0;blocked(api('/factoryStock/'+str(winner),token=seller));checks.append('sales withdrawal automatically releases stock')
 result={'passed':checks};(b/'stock-test-result.json').write_text(json.dumps(result,ensure_ascii=False,indent=2));print(json.dumps(result,ensure_ascii=False,indent=2))
finally:
 if ids:
  keys=','.join(str(int(x)) for x in ids)
  sql(f"DELETE FROM jsh_factory_stock_reservation WHERE head_id IN ({keys}) AND tenant_id=63; DELETE FROM jsh_factory_stock_check WHERE head_id IN ({keys}) AND tenant_id=63; DELETE FROM jsh_factory_stock_history WHERE head_id IN ({keys}) AND tenant_id=63; DELETE FROM jsh_factory_sales_history WHERE head_id IN ({keys}) AND tenant_id=63; DELETE FROM jsh_factory_sales_order WHERE head_id IN ({keys}) AND tenant_id=63; DELETE FROM jsh_depot_item WHERE header_id IN ({keys}) AND tenant_id=63; DELETE FROM jsh_depot_head WHERE id IN ({keys}) AND tenant_id=63 AND remark='{marker}'")
 if receipt_ids:
  keys=','.join(str(int(x)) for x in receipt_ids)
  sql(f"DELETE q FROM jsh_factory_batch_quality q JOIN jsh_depot_item di ON q.item_id=di.id WHERE di.header_id IN ({keys}) AND q.tenant_id=63; DELETE FROM jsh_depot_item WHERE header_id IN ({keys}) AND tenant_id=63; DELETE FROM jsh_depot_head WHERE id IN ({keys}) AND tenant_id=63 AND remark='{marker}'")
 # Restore the original derived stock cache after deleting only this test's ledger rows.
 api('/material/batchSetMaterialCurrentStock',{'ids':'620'},seller)
 for token in [seller,admin]:api('/user/logout',token=token)
 f.unlink(missing_ok=True)



