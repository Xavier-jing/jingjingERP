from pathlib import Path
import os
os.environ.setdefault('ERP_WORK_DIR',str(Path(__file__).resolve().parents[2]/'.local-runtime'))
# Keep temporary connection configuration inside this checkout.
src=Path('jshERP-boot/tests/factory_workshop_helpers.py').read_text(encoding='utf-8');base=Path('jshERP-boot/tests').resolve()
stock=(base/'factory_stock_workflow.py').read_text(encoding='utf-8-sig').split("\nseller=login('jsh');admin")[0]
sales=(base/'factory_sales_workflow.py').read_text(encoding='utf-8').split("seller=login('jsh')")[0]
stock=stock[stock.index('from concurrent.futures'):].replace("b/'local/stock-test.cnf'","Path.cwd()/'execution-test.cnf'")
exec(sales);exec(stock)
src=src[src.index('def denied'):];exec(src)
with WorkshopFixture() as t:
 i=t.order();t.approved(i);ok(t.distribute(i,[dict(lineNo=0,stageNo=1,workshopNo=1,quantity=10)]));ok(t.accept(i,1));ok(t.plan(i,1))
 def record(action='start',token=None,**kw):
  return t.prod('/'+str(i)+'/execution',dict(version=t.detail(i)['version'],action=action,lineNo=0,stageNo=1,workshopNo=1,actualStart='2026-10-23T09:00',materialsReady=True,reportDate='2026-10-23',batchNumber='TEST-A',inputQuantity=6,outputQuantity=5,lossQuantity=1,**kw),token or t.chiefs[0])
 try:
  denied(record(token=t.seller));denied(record('report'));ok(record());denied(record());denied(t.plan(i,1));ok(record('report'));denied(record('report'))
  d=t.detail(i);assert len(d['starts'])==1 and len(d['reports'])==1
  payload=dict(version=d['version'],action='report',lineNo=0,stageNo=1,workshopNo=1,reportDate='2026-10-23',batchNumber='TEST-B',inputQuantity=7,outputQuantity=6,lossQuantity=1)
  denied(t.prod('/'+str(i)+'/execution',payload,t.chiefs[0]));payload.update(outputQuantity=5,inputQuantity=6);ok(t.prod('/'+str(i)+'/execution',payload,t.chiefs[0]))
  print('9 execution checks passed: permissions, start prerequisite, start, duplicate start, plan protection, report, duplicate report, quota, final output')
 finally:
  sql(f'DELETE FROM jsh_factory_production_report WHERE tenant_id=63 AND head_id={i};DELETE FROM jsh_factory_production_start WHERE tenant_id=63 AND head_id={i}')
