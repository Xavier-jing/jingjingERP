from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
exec(Path(__file__).with_name('factory_stock_workflow.py').read_text(encoding='utf-8-sig').split("\nseller=login('jsh');admin")[0])

def denied(result):
 assert result['code']==409,result
 return result

class WorkshopFixture:
 def __init__(self):
  self.ids=[];self.raw_ids=[];self.receipts=[];self.user_ids=[];self.tokens=[];self.role_id=None;self.changed=False
  self.marker='WORKSHOP-TEST-'+uuid.uuid4().hex[:10]
  value=sql("SELECT JSON_OBJECT('reviewer_id',reviewer_id,'coordinator_id',coordinator_id,'workshop1_director_id',workshop1_director_id,'workshop2_director_id',workshop2_director_id,'workshop3_director_id',workshop3_director_id,'updated_at',DATE_FORMAT(updated_at,'%Y-%m-%d %H:%i:%s')) FROM jsh_factory_production_config WHERE tenant_id=63")
  self.old=json.loads(value) if value else None
 def __enter__(self):
  try:
   assert not sql("SELECT head_id FROM jsh_factory_production_task WHERE tenant_id=63 AND workflow_status='pending' LIMIT 1"),'Real pending production tasks exist; do not reconfigure'
   self.seller=login('jsh');self.leader=login('test123');self.admin=login('admin');self.tokens=[self.seller,self.leader,self.admin]
   sql(f"INSERT INTO jsh_role(name,type,enabled,tenant_id,delete_flag) VALUES('{self.marker}','全部数据',1,63,'0')")
   self.role_id=int(sql(f"SELECT id FROM jsh_role WHERE name='{self.marker}' AND tenant_id=63"))
   menus=sql("SELECT id FROM jsh_function WHERE url IN('/factory/production_task','/factory/material_request','/factoryProduction')").split()
   functions=''.join('['+value+']' for value in menus)
   sql(f"INSERT INTO jsh_user_business(type,key_id,value,tenant_id,delete_flag) VALUES('RoleFunctions','{self.role_id}','{functions}',63,'0')")
   self.chiefs=[]
   for w in range(1,4):
    name='ws_'+uuid.uuid4().hex[:12]
    sql(f"INSERT INTO jsh_user(username,login_name,password,status,tenant_id,delete_flag,ismanager,isystem,leader_flag) SELECT '{name}','{name}',password,0,63,'0',ismanager,isystem,leader_flag FROM jsh_user WHERE id=131 AND tenant_id=63")
    user=int(sql(f"SELECT id FROM jsh_user WHERE login_name='{name}' AND tenant_id=63"));self.user_ids.append(user)
    sql(f"INSERT INTO jsh_user_business(type,key_id,value,tenant_id,delete_flag) VALUES('UserRole','{user}','[{self.role_id}]',63,'0')")
    token=login(name);self.chiefs.append(token);self.tokens.append(token)
   self.config={'reviewerId':131,'coordinatorId':63,**{'workshop'+str(w)+'DirectorId':self.user_ids[w-1] for w in range(1,4)}}
   ok(api('/factoryProduction/config',self.config,self.seller));self.changed=True
   return self
  except Exception:
   self.close();raise
 def __exit__(self,*args):self.close()
 def prod(self,path,body=None,token=None):return api('/factoryProduction'+path,body,token or self.seller)
 def detail(self,i):return ok(self.prod('/'+str(i)))
 def action(self,i,action,token=None,workshop=None,version=None,**extra):
  return self.prod('/'+str(i)+'/action',dict(version=self.detail(i)['version'] if version is None else version,action=action,workshopNo=workshop,**extra),token)
 def warehouse(self,i,q=0):
  d=ok(api('/factoryStock/'+str(i),token=self.seller));ok(api('/factoryStock/'+str(i)+'/save',{'version':d['version'],'confirmed':True,'allocations':[] if not q else [{'lineNo':0,'depotId':14,'batchNumber':'DEMO-STOCK-A','quantity':str(q)}]},self.seller))
 def order(self,two=False):
  time.sleep(1.1);lines=[dict(barCode='FACTORY-DEMO-620',quantity=10,price=10)]
  if two:lines.append(dict(barCode='FACTORY-DEMO-621',quantity=3,price=20))
  i=ok(api('/factorySales/save',{'customerId':58,'deliveryDate':'2026-11-20','remark':self.marker,'lines':lines},self.seller));self.ids.append(i)
  sql(f"UPDATE jsh_factory_sales_order SET workflow_status='approved' WHERE head_id={i} AND tenant_id=63;UPDATE jsh_depot_head SET status='1' WHERE id={i} AND tenant_id=63")
  self.warehouse(i);return i
 def payload(self,i,existing=False):
  source=ok(self.prod('/source/'+str(i)))
  return dict(version=self.detail(i)['version'] if existing else None,taskTime='2026-11-01T09:30',requirements='Test requirements',lines=[dict(lineNo=line['lineNo'],productionQuantity=line['missing'],adjustReason='') for line in source['stock']['lines']])
 def draft(self,i):ok(self.prod('/'+str(i)+'/save',self.payload(i)))
 def approved(self,i):self.draft(i);ok(self.action(i,'submit'));ok(self.action(i,'approve',self.leader))
 def distribute(self,i,routes,token=None,**extra):return self.prod('/'+str(i)+'/distribute',dict(version=self.detail(i)['version'],routes=routes,**extra),token)
 def accept(self,i,w,**extra):return self.action(i,'accept',self.chiefs[w-1],w,**extra)
 def assignments(self,i,w):
  grouped={}
  for row in self.detail(i)['routes']:
   if row['workshopNo']!=w:continue
   key=(row['lineNo'],row['stageNo']);grouped[key]=grouped.get(key,Decimal(0))+Decimal(str(row['quantity']))
  return [dict(lineNo=line,stageNo=stage,workshopNo=w,quantity=str(q),leader='Leader '+str(w),staff='Staff '+str(w),shift='Day',startDate='2026-11-01',endDate='2026-11-10') for (line,stage),q in grouped.items()]
 def plan(self,i,w,rows=None,token=None,**extra):return self.prod('/'+str(i)+'/plan',dict(version=self.detail(i)['version'],workshopNo=w,plan=rows if rows is not None else self.assignments(i,w),**extra),token or self.chiefs[w-1])
 def seed_raw(self,unit,bat):
  code='RAWTEST-'+uuid.uuid4().hex[:12]
  sql(f"INSERT INTO jsh_material(name,unit,enabled,tenant_id,delete_flag,enable_serial_number,enable_batch_number) VALUES('{self.marker}','{unit}',1,63,'0','0','{'1' if bat else '0'}')")
  material=int(sql(f"SELECT id FROM jsh_material WHERE name='{self.marker}' AND unit='{unit}' AND tenant_id=63 ORDER BY id DESC LIMIT 1"));self.raw_ids.append(material)
  sql(f"INSERT INTO jsh_material_extend(material_id,bar_code,commodity_unit,default_flag,tenant_id,delete_flag) VALUES({material},'{code}','{unit}','1',63,'0')")
  time.sleep(1.1);number=self.marker+'-'+str(material);head=dict(type='入库',subType='其它',number=number,status='1',operTime='2026-10-23 12:00:00',remark=self.marker,totalPrice=40,discountLastMoney=40,changeAmount=0,debt=0,discount=0,discountMoney=0,otherMoney=0)
  row=dict(barCode=code,unit=unit,operNumber=20,depotId=14,batchNumber=bat,unitPrice=2,allPrice=40,taxRate=0,taxMoney=0,taxLastMoney=40)
  r=api('/depotHead/addDepotHeadAndDetail',dict(info=json.dumps(head,ensure_ascii=False),rows=json.dumps([row],ensure_ascii=False)),self.seller);assert r['code']==200,r
  self.receipts.append(int(sql(f"SELECT id FROM jsh_depot_head WHERE tenant_id=63 AND number='{number}'")));return code
 def close(self):
  posted=[]
  try:
   if self.ids:
    keys=','.join(str(i) for i in self.ids)
    req=sql(f"SELECT id FROM jsh_factory_material_request WHERE tenant_id=63 AND task_head_id IN({keys})").split()
    posted=[int(x) for x in sql(f"SELECT ledger_head_id FROM jsh_factory_material_request WHERE tenant_id=63 AND task_head_id IN({keys}) AND ledger_head_id IS NOT NULL").split()]
    if req:sql(f"DELETE FROM jsh_factory_material_history WHERE tenant_id=63 AND request_id IN({','.join(req)})")
    sql(f"DELETE FROM jsh_factory_material_request WHERE tenant_id=63 AND task_head_id IN({keys});DELETE FROM jsh_factory_workshop_task WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_production_history WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_production_task WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_stock_reservation WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_stock_check WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_stock_history WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_sales_history WHERE tenant_id=63 AND head_id IN({keys});DELETE FROM jsh_factory_sales_order WHERE tenant_id=63 AND head_id IN({keys})")
   allheads=self.ids+self.receipts+posted
   if allheads:
    keys=','.join(str(i) for i in allheads);sql(f"DELETE FROM jsh_depot_item WHERE tenant_id=63 AND header_id IN({keys});DELETE FROM jsh_depot_head WHERE tenant_id=63 AND id IN({keys})")
   if self.raw_ids:
    keys=','.join(str(i) for i in self.raw_ids);sql(f"DELETE FROM jsh_material_current_stock WHERE tenant_id=63 AND material_id IN({keys});DELETE FROM jsh_material_extend WHERE tenant_id=63 AND material_id IN({keys});DELETE FROM jsh_material WHERE tenant_id=63 AND id IN({keys}) AND name='{self.marker}'")
   if self.changed:
    if self.old:
     fields=['reviewer_id','coordinator_id','workshop1_director_id','workshop2_director_id','workshop3_director_id'];parts=','.join(key+'='+(str(int(self.old[key])) if self.old[key] is not None else 'NULL') for key in fields);sql("UPDATE jsh_factory_production_config SET "+parts+",updated_at='"+self.old['updated_at']+"' WHERE tenant_id=63")
    else:sql("DELETE FROM jsh_factory_production_config WHERE tenant_id=63")
   for token in self.tokens:api('/user/logout',token=token)
   if self.user_ids:
    keys=','.join(str(i) for i in self.user_ids);sql(f"DELETE FROM jsh_user_business WHERE tenant_id=63 AND type='UserRole' AND key_id IN({keys});DELETE FROM jsh_log WHERE tenant_id=63 AND user_id IN({keys});DELETE FROM jsh_user WHERE tenant_id=63 AND id IN({keys})")
   if self.role_id:sql(f"DELETE FROM jsh_user_business WHERE tenant_id=63 AND type='RoleFunctions' AND key_id='{self.role_id}';DELETE FROM jsh_role WHERE tenant_id=63 AND id={self.role_id} AND name='{self.marker}'")
  finally:f.unlink(missing_ok=True)
