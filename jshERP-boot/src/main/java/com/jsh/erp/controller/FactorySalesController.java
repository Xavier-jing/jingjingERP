package com.jsh.erp.controller;
import com.alibaba.fastjson.JSONObject;
import com.jsh.erp.service.FactorySalesService;
import org.springframework.web.bind.annotation.*;
import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import java.util.*;
@RestController
@RequestMapping("/factorySales")
public class FactorySalesController {
 @Resource private FactorySalesService service;
 private Map<String,Object> ok(Object data){Map<String,Object> r=new HashMap<>();r.put("code",200);r.put("data",data);return r;}
 @GetMapping("/options") public Object options()throws Exception{return ok(service.options());}
 @PostMapping("/reviewer") public Object reviewer(@RequestBody JSONObject body)throws Exception{service.configure(body.getLong("reviewerId"));return ok(null);}
 @GetMapping("/list") public Object list(@RequestParam(defaultValue="")String keyword,@RequestParam(defaultValue="")String state,@RequestParam(defaultValue="1")int page,@RequestParam(defaultValue="10")int size,@RequestParam Map<String,String> filters)throws Exception{return ok(service.list(keyword,state,page,size,filters));}
 @GetMapping("/{id}") public Object detail(@PathVariable Long id)throws Exception{return ok(service.detail(id));}
 @PostMapping("/delete") public Object delete(@RequestBody JSONObject body)throws Exception{service.deleteOrders(body.getJSONArray("orders"));return ok(null);}
 @PostMapping("/save") public Object save(@RequestBody JSONObject body,HttpServletRequest request)throws Exception{return ok(service.save(body,request));}
 @PostMapping("/{id}/action") public Object action(@PathVariable Long id,@RequestBody JSONObject body)throws Exception{service.action(id,body);return ok(null);}
}
