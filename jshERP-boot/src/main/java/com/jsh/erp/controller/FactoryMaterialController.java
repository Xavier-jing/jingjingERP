package com.jsh.erp.controller;
import com.alibaba.fastjson.JSONObject;
import com.jsh.erp.service.FactoryMaterialService;
import org.springframework.web.bind.annotation.*;
import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import java.util.*;
@RestController
@RequestMapping("/factoryMaterial")
public class FactoryMaterialController {
 @Resource private FactoryMaterialService service;
 private Map<String,Object> ok(Object data){Map<String,Object> r=new HashMap<>();r.put("code",200);r.put("data",data);return r;}
 @GetMapping("/options") public Object options()throws Exception{return ok(service.options());}
 @GetMapping("/source/{id}") public Object source(@PathVariable long id)throws Exception{return ok(service.source(id));}
 @GetMapping("/stock") public Object stock(@RequestParam String barCode,@RequestParam long depotId,@RequestParam(defaultValue="")String batchNumber)throws Exception{return ok(service.stock(barCode,depotId,batchNumber));}
 @GetMapping("/batches") public Object batches(@RequestParam String barCode,@RequestParam long depotId)throws Exception{return ok(service.batches(barCode,depotId));}
 @GetMapping("/list") public Object list(@RequestParam(defaultValue="0")long taskId,@RequestParam(defaultValue="")String keyword,@RequestParam(defaultValue="")String state,@RequestParam(defaultValue="1")int page,@RequestParam(defaultValue="10")int size)throws Exception{return ok(service.list(taskId,keyword,state,page,size));}
 @GetMapping("/{id}") public Object detail(@PathVariable long id)throws Exception{return ok(service.detail(id));}
 @PostMapping("/save") public Object save(@RequestBody JSONObject body)throws Exception{return ok(service.save(body));}
 @PostMapping("/{id}/action") public Object action(@PathVariable long id,@RequestBody JSONObject body,HttpServletRequest request)throws Exception{service.action(id,body,request);return ok(null);}
 @PostMapping("/{id}/delete") public Object delete(@PathVariable long id,@RequestBody JSONObject body)throws Exception{service.delete(id,body);return ok(null);}
}
