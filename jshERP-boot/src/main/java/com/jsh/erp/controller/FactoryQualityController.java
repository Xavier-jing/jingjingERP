package com.jsh.erp.controller;

import com.alibaba.fastjson.JSONObject;
import com.jsh.erp.service.FactoryQualityService;
import org.springframework.web.bind.annotation.*;
import javax.annotation.Resource;
import java.util.*;
import javax.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/factoryQuality")
public class FactoryQualityController {
    @Resource private FactoryQualityService service;
    private Object ok(Object value){Map<String,Object> r=new HashMap<>();r.put("code",200);r.put("data",value);return r;}
    @GetMapping("/options") public Object options()throws Exception{return ok(service.options());}
    @PostMapping("/config") public Object config(@RequestBody JSONObject b)throws Exception{service.configure(b);return ok(null);}
    @GetMapping("/standards") public Object standards()throws Exception{return ok(service.standards());}
    @PostMapping("/standards") public Object standard(@RequestBody JSONObject b)throws Exception{service.saveStandard(b);return ok(null);}
    @GetMapping("/standardOptions") public Object standardOptions()throws Exception{return ok(service.standardOptions());}
    @GetMapping("/templates") public Object templates()throws Exception{return ok(service.templates());}
    @PostMapping("/templates") public Object template(@RequestBody JSONObject b)throws Exception{return ok(service.saveTemplate(b));}
    @GetMapping("/tasks") public Object tasks(@RequestParam(defaultValue="")String keyword,@RequestParam(defaultValue="1")int page)throws Exception{return ok(service.tasks(keyword,page));}
    @GetMapping("/task/{id}") public Object task(@PathVariable long id,@RequestParam(defaultValue="false")boolean finished)throws Exception{return ok(service.taskDetail(id,finished));}
    @PostMapping("/request") public Object request(@RequestBody JSONObject b)throws Exception{return ok(service.request(b));}
    @GetMapping("/{id}") public Object detail(@PathVariable long id)throws Exception{return ok(service.detail(id));}
    @PostMapping("/{id}/request") public Object maintain(@PathVariable long id,@RequestBody JSONObject b)throws Exception{service.maintainRequest(id,b);return ok(null);}
    @PostMapping("/{id}/action") public Object action(@PathVariable long id,@RequestBody JSONObject b)throws Exception{service.action(id,b);return ok(null);}
    @PostMapping("/leaders") public Object leaders(@RequestBody JSONObject b)throws Exception{service.configureLeaders(b);return ok(null);}
    @PostMapping("/finished/{id}/action") public Object finished(@PathVariable long id,@RequestBody JSONObject b,HttpServletRequest request)throws Exception{service.finishedAction(id,b,request);return ok(null);}
}
