START TRANSACTION;
INSERT INTO jsh_function(number,name,parent_number,url,component,state,sort,enabled,type,push_btn,icon,delete_flag)
 SELECT 'factoryProgressRoot','业务看板','0','/factoryProgress','/layouts/TabLayout',b'0','0300',b'1','电脑版','1','dashboard','0'
 WHERE NOT EXISTS(SELECT 1 FROM jsh_function WHERE number='factoryProgressRoot');
SET @progressRoot=(SELECT id FROM jsh_function WHERE number='factoryProgressRoot');
SET @progressBoard=(SELECT id FROM jsh_function WHERE url='/factory/order_progress');
UPDATE jsh_function SET parent_number='factoryProgressRoot',name='订单全过程进度',sort='0301'
 WHERE id=@progressBoard;
UPDATE jsh_user_business SET value=CONCAT(IFNULL(value,''),'[',@progressRoot,']')
 WHERE type='RoleFunctions' AND value LIKE CONCAT('%[',@progressBoard,']%')
 AND value NOT LIKE CONCAT('%[',@progressRoot,']%');
COMMIT;
