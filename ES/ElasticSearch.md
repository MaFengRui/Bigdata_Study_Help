# 简介

ElasticSearch是一款基于Apache Lucene构建的开源搜索引擎，它采用Java编写并使用Lucene构建索引、提供搜索功能，ElasticSearch的目标是让全文搜索变得简单，开发者可以通过它简单明了的RestFul API轻松地实现搜索功能，而不必去面对Lucene的复杂性。。**ES能够轻松的进行大规模的横向扩展，以支撑PB级的结构化和非结构化海量数据的处理。**

**简言之**：ES就是基于Lucene的分布式搜索和分析引擎

**设计目的**：主要用于云计算中， 能够达到实时搜索、稳定、可靠、快速安装使用也非常方便

# 与MYSQL对比



![1550481964860](/home/mafenrgui/IdeaProjects/Bigdata_Study_Help/ES/ElasticSearch.assets/1550481964860.png)

```
一个 Elasticsearch 集群可以包含多个索引(数据库)，也就是说其中包含了很多类型(表)。这些类型中包含了很多的文档(行)，然后每个文档中又包含了很多的字段(列)。Elasticsearch的交互，可以使用Java API，也可以直接使用HTTP的Restful API方式，比如我们打算插入一条记录，可以简单发送一个HTTP
```



# 索引：

##   ①倒排索引

     ```
 根据给定的关键字，从不同的资源文件中检索其出现的次数。也被称为反向索引。是一种索引方法，被用来存储在全文搜索下某个单词在一个文档或者一组文档中的存储位置的映射。它是文档检索系统中最常用的数据结构。通过倒排索引，可以根据单词快速获取包含这个单词的文档列表。倒排索引主要由两个部分组成：“单词词典”和“倒排文件”。 
     ```

### ES如何做倒排索引

ES的倒排索引要比关系型数据库的B-TREE索引快

![Alt text](/home/mafenrgui/IdeaProjects/Bigdata_Study_Help/ES/ElasticSearch.assets/inverted-index.png)

实例：在ES中创建这几个数据条数据，他会创建索引

```
| ID | Name | Age  |  Sex     |
| -- |:------------:| -----:| -----:| 
| 1  | Kate         | 24 | Female
| 2  | John         | 24 | Male
| 3  | Bill         | 29 | Male
```

**ID是Elasticsearch自建的文档id，那么Elasticsearch建立的索引如下:**

Name：

```
| Term | Posting List |
| -- |:----:|
| Kate | 1 |
| John | 2 |
| Bill | 3 |
```

**Age:**

```
| Term | Posting List |
| -- |:----:|
| 24 | [1,2] |
| 29 | 3 |
```

**Sex:**

```
| Term | Posting List |
| -- |:----:|
| Female | 1 |
| Male | [2,3] |
```



### 倒排列表

```
倒排列表用来记录有哪些文档包含了某个单词。一般在文档集合里会有很多文档包含某个单词，每个文档会记录文档编号（DocID），单词在这个文档中出现的次数（TF）及单词在文档中哪些位置出现过等信息，这样与一个文档相关的信息被称做倒排索引项（Posting），包含这个单词的一系列倒排索引项形成了列表结构，这就是某个单词对应的倒排列表。	  
```

  ③正排索引 
      先有检索的资源，然后将待检索的资源从给定的资源文件中进行检索。



# 主题



