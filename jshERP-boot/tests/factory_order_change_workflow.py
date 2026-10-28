"""Production order change / cancellation against disposable local ERP fixtures."""
from factory_workshop_helpers import *
from datetime import date
import sys
checks=[]
def check(name,b=True):
 assert b,name
 checks.append(name)
def quoted(v):return "'"+str(v).replace('\\','\\\\').replace("'","''")+"'"
with WorkshopFixture() as t:
 old=sql('SELECT leader_ids FROM jsh_factory_change_config WHERE tenant_id=63');change_ids=[];head=None;quality_heads=[];release_audit=None
 old_quality=sql("SELECT JSON_OBJECT('director_id',director_id,'inspectors_json',inspectors_json,'updated_at',DATE_FORMAT(updated_at,'%Y-%m-%d %H:%i:%s')) FROM jsh_factory_quality_config WHERE tenant_id=63")
 old_release=sql("SELECT JSON_OBJECT('ids',leader_ids_json,'updated_at',DATE_FORMAT(updated_at,'%Y-%m-%d %H:%i:%s')) FROM jsh_factory_release_config WHERE tenant_id=63")
 old_standards=sql("SELECT JSON_OBJECT('inspection_kind',inspection_kind,'stage_no',stage_no,'version',version,'forms_json',forms_json,'template_id',template_id,'updated_by',updated_by,'updated_at',DATE_FORMAT(updated_at,'%Y-%m-%d %H:%i:%s')) FROM jsh_factory_quality_standard WHERE tenant_id=63 AND bar_code='FACTORY-DEMO-620' AND stage_no IN(0,1)").splitlines()
 def c(path,body=None,token=None):return api('/factoryOrderChanges'+path,body,token or t.seller)
 def source():return ok(c('/source/'+str(head)))
 def detail(i):return ok(c('/'+str(i)))
 def create(kind='change',token=None,**kw):
  s=source();body=dict(headId=head,orderVersion=s['orderVersion'],kind=kind,reason='Customer changed demand',deliveryDate='2026-12-01',requirements='Updated packaging',lines=[dict(lineNo=0,quantity=4)]);body.update(kw);return c('/create',body,token)
 def keep(r):i=ok(r);change_ids.append(i);return i
 def action(i,a,token=None,**kw):
  d=detail(i);body=dict(action=a,version=d['version'],orderVersion=d['source']['orderVersion'],taskVersion=d['source']['taskVersion'],comment='Coordinator adjustment',plan=[dict(quantity=p['quantity']) for p in d['source']['plan']]);body.update(kw);return c('/'+str(i)+'/action',body,token)
 def report(q=1,batch=None):return t.prod('/'+str(head)+'/execution',dict(action='report',version=t.detail(head)['version'],lineNo=0,stageNo=1,workshopNo=1,reportDate=date.today().isoformat(),batchNumber=batch or t.marker+'-'+uuid.uuid4().hex[:6],inputQuantity=q,outputQuantity=q,lossQuantity=0),t.chiefs[0])
 def mat(path,body=None,token=None):return api('/factoryMaterial'+path,body,token or t.chiefs[0])
 def ma(i,a,token=None):return mat('/'+str(i)+'/action',dict(action=a,version=ok(mat('/'+str(i)))['version'],comment='Test material return'),token)
 try:
  denied(c('/options',token=t.admin));denied(c('/config',dict(leaderIds=[t.user_ids[1]]),t.chiefs[0]));denied(c('/config',dict(leaderIds=[])));denied(c('/config',dict(leaderIds=[999999999])));ok(c('/config',dict(leaderIds=[t.user_ids[1],t.user_ids[2]])));check('owner-only valid multiple leader configuration')
  head=t.order();t.approved(head);ok(t.distribute(head,[dict(lineNo=0,stageNo=1,workshopNo=1,quantity=10)]));ok(t.accept(head,1));ok(t.plan(head,1))
  ok(t.prod('/'+str(head)+'/execution',dict(action='start',version=t.detail(head)['version'],lineNo=0,stageNo=1,workshopNo=1,actualStart=date.today().isoformat()+'T00:00',materialsReady=True),t.chiefs[0]));ok(report(2));original_reports=t.detail(head)['reports']
  denied(create(token=t.chiefs[1]));denied(create(reason=''));denied(create(lines=[dict(lineNo=0,quantity=-1)]));denied(create(lines=[dict(lineNo=0,quantity=0)]));s=source();denied(create(deliveryDate=s['order']['deliveryDate'],requirements=s['order']['requirements'],lines=[dict(lineNo=0,quantity=10)]));check('only original sales may request; reason, quantity and actual changes required')
  # A shipment in either active state must be handled first; this fixture has no stock posting.
  sql(f"INSERT INTO jsh_factory_shipment(head_id,tenant_id,workflow_status,trucks_json,requested_by,requested_at) VALUES({head},63,'requested','[]',63,NOW())")
  try:
   denied(create());sql(f"UPDATE jsh_factory_shipment SET workflow_status='shipped' WHERE tenant_id=63 AND head_id={head}");denied(create())
  finally:sql(f'DELETE FROM jsh_factory_shipment WHERE tenant_id=63 AND head_id={head}')
  check('active shipping and already shipped orders cannot change or cancel')
  first=keep(create());denied(create());ok(report(1));check('one active change per order; pending approval leaves original production running',source()['order']['lines'][0]['quantity']==10)
  denied(action(first,'approve',t.chiefs[0]));denied(action(first,'reject',t.chiefs[1],comment=''));ok(action(first,'reject',t.chiefs[1],comment='Please revise'));second=keep(create());ok(action(second,'withdraw',comment='Sales correction'));check('leader rejection and sales withdrawal release active application slot')
  # Issue materials before cancellation, so the final check proves a real return remains possible.
  raw=t.seed_raw('吨',t.marker+'-RAW');issue_body=dict(taskId=head,kind='issue',lineNo=0,stageNo=1,workshopNo=1,reason='',lines=[dict(barCode=raw,depotId=14,batchNumber=t.marker+'-RAW',quantity=2)])
  issued=ok(mat('/save',issue_body));ok(ma(issued,'submit'));time.sleep(1.1);ok(ma(issued,'confirm',t.seller))
  change=keep(create());ok(action(change,'approve',t.chiefs[2]));denied(action(change,'approve',t.chiefs[1]));denied(report());denied(mat('/save',issue_body));denied(action(change,'apply',t.chiefs[1]));check('any one leader approves; new production and material issue wait for coordinator')
  denied(action(change,'apply',plan=[dict(quantity=2)]));check('coordinator cannot erase already produced output',source()['order']['lines'][0]['quantity']==10 and source()['plan'][0]['quantity']==10)
  denied(action(change,'apply',taskVersion=1));denied(action(change,'apply',comment=''));check('latest progress versions and coordinator explanation are required')
  ok(action(change,'apply',plan=[dict(quantity=5,workshopNo=3)]));sales=ok(api('/factorySales/'+str(head),token=t.seller));now=t.detail(head)
  check('apply atomically changes demand, delivery, requirements and server-priced amounts',sales['lines'][0]['quantity']==4 and sales['lines'][0]['price']==10 and sales['total_price']==40 and str(sales['delivery_date']).startswith('2026-12-01') and sales['requirements']=='Updated packaging')
  check('plan changes preserve topology, starts and all historical reports',now['routes'][0]['workshopNo']==1 and now['routes'][0]['quantity']==5 and now['plan'][0]['quantity']==5 and len(now['reports'])==2 and len(now['starts'])==1 and any(r['id']==original_reports[0]['id'] for r in now['reports']))
  check('source ledger quantities match demand; reservations and old stock check released',Decimal(sql(f'SELECT oper_number FROM jsh_depot_item WHERE tenant_id=63 AND header_id={head}'))==4 and sql(f'SELECT COUNT(*) FROM jsh_factory_stock_check WHERE tenant_id=63 AND head_id={head}')=='0')
  denied(action(change,'apply'));ok(report(2));denied(report(1));check('applied change cannot replay and production follows the adjusted cumulative quota')
  cancel=keep(create('cancel'));ok(action(cancel,'approve',t.chiefs[1]));payload=dict(action='apply',version=detail(cancel)['version'],orderVersion=source()['orderVersion'],taskVersion=source()['taskVersion'],comment='Stop production, keep historical inventory')
  with ThreadPoolExecutor(2) as pool:results=list(pool.map(lambda _:c('/'+str(cancel)+'/action',payload),range(2)))
  check('concurrent cancellation applies exactly once',sum(r['code']==200 for r in results)==1 and all(r['code'] in (200,409) for r in results))
  sales=ok(api('/factorySales/'+str(head),token=t.seller));denied(report());denied(mat('/save',issue_body));denied(create());check('cancelled order stops new production, issues and further applications but preserves quantities',sales['workflow_status']=='cancelled' and sales['lines'][0]['quantity']==4 and len(t.detail(head)['reports'])==3)
  retbody=dict(issue_body,kind='return',referenceId=issued,reason='Unused material after stopping',lines=[dict(barCode=raw,depotId=14,batchNumber=t.marker+'-RAW',quantity=1,referenceLine=0)])
  returned=ok(mat('/save',retbody));ok(ma(returned,'submit'));time.sleep(1.1);ok(ma(returned,'confirm',t.seller));check('stopped order can still return actual issued materials')
  def q(path,body=None,token=None):
   result=api('/factoryQuality'+path,body,token or t.seller)
   if result['code']!=200:print('Quality request failed:',path,result,flush=True)
   return result
  ok(q('/config',dict(directorId=131,inspectorIds=[t.user_ids[2]])));ok(q('/leaders',dict(leaderIds=[131])));release_audit=sql("SELECT MAX(id) FROM jsh_factory_quality_history WHERE tenant_id=63 AND action='release_config'")
  standard=next((s for s in ok(q('/standards')) if s['bar_code']=='FACTORY-DEMO-620' and s['stage_no']==1),{})
  finished_standard=next((s for s in ok(q('/standards')) if s['bar_code']=='FACTORY-DEMO-620' and s['inspection_kind']=='finished'),{})
  ok(q('/standards',dict(barCode='FACTORY-DEMO-620',stageNo=0,inspectionKind='finished',version=finished_standard.get('version'),forms=[dict(name=t.marker,items=[dict(name='Sample',unit='%',min=0,max=10)])])))
  ok(q('/standards',dict(barCode='FACTORY-DEMO-620',stageNo=1,version=standard.get('version'),forms=[dict(name=t.marker,items=[dict(name='Sample',unit='%',min=0,max=10)])])))
  batch=original_reports[0]['batch_number'];inspection=ok(q('/request',dict(headId=head,lineNo=0,stageNo=1,workshopNo=1,batchNumber=batch,finished=True),t.chiefs[0]))
  def qa(a,token=None,**kw):return q('/'+str(inspection)+'/action',dict(action=a,version=ok(q('/'+str(inspection)))['version'],**kw),token)
  ok(qa('form',t.chiefs[2],formIndex=0,values=[dict(value=5)]));ok(qa('submit',t.chiefs[2]));ok(qa('approve',t.leader,qualifiedQuantity=2,comment='Historical output qualified'))
  def finished():return ok(q('/task/'+str(head)+'?finished=true'))['finishedBatches'][0]
  # Original ERP throttles repeated stock postings by the same user within one second.
  time.sleep(1.1)
  f=finished();ok(q('/finished/'+str(f['id'])+'/action',dict(action='receive',version=f['version'],depotId=14)));quality_heads.append(int(sql(f"SELECT ledger_head_id FROM jsh_factory_finished_batch WHERE tenant_id=63 AND id={f['id']}")));f=finished();ok(q('/finished/'+str(f['id'])+'/action',dict(action='release',version=f['version']),t.leader))
  other_order=t.order();stock_detail=ok(api('/factoryStock/'+str(other_order),token=t.seller));ok(api('/factoryStock/'+str(other_order)+'/save',dict(version=stock_detail['version'],confirmed=True,allocations=[dict(lineNo=0,depotId=14,batchNumber=batch,quantity=2)]),t.seller));check('cancelled-order historical output can finish QC, enter stock and supply another order')
  h=detail(change)['history'];record=json.loads(next(r['payload_json'] for r in h if r['action']=='apply'))['productionAdjustment'];check('before and after order and plan contents, actors and timestamps retained',detail(change)['before']['lines'][0]['quantity']==10 and detail(change)['after']['lines'][0]['quantity']==4 and record['beforePlan'][0]['quantity']==10 and record['afterPlan'][0]['quantity']==5 and any(r['actor_name'] for r in h))
  sql(f'UPDATE jsh_factory_order_change SET tenant_id=999999999 WHERE tenant_id=63 AND id={change}')
  try:denied(c('/'+str(change)));check('change requests isolate tenant data')
  finally:sql(f'UPDATE jsh_factory_order_change SET tenant_id=63 WHERE tenant_id=999999999 AND id={change}')
  if '--preview' in sys.argv:print(json.dumps(dict(headId=head,changeId=change,cancelId=cancel)),flush=True);input('Preview ready; press Enter to clean: ')
  print(json.dumps(dict(passed=checks,count=len(checks)),ensure_ascii=False,indent=2))
 finally:
  if head:
   sql(f'DELETE h FROM jsh_factory_quality_history h JOIN jsh_factory_inspection i ON i.id=h.inspection_id AND i.tenant_id=h.tenant_id WHERE i.tenant_id=63 AND i.head_id={head};DELETE FROM jsh_factory_quality_transfer WHERE tenant_id=63 AND head_id={head};DELETE FROM jsh_factory_finished_batch WHERE tenant_id=63 AND head_id={head};DELETE FROM jsh_factory_inspection WHERE tenant_id=63 AND head_id={head}')
  if quality_heads:
   keys=','.join(map(str,quality_heads));sql(f'DELETE q FROM jsh_factory_batch_quality q JOIN jsh_depot_item di ON di.id=q.item_id AND di.tenant_id=q.tenant_id WHERE di.tenant_id=63 AND di.header_id IN({keys})');sql(f'DELETE FROM jsh_depot_item WHERE tenant_id=63 AND header_id IN({keys});DELETE FROM jsh_depot_head WHERE tenant_id=63 AND id IN({keys})');sql('DELETE FROM jsh_factory_stock_reservation WHERE tenant_id=63 AND head_id IN('+','.join(map(str,t.ids))+')');api('/material/batchSetMaterialCurrentStock',dict(ids='620'),t.seller)
  sql("DELETE FROM jsh_factory_quality_history WHERE tenant_id=63 AND inspection_id IS NULL AND (payload_json LIKE '%"+t.marker+"%' OR JSON_EXTRACT(payload_json,'$.inspectorIds[0]')="+str(t.user_ids[2])+")")
  # Restore the non-test configuration and standard after the cancellation/QC scenario.
  sql("DELETE FROM jsh_factory_quality_standard WHERE tenant_id=63 AND bar_code='FACTORY-DEMO-620' AND stage_no IN(0,1)")
  for value in old_standards:
   s=json.loads(value);sql("INSERT INTO jsh_factory_quality_standard(tenant_id,bar_code,stage_no,version,forms_json,updated_by,updated_at,template_id,inspection_kind) VALUES(63,'FACTORY-DEMO-620',"+str(s['stage_no'])+','+str(s['version'])+','+quoted(s['forms_json'])+','+str(s['updated_by'])+','+quoted(s['updated_at'])+','+(str(s['template_id']) if s['template_id'] is not None else 'NULL')+','+quoted(s['inspection_kind'])+')')
  sql('DELETE FROM jsh_factory_quality_config WHERE tenant_id=63;DELETE FROM jsh_factory_release_config WHERE tenant_id=63')
  if old_quality:
   v=json.loads(old_quality);sql('INSERT INTO jsh_factory_quality_config VALUES(63,'+str(v['director_id'])+','+quoted(v['inspectors_json'])+','+quoted(v['updated_at'])+')')
  if old_release:
   v=json.loads(old_release);sql('INSERT INTO jsh_factory_release_config VALUES(63,'+quoted(v['ids'])+','+quoted(v['updated_at'])+')')
  if release_audit:sql('DELETE FROM jsh_factory_quality_history WHERE tenant_id=63 AND id='+release_audit)
  if change_ids:
   keys=','.join(map(str,change_ids));sql(f'DELETE FROM jsh_factory_order_change_history WHERE tenant_id=63 AND change_id IN({keys});DELETE FROM jsh_factory_order_change WHERE tenant_id=63 AND id IN({keys})')
  if head:sql(f'DELETE FROM jsh_factory_production_report WHERE tenant_id=63 AND head_id={head};DELETE FROM jsh_factory_production_start WHERE tenant_id=63 AND head_id={head}')
  sql('DELETE FROM jsh_factory_change_config WHERE tenant_id=63')
  if old:sql('INSERT INTO jsh_factory_change_config VALUES(63,'+quoted(old)+')')
  sql("DELETE FROM jsh_factory_order_change_history WHERE tenant_id=63 AND change_id=0 AND payload_json="+quoted(json.dumps([t.user_ids[1],t.user_ids[2]],separators=(',',':'))))
