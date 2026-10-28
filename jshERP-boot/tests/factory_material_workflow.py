from factory_workshop_helpers import *
with WorkshopFixture() as ctx:
 seller=ctx.seller;director=ctx.chiefs[0];not_director=ctx.chiefs[1];admin=ctx.admin;ids=ctx.ids;raw_ids=ctx.raw_ids;receipt_ids=ctx.receipts;docs=[];checks=[];marker=ctx.marker;batch='RAW-'+uuid.uuid4().hex[:8];blocked=denied
 def mat(path,data=None,token=None):return api('/factoryMaterial'+path,data,token or director)
 def detail(i):return ok(mat('/'+str(i)))
 def action(i,act,token=None,version=None):
  if act=='confirm':time.sleep(1.1)
  return mat('/'+str(i)+'/action',{'action':act,'comment':'Test explanation','version':detail(i)['version'] if version is None else version},token)
 def physical(bar,bat=''):
  return ok(mat('/stock?barCode='+bar+'&depotId=14&batchNumber='+bat))['physical']
 def create(body):
  i=ok(mat('/save',body));docs.append(i);return i
 def save_body(kind='issue',q=5,reference=None,barcode=None,bat=None):
  return dict(taskId=task_id,kind=kind,referenceId=reference,lineNo=0,stageNo=1,workshopNo=1,reason='' if kind=='issue' else 'Test reason',lines=[dict(barCode=barcode or raw_bar,depotId=14,batchNumber=batch if bat is None else bat,quantity=str(q),referenceLine=0 if kind=='return' else None)])
 def seed_raw(unit,bat):
  code='RAWTEST-'+uuid.uuid4().hex[:12]
  sql(f"INSERT INTO jsh_material(name,unit,enabled,tenant_id,delete_flag,enable_serial_number,enable_batch_number) VALUES('{marker}','{unit}',1,63,'0','0','{'1' if bat else '0'}');")
  material=int(sql(f"SELECT id FROM jsh_material WHERE name='{marker}' AND unit='{unit}' AND tenant_id=63 ORDER BY id DESC LIMIT 1"));raw_ids.append(material)
  sql(f"INSERT INTO jsh_material_extend(material_id,bar_code,commodity_unit,default_flag,tenant_id,delete_flag) VALUES({material},'{code}','{unit}','1',63,'0')")
  time.sleep(1.1);number=marker+'-'+str(material);head=dict(type='入库',subType='其它',number=number,status='1',operTime='2026-10-23 12:00:00',remark=marker,totalPrice=40,discountLastMoney=40,changeAmount=0,debt=0,discount=0,discountMoney=0,otherMoney=0)
  row=dict(barCode=code,unit=unit,operNumber=20,depotId=14,batchNumber=bat,unitPrice=2,allPrice=40,taxRate=0,taxMoney=0,taxLastMoney=40)
  r=api('/depotHead/addDepotHeadAndDetail',{'info':json.dumps(head,ensure_ascii=False),'rows':json.dumps([row],ensure_ascii=False)},seller);assert r['code']==200,r
  receipt_ids.append(int(sql(f"SELECT id FROM jsh_depot_head WHERE tenant_id=63 AND number='{number}'")));return code
 blocked(mat('/options',token=admin));opts=ok(mat('/options'));assert opts['canRequest'];assert ok(mat('/options',token=not_director))['workshopNos']==[2];checks.append('business tenant, three workshop identities and independent warehouse permission')
 time.sleep(1.1);task_id=ok(api('/factorySales/save',{'customerId':58,'deliveryDate':'2026-11-20','remark':marker,'lines':[{'barCode':'FACTORY-DEMO-620','quantity':'10','price':'10'}]},seller));ids.append(task_id)
 plan=[dict(lineNo=0,stageNo=1,workshopNo=1,quantity=10,leader='Leader',staff='A,B',shift='Day',startDate='2026-11-01',endDate='2026-11-10')]
 sql(f"UPDATE jsh_factory_sales_order SET workflow_status='approved' WHERE head_id={task_id};UPDATE jsh_depot_head SET status='1' WHERE id={task_id}")
 d=ok(api('/factoryStock/'+str(task_id),token=seller));ok(api('/factoryStock/'+str(task_id)+'/save',{'version':d['version'],'confirmed':True,'allocations':[]},seller))
 # Scheduled parent is a fixture; the production workflow has a separate integration suite.
 lines=ok(api('/factorySales/'+str(task_id),token=seller))['stock']['lines'];lines[0]['productionQuantity']=10;lines[0]['adjustReason']=''
 routes=[dict(lineNo=0,stageNo=1,workshopNo=1,quantity=10),dict(lineNo=0,stageNo=2,workshopNo=2,quantity=10)]
 sql(f"INSERT INTO jsh_factory_production_task(head_id,tenant_id,number,workflow_status,version,requirements,lines_json,plan_json,created_by,created_at,updated_at,task_time,route_json) VALUES({task_id},63,'{marker}','approved',1,'Test','{json.dumps(lines,ensure_ascii=False)}','{json.dumps(plan)}',63,NOW(),NOW(),'2026-11-01T09:30','{json.dumps(routes)}')")
 raw_bar=seed_raw('吨',batch);kg_bar=seed_raw('千克','')
 blocked(mat('/save',save_body()));sql(f"UPDATE jsh_factory_production_task SET workflow_status='distributed' WHERE head_id={task_id};INSERT INTO jsh_factory_workshop_task(tenant_id,head_id,workshop_no,workflow_status,updated_at) VALUES(63,{task_id},1,'accepted',NOW()),(63,{task_id},2,'pending',NOW())");blocked(mat('/save',save_body()));sql(f"UPDATE jsh_factory_workshop_task SET workflow_status='scheduled' WHERE head_id={task_id} AND tenant_id=63 AND workshop_no=1")
 bad=save_body();bad['workshopNo']=3;blocked(mat('/save',bad));blocked(mat('/save',save_body(),not_director));bad=save_body();bad['lines'][0]['quantity']='-1';blocked(mat('/save',bad));checks.append('own workshop must be scheduled; another pending workshop does not block issuing')
 i=create(save_body());assert ok(mat('/list?taskId='+str(task_id),token=not_director))['total']==0;cross=save_body();cross.update(id=i,version=detail(i)['version']);blocked(mat('/save',cross,not_director));blocked(action(i,'submit',not_director));assert physical(raw_bar,batch)==20;stale=detail(i)['version'];ok(action(i,'submit'));blocked(action(i,'withdraw',version=stale));bad={'version':detail(i)['version'],'action':'reject','comment':''};blocked(mat('/'+str(i)+'/action',bad,seller));ok(action(i,'reject',seller));body=save_body();body.update(id=i,version=detail(i)['version']);ok(mat('/save',body));ok(action(i,'submit'));checks.append('draft and submit do not change stock; return/edit/resubmit and stale protection')
 shortage=create(save_body(q=21));ok(action(shortage,'submit'));blocked(action(shortage,'confirm',seller));assert physical(raw_bar,batch)==20 and detail(shortage)['ledger_head_id'] is None;ok(action(shortage,'cancel'));checks.append('insufficient stock rolls back without a ledger entry')
 blocked(action(i,'confirm',director));ok(action(i,'confirm',seller));assert physical(raw_bar,batch)==15;ledger=detail(i)['ledger_head_id'];assert sql(f"SELECT total_price FROM jsh_depot_head WHERE id={ledger} AND tenant_id=63").startswith('10.');blocked(action(i,'confirm',seller));assert physical(raw_bar,batch)==15;checks.append('warehouse confirmation posts once to original stock ledger using inventory cost')
 item_id=int(sql(f"SELECT id FROM jsh_depot_item WHERE header_id={ledger} AND tenant_id=63 LIMIT 1"))
 assert api('/depotHead/batchSetStatus',{'ids':str(ledger),'status':'0'},seller)['code']==409;assert api('/depotHead/delete?id='+str(ledger),token=seller,method='DELETE')['code']==409;assert api('/depotHead/updateDepotHeadAndDetail',{'info':json.dumps({'id':ledger}),'rows':'[]'},seller,method='PUT')['code']==409;assert physical(raw_bar,batch)==15;checks.append('legacy delete, unapproval and ledger edit cannot bypass material confirmation')
 body=save_body(kind='supplement',q=2);bad=dict(body,reason='');blocked(mat('/save',bad));supp=create(body);ok(action(supp,'submit'));ok(action(supp,'confirm',seller));assert physical(raw_bar,batch)==13;checks.append('supplemental material needs a reason and posts against the same task')
 bad=save_body(kind='return',q=6,reference=i);blocked(mat('/save',bad));ret=create(save_body(kind='return',q=2,reference=i));ok(action(ret,'submit'));assert physical(raw_bar,batch)==13;ok(action(ret,'confirm',seller));assert physical(raw_bar,batch)==15;assert sql(f"SELECT total_price FROM jsh_depot_head WHERE id={detail(ret)['ledger_head_id']} AND tenant_id=63").startswith('4.');assert detail(i)['returned']['0']==2;checks.append('partial returns reference issued batches and add stock only on receipt')
 a=create(save_body(kind='return',q=3,reference=i));bdoc=create(save_body(kind='return',q=3,reference=i));ok(action(a,'submit'));ok(action(bdoc,'submit'));time.sleep(1.1)
 requests=[(doc,detail(doc)['version']) for doc in [a,bdoc]]
 with ThreadPoolExecutor(2) as pool:results=list(pool.map(lambda pair:mat('/'+str(pair[0])+'/action',{'action':'confirm','version':pair[1]},seller),requests))
 assert sum(r['code']==200 for r in results)==1 and all(r['code'] in (200,409) for r in results),results;assert physical(raw_bar,batch)==18;assert detail(i)['returned']['0']==5;checks.append('concurrent returns cannot exceed issued quantity')
 loser=[a,bdoc][next(n for n,r in enumerate(results) if r['code']!=200)];ok(action(loser,'cancel'))
 kg=create(save_body(q=4,barcode=kg_bar,bat=''));ok(action(kg,'submit'));ok(action(kg,'confirm',seller));assert physical(kg_bar)==16 and detail(kg)['lines'][0]['unit']=='千克';checks.append('non-batch raw materials preserve their basic units')
 left=create(save_body(q=12));right=create(save_body(q=12));ok(action(left,'submit'));ok(action(right,'submit'));time.sleep(1.1);requests=[(doc,detail(doc)['version']) for doc in [left,right]]
 with ThreadPoolExecutor(2) as pool:results=list(pool.map(lambda pair:mat('/'+str(pair[0])+'/action',{'action':'confirm','version':pair[1]},seller),requests))
 assert sum(r['code']==200 for r in results)==1 and all(r['code'] in (200,409) for r in results),results;assert physical(raw_bar,batch)==6;checks.append('concurrent material issues cannot oversell physical stock')
 prod=ok(api('/factoryProduction/'+str(task_id),token=director));assert any(row['id']==i and row['workflow_status']=='confirmed' for row in prod['materials']);bad_plan=json.loads(json.dumps(plan));bad_plan[0]['workshopNo']=2;blocked(ctx.distribute(task_id,[dict(lineNo=0,stageNo=1,workshopNo=3,quantity=10),dict(lineNo=0,stageNo=2,workshopNo=2,quantity=10)]));checks.append('production shows material progress and cannot remove referenced workshop routes')
 multi=save_body(q=7);multi['lines'].append(dict(barCode=kg_bar,depotId=14,batchNumber='',quantity='2'));multi_id=create(multi);ok(action(multi_id,'submit'));blocked(action(multi_id,'confirm',seller));assert physical(raw_bar,batch)==6 and physical(kg_bar)==16;ok(action(multi_id,'withdraw'));multi['lines'][0]['quantity']='1';multi.update(id=multi_id,version=detail(multi_id)['version']);ok(mat('/save',multi));ok(action(multi_id,'submit'));ok(action(multi_id,'confirm',seller));assert physical(raw_bar,batch)==5 and physical(kg_bar)==14;checks.append('multi-material confirmation is atomic and keeps different units separate')
 assert ok(mat('/list?taskId='+str(task_id)+'&size=1'))['total']==len(docs);checks.append('task filtering and pagination include all material documents')
 print(json.dumps({'passed':checks},ensure_ascii=False,indent=2));(Path('work')/'material-test-result.json').write_text(json.dumps({'passed':checks},ensure_ascii=False,indent=2),encoding='utf-8')
