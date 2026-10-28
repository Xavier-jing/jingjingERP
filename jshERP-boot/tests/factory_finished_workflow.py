"""Final sampling, whole-batch receipts and release against the local test tenant."""
from datetime import date,timedelta
from factory_workshop_helpers import *
import sys

checks=[]
def check(name,valid=True):
 assert valid,name
 checks.append(name)
def quoted(v):return "'"+str(v).replace('\\','\\\\').replace("'","''")+"'"

with WorkshopFixture() as t:
 old_quality=sql("SELECT JSON_OBJECT('director_id',director_id,'inspectors_json',inspectors_json,'updated_at',DATE_FORMAT(updated_at,'%Y-%m-%d %H:%i:%s')) FROM jsh_factory_quality_config WHERE tenant_id=63")
 old_release=sql("SELECT JSON_OBJECT('ids',leader_ids_json,'updated_at',DATE_FORMAT(updated_at,'%Y-%m-%d %H:%i:%s')) FROM jsh_factory_release_config WHERE tenant_id=63")
 posted=[];code='FINALTEST-'+uuid.uuid4().hex[:12]
 def q(path,body=None,token=None):return api('/factoryQuality'+path,body,token or t.seller)
 def detail(i):return ok(q('/'+str(i)))
 def qa(i,action,token=None,**body):return q('/'+str(i)+'/action',dict(version=detail(i)['version'],action=action,**body),token)
 def task(head):return ok(q('/task/'+str(head)+'?finished=true'))
 def batch(head):return task(head)['finishedBatches'][0]
 def fa(head,action,token=None,**body):
  r=batch(head);return q('/finished/'+str(r['id'])+'/action',dict(version=r['version'],action=action,**body),token)
 def order():
  time.sleep(1.1);head=ok(api('/factorySales/save',dict(customerId=58,deliveryDate='2026-11-20',remark=t.marker,lines=[dict(barCode=code,quantity=10,price=10)]),t.seller));t.ids.append(head)
  sql(f"UPDATE jsh_factory_sales_order SET workflow_status='approved' WHERE tenant_id=63 AND head_id={head};UPDATE jsh_depot_head SET status='1' WHERE tenant_id=63 AND id={head}")
  t.warehouse(head);return head
 def record(head,w,qty,day=None,start=False,**changes):
  day=day or date.today().isoformat();body=dict(version=t.detail(head)['version'],action='start' if start else 'report',lineNo=0,stageNo=1,workshopNo=w,actualStart=(date.today()-timedelta(days=1)).isoformat()+'T00:00',materialsReady=True,reportDate=day,batchNumber=t.marker,inputQuantity=qty,outputQuantity=qty,lossQuantity=0)
  body.update(changes);return t.prod('/'+str(head)+'/execution',body,t.chiefs[w-1])
 def send(head,parent=None,token=None,**changes):
  body=dict(headId=head,lineNo=0,stageNo=1,workshopNo=1,batchNumber=t.marker,quantity=1,finished=True,parentId=parent,comment='Adjusted whole batch' if parent else '')
  body.update(changes);return q('/request',body,token or t.chiefs[0])
 def fill(i,value):
  ok(qa(i,'form',t.chiefs[2],formIndex=0,values=[dict(value=value)],comment='Final sample'))
  ok(qa(i,'submit',t.chiefs[2]))
 def movement(qty):
  time.sleep(1.1);number=t.marker+'-OUT-'+uuid.uuid4().hex[:6]
  head=dict(number=number,type='出库',subType='其它',status='1',operTime=date.today().isoformat()+' 12:00:00',remark=t.marker,totalPrice=0,discountLastMoney=0,changeAmount=0,debt=0,discount=0,discountMoney=0,otherMoney=0)
  row=dict(barCode=code,unit='吨',depotId=14,batchNumber=t.marker,operNumber=qty,unitPrice=0,allPrice=0,taxRate=0,taxMoney=0,taxLastMoney=0)
  result=api('/depotHead/addDepotHeadAndDetail',dict(info=json.dumps(head,ensure_ascii=False),rows=json.dumps([row],ensure_ascii=False)),t.seller)
  if result['code']==200:posted.append(int(sql("SELECT id FROM jsh_depot_head WHERE tenant_id=63 AND number="+quoted(number))))
  result.setdefault('data',None);return result
 try:
  sql("INSERT INTO jsh_material(name,unit,enabled,tenant_id,delete_flag,enable_serial_number,enable_batch_number,brand,standard,model) VALUES("+quoted(t.marker)+",'吨',1,63,'0','0','1','TEST','Test standard','Test model')")
  material=int(sql("SELECT id FROM jsh_material WHERE tenant_id=63 AND name="+quoted(t.marker)));t.raw_ids.append(material)
  sql(f"INSERT INTO jsh_material_extend(material_id,bar_code,commodity_unit,default_flag,tenant_id,delete_flag) VALUES({material},'{code}','吨','1',63,'0')")
  ok(q('/config',dict(directorId=131,inspectorIds=[t.user_ids[2]])))
  denied(q('/leaders',dict(leaderIds=[131]),t.chiefs[0]));denied(q('/leaders',dict(leaderIds=[])));ok(q('/leaders',dict(leaderIds=[131,t.user_ids[1]])))
  check('release configuration limited to owner; multiple leaders supported')
  ok(q('/standards',dict(barCode=code,stageNo=0,inspectionKind='finished',forms=[dict(name=t.marker,items=[dict(name='Final moisture',unit='%',min=5,max=8)])])))
  head=order();t.approved(head);ok(t.distribute(head,[dict(lineNo=0,stageNo=1,workshopNo=1,quantity=6),dict(lineNo=0,stageNo=1,workshopNo=2,quantity=4)]))
  for w in (1,2):ok(t.accept(head,w));ok(t.plan(head,w));ok(record(head,w,1,start=True))
  denied(send(head));ok(record(head,1,4,day=(date.today()-timedelta(days=1)).isoformat()));ok(record(head,1,2));ok(record(head,2,4))
  denied(send(head,token=t.seller));denied(send(head,stageNo=2));inspection=ok(send(head))
  check('whole batch aggregates multiple days and parallel final workshops; supplied partial quantity ignored',detail(inspection)['quantity']==10)
  denied(send(head));denied(send(head,workshopNo=2,token=t.chiefs[1]));locked=denied(record(head,1,1,batchNumber=t.marker));assert '最终送检' in json.dumps(locked,ensure_ascii=False),locked
  check('single final inspection freezes final output and prevents duplicate batches')
  denied(fa(head,'receive',depotId=14));fill(inspection,9);denied(qa(inspection,'approve',t.leader,qualifiedQuantity=5,comment='Partial not allowed'));ok(qa(inspection,'approve',t.leader,qualifiedQuantity=0,comment='Whole batch adjust and retest'))
  denied(fa(head,'receive',depotId=14));check('final sampling rejects partial verdict; failed batch cannot enter warehouse')
  denied(send(head,parent=inspection,finished=False));retry=ok(send(head,parent=inspection));denied(send(head,parent=inspection));fill(retry,7);ok(qa(retry,'approve',t.leader,qualifiedQuantity=10,comment='Whole batch qualified'))
  check('whole-batch reinspection retains failed results and fixes quantity',detail(retry)['quantity']==10 and detail(retry)['parent_id']==inspection and detail(inspection)['forms'][0]['items'][0]['value']==9)
  denied(fa(head,'release',t.leader));denied(fa(head,'receive',t.chiefs[0],depotId=14));denied(fa(head,'receive',depotId=999999));denied(qa(retry,'transfer',t.chiefs[0],stageNo=2,workshopNo=2,quantity=10))
  check('warehouse permission, depot access and final-vs-semi boundaries')
  r=batch(head);payload=dict(version=r['version'],action='receive',depotId=14,quantity=1)
  with ThreadPoolExecutor(2) as pool:results=list(pool.map(lambda _:q('/finished/'+str(r['id'])+'/action',payload),range(2)))
  check('concurrent whole-batch receipt creates exactly one ledger',sum(x['code']==200 for x in results)==1 and all(x['code'] in (200,409) for x in results))
  r=batch(head);ledger=int(r['ledger_head_id']);qty=sql(f'SELECT basic_number FROM jsh_depot_item WHERE tenant_id=63 AND header_id={ledger}')
  check('receipt always uses whole quantity',Decimal(qty)==10)
  denied(api('/depotHead/batchSetStatus',dict(ids=str(ledger),status='0'),t.seller));denied(api('/depotHead/delete?id='+str(ledger),token=t.seller,method='DELETE'));check('legacy edit/delete/unaudit cannot alter managed receipt')
  stock=ok(api('/factoryStock/'+str(head),token=t.seller));lot=next(x for x in stock['lots'] if x['batchNumber']==t.marker)
  check('qualified pending-release stock is eligible for reservation',lot['eligible']==10 and lot['hasPendingRelease'])
  ok(api('/factoryStock/'+str(head)+'/save',dict(version=stock['version'],confirmed=True,allocations=[dict(lineNo=0,depotId=14,batchNumber=t.marker,quantity=10)]),t.seller))
  item=int(sql(f'SELECT id FROM jsh_depot_item WHERE tenant_id=63 AND header_id={ledger}'))
  check('warehouse can read final summary', 'Final moisture' in ok(api('/factoryStock/report/'+str(item),token=t.seller))['report_text'])
  denied(movement(1));check('pending-release stock blocked through legacy outbound endpoint')
  denied(fa(head,'hold',t.leader,comment=''));ok(fa(head,'hold',t.leader,comment='Hold for review'));denied(fa(head,'release',t.chiefs[1]));denied(movement(1))
  check('leader refusal requires opinion and keeps full batch frozen')
  denied(fa(head,'resubmit',comment='Reviewed'));ok(fa(head,'resubmit',t.chiefs[0],comment='Handling completed, request review'))
  r=batch(head);payload=dict(version=r['version'],action='release',comment='Approve whole batch',quantity=1)
  with ThreadPoolExecutor(2) as pool:results=list(pool.map(lambda token:q('/finished/'+str(r['id'])+'/action',payload,token),[t.leader,t.chiefs[1]]))
  r=batch(head);check('either configured leader can release; concurrent approvals commit once',sum(x['code']==200 for x in results)==1 and r['release_state']=='released' and r['released_by'] in (131,t.user_ids[1]))
  denied(movement(1));stock=ok(api('/factoryStock/'+str(head),token=t.seller));ok(api('/factoryStock/'+str(head)+'/release',dict(version=stock['version']),t.seller));denied(movement(-1));ok(movement(1));denied(movement(10))
  check('released goods still respect reservations and whole-batch outbound quantity')
  history=detail(retry)['history'];check('receipt, refusal, handling and actual approval are audited',all(any(h['action']==a for h in history) for a in ['finished_receive','finished_hold','finished_resubmit','finished_release']))
  bid=r['id'];sql(f'UPDATE jsh_factory_finished_batch SET tenant_id=999999999 WHERE id={bid} AND tenant_id=63')
  try:denied(q('/finished/'+str(bid)+'/action',dict(version=r['version'],action='release'),t.leader));check('finished batch actions isolate tenants')
  finally:sql(f'UPDATE jsh_factory_finished_batch SET tenant_id=63 WHERE id={bid} AND tenant_id=999999999')
  if '--preview' in sys.argv:
   print(json.dumps(dict(head=head,inspectionId=retry,batchId=bid)),flush=True);input('Preview ready; press Enter to clean: ')
  print(json.dumps(dict(passed=checks,count=len(checks)),ensure_ascii=False,indent=2))
 finally:
  if t.ids:
   keys=','.join(map(str,t.ids));ledgers=sql(f'SELECT ledger_head_id FROM jsh_factory_finished_batch WHERE tenant_id=63 AND head_id IN({keys}) AND ledger_head_id IS NOT NULL').split();all_ledger=ledgers+list(map(str,posted))
   if all_ledger:
    lk=','.join(all_ledger);sql(f'DELETE q FROM jsh_factory_batch_quality q JOIN jsh_depot_item di ON di.id=q.item_id AND di.tenant_id=q.tenant_id WHERE q.tenant_id=63 AND di.header_id IN({lk});DELETE FROM jsh_depot_item WHERE tenant_id=63 AND header_id IN({lk});DELETE FROM jsh_depot_head WHERE tenant_id=63 AND id IN({lk})')
   sql(f'DELETE h FROM jsh_factory_quality_history h JOIN jsh_factory_inspection i ON i.id=h.inspection_id AND i.tenant_id=h.tenant_id WHERE i.tenant_id=63 AND i.head_id IN({keys});DELETE FROM jsh_factory_finished_batch WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_inspection WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_production_report WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_production_start WHERE tenant_id=63 AND head_id IN({keys})')
  sql("DELETE FROM jsh_factory_quality_standard WHERE tenant_id=63 AND bar_code="+quoted(code))
  sql("DELETE FROM jsh_factory_quality_history WHERE tenant_id=63 AND inspection_id IS NULL AND ((action='standard' AND JSON_UNQUOTE(JSON_EXTRACT(payload_json,'$.barCode'))="+quoted(code)+") OR (action='configure' AND JSON_CONTAINS(payload_json,'"+str(t.user_ids[2])+"','$.inspectorIds')) OR (action='release_config' AND JSON_CONTAINS(payload_json,'"+str(t.user_ids[1])+"','$.leaderIds')))")
  sql('DELETE FROM jsh_factory_quality_config WHERE tenant_id=63;DELETE FROM jsh_factory_release_config WHERE tenant_id=63')
  if old_quality:
   c=json.loads(old_quality);sql(f"INSERT INTO jsh_factory_quality_config VALUES(63,{int(c['director_id'])},{quoted(c['inspectors_json'])},{quoted(c['updated_at'])})")
  if old_release:
   c=json.loads(old_release);sql(f"INSERT INTO jsh_factory_release_config VALUES(63,{quoted(c['ids'])},{quoted(c['updated_at'])})")
