"""Integration test against the local ERP; temporary business data is removed in finally."""
from datetime import date
import sys
from factory_workshop_helpers import *

passed=[]
def check(name,condition=True):
 assert condition,name
 passed.append(name)

with WorkshopFixture() as t:
 old_config=sql("SELECT JSON_OBJECT('director_id',director_id,'inspectors_json',inspectors_json,'updated_at',DATE_FORMAT(updated_at,'%Y-%m-%d %H:%i:%s')) FROM jsh_factory_quality_config WHERE tenant_id=63")
 old_standard=sql("SELECT JSON_OBJECT('version',version,'forms_json',forms_json,'template_id',template_id,'updated_by',updated_by,'updated_at',DATE_FORMAT(updated_at,'%Y-%m-%d %H:%i:%s')) FROM jsh_factory_quality_standard WHERE tenant_id=63 AND bar_code='FACTORY-DEMO-620' AND stage_no=1")
 def q(path,body=None,token=None):return api('/factoryQuality'+path,body,token or t.seller)
 def inspection(i):return ok(q('/'+str(i)))
 def act(i,action,token=None,**body):return q('/'+str(i)+'/action',dict(version=inspection(i)['version'],action=action,**body),token)
 def request(head,quantity=10,parent=None,token=None,**changes):
  payload=dict(headId=head,lineNo=0,stageNo=1,workshopNo=1,batchNumber=t.marker,quantity=quantity,parentId=parent,comment='Adjusted and retested' if parent else '')
  payload.update(changes);return q('/request',payload,token or t.chiefs[0])
 def standard(forms,version=None,token=None):return q('/standards',dict(barCode='FACTORY-DEMO-620',stageNo=1,forms=forms,version=version),token)
 forms=[dict(name=t.marker+' Physical test',items=[dict(name='Moisture',unit='%',min=5,max=8)]),dict(name=t.marker+' Chemical test',items=[dict(name='Purity',unit='%',min=90,max=None),dict(name='Observed value',unit='',min=None,max=None)])]
 try:
  denied(q('/options',token=t.admin));denied(q('/config',dict(directorId=131,inspectorIds=[t.user_ids[2]]),t.chiefs[0]));check('tenant and configuration permissions')
  ok(q('/config',dict(directorId=131,inspectorIds=[t.user_ids[2]])));denied(standard(forms,token=t.chiefs[0]));check('only director or owner maintains standards')
  existing=next((r for r in ok(q('/standards')) if r['bar_code']=='FACTORY-DEMO-620' and r['stage_no']==1),None)
  version=existing['version'] if existing else None
  bad=json.loads(json.dumps(forms));bad[0]['items'][0].update(min=9,max=8);denied(standard(bad,version));ok(standard(forms,version));denied(standard(forms,version));check('standard ranges and stale version protection')
  head=t.order();t.approved(head);ok(t.distribute(head,[dict(lineNo=0,stageNo=1,workshopNo=1,quantity=10),dict(lineNo=0,stageNo=2,workshopNo=2,quantity=10)]))
  for w in (1,2):ok(t.accept(head,w));ok(t.plan(head,w))
  today=date.today().isoformat()
  def execution(w,stage,action,**changes):
   payload=dict(version=t.detail(head)['version'],workshopNo=w,lineNo=0,stageNo=stage,action=action,actualStart=today+'T00:00',materialsReady=True,reportDate=today,batchNumber=t.marker,inputQuantity=10,outputQuantity=10,lossQuantity=0)
   payload.update(changes);return t.prod('/'+str(head)+'/execution',payload,t.chiefs[w-1])
  denied(request(head));ok(execution(1,1,'start'));ok(execution(1,1,'report'));denied(request(head,11));denied(request(head,token=t.chiefs[1]));check('inspection requires output, correct director and quantity')
  original=ok(request(head));denied(request(head,1));denied(execution(2,2,'start'));check('duplicate inspection and downstream start without received goods denied')
  d=inspection(original);saved_standard=d['standard_version'];changed=json.loads(json.dumps(forms));changed[0]['items'][0]['max']=12
  current=next(r for r in ok(q('/standards')) if r['bar_code']=='FACTORY-DEMO-620' and r['stage_no']==1);ok(standard(changed,current['version']));check('inspection retains historical standard',inspection(original)['forms'][0]['items'][0]['max']==8 and inspection(original)['standard_version']==saved_standard)
  denied(act(original,'form',formIndex=0,values=[dict(value=9)]));denied(act(original,'approve',t.leader,qualifiedQuantity=8,comment='Partial'))
  ok(act(original,'form',t.chiefs[2],formIndex=0,values=[dict(value=9)],comment='Abnormal sample'))
  denied(act(original,'submit',t.chiefs[2]));check('form permissions, director prerequisite and incomplete tables denied')
  ok(act(original,'form',t.chiefs[2],formIndex=1,values=[dict(value=90),dict(value=-2)],comment='Complete'))
  stale=inspection(original)['version'];ok(act(original,'submit',t.chiefs[2]));denied(q('/'+str(original)+'/action',dict(version=stale,action='form',formIndex=0,values=[dict(value=7)]),t.chiefs[2]));denied(act(original,'approve',t.chiefs[0],qualifiedQuantity=8,comment='Partial'));denied(act(original,'return',t.leader,comment=''));ok(act(original,'return',t.leader,comment='Please verify sample'));check('submit locks data, stale writes and unauthorized review denied; return supported')
  ok(act(original,'form',t.chiefs[2],formIndex=0,values=[dict(value=9)],comment='Verified actual value, do not replace'))
  ok(act(original,'submit',t.chiefs[2]));denied(act(original,'approve',t.leader,qualifiedQuantity=8,comment=''));denied(act(original,'approve',t.leader,qualifiedQuantity=11,comment='Invalid'));ok(act(original,'approve',t.leader,qualifiedQuantity=8,comment='8 tons qualified, 2 tons adjust and retest'))
  denied(act(original,'form',t.chiefs[2],formIndex=0,values=[dict(value=7)]));check('abnormal and partial result explanations, quantity limits and approved immutability')
  denied(request(head,3,parent=original));denied(request(head,2,parent=original,comment=''));retry=ok(request(head,2,parent=original));denied(request(head,1,parent=original));check('reinspection limited to failed quantity and requires adjustment explanation')
  for index,values in ((0,[dict(value=7)]),(1,[dict(value=95),dict(value=1)])):ok(act(retry,'form',t.chiefs[2],formIndex=index,values=values,comment='Retest'))
  ok(act(retry,'submit',t.chiefs[2]));ok(act(retry,'approve',t.leader,qualifiedQuantity=2,comment='Retest qualified'))
  check('reinspection preserves original abnormal results and lineage',inspection(original)['forms'][0]['items'][0]['value']==9 and inspection(retry)['parent_id']==original)
  denied(act(original,'transfer',t.chiefs[1],stageNo=2,workshopNo=2,quantity=8));denied(act(original,'transfer',t.chiefs[0],stageNo=3,workshopNo=2,quantity=8));denied(act(original,'transfer',t.chiefs[0],stageNo=2,workshopNo=3,quantity=8));denied(act(original,'transfer',t.chiefs[0],stageNo=2,workshopNo=2,quantity=9));check('transfer enforces source director, next route and qualified quantity')
  body=dict(version=inspection(original)['version'],action='transfer',stageNo=2,workshopNo=2,quantity=8)
  with ThreadPoolExecutor(2) as pool:results=list(pool.map(lambda _:q('/'+str(original)+'/action',body,t.chiefs[0]),range(2)))
  check('concurrent duplicate transfers allow one success',sum(r['code']==200 for r in results)==1 and all(r['code'] in (200,409) for r in results))
  denied(execution(2,2,'start'));tr=ok(q('/task/'+str(head)))['transfers'][0]
  denied(act(original,'receive',t.chiefs[0],transferId=tr['id']));ok(act(original,'receive',t.chiefs[1],transferId=tr['id']));denied(act(original,'receive',t.chiefs[1],transferId=tr['id']));check('only receiving director confirms once; pending goods cannot start production')
  ok(execution(2,2,'start'));denied(execution(2,2,'report',batchNumber='WRONG'));denied(execution(2,2,'report',inputQuantity=9,outputQuantity=9));ok(execution(2,2,'report',inputQuantity=8,outputQuantity=8));check('downstream production uses inherited batch and received input quantity')
  ok(act(retry,'transfer',t.chiefs[0],stageNo=2,workshopNo=2,quantity=2));tr=ok(q('/task/'+str(head)))['transfers'][0];ok(act(retry,'receive',t.chiefs[1],transferId=tr['id']))
  check('partially qualified and retested goods total 10 tons',sum(Decimal(str(r['quantity'])) for r in ok(q('/task/'+str(head)))['transfers'])==10)
  check('audit retains form values and confirmations',any(h['action']=='form' and '9' in h['payload_json'] for h in inspection(original)['history']) and any(h['action']=='receive' for h in inspection(original)['history']))
  check('quality workbench exposes no prices',all(not any(k in line for k in ('price','unitPrice','allPrice','taxLastMoney')) for line in ok(q('/task/'+str(head)))['lines']))
  # Simulate a foreign tenant row without altering any real user's tenant.
  sql(f'UPDATE jsh_factory_inspection SET tenant_id=999999999 WHERE id={retry} AND tenant_id=63')
  try:denied(q('/'+str(retry)));check('cross-tenant inspection isolation')
  finally:sql(f'UPDATE jsh_factory_inspection SET tenant_id=63 WHERE id={retry} AND tenant_id=999999999')
  if '--preview' in sys.argv:
   print(json.dumps(dict(previewHeadId=head,inspectionId=original,reinspectionId=retry)),flush=True)
   input('Preview ready; press Enter to remove temporary data: ')
  print(json.dumps(dict(passed=passed,count=len(passed)),ensure_ascii=False,indent=2))
 finally:
  if t.ids:
   keys=','.join(map(str,t.ids));sql(f'DELETE h FROM jsh_factory_quality_history h JOIN jsh_factory_inspection i ON i.id=h.inspection_id AND i.tenant_id=h.tenant_id WHERE i.tenant_id=63 AND i.head_id IN({keys});DELETE FROM jsh_factory_quality_transfer WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_inspection WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_production_report WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_production_start WHERE tenant_id=63 AND head_id IN({keys})')
  sql("DELETE FROM jsh_factory_quality_config WHERE tenant_id=63;DELETE FROM jsh_factory_quality_standard WHERE tenant_id=63 AND bar_code='FACTORY-DEMO-620' AND stage_no=1")
  def quoted(v):return "'"+str(v).replace('\\','\\\\').replace("'","''")+"'"
  sql("DELETE FROM jsh_factory_quality_history WHERE tenant_id=63 AND inspection_id IS NULL AND ((action='standard' AND JSON_UNQUOTE(JSON_EXTRACT(payload_json,'$.forms[0].name'))="+quoted(forms[0]['name'])+") OR (action='configure' AND JSON_EXTRACT(payload_json,'$.directorId')=131 AND JSON_LENGTH(payload_json,'$.inspectorIds')=1 AND JSON_CONTAINS(payload_json,'"+str(t.user_ids[2])+"','$.inspectorIds')))")
  if old_config:
   c=json.loads(old_config);sql(f"INSERT INTO jsh_factory_quality_config VALUES(63,{int(c['director_id'])},{quoted(c['inspectors_json'])},{quoted(c['updated_at'])})")
  if old_standard:
   s=json.loads(old_standard);sql(f"INSERT INTO jsh_factory_quality_standard(tenant_id,bar_code,stage_no,version,forms_json,updated_by,updated_at,template_id) VALUES(63,'FACTORY-DEMO-620',1,{int(s['version'])},{quoted(s['forms_json'])},{int(s['updated_by'])},{quoted(s['updated_at'])},{str(s['template_id']) if s['template_id'] is not None else 'NULL'})")
