"""Customer return scenarios reuse the disposable, fully shipped fixtures.
Run: factory_shipping_workflow.py --returns (optionally --preview for UI QA).
"""
from factory_workshop_helpers import *
import sys

def verify_returns(t,main,order,reserve,allocation,codes,batch,check):
 old=sql('SELECT leader_ids FROM jsh_factory_return_config WHERE tenant_id=63');ids=[];ledgers=[]
 def quoted(s):return "'"+str(s).replace('\\','\\\\').replace("'","''")+"'"
 def ret(path,body=None,token=None):return api('/factoryReturns'+path,body,token or t.seller)
 def detail(i):return ok(ret('/'+str(i)))
 def action(i,a,token=None,**body):return ret('/'+str(i)+'/action',dict(action=a,version=detail(i)['version'],**body),token)
 def create(q,source=main,token=None):return ret('/create',dict(sourceHeadId=source,reason='Customer test return',lines=[dict(sourceItemId=item,quantity=q)]),token)
 def remember(r):i=ok(r);ids.append(i);return i
 try:
  denied(ret('/options',token=t.admin));denied(ret('/config',dict(leaderIds=[t.user_ids[1]]),t.chiefs[0]));denied(ret('/config',dict(leaderIds=[])));denied(ret('/config',dict(leaderIds=[999999999])))
  ok(ret('/config',dict(leaderIds=[t.user_ids[1],t.user_ids[2]])));check('returns: leader configuration requires owner and valid tenant accounts')
  source=ok(ret('/source/'+str(main)));item=next(l['sourceItemId'] for l in source['lines'] if l['batchNumber']==batch)
  denied(create(1,token=t.chiefs[0]));denied(create(7));denied(create(0));denied(ret('/create',dict(sourceHeadId=main,reason='',lines=[dict(sourceItemId=item,quantity=1)])))
  denied(ret('/create',dict(sourceHeadId=main,reason='bad source',lines=[dict(sourceItemId=999999999,quantity=1)])));check('returns: only original sales may request positive quantities within shipped source items')
  # Mark the original fixture lot as a managed final batch to exercise its net outbound cap.
  sql(f"INSERT INTO jsh_factory_finished_batch(tenant_id,head_id,line_no,stage_no,material_id,bar_code,batch_number,quantity,root_inspection_id,inspection_id,depot_id,ledger_head_id,release_state) VALUES(63,{main},0,1,{t.raw_ids[0]},'{codes[0]}',{quoted(batch)},7,0,0,14,{t.receipts[0]},'released')")
  r=remember(create(2));denied(action(r,'approve',t.chiefs[0]));denied(action(r,'receive',t.chiefs[0],depotId=15));ok(action(r,'approve',t.chiefs[2]));denied(action(r,'approve',t.chiefs[1]));check('returns: any one configured leader approves; warehouse cannot approve or receive early')
  denied(action(r,'receive',t.chiefs[1],depotId=15));denied(action(r,'receive',t.chiefs[0],depotId=999999999))
  sql(f"UPDATE jsh_material SET unit='公斤' WHERE tenant_id=63 AND id={t.raw_ids[0]}")
  try:denied(action(r,'receive',t.chiefs[0],depotId=15))
  finally:sql(f"UPDATE jsh_material SET unit='吨' WHERE tenant_id=63 AND id={t.raw_ids[0]}")
  check('returns: failed receipt preserves approved state without stock posting',detail(r)['workflow_status']=='approved' and detail(r)['ledger_head_id'] is None)
  payload=dict(action='receive',version=detail(r)['version'],depotId=15)
  time.sleep(1.1)
  with ThreadPoolExecutor(2) as pool:results=list(pool.map(lambda _:ret('/'+str(r)+'/action',payload,t.chiefs[0]),range(2)))
  check('returns: concurrent receipt posts exactly once',sum(x['code']==200 for x in results)==1 and all(x['code'] in (200,409) for x in results))
  d=detail(r);ledger=d['ledger_head_id'];ledgers.append(ledger)
  check('returns: receipt immediately restores released, resalable stock without a new inspection',sql(f"SELECT CONCAT(q.qc_status,':',q.release_state,':',q.return_released,':',di.basic_number,':',di.depot_id) FROM jsh_factory_batch_quality q JOIN jsh_depot_item di ON di.id=q.item_id AND di.tenant_id=q.tenant_id WHERE di.header_id={ledger} AND di.tenant_id=63").startswith('passed:released:1:2.') and d['workflow_status']=='received' and d['receivedDepotName']=='仓库2')
  denied(action(r,'cancel',comment='too late'));denied(api('/depotHead/batchSetStatus',dict(ids=str(ledger),status='0'),t.seller));denied(api('/depotHead/delete?id='+str(ledger),token=t.seller,method='DELETE'));check('returns: received record and inventory ledger are immutable')
  # A separate credit order can reserve and resell the returned stock under the same final batch.
  resale=order('credit',(2,));ok(reserve(resale,[allocation(0,15,batch,2)]))
  def dispatch(a,**body):
   d=ok(api('/factoryShipping/'+str(resale),token=t.seller));return api('/factoryShipping/'+str(resale)+'/action',dict(action=a,version=(d['shipment'] or {}).get('version'),orderVersion=d['orderVersion'],**body),t.chiefs[0] if a!='request' else t.seller)
  ok(dispatch('request'));photo=ok(api('/factoryShipping/'+str(main),token=t.seller))['shipment']['trucks'][0]['photos'][0]
  ok(dispatch('trucks',trucks=[dict(plate='RETURN-RESALE',driver='TEST DRIVER',phone='13000000000',photos=[photo],lines=[allocation(0,15,batch,2)])]));ok(dispatch('ship'));check('returns: returned stock resells through normal reservation and dispatch; final batch cap uses net outbound')
  # Two concurrent requests for three tons each cannot claim the four remaining tons twice.
  with ThreadPoolExecutor(2) as pool:results=list(pool.map(lambda _:create(3),range(2)))
  for result in results:
   if result['code']==200:ids.append(result['data'])
  check('returns: concurrent applications cannot exceed original shipped quantity',sum(x['code']==200 for x in results)==1 and all(x['code'] in (200,409) for x in results))
  pending=ids[-1];denied(create(2));denied(action(pending,'cancel',comment=''));ok(action(pending,'cancel',comment='Correct quantity'))
  denied(ret('/'+str(r)+'/action',dict(action='cancel',version=1,comment='stale')));check('returns: active requests consume quota and cancellation releases it; stale actions denied')
  rejected=remember(create(1));denied(action(rejected,'reject',t.chiefs[1],comment=''));ok(action(rejected,'reject',t.chiefs[1],comment='Correct paperwork'));check('returns: rejection requires reason and frees quota')
  final=remember(create(4));ok(action(final,'approve',t.chiefs[1]));ok(action(final,'reject',t.chiefs[0],comment='Actual quantity differs'));check('returns: warehouse can return approved paperwork before receiving')
  final=remember(create(4));ok(action(final,'approve',t.chiefs[1]));time.sleep(1.1);ok(action(final,'receive',t.chiefs[0],depotId=14));ledgers.append(detail(final)['ledger_head_id']);denied(create('0.000001'));check('returns: multiple partial receipts stop at the exact original shipped quantity')
  sql(f'UPDATE jsh_factory_customer_return SET tenant_id=999999999 WHERE tenant_id=63 AND id={r}')
  try:denied(ret('/'+str(r)));denied(ret('/'+str(r)+'/action',dict(action='cancel',version=1,comment='wrong tenant')))
  finally:sql(f'UPDATE jsh_factory_customer_return SET tenant_id=63 WHERE tenant_id=999999999 AND id={r}')
  check('returns: tenant isolation, history and source lookup',len(detail(r)['history'])==3 and ok(ret('/source/'+str(main)))['lines'][0]['availableQuantity']>=0 and ok(ret('/list'))['total']>=len(ids))
  if '--preview' in sys.argv:print(json.dumps(dict(returnId=r,sourceHeadId=main)),flush=True);input('Return preview ready; press Enter to clean: ')
 finally:
  if ids:
   keys=','.join(map(str,ids));posted=sql(f'SELECT ledger_head_id FROM jsh_factory_customer_return WHERE tenant_id=63 AND id IN({keys}) AND ledger_head_id IS NOT NULL').split()
   if posted:
    pk=','.join(posted);sql(f'DELETE q FROM jsh_factory_batch_quality q JOIN jsh_depot_item di ON di.id=q.item_id AND di.tenant_id=q.tenant_id WHERE di.tenant_id=63 AND di.header_id IN({pk});DELETE FROM jsh_depot_item WHERE tenant_id=63 AND header_id IN({pk});DELETE FROM jsh_depot_head WHERE tenant_id=63 AND id IN({pk})')
   sql(f'DELETE FROM jsh_factory_customer_return_history WHERE tenant_id=63 AND return_id IN({keys});DELETE FROM jsh_factory_customer_return_line WHERE tenant_id=63 AND return_id IN({keys});DELETE FROM jsh_factory_customer_return WHERE tenant_id=63 AND id IN({keys})')
  sql(f'DELETE FROM jsh_factory_finished_batch WHERE tenant_id=63 AND head_id={main} AND root_inspection_id=0')
  sql('DELETE FROM jsh_factory_return_config WHERE tenant_id=63')
  if old:sql('INSERT INTO jsh_factory_return_config VALUES(63,'+quoted(old)+')')
  sql("DELETE FROM jsh_factory_customer_return_history WHERE tenant_id=63 AND return_id=0 AND action='configure' AND comment="+quoted('审批领导账号：'+json.dumps([t.user_ids[1],t.user_ids[2]],separators=(',',':'))))
