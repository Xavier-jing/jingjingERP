package com.jsh.erp.controller;
import com.alibaba.fastjson.JSONObject;
import com.jsh.erp.service.FactoryShippingService;
import org.springframework.web.bind.annotation.*;
import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import java.util.*;

@RestController
@RequestMapping("/factoryShipping")
public class FactoryShippingController {
 @Resource private FactoryShippingService service;
 private Object ok(Object data){Map<String,Object> r=new HashMap<>();r.put("code",200);r.put("data",data);return r;}
 @GetMapping("/options") public Object options()throws Exception{return ok(service.options());}
 @PostMapping("/config") public Object config(@RequestBody JSONObject body)throws Exception{service.configure(body);return ok(null);}
 @GetMapping("/list") public Object list(@RequestParam(defaultValue="")String keyword,@RequestParam(defaultValue="1")int page)throws Exception{return ok(service.list(keyword,page));}
 @GetMapping("/{id}") public Object detail(@PathVariable long id)throws Exception{return ok(service.detail(id));}
 @PostMapping("/{id}/action") public Object action(@PathVariable long id,@RequestBody JSONObject body,HttpServletRequest request)throws Exception{service.action(id,body,request);return ok(null);}
}
