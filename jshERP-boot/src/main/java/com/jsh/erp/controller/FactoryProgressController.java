package com.jsh.erp.controller;
import com.jsh.erp.service.FactoryProgressService;
import org.springframework.web.bind.annotation.*;
import javax.annotation.Resource;
import java.util.*;
@RestController
@RequestMapping("/factoryProgress")
public class FactoryProgressController {
 @Resource private FactoryProgressService service;
 private Object ok(Object data){Map<String,Object> r=new HashMap<>();r.put("code",200);r.put("data",data);return r;}
 @GetMapping("/options") public Object options()throws Exception{return ok(service.options());}
 @GetMapping("/list") public Object list(@RequestParam(defaultValue="")String keyword,@RequestParam(defaultValue="1")int page)throws Exception{return ok(service.list(keyword,page));}
 @GetMapping("/{id}") public Object detail(@PathVariable long id)throws Exception{return ok(service.detail(id));}
}
