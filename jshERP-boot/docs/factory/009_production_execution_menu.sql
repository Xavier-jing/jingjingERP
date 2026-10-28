INSERT INTO jsh_function(number,name,parent_number,url,component,state,sort,enabled,type,push_btn,icon,delete_flag)
 SELECT 'factory090103','开工与生产日报','factory0901','/factory/production_execution','/factory/ProductionExecutionList',b'0','0433',b'1','电脑版','1','form','0'
 WHERE NOT EXISTS(SELECT 1 FROM jsh_function WHERE url='/factory/production_execution');
SET @executionMenu=(SELECT id FROM jsh_function WHERE url='/factory/production_execution');
SET @taskMenu=(SELECT id FROM jsh_function WHERE url='/factory/production_task');
UPDATE jsh_user_business SET value=CONCAT(IFNULL(value,''),'[',@executionMenu,']')
 WHERE type='RoleFunctions' AND value LIKE CONCAT('%[',@taskMenu,']%') AND value NOT LIKE CONCAT('%[',@executionMenu,']%');
