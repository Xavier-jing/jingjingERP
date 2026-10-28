-- Factory customization: hide retail navigation without removing historical bills.
-- Re-runnable. Menu enablement is read by FunctionService.getRoleFunction.
START TRANSACTION;
UPDATE jsh_function
SET enabled = b'0'
WHERE url IN ('/billC', '/bill/retail_out', '/bill/retail_back', '/report/retail_out_report');
COMMIT;
