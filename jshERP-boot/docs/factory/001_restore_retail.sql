-- Restore the four retail menus supplied as enabled in the upstream seed database.
START TRANSACTION;
UPDATE jsh_function
SET enabled = b'1'
WHERE url IN ('/billC', '/bill/retail_out', '/bill/retail_back', '/report/retail_out_report');
COMMIT;
