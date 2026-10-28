package com.jsh.erp.controller;
import com.alibaba.fastjson.JSONObject;
import com.jsh.erp.service.FactoryStockService;
import org.springframework.web.bind.annotation.*;
import javax.annotation.Resource;
import java.util.*;
@RestController
@RequestMapping("/factoryStock")
public class FactoryStockController {
    @Resource private FactoryStockService service;
    private Map<String,Object> ok(Object data){Map<String,Object> r=new HashMap<>();r.put("code",200);r.put("data",data);return r;}
    @GetMapping("/list") public Object list(@RequestParam(defaultValue="")String keyword,@RequestParam(defaultValue="1")int page,@RequestParam(defaultValue="10")int size,@RequestParam Map<String,String> filters)throws Exception{return ok(service.list(keyword,page,size,filters));}
    @GetMapping("/options") public Object options()throws Exception{return ok(service.options());}
    @GetMapping("/{id}") public Object detail(@PathVariable long id)throws Exception{return ok(service.detail(id));}
    @GetMapping("/report/{id}") public Object report(@PathVariable long id)throws Exception{return ok(service.report(id));}
    @PostMapping("/{id}/save") public Object save(@PathVariable long id,@RequestBody JSONObject body)throws Exception{service.save(id,body);return ok(null);}
    @PostMapping("/{id}/release") public Object release(@PathVariable long id,@RequestBody JSONObject body)throws Exception{service.release(id,body);return ok(null);}
}
