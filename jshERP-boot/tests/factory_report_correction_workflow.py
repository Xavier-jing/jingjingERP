"""Direct corrections, history, downstream locks and inspection races on disposable tasks."""
from factory_workshop_helpers import *
from datetime import date,timedelta
import sys

checks=[]
def check(name,valid=True):
 assert valid,name
 checks.append(name)
def quoted(v):return "'"+str(v).replace('\\','\\\\').replace("'","''")+"'"

with WorkshopFixture() as t:
 old_config=sql("SELECT JSON_OBJECT('director_id',director_id,'inspectors_json',inspectors_json,'updated_at',DATE_FORMAT(updated_at,'%Y-%m-%d %H:%i:%s')) FROM jsh_factory_quality_config WHERE tenant_id=63")
 old_standards=sql("SELECT JSON_OBJECT('inspection_kind',inspection_kind,'stage_no',stage_no,'version',version,'forms_json',forms_json,'template_id',template_id,'updated_by',updated_by,'updated_at',DATE_FORMAT(updated_at,'%Y-%m-%d %H:%i:%s')) FROM jsh_factory_quality_standard WHERE tenant_id=63 AND bar_code='FACTORY-DEMO-620' AND stage_no IN(0,1,2)").splitlines()
 today=date.today().isoformat();yesterday=(date.today()-timedelta(days=1)).isoformat();batch=t.marker+'-A';other=t.marker+'-B'
 def q(path,body=None,token=None):return api('/factoryQuality'+path,body,token or t.seller)
 def execution(action='report',w=1,stage=1,token=None,**changes):
  payload=dict(version=t.detail(head)['version'],action=action,workshopNo=w,lineNo=0,stageNo=stage,actualStart=yesterday+'T00:00',materialsReady=True,reportDate=today,batchNumber=batch,inputQuantity=6,outputQuantity=5,lossQuantity=1,comment='Original daily note');payload.update(changes)
  return t.prod('/'+str(head)+'/execution',payload,token or t.chiefs[w-1])
 def report(i):return next(r for r in t.detail(head)['reports'] if r['id']==i)
 def correct(i,**changes):
  changes.setdefault('reason','Correct entered figures');return execution('correctReport',reportId=i,**changes)
 def send(b=batch,quantity=6,finished=False,w=1,stage=1):return q('/request',dict(headId=head,lineNo=0,stageNo=stage,workshopNo=w,batchNumber=b,quantity=quantity,finished=finished),t.chiefs[w-1])
 def qa(i,a,token=None,**body):return q('/'+str(i)+'/action',dict(version=ok(q('/'+str(i)))['version'],action=a,**body),token)
 try:
  head=t.order();t.approved(head);ok(t.distribute(head,[dict(lineNo=0,stageNo=1,workshopNo=1,quantity=10),dict(lineNo=0,stageNo=2,workshopNo=2,quantity=10)]))
  for w in (1,2):ok(t.accept(head,w));ok(t.plan(head,w))
  ok(execution('start'));ok(execution());ok(execution(batchNumber=other,inputQuantity=4,outputQuantity=3,lossQuantity=1))
  a=next(r['id'] for r in t.detail(head)['reports'] if r['batch_number']==batch);b=next(r['id'] for r in t.detail(head)['reports'] if r['batch_number']==other);original=report(a)
  denied(correct(a,token=t.seller));denied(correct(a,token=t.chiefs[1]));denied(correct(a,token=t.admin));denied(correct(999999999));denied(correct(a,w=2,stage=2));check('only current corresponding director may correct the exact task and report')
  denied(correct(a,reason=''));denied(correct(a,inputQuantity=2));denied(correct(a,lossQuantity=-1));denied(correct(a,outputQuantity='1.0000001'));denied(correct(a,reportDate='2099-01-01'));denied(correct(a,reportDate='2000-01-01'));denied(correct(a,reportDate='not-date'));check('reason, date, precision and input-output-loss constraints remain enforced')
  denied(correct(a,batchNumber=other));denied(correct(a,inputQuantity=9,outputQuantity=8));check('duplicate daily batch and cumulative workshop quota remain enforced')
  ok(correct(a,inputQuantity=7,outputQuantity=6,lossQuantity=1,comment='Corrected note'))
  d=t.detail(head);change=json.loads(next(h['payload_json'] for h in d['history'] if h['action']=='report_correct'))
  check('direct correction updates the same report without approval and preserves original author',report(a)['output_quantity']==6 and report(a)['actor_id']==original['actor_id'] and report(a)['created_at']==original['created_at'] and len(d['reports'])==2)
  check('history keeps complete before and after contents, reason, actor and readable dates',change['reportId']==a and change['before']['output_quantity']==5 and change['after']['output_quantity']==6 and change['before']['comment']=='Original daily note' and change['after']['comment']=='Corrected note' and change['before']['report_date']==today and change['reason']=='Correct entered figures')
  ok(correct(a,reportDate=yesterday,batchNumber=batch+'-EDIT'));ok(correct(a,inputQuantity=7,outputQuantity=6,lossQuantity=1));check('unlinked report date and batch can change with every revision retained',sum(h['action']=='report_correct' for h in t.detail(head)['history'])==3)
  version=t.detail(head)['version'];base=dict(action='correctReport',version=version,reportId=a,workshopNo=1,lineNo=0,stageNo=1,reportDate=today,batchNumber=batch,inputQuantity=7,outputQuantity=6,lossQuantity=1,reason='Concurrent correction',comment='Concurrent note')
  with ThreadPoolExecutor(2) as pool:results=list(pool.map(lambda _:t.prod('/'+str(head)+'/execution',base,t.chiefs[0]),range(2)))
  check('concurrent corrections allow one version only',sum(r['code']==200 for r in results)==1 and all(r['code'] in (200,409) for r in results))
  old_version=t.detail(head)['version'];history_count=sum(h['action']=='report_correct' for h in t.detail(head)['history']);denied(correct(a,inputQuantity=1));check('failed correction leaves report version and audit unchanged',t.detail(head)['version']==old_version and sum(h['action']=='report_correct' for h in t.detail(head)['history'])==history_count)
  ok(q('/config',dict(directorId=131,inspectorIds=[t.user_ids[2]])))
  for stage in (1,2):
   existing=next((s for s in ok(q('/standards')) if s['bar_code']=='FACTORY-DEMO-620' and s['stage_no']==stage),{})
   ok(q('/standards',dict(barCode='FACTORY-DEMO-620',stageNo=stage,version=existing.get('version'),forms=[dict(name=t.marker,items=[dict(name='Sample',unit='%',min=0,max=10)])])))
  finished_standard=next((s for s in ok(q('/standards')) if s['bar_code']=='FACTORY-DEMO-620' and s['inspection_kind']=='finished'),{})
  ok(q('/standards',dict(barCode='FACTORY-DEMO-620',stageNo=0,inspectionKind='finished',version=finished_standard.get('version'),forms=[dict(name=t.marker,items=[dict(name='Sample',unit='%',min=0,max=10)])])))
  inspection=ok(send());denied(correct(a));denied(correct(b,batchNumber=batch));check('submitted inspection locks original batch and blocks moving another report into it')
  # Complete source inspection and transfer to the second operation.
  ok(qa(inspection,'form',t.chiefs[2],formIndex=0,values=[dict(value=5)]));ok(qa(inspection,'submit',t.chiefs[2]));ok(qa(inspection,'approve',t.leader,qualifiedQuantity=6,comment='Qualified'))
  ok(qa(inspection,'transfer',t.chiefs[0],stageNo=2,workshopNo=2,quantity=6));transfer=ok(q('/task/'+str(head)))['transfers'][0]['id'];ok(qa(inspection,'receive',t.chiefs[1],transferId=transfer));denied(correct(a));check('transferred and received source output stays immutable')
  ok(execution('start',w=2,stage=2));ok(execution(w=2,stage=2,inputQuantity=4,outputQuantity=4,lossQuantity=0));down=next(r['id'] for r in t.detail(head)['reports'] if r['stage_no']==2)
  ok(correct(down,w=2,stage=2,inputQuantity=6,outputQuantity=5,lossQuantity=1));denied(correct(down,w=2,stage=2,inputQuantity=7,outputQuantity=6,lossQuantity=1));denied(correct(down,w=2,stage=2,batchNumber='NOT-RECEIVED'))
  check('downstream correction excludes its old input but cannot exceed received batch quantities')
  final=ok(send(finished=True,w=2,stage=2));denied(correct(down,w=2,stage=2));check('final whole-batch sampling freezes every linked daily output')
  # The other first-operation batch is still editable until its own inspection.
  payload=dict(action='correctReport',version=t.detail(head)['version'],reportId=b,workshopNo=1,lineNo=0,stageNo=1,reportDate=today,batchNumber=other,inputQuantity=3,outputQuantity=2,lossQuantity=1,reason='Race with sampling',comment='Updated during sampling')
  with ThreadPoolExecutor(2) as pool:
   tasks=[pool.submit(lambda:t.prod('/'+str(head)+'/execution',payload,t.chiefs[0])),pool.submit(lambda:send(b=other,quantity=3))];results=[r.result() for r in tasks]
  check('sampling and correction serialize against latest output so only one incompatible change succeeds',sum(r['code']==200 for r in results)==1 and all(r['code'] in (200,409) for r in results))
  sql(f'UPDATE jsh_factory_production_report SET tenant_id=999999999 WHERE tenant_id=63 AND id={b}')
  try:denied(correct(b));check('report correction isolates tenant data')
  finally:sql(f'UPDATE jsh_factory_production_report SET tenant_id=63 WHERE tenant_id=999999999 AND id={b}')
  if '--preview' in sys.argv:
   ok(execution(batchNumber=t.marker+'-UI',inputQuantity='0.5',outputQuantity='0.5',lossQuantity=0,comment='UI correction fixture'))
   ok(t.prod('/config',dict(t.config,workshop1DirectorId=63)))
   print(json.dumps(dict(headId=head,correctedReportId=a,downstreamReportId=down)),flush=True);input('Preview ready; press Enter to clean: ')
  print(json.dumps(dict(passed=checks,count=len(checks)),ensure_ascii=False,indent=2))
 finally:
  if t.ids:
   keys=','.join(map(str,t.ids));sql(f'DELETE h FROM jsh_factory_quality_history h JOIN jsh_factory_inspection i ON i.id=h.inspection_id AND i.tenant_id=h.tenant_id WHERE i.tenant_id=63 AND i.head_id IN({keys});DELETE FROM jsh_factory_quality_transfer WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_finished_batch WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_inspection WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_production_report WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_production_start WHERE tenant_id=63 AND head_id IN({keys})')
  sql("DELETE FROM jsh_factory_quality_history WHERE tenant_id=63 AND inspection_id IS NULL AND (payload_json LIKE '%"+t.marker+"%' OR JSON_EXTRACT(payload_json,'$.inspectorIds[0]')="+str(t.user_ids[2])+")")
  sql("DELETE FROM jsh_factory_quality_standard WHERE tenant_id=63 AND bar_code='FACTORY-DEMO-620' AND stage_no IN(0,1,2)")
  for value in old_standards:
   s=json.loads(value);sql("INSERT INTO jsh_factory_quality_standard(tenant_id,bar_code,stage_no,version,forms_json,updated_by,updated_at,template_id,inspection_kind) VALUES(63,'FACTORY-DEMO-620',"+str(s['stage_no'])+','+str(s['version'])+','+quoted(s['forms_json'])+','+str(s['updated_by'])+','+quoted(s['updated_at'])+','+(str(s['template_id']) if s['template_id'] is not None else 'NULL')+','+quoted(s['inspection_kind'])+')')
  sql('DELETE FROM jsh_factory_quality_config WHERE tenant_id=63')
  if old_config:
   c=json.loads(old_config);sql('INSERT INTO jsh_factory_quality_config VALUES(63,'+str(c['director_id'])+','+quoted(c['inspectors_json'])+','+quoted(c['updated_at'])+')')
