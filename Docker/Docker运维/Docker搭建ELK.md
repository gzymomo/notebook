[TOC]

# 1、ELK概述
ELK是Elasticsearch、Logstash、Kibana三大开源框架首字母大写简称。
 - Elasticsearch是一个基于Lucene、分布式、通过Restful方式进行交互的近实时搜索平台框架。像类似百度、谷歌这种大数据全文搜索引擎的场景都可以使用Elasticsearch作为底层支持框架.
 - Logstash是ELK的中央数据流引擎，用于从不同目标（文件/数据存储/MQ）收集的不同格式数据，经过过滤后支持输出到不同目的地（文件/MQ/redis/elasticsearch/kafka等）。
 - Kibana可以将elasticsearch的数据通过友好的页面展示出来，提供实时分析的功能。
 - FileBeat，它是一个轻量级的日志收集处理工具(Agent)，Filebeat占用资源少，适合于在各个服务器上搜集日志后传输给Logstash，官方也推荐此工具。

通过Logstash去收集每台服务器日志文件，然后按定义的正则模板过滤后传输到Kafka或redis，然后由另一个Logstash从KafKa或redis读取日志存储到elasticsearch中创建索引，最后通过Kibana展示给开发者或运维人员进行分析。这样大大提升了运维线上问题的效率。除此之外，还可以将收集的日志进行大数据分析，得到更有价值的数据给到高层进行决策。