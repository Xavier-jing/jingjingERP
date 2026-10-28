"""Product quality standards, shared templates and real inspection snapshots."""
from factory_workshop_helpers import *
from datetime import date
import sys
checks=[]
def check(name,valid=True):
 assert valid,name
 checks.append(name)
def quoted(v):return "'"+str(v).replace('\\','\\\\').replace("'","''")+"'"
with WorkshopFixture() as t:
 old=sql("SELECT JSON_OBJECT('director_id',director_id,'inspectors_json',inspectors_json,'updated_at',DATE_FORMAT(updated_at,'%Y-%m-%d %H:%i:%s')) FROM jsh_factory_quality_config WHERE tenant_id=63")
 code='QSTANDARD-'+uuid.uuid4().hex[:12];template_ids=[];standard_role=None
 def q(path,body=None,token=None):return api('/factoryQuality'+path,body,token or t.seller)
 def detail(i):return ok(q('/'+str(i)))
 def action(i,a,token=None,**body):return q('/'+str(i)+'/action',dict(action=a,version=detail(i)['version'],**body),token)
 def binding(kind,tid,version=None,**changes):
  body=dict(barCode=code,stageNo=1 if kind=='semi' else 0,inspectionKind=kind,templateId=tid,version=version);body.update(changes);return q('/standards',body)
 def send(finished=False):return q('/request',dict(headId=head,lineNo=0,stageNo=2 if finished else 1,workshopNo=2 if finished else 1,batchNumber=t.marker,quantity=5,finished=finished),t.chiefs[1 if finished else 0])
 def record(w,stage,qty):
  base=dict(version=t.detail(head)['version'],lineNo=0,stageNo=stage,workshopNo=w,actualStart=date.today().isoformat()+'T00:00',materialsReady=True)
  ok(t.prod('/'+str(head)+'/execution',dict(base,action='start'),t.chiefs[w-1]));base['version']=t.detail(head)['version']
  ok(t.prod('/'+str(head)+'/execution',dict(base,action='report',reportDate=date.today().isoformat(),batchNumber=t.marker,inputQuantity=qty,outputQuantity=qty,lossQuantity=0),t.chiefs[w-1]))
 try:
  ok(q('/config',dict(directorId=131,inspectorIds=[t.user_ids[2]])))
  sql("INSERT INTO jsh_material(name,unit,enabled,tenant_id,delete_flag,enable_serial_number,enable_batch_number,brand,standard,model) VALUES("+quoted(t.marker)+",'吨',1,63,'0','0','1','TEST','TEST','TEST')")
  material=int(sql('SELECT id FROM jsh_material WHERE tenant_id=63 AND name='+quoted(t.marker)));t.raw_ids.append(material)
  sql(f"INSERT INTO jsh_material_extend(material_id,bar_code,commodity_unit,default_flag,tenant_id,delete_flag) VALUES({material},'{code}','吨','1',63,'0')")
  sql("INSERT INTO jsh_role(name,type,enabled,tenant_id,delete_flag) VALUES("+quoted(t.marker+' standard')+",'个人数据',1,63,'0')");standard_role=int(sql('SELECT id FROM jsh_role WHERE tenant_id=63 AND name='+quoted(t.marker+' standard')))
  menu=sql("SELECT id FROM jsh_function WHERE url='/factory/quality_standard'");sql(f"INSERT INTO jsh_user_business(type,key_id,value,tenant_id,delete_flag) VALUES('RoleFunctions','{standard_role}','[{menu}]',63,'0')")
  viewer_name='qc_'+uuid.uuid4().hex[:12];sql(f"INSERT INTO jsh_user(username,login_name,password,status,tenant_id,delete_flag,ismanager,isystem,leader_flag) SELECT '{viewer_name}','{viewer_name}',password,0,63,'0',ismanager,isystem,leader_flag FROM jsh_user WHERE id=131 AND tenant_id=63")
  viewer_id=int(sql("SELECT id FROM jsh_user WHERE tenant_id=63 AND login_name="+quoted(viewer_name)));t.user_ids.append(viewer_id);sql(f"INSERT INTO jsh_user_business(type,key_id,value,tenant_id,delete_flag) VALUES('UserRole','{viewer_id}','[{standard_role}]',63,'0')")
  viewer=login(viewer_name);t.tokens.append(viewer);ok(q('/standardOptions',token=viewer));ok(q('/standards',token=viewer));denied(q('/tasks',token=viewer));denied(q('/options',token=viewer));check('standards-only menu reads configuration without granting inspection workflow access')
  forms=[dict(name='物理检测',items=[dict(name='区间',type='number',unit='%',min=1,max=5),dict(name='下限',min=3),dict(name='上限',max=8),dict(name='外观',type='text',expected='合格'),dict(name='备注',type='text')])]
  payload=dict(name=t.marker,forms=forms)
  denied(q('/templates',payload,t.chiefs[0]));denied(q('/templates',token=t.admin));check('only director or owner writes; platform account cannot read business templates')
  tid=ok(q('/templates',payload,t.leader));template_ids.append(tid)
  denied(q('/templates',payload));bad=json.loads(json.dumps(payload));bad['name']+='bad';bad['forms'][0]['items'][0]['min']=6;denied(q('/templates',bad));bad['forms'][0]['items'][0]['type']='invalid';denied(q('/templates',bad));check('duplicate names, invalid ranges and item types rejected')
  finalforms=[dict(name='最终检测',items=[dict(name='最终外观',type='text',expected='合格')])]
  fid=ok(q('/templates',dict(name=t.marker+' final',forms=finalforms)));template_ids.append(fid)
  sql(f"INSERT INTO jsh_material_extend(material_id,bar_code,commodity_unit,default_flag,tenant_id,delete_flag) VALUES({material},'{code}-B','吨','0',63,'0')");ok(binding('semi',tid,barCode=code+'-B'));ok(binding('semi',tid));ok(binding('finished',fid));denied(binding('semi',tid));check('semi by operation and finished standards are separate; stale binding writes rejected')
  denied(binding('semi',999999999,version=1));check('missing templates cannot be bound')
  time.sleep(1.1);head=ok(api('/factorySales/save',dict(customerId=58,deliveryDate='2026-11-20',remark=t.marker,lines=[dict(barCode=code,quantity=10,price=10)]),t.seller));t.ids.append(head)
  sql(f"UPDATE jsh_factory_sales_order SET workflow_status='approved' WHERE tenant_id=63 AND head_id={head};UPDATE jsh_depot_head SET status='1' WHERE tenant_id=63 AND id={head}")
  t.warehouse(head);t.approved(head);ok(t.distribute(head,[dict(lineNo=0,stageNo=1,workshopNo=1,quantity=10),dict(lineNo=0,stageNo=2,workshopNo=2,quantity=10)]))
  for w in (1,2):ok(t.accept(head,w));ok(t.plan(head,w))
  record(1,1,10);first=ok(send());check('new inspection snapshots the selected shared template',detail(first)['standard_version']==1)
  updated=json.loads(json.dumps(forms));updated[0]['items'][0]['max']=2
  ok(q('/templates',dict(id=tid,version=1,name=t.marker,forms=updated),t.leader));denied(q('/templates',dict(id=tid,version=1,name=t.marker,forms=forms)));second=ok(send());shared_rows=[r for r in ok(q('/standards')) if r['template_id']==tid];check('multiple products share template updates',len(shared_rows)==2 and all(r['forms'][0]['items'][0]['max']==2 for r in shared_rows))
  check('template updates affect new inspections and preserve old standard snapshots',detail(second)['standard_version']==2 and detail(second)['forms'][0]['items'][0]['max']==2 and detail(first)['forms'][0]['items'][0]['max']==5)
  values=[dict(value=v) for v in [9,3,8,'不合格','观察记录']]
  ok(action(first,'form',t.chiefs[2],formIndex=0,values=values,comment='保留原始异常值'));ok(action(first,'submit',t.chiefs[2]));denied(action(first,'approve',t.leader,qualifiedQuantity=5,comment=''))
  check('out-of-range numeric and textual values are saved; director must explain an abnormal verdict',detail(first)['forms'][0]['items'][0]['value']==9 and detail(first)['forms'][0]['items'][3]['value']=='不合格')
  ok(action(first,'approve',t.leader,qualifiedQuantity=5,comment='已核实并记录处理结论'))
  ok(action(first,'transfer',t.chiefs[0],stageNo=2,workshopNo=2,quantity=5));transfer=ok(q('/task/'+str(head)))['transfers'][0]
  ok(action(first,'receive',t.chiefs[1],transferId=transfer['id']));record(2,2,5);final=ok(send(True))
  check('final inspection uses finished template independently of semi operation standards',detail(final)['forms'][0]['name']=='最终检测')
  ok(action(final,'form',t.chiefs[2],formIndex=0,values=[dict(value='不合格')],comment='照实保存'));ok(action(final,'submit',t.chiefs[2]));denied(action(final,'approve',t.leader,qualifiedQuantity=5,comment=''));ok(action(final,'return',t.leader,comment='补充检测'));
  ok(action(final,'form',t.chiefs[2],formIndex=0,values=[dict(value='合格')],comment='边界验收'));ok(action(final,'submit',t.chiefs[2]));ok(action(final,'approve',t.leader,qualifiedQuantity=5,comment=''))
  check('matching textual standard completes whole-batch final QC without false abnormal flags',detail(final)['workflow_status']=='approved')
  ok(action(second,'form',t.chiefs[2],formIndex=0,values=[dict(value=v) for v in [2,3,8,'合格','人工记录']],comment='含上下限边界'));ok(action(second,'submit',t.chiefs[2]));ok(action(second,'approve',t.leader,qualifiedQuantity=5,comment=''))
  check('inclusive range, single lower/upper bounds and manual text work together')
  # A copied template owns its forms and never follows later updates to its source.
  clone=ok(q('/templates',dict(name=t.marker+' copy',forms=updated)));template_ids.append(clone)
  custom=[dict(name='独立分表',items=[dict(name='独立指标',max=1)])]
  ok(binding('semi',None,version=1,forms=custom));ok(q('/templates',dict(id=tid,version=2,name=t.marker,forms=forms)))
  rows=ok(q('/standards'));own=next(r for r in rows if r['bar_code']==code and r['inspection_kind']=='semi')
  check('product can detach shared template into independent standards',own['template_id'] is None and own['forms'][0]['name']=='独立分表')
  ts=ok(q('/templates'));check('copied template is independent and binding count updates',next(x for x in ts if x['id']==clone)['forms'][0]['items'][0]['max']==2 and next(x for x in ts if x['id']==tid)['binding_count']==1)
  sql(f'UPDATE jsh_factory_quality_template SET tenant_id=999999 WHERE id={clone} AND tenant_id=63')
  try:
   denied(q('/templates',dict(id=clone,version=1,name=t.marker+' stolen',forms=forms)));denied(binding('semi',clone,version=2));check('cross-tenant template read/write and binding isolated',all(x['id']!=clone for x in ok(q('/templates'))))
  finally:sql(f'UPDATE jsh_factory_quality_template SET tenant_id=63 WHERE id={clone} AND tenant_id=999999')
  if '--preview' in sys.argv:
   print(json.dumps(dict(headId=head,inspectionId=first,code=code,templateId=tid)),flush=True);input('Preview ready; Enter cleans fixtures: ')
  print(json.dumps(dict(passed=checks,count=len(checks)),ensure_ascii=False,indent=2))
 finally:
  if t.ids:
   keys=','.join(map(str,t.ids));sql(f'DELETE h FROM jsh_factory_quality_history h JOIN jsh_factory_inspection i ON i.id=h.inspection_id AND i.tenant_id=h.tenant_id WHERE i.tenant_id=63 AND i.head_id IN({keys});DELETE FROM jsh_factory_quality_transfer WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_finished_batch WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_inspection WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_production_report WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_production_start WHERE tenant_id=63 AND head_id IN({keys})')
  sql('DELETE FROM jsh_factory_quality_standard WHERE tenant_id=63 AND bar_code IN('+quoted(code)+','+quoted(code+'-B')+')')
  if template_ids:sql('DELETE FROM jsh_factory_quality_template WHERE tenant_id=63 AND id IN('+','.join(map(str,template_ids))+')')
  sql("DELETE FROM jsh_factory_quality_history WHERE tenant_id=63 AND inspection_id IS NULL AND ((action='standard' AND JSON_UNQUOTE(JSON_EXTRACT(payload_json,'$.barCode')) IN("+quoted(code)+','+quoted(code+'-B')+")) OR (action='quality_template' AND JSON_UNQUOTE(JSON_EXTRACT(payload_json,'$.name')) LIKE "+quoted(t.marker+'%')+") OR (action='configure' AND JSON_CONTAINS(payload_json,'"+str(t.user_ids[2])+"','$.inspectorIds')))")
  if standard_role:sql(f"DELETE FROM jsh_user_business WHERE tenant_id=63 AND type='RoleFunctions' AND key_id='{standard_role}';DELETE FROM jsh_role WHERE tenant_id=63 AND id={standard_role}")
  sql('DELETE FROM jsh_factory_quality_config WHERE tenant_id=63')
  if old:
   c=json.loads(old);sql(f"INSERT INTO jsh_factory_quality_config VALUES(63,{int(c['director_id'])},{quoted(c['inspectors_json'])},{quoted(c['updated_at'])})")

