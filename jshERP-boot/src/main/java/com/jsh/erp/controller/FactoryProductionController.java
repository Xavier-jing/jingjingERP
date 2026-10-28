package com.jsh.erp.controller;
import com.alibaba.fastjson.JSONObject;
import com.jsh.erp.service.FactoryProductionService;
import org.springframework.web.bind.annotation.*;
import javax.annotation.Resource;
import java.util.*;
@RestController
@RequestMapping("/factoryProduction")
public class FactoryProductionController {
 @Resource private FactoryProductionService service;
 private Map<String,Object> ok(Object value){Map<String,Object> result=new HashMap<>();result.put("code",200);result.put("data",value);return result;}
 @GetMapping("/options") public Object options()throws Exception{return ok(service.options());}
 @PostMapping("/config") public Object config(@RequestBody JSONObject body)throws Exception{service.configure(body);return ok(null);}
 @GetMapping("/list") public Object list(@RequestParam(defaultValue="")String keyword,@RequestParam(defaultValue="")String state,@RequestParam(defaultValue="1")int page,@RequestParam(defaultValue="10")int size)throws Exception{return ok(service.list(keyword,state,page,size));}
 @GetMapping("/source/{id}") public Object source(@PathVariable long id)throws Exception{return ok(service.source(id));}
 @GetMapping("/{id}") public Object detail(@PathVariable long id)throws Exception{return ok(service.detail(id));}
 @PostMapping("/{id}/save") public Object save(@PathVariable long id,@RequestBody JSONObject body)throws Exception{service.save(id,body);return ok(null);}
 @PostMapping("/{id}/action") public Object action(@PathVariable long id,@RequestBody JSONObject body)throws Exception{service.action(id,body);return ok(null);}
 @PostMapping("/{id}/distribute") public Object distribute(@PathVariable long id,@RequestBody JSONObject body)throws Exception{service.distribute(id,body);return ok(null);}
 @PostMapping("/{id}/plan") public Object plan(@PathVariable long id,@RequestBody JSONObject body)throws Exception{service.plan(id,body);return ok(null);}
 @PostMapping("/{id}/execution") public Object execution(@PathVariable long id,@RequestBody JSONObject body)throws Exception{service.execution(id,body);return ok(null);}
}
