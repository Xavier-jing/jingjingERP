package com.jsh.erp.controller;
import com.alibaba.fastjson.JSONObject;
import com.jsh.erp.service.FactoryOrderChangeService;
import org.springframework.web.bind.annotation.*;
import javax.annotation.Resource;
import java.util.*;
@RestController
@RequestMapping("/factoryOrderChanges")
public class FactoryOrderChangeController {
 @Resource private FactoryOrderChangeService service;
 private Object ok(Object data){Map<String,Object> r=new HashMap<>();r.put("code",200);r.put("data",data);return r;}
 @GetMapping("/options") public Object options()throws Exception{return ok(service.options());}
 @PostMapping("/config") public Object config(@RequestBody JSONObject b)throws Exception{service.configure(b);return ok(null);}
 @GetMapping("/sources") public Object sources(@RequestParam(defaultValue="")String keyword,@RequestParam(defaultValue="1")int page)throws Exception{return ok(service.sources(keyword,page));}
 @GetMapping("/source/{id}") public Object source(@PathVariable long id)throws Exception{return ok(service.source(id));}
 @GetMapping("/list") public Object list(@RequestParam(defaultValue="")String keyword,@RequestParam(defaultValue="1")int page)throws Exception{return ok(service.list(keyword,page));}
 @PostMapping("/create") public Object create(@RequestBody JSONObject b)throws Exception{return ok(service.create(b));}
 @GetMapping("/{id}") public Object detail(@PathVariable long id)throws Exception{return ok(service.detail(id));}
 @PostMapping("/{id}/action") public Object action(@PathVariable long id,@RequestBody JSONObject b)throws Exception{service.action(id,b);return ok(null);}
}
