from pathlib import Path
from urllib.parse import urlencode
s=Path(__file__).with_name('factory_stock_workflow.py').read_text(encoding='utf-8-sig');exec(s[:s.index("\nseller=login('jsh');admin")])
t=login('jsh');ids=[];marker='QUERY-TEST-'+uuid.uuid4().hex[:8];checks=[]
def listing(**kw):return ok(api('/factoryStock/list?'+urlencode(kw),token=t))
def detail(i):return ok(api('/factoryStock/'+str(i),token=t))
def reserve(i,q):
 d=detail(i);return ok(api('/factoryStock/'+str(i)+'/save',{'version':d['version'],'confirmed':True,'allocations':[] if q==0 else [{'lineNo':0,'depotId':14,'batchNumber':'DEMO-STOCK-A','quantity':str(q)}]},t))
try:
 opts=ok(api('/factoryStock/options',token=t));assert opts['customers'] and opts['depots'] and opts['users'];checks.append('tenant query options available')
 for n in range(2):
  time.sleep(1.1);i=ok(api('/factorySales/save',{'customerId':58+n,'deliveryDate':'2026-11-10','remark':marker+str(n),'lines':[{'barCode':'FACTORY-DEMO-620','quantity':'2.5','price':'10'}]},t));ids.append(i);sql(f"UPDATE jsh_factory_sales_order SET workflow_status='approved' WHERE head_id={i} AND tenant_id=63;UPDATE jsh_depot_head SET status='1',create_time='{'2026-10-23' if n==0 else '2020-01-01'} 12:00:00' WHERE id={i} AND tenant_id=63")
 i,j=ids;number=detail(i)['number'];assert listing(number=number)['total']==1;assert listing(number=number+'NO')['total']==0
 assert listing(number=number,material='WHA-413')['total']==1;assert listing(number=number,material='NO-SUCH-PRODUCT')['total']==0;assert listing(number=number,material='FACTORY-DEMO-620')['total']==1;checks.append('number and product information filters')
 assert listing(remark=marker)['total']==2;assert listing(remark=marker,beginDate='2026-10-23',endDate='2026-10-23')['total']==1;assert listing(number=number,beginDate='2020-01-01',endDate='2020-01-01')['total']==0;blocked(api('/factoryStock/list?beginDate=2026-10-24&endDate=2026-10-23',token=t));blocked(api('/factoryStock/list?beginDate=bad-date',token=t));checks.append('inclusive date range and invalid dates')
 assert listing(remark=marker,customerId=58,creatorId=63)['total']==1;assert listing(number=number,customerId=59)['total']==0;assert listing(number=number,creatorId=131)['total']==0;checks.append('customer, operator and remark combined filters')
 assert listing(number=number,stockState='unchecked')['total']==1;assert listing(number=number,depotId=14)['total']==0
 reserve(i,1);assert listing(number=number,stockState='partial',depotId=14)['total']==1;assert listing(number=number,depotId=15)['total']==0
 reserve(i,2.5);assert listing(number=number,stockState='ready')['total']==1;assert listing(number=number,stockState='partial')['total']==0
 reserve(i,0);assert listing(number=number,stockState='shortage')['total']==1;assert listing(number=number,stockState='unchecked')['total']==0;blocked(api('/factoryStock/list?stockState=invalid',token=t));blocked(api('/factoryStock/list?depotId=999999',token=t));checks.append('all four reservation states and permitted warehouse filter')
 page=listing(remark=marker,page=1,size=1);assert page['total']==2 and len(page['rows'])==1;assert listing(remark=marker,page=2,size=1)['rows'][0]['head_id']!=page['rows'][0]['head_id'];checks.append('filters applied before pagination; clearing restores matches')
 print(json.dumps({'passed':checks},ensure_ascii=False,indent=2));(b/'stock-query-test-result.json').write_text(json.dumps({'passed':checks},ensure_ascii=False,indent=2),encoding='utf-8')
finally:
 if ids:
  keys=','.join(str(int(x)) for x in ids)
  sql(f"DELETE FROM jsh_factory_stock_reservation WHERE head_id IN({keys}) AND tenant_id=63;DELETE FROM jsh_factory_stock_check WHERE head_id IN({keys}) AND tenant_id=63;DELETE FROM jsh_factory_stock_history WHERE head_id IN({keys}) AND tenant_id=63;DELETE FROM jsh_factory_sales_history WHERE head_id IN({keys}) AND tenant_id=63;DELETE FROM jsh_factory_sales_order WHERE head_id IN({keys}) AND tenant_id=63;DELETE FROM jsh_depot_item WHERE header_id IN({keys}) AND tenant_id=63;DELETE FROM jsh_depot_head WHERE id IN({keys}) AND tenant_id=63 AND remark LIKE '{marker}%' ")
 api('/user/logout',token=t);f.unlink(missing_ok=True)
