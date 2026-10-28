from pathlib import Path
s=Path(__file__).with_name('factory_stock_workflow.py').read_text(encoding='utf-8-sig');exec(s[:s.index("\nseller=login('jsh');admin")])
seller=login('jsh');other=login('test123');ids=[];following=[];checks=[];marker='CONTROLS-TEST-'+uuid.uuid4().hex[:8]
options=ok(api('/factorySales/options',token=seller));reviewer=seller if options['reviewerId']==63 else other;nonreviewer=other if options['reviewerId']==63 else seller

def detail(i):return ok(api('/factorySales/'+str(i),token=seller))
def action(i,act,token=None,version=None):return api('/factorySales/'+str(i)+'/action',{'action':act,'version':detail(i)['version'] if version is None else version},token or seller)
def order():
 time.sleep(1.1)
 i=ok(api('/factorySales/save',{'customerId':58,'deliveryDate':'2026-11-10','remark':marker,'lines':[{'barCode':'FACTORY-DEMO-620','quantity':'2.5','price':'10'}]},seller));ids.append(i);return i

def state(i,value):sql(f"UPDATE jsh_factory_sales_order SET workflow_status='{value}' WHERE head_id={i} AND tenant_id=63; UPDATE jsh_depot_head SET status='{'1' if value=='approved' else '9' if value=='pending' else '0'}' WHERE id={i} AND tenant_id=63")
def remove(rows,token=None):return api('/factorySales/delete',{'orders':[{'id':i,'version':detail(i)['version']} for i in rows]},token or seller)
try:
 i=order();j=order()
 row=next(r for r in ok(api('/factorySales/list?size=100',token=seller))['rows'] if r['head_id']==i)
 assert row['material_count']==2.5 and row['total_price']==25 and 'materials_list' in row and 'discount_last_money' in row;checks.append('original-style columns have actual order data')
 blocked(remove([i],other));blocked(action(i,'delete',version=0));assert detail(i)['workflow_status']=='draft';checks.append('delete permission and stale version enforced')
 state(j,'approved');blocked(remove([i,j]));assert detail(i)['workflow_status']=='draft';checks.append('mixed-state batch delete rolls back all orders')
 blocked(action(j,'unapprove',nonreviewer));state(j,'pending');blocked(remove([j]));blocked(action(j,'unapprove',reviewer));state(j,'approved');checks.append('pending and approved delete denied; unapproval permission and state enforced')
 d=ok(api('/factoryStock/'+str(j),token=seller));ok(api('/factoryStock/'+str(j)+'/save',{'version':d['version'],'confirmed':True,'allocations':[{'lineNo':0,'depotId':14,'batchNumber':'DEMO-STOCK-A','quantity':'1'}]},seller))
 n=detail(j)['number'];sql(f"INSERT INTO jsh_depot_head(number,type,sub_type,tenant_id,link_number,remark,delete_flag) VALUES('{marker}-FOLLOW','出库','销售',63,'{n}','{marker}','0')");following.append(int(sql(f"SELECT id FROM jsh_depot_head WHERE number='{marker}-FOLLOW' AND tenant_id=63")))
 blocked(action(j,'unapprove',reviewer));assert detail(j)['stock']['reserved']==1;checks.append('downstream document blocks unapproval without releasing stock')
 sql(f"DELETE FROM jsh_depot_head WHERE id={following[0]} AND tenant_id=63 AND remark='{marker}'");following.clear()
 ok(action(j,'unapprove',reviewer));d=detail(j);assert d['workflow_status']=='draft' and d['stock']['reserved']==0 and any(h['action']=='unapprove' for h in d['history']);checks.append('reviewer unapproval resets draft and releases stock with history')
 state(i,'returned');ok(remove([i,j]));blocked(api('/factorySales/'+str(i),token=seller));blocked(api('/factorySales/'+str(j),token=seller));assert sql(f"SELECT COUNT(*) FROM jsh_factory_sales_history WHERE head_id IN({i},{j}) AND action='delete' AND tenant_id=63")=='2';assert sql(f"SELECT COUNT(*) FROM jsh_depot_item WHERE header_id IN({i},{j}) AND delete_flag='0' AND tenant_id=63")=='0';checks.append('draft and returned orders soft deleted; audit retained')
 print(json.dumps({'passed':checks},ensure_ascii=False,indent=2));(b/'sales-controls-test-result.json').write_text(json.dumps({'passed':checks},ensure_ascii=False,indent=2),encoding='utf-8')
finally:
 keys=','.join(str(int(x)) for x in ids)
 if ids:
  sql(f"DELETE FROM jsh_factory_stock_reservation WHERE head_id IN({keys}) AND tenant_id=63; DELETE FROM jsh_factory_stock_check WHERE head_id IN({keys}) AND tenant_id=63; DELETE FROM jsh_factory_stock_history WHERE head_id IN({keys}) AND tenant_id=63; DELETE FROM jsh_factory_sales_history WHERE head_id IN({keys}) AND tenant_id=63; DELETE FROM jsh_factory_sales_order WHERE head_id IN({keys}) AND tenant_id=63; DELETE FROM jsh_depot_item WHERE header_id IN({keys}) AND tenant_id=63; DELETE FROM jsh_depot_head WHERE id IN({keys}) AND tenant_id=63 AND remark='{marker}'")
 for i in following:sql(f"DELETE FROM jsh_depot_head WHERE id={i} AND tenant_id=63 AND remark='{marker}'")
 for t in [seller,other]:api('/user/logout',token=t)
 f.unlink(missing_ok=True)
