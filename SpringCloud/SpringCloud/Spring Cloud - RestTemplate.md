[TOC]

# SpringCloud应用间通信
SpringCloud中服务间两种restful调用方式

- RestTemplate
- Feign

# RestTemplate的三种使用方式
```java
@RestController
@Slf4j
public class clientController{

   @GetMapping("/getProductMsg")
   public String getProductMsg(){
     //1：第一种方式
	 RestTemplate restTemplage = new RestTemplate();
	 String response = restTemplate.getForObject("http://localhost:8080/msg",String.class);
	 log.info("response={}",response);
	 return response;
   }


   @Autowird
   private LoadBalancerClient loadBalancerClient;

   @GetMapping("/getProductMsg2")
   public String getProductMsg2(){
     //2：第二种方式：注入LoadBalancerClient;
	 ServiceInstance serviceInstance = loadBalancerClient.choose("PRODUCT");
	 String url = String.format("http://%s:%s",serviceInstance.getHost,serviceInstance/getPort());
	 RestTemplate restTemplage = new RestTemplate();
	 String response = restTemplate.getForObject(url,String.class);
	 log.info("response={}",response);
	 return response;
   }

    @Autowired
	private RestTemplate restTemplate;

   @GetMapping("/getProductMsg3")
   public String getProductMsg3(){
     //3：第三种方式：RestTemplateConfig;
	 String response = restTemplate.getForObject("http://PRODUCT/msg",String.class);
	 log.info("response={}",response);
	 return response;
   }

}
```

```java
@Component
public class RestTemplateConfig{

   @Bean
   @LoadBalanced
   public RestTemplate restTemplate(){
      return new RestTemplate();
   }

}
```

