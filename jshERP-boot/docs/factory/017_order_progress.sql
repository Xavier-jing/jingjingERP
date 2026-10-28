INSERT INTO jsh_function(number,name,parent_number,url,component,state,sort,enabled,type,push_btn,icon,delete_flag)
 SELECT 'factoryOrderProgress','订单全过程进度看板',parent_number,'/factory/order_progress','/factory/OrderProgressList',b'0','0320',b'1','电脑版','1','dashboard','0'
 FROM jsh_function WHERE id=242 AND NOT EXISTS(SELECT 1 FROM jsh_function WHERE url='/factory/order_progress');
SET @board=(SELECT id FROM jsh_function WHERE url='/factory/order_progress');
SET @production=(SELECT id FROM jsh_function WHERE url='/factory/production_task');
SET @salesRoot=(SELECT id FROM jsh_function WHERE number=(SELECT parent_number FROM jsh_function WHERE id=242));
UPDATE jsh_user_business SET value=CONCAT(IFNULL(value,''),'[',@salesRoot,'][',@board,']')
 WHERE type='RoleFunctions' AND (value LIKE '%[242]%' OR value LIKE CONCAT('%[',@production,']%'))
 AND value NOT LIKE CONCAT('%[',@board,']%');
