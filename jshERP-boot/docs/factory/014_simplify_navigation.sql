-- Hide unused navigation; keep historical bills, role grants and ledger APIs.
-- Re-runnable. Re-enable these URLs through administrator menu management if needed.
UPDATE jsh_function SET enabled=b'0'
WHERE url IN('/billC','/bill/retail_out','/bill/retail_back','/report/retail_out_report',
 '/system/member','/bill/assemble','/bill/disassemble','/bill/sale_out');
