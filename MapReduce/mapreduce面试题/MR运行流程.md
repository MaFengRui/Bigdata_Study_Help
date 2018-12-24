# MR运行流程

程序运行流程

![01](/home/mafenrgui/IdeaProjects/Bigdata_Study_Help/MapReduce/mapreduce面试题/MR运行流程.assets/01-1545471898927.png)

客户端执行流程

![02](/home/mafenrgui/IdeaProjects/Bigdata_Study_Help/MapReduce/mapreduce面试题/MR运行流程.assets/02.png)





![03](/home/mafenrgui/IdeaProjects/Bigdata_Study_Help/MapReduce/mapreduce面试题/MR运行流程.assets/03.png)

以上图片总结

- 1.执行hadoop jar worldcount.jar 执行worldcount的yarnRunner的main程序，里面设置了job的信息代码，，如果什么也不加入，自动读取core.site文件，上图中有设置JOB信息的代码，当执行的mian 方法的job.waitForCompletion()的时候，会与调用与yarn服务器进行建立连接，

  ```
  客户端代码，会将待处理的数据执行逻辑切片，根据特定的split大小划分多个，然后每一个split执行一个map?这个决定map数量？
  答;是的。我们可以手动设置split数量；
  那reduce数量由什么决定呢？reduce数量，有我们的业务逻辑决定，，所以由我们的分区数量决定，当我们指定reduce task数量大于分区数，有的reducetask输出文件为空。当分区数大于reducetask数量，会导致部分数据丢失。
  ```

  

  切片是根据input的路径进行切片，序列化为了一个job.split的序列化文件，job将我们设置job的信息（输入输出路径），放在job.xml序列化文件中。

- 2.向yarn申请个运行一个MRjob，

- 3.RM接受任务，并创建一个wc的task,yarn也就是rm会向client返回一个路径(hdfs://---//staging/jobid)，和一个jobid(这个jobid的返回代表yarn同意执行这个job了），此时客户端会将job.xml,split.xml,wc.jar封装成一个任务，然后提交到hdfs。

  ```
  保存在hdfs://----//staging/jobid,并且由NM去下载这个job），此时的任务只是一个壳，具体的任务在程序代码保存的地址中，yarn也是通过这个地址找到代码（里面包括了配置资源文件等等），运行任务
  ```

  这个wc Task是真正执行的mr，之前的都是客户端执行的，就是我们通常写的job.set....并放入task资源队列

- 4.RM会在一个时机

  ```
  这个时机是啥? 
  就是rm监听nm的资源情况，空闲了就分配他，问题来了不是说mr是细粒度资源申请吗？
  ```

  将wc任务分配给nm去处理。

- 5.nm收到任务后，回去hdfs中下载三个文件，运行mr程序，也就是AM

  ```
  AM啥时候创建的？
  ```

  根据wc.jar

  ```
  ？？？这个jar和nm收到的任务是同一个任务吗？
  答：不是,jar中是真正执行的任务
  ```

  中的代码，将maptask启动在各个nodemanger，但是还没有运行资源，然后就是分发任务的AM去想rm申请运行map资源.

- 6.rm接受一个maptask会把他放到task资源队列（和wc是一个资源队列吗？）

- 7.rm会在一个时机（）。将map资源分配给在各个节点已经的启动的maptask去处理这个任务,会将结果根据配置文件中的保存路径，保存下来。

- 8.dm1运行map也就是mapTask.

- 9.map运行完毕，通知AMmaster

- 10.AM 向RM申请运行reduceTask资源

- 11.RM接受任务创建一个reduce的task，并放入task资源队列

- 12.rm在一个时机，将reducetask分配给nm处理这个任务，然后会将更具配置文件的map结果输出文件地址拉取文件，汇总输出到指定输出路径

- 13.nm运行reducetask

**划重点：**

yarn只负责申请资源，分配资源，回收资源。

RM负责协调资源管理，nm负责运行具体代码

mr程序使用yarn的api申请资源。

yarn是分布式操作系统平台，mapreduce是运行在yarn上的程序，他俩是通过yarn的api来体现他俩的关系。运行的时候会发现configration里面默认添加yarn.site文件