"""Read-only order board: scope, money, stage totals, live states and navigation."""
from factory_workshop_helpers import *
from datetime import date
import sys
checks=[]
def check(name,valid=True):
 assert valid,name
 checks.append(name)
def quoted(v):return "'"+str(v).replace('\\','\\\\').replace("'","''")+"'"
def keys(value):
 if isinstance(value,dict):return set(value).union(*(keys(v) for v in value.values()))
 if isinstance(value,list):return set().union(*(keys(v) for v in value))
 return set()
with WorkshopFixture() as t:
 old_quality=sql("SELECT JSON_OBJECT('director_id',director_id,'inspectors_json',inspectors_json,'updated_at',DATE_FORMAT(updated_at,'%Y-%m-%d %H:%i:%s')) FROM jsh_factory_quality_config WHERE tenant_id=63")
 old_release=sql("SELECT JSON_OBJECT('ids',leader_ids_json,'updated_at',DATE_FORMAT(updated_at,'%Y-%m-%d %H:%i:%s')) FROM jsh_factory_release_config WHERE tenant_id=63")
 old_change=sql('SELECT leader_ids FROM jsh_factory_change_config WHERE tenant_id=63')
 old_standards=sql("SELECT JSON_OBJECT('inspection_kind',inspection_kind,'stage_no',stage_no,'version',version,'forms_json',forms_json,'template_id',template_id,'updated_by',updated_by,'updated_at',DATE_FORMAT(updated_at,'%Y-%m-%d %H:%i:%s')) FROM jsh_factory_quality_standard WHERE tenant_id=63 AND bar_code='FACTORY-DEMO-620' AND stage_no IN(0,1,2)").splitlines()
 sales_role=None;posted=[];quality_audits=[];head=None
 def b(path,token=None):return api('/factoryProgress'+path,token=token or t.seller)
 def detail(token=None):return ok(b('/'+str(head),token))
 def q(path,body=None,token=None):return api('/factoryQuality'+path,body,token or t.seller)
 def qa(i,a,token=None,**body):return q('/'+str(i)+'/action',dict(action=a,version=ok(q('/'+str(i)))['version'],**body),token)
 today=date.today().isoformat()
 def execution(w,stage,action='report',line=0,**changes):
  body=dict(action=action,version=t.detail(head)['version'],workshopNo=w,lineNo=line,stageNo=stage,actualStart=today+'T00:00',materialsReady=True,reportDate=today,batchNumber=t.marker,inputQuantity=6,outputQuantity=5,lossQuantity=1);body.update(changes);return t.prod('/'+str(head)+'/execution',body,t.chiefs[w-1])
 def batch():return ok(q('/task/'+str(head)+'?finished=true'))['finishedBatches'][0]
 try:
  denied(b('/options',t.admin));denied(b('/list?keyword='+('x'*101)));denied(b('/list?page=0'));check('business tenant and bounded list parameters enforced')
  head=t.order(two=True);t.approved(head);ok(t.distribute(head,[dict(lineNo=0,stageNo=1,workshopNo=1,quantity=10),dict(lineNo=0,stageNo=2,workshopNo=2,quantity=10),dict(lineNo=1,stageNo=1,workshopNo=3,quantity=3)]))
  for w in (1,2,3):ok(t.accept(head,w));ok(t.plan(head,w))
  other=t.order()
  # A separate ordinary salesperson owns only the second order.
  sql("INSERT INTO jsh_role(name,type,enabled,tenant_id,delete_flag) VALUES("+quoted(t.marker+' sales')+",'个人数据',1,63,'0')");sales_role=int(sql('SELECT id FROM jsh_role WHERE tenant_id=63 AND name='+quoted(t.marker+' sales')))
  menus=sql("SELECT id FROM jsh_function WHERE url IN('/bill/sale_order','/factory/order_progress')").split();sql(f"INSERT INTO jsh_user_business(type,key_id,value,tenant_id,delete_flag) VALUES('RoleFunctions','{sales_role}','"+''.join('['+i+']' for i in menus)+"',63,'0')")
  name='progress_'+uuid.uuid4().hex[:10];sql("INSERT INTO jsh_user(username,login_name,password,status,tenant_id,delete_flag) SELECT '"+name+"','"+name+"',password,0,63,'0' FROM jsh_user WHERE id=131")
  seller_id=int(sql("SELECT id FROM jsh_user WHERE tenant_id=63 AND login_name='"+name+"'"));t.user_ids.append(seller_id);sql(f"INSERT INTO jsh_user_business(type,key_id,value,tenant_id,delete_flag) VALUES('UserRole','{seller_id}','[{sales_role}]',63,'0')");seller=login(name);t.tokens.append(seller);sql(f'UPDATE jsh_factory_sales_order SET created_by={seller_id} WHERE tenant_id=63 AND head_id={other}')
  seller_rows=ok(b('/list',seller));check('ordinary sales sees only own orders before pagination',seller_rows['total']==1 and seller_rows['rows'][0]['head_id']==other and ok(b('/list?page=2',seller))['rows']==[]);denied(b('/'+str(head),seller));denied(b('/'+str(other),t.chiefs[0]));check('direct detail links cannot bypass sales or workshop scope')
  ok(execution(1,1,'start'));ok(execution(1,1));ok(execution(3,1,'start',line=1));ok(execution(3,1,line=1,inputQuantity=3,outputQuantity=2,lossQuantity=1))
  ok(q('/config',dict(directorId=131,inspectorIds=[t.user_ids[2]])))
  for stage in (1,2):
   existing=next((s for s in ok(q('/standards')) if s['bar_code']=='FACTORY-DEMO-620' and s['stage_no']==stage),{})
   ok(q('/standards',dict(barCode='FACTORY-DEMO-620',stageNo=stage,version=existing.get('version'),forms=[dict(name=t.marker,items=[dict(name='Sample',unit='%',min=0,max=10)])])))
  finished_standard=next((s for s in ok(q('/standards')) if s['bar_code']=='FACTORY-DEMO-620' and s['inspection_kind']=='finished'),{})
  ok(q('/standards',dict(barCode='FACTORY-DEMO-620',stageNo=0,inspectionKind='finished',version=finished_standard.get('version'),forms=[dict(name=t.marker,items=[dict(name='Sample',unit='%',min=0,max=10)])])))
  inspection=ok(q('/request',dict(headId=head,lineNo=0,stageNo=1,workshopNo=1,batchNumber=t.marker,quantity=5),t.chiefs[0]));ok(qa(inspection,'form',t.chiefs[2],formIndex=0,values=[dict(value=5)]));ok(qa(inspection,'submit',t.chiefs[2]));ok(qa(inspection,'approve',t.leader,qualifiedQuantity=5,comment='Passed'));ok(qa(inspection,'transfer',t.chiefs[0],stageNo=2,workshopNo=2,quantity=5));transfer=ok(q('/task/'+str(head)))['transfers'][0]['id']
  check('board exposes a real pending receiving handoff',any('待接收车间' in x for x in detail()['pending']))
  ok(qa(inspection,'receive',t.chiefs[1],transferId=transfer));ok(execution(2,2,'start'));ok(execution(2,2,inputQuantity=5,outputQuantity=4,lossQuantity=1))
  all_data=detail();line=next(p for p in all_data['lines'] if p['lineNo']==0);check('final output uses last operation only; stages keep separate input/output/loss',line['finalOutput']==4 and len(all_data['stages'])==3 and sum(r['output'] for r in all_data['stages'] if r['lineNo']==0)==9 and all_data['total_price']==160)
  chief=detail(t.chiefs[0]);check('workshop scope filters products, operations and other workshop output',len(chief['lines'])==1 and chief['lines'][0]['lineNo']==0 and len(chief['stages'])==1 and chief['stages'][0]['workshopNo']==1 and chief['stages'][0]['output']==5)
  check('workshop board never returns order prices, amounts or financial payloads',not keys(chief)&{'price','total_price','unitPrice','allPrice','paid_amount','payload_json','lines_json','trucks_json'})
  chief_links={r['url']:r for r in chief['links']};check('jump availability follows existing menu grants and carries the exact task',not chief_links['/factory/shipping']['enabled'] and chief_links['/factory/production_task']['enabled'] and chief_links['/factory/production_task']['query']['viewId']==str(head))
  sql("INSERT INTO jsh_factory_change_config VALUES(63,'["+str(t.user_ids[0])+" ]') ON DUPLICATE KEY UPDATE leader_ids=VALUES(leader_ids)")
  leader=ok(b('/'+str(other),t.chiefs[0]));check('configured leader sees all orders without automatically gaining money visibility','total_price' not in leader)
  sql('DELETE FROM jsh_factory_change_config WHERE tenant_id=63')
  if old_change:sql('INSERT INTO jsh_factory_change_config VALUES(63,'+quoted(old_change)+')')
  ok(t.prod('/config',dict(t.config,coordinatorId=t.user_ids[1])));check('coordinator sees orders belonging to other sales',ok(b('/'+str(other),t.chiefs[1]))['head_id']==other);ok(t.prod('/config',t.config))
  final=ok(q('/request',dict(headId=head,lineNo=0,stageNo=2,workshopNo=2,batchNumber=t.marker,finished=True),t.chiefs[1]));check('final sampling is shown without inflating physical output',detail()['batches'][0]['quantity']==4 and detail()['batches'][0]['progress']=='待检测填报')
  ok(qa(final,'form',t.chiefs[2],formIndex=0,values=[dict(value=5)]));ok(qa(final,'submit',t.chiefs[2]));check('submitted final inspection waits for actual QC director confirmation',detail()['batches'][0]['progress']=='待质检主任确认')
  ok(qa(final,'approve',t.leader,qualifiedQuantity=4,comment='Whole batch passed'));check('approved final sample becomes pending whole-batch receipt',detail()['batches'][0]['progress']=='待整批入库')
  time.sleep(1.1);f=batch();ok(q('/finished/'+str(f['id'])+'/action',dict(action='receive',version=f['version'],depotId=14)));posted.append(batch()['ledger_head_id']);check('receipt becomes pending leadership release',detail()['batches'][0]['progress']=='待领导放行')
  ok(q('/leaders',dict(leaderIds=[131])));quality_audits.append(sql("SELECT MAX(id) FROM jsh_factory_quality_history WHERE tenant_id=63 AND action='release_config'"));f=batch();ok(q('/finished/'+str(f['id'])+'/action',dict(action='release',version=f['version']),t.leader));check('released batch remains a historical batch total, not a fabricated current stock total',detail()['batches'][0]['progress']=='已整批放行' and detail()['lines'][0]['finalOutput']==4)
  # A pending shipping fixture checks payment and vehicle progress without creating a second stock ledger.
  sql(f"UPDATE jsh_factory_sales_order SET payment_terms='prepay' WHERE tenant_id=63 AND head_id={head};INSERT INTO jsh_factory_shipment(head_id,tenant_id,workflow_status,trucks_json,requested_by,requested_at) VALUES({head},63,'requested','[]',63,NOW())")
  check('prepayment backlog is derived from the recorded finance confirmation',any('待财务确认到账' in x for x in detail()['pending']) and detail()['shipment']['truckCount']==0)
  sql(f'UPDATE jsh_factory_shipment SET paid_by=131,paid_date=CURDATE() WHERE tenant_id=63 AND head_id={head}');check('finance confirmation advances backlog to packing and unified dispatch',any('待仓库装车' in x for x in detail()['pending']) and not any('待财务确认到账' in x for x in detail()['pending']))
  count=sql(f'SELECT COUNT(*) FROM jsh_factory_production_report WHERE tenant_id=63 AND head_id={head}');result=api('/factoryProgress/'+str(head)+'/action',dict(action='ship'),t.seller);check('board has no business mutation endpoint',result['code']!=200 and sql(f'SELECT COUNT(*) FROM jsh_factory_production_report WHERE tenant_id=63 AND head_id={head}')==count)
  sql(f'UPDATE jsh_factory_sales_order SET tenant_id=999999999 WHERE tenant_id=63 AND head_id={head}')
  try:denied(b('/'+str(head)));check('board lookup isolates tenants')
  finally:sql(f'UPDATE jsh_factory_sales_order SET tenant_id=63 WHERE tenant_id=999999999 AND head_id={head}')
  if '--preview' in sys.argv:print(json.dumps(dict(headId=head,otherHeadId=other,inspectionId=inspection,finalId=final)),flush=True);input('Preview ready; press Enter to clean: ')
  print(json.dumps(dict(passed=checks,count=len(checks)),ensure_ascii=False,indent=2))
 finally:
  if head:
   sql(f'DELETE FROM jsh_factory_shipment WHERE tenant_id=63 AND head_id={head};DELETE h FROM jsh_factory_quality_history h JOIN jsh_factory_inspection i ON i.id=h.inspection_id AND i.tenant_id=h.tenant_id WHERE i.tenant_id=63 AND i.head_id={head};DELETE FROM jsh_factory_quality_transfer WHERE tenant_id=63 AND head_id={head};DELETE FROM jsh_factory_finished_batch WHERE tenant_id=63 AND head_id={head};DELETE FROM jsh_factory_inspection WHERE tenant_id=63 AND head_id={head};DELETE FROM jsh_factory_production_report WHERE tenant_id=63 AND head_id={head};DELETE FROM jsh_factory_production_start WHERE tenant_id=63 AND head_id={head}')
  if posted:
   pk=','.join(map(str,posted));sql(f'DELETE q FROM jsh_factory_batch_quality q JOIN jsh_depot_item di ON di.id=q.item_id AND di.tenant_id=q.tenant_id WHERE di.tenant_id=63 AND di.header_id IN({pk});DELETE FROM jsh_depot_item WHERE tenant_id=63 AND header_id IN({pk});DELETE FROM jsh_depot_head WHERE tenant_id=63 AND id IN({pk})');api('/material/batchSetMaterialCurrentStock',dict(ids='620'),t.seller)
  for audit in quality_audits:sql('DELETE FROM jsh_factory_quality_history WHERE tenant_id=63 AND id='+audit)
  sql("DELETE FROM jsh_factory_quality_history WHERE tenant_id=63 AND inspection_id IS NULL AND (payload_json LIKE '%"+t.marker+"%' OR JSON_EXTRACT(payload_json,'$.inspectorIds[0]')="+str(t.user_ids[2])+")")
  sql("DELETE FROM jsh_factory_quality_standard WHERE tenant_id=63 AND bar_code='FACTORY-DEMO-620' AND stage_no IN(0,1,2)")
  for value in old_standards:
   s=json.loads(value);sql("INSERT INTO jsh_factory_quality_standard(tenant_id,bar_code,stage_no,version,forms_json,updated_by,updated_at,template_id,inspection_kind) VALUES(63,'FACTORY-DEMO-620',"+str(s['stage_no'])+','+str(s['version'])+','+quoted(s['forms_json'])+','+str(s['updated_by'])+','+quoted(s['updated_at'])+','+(str(s['template_id']) if s['template_id'] is not None else 'NULL')+','+quoted(s['inspection_kind'])+')')
  sql('DELETE FROM jsh_factory_quality_config WHERE tenant_id=63;DELETE FROM jsh_factory_release_config WHERE tenant_id=63;DELETE FROM jsh_factory_change_config WHERE tenant_id=63')
  if old_quality:
   c=json.loads(old_quality);sql('INSERT INTO jsh_factory_quality_config VALUES(63,'+str(c['director_id'])+','+quoted(c['inspectors_json'])+','+quoted(c['updated_at'])+')')
  if old_release:
   c=json.loads(old_release);sql('INSERT INTO jsh_factory_release_config VALUES(63,'+quoted(c['ids'])+','+quoted(c['updated_at'])+')')
  if old_change:sql('INSERT INTO jsh_factory_change_config VALUES(63,'+quoted(old_change)+')')
  if sales_role:sql(f"DELETE FROM jsh_user_business WHERE tenant_id=63 AND type='RoleFunctions' AND key_id='{sales_role}';DELETE FROM jsh_role WHERE tenant_id=63 AND id={sales_role}")
