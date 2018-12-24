## 资源调优

​    
​    

    在我们开发完的spark作业，我们要为spark作业分配合适的资源，基本我们都可以在spark-submit中设置资源
 首先我们要知道spark作业任务执行流程才知道，哪里需要合适的资源

![Spark在作业简图](Spark调优实战.assets/spark作业执行原理简图.png"Spark在作业简图")

    在executor内存中主要分为三块
        第一块：供我们的执行task代码使用，占比20%
        第二块:供我们在shuffle使用，要去shuffle之前的task中拉去数据，供我们进行聚合计算等操作使用,占20%
        第三块：供我们持久化操作使用，占比40%
    task执行速度
         １、cpu核数：
            因为每个executor中所分配的cpu核数影响的是该executor同时可以处理几个task

  


###  设置每个application的executor的数量（num-executors）

​    参数说明：在yarn模式下,driver向yarn申请资源的时候，他会很这个设置来启动相应数量的execuor。
            如果默认不设置的他会启动较少的executor，导致我的作业执行的较慢。
    参数建议：看自己的情况，太少无法充分利用集群的资源
                        太多的话大部分队列无法给予充分的资源

### 设置executor的内存大小（executor-memory）

​    参数说明：决定了spark作业的性能，和创建的jvm的OOM有关
    参数建议：每个executor的内存设置为４－８G，具体的还要看自己部门的资源队列，num-executor*executor就是我的作业总内存
            最好不要超过这个资源队列的最大内存，如果在和团队其他人共享这个资源队列那就最好不要超过１／２，１／３
            避免自己的作业可以执行，别的同学的作业无法执行

#### 扩展一：面试题？YARN队列资源不足导致的application直接失败？原因？怎么解决？，对于有一大一小的作业怎么合理调度？

​            

                原因１：资源分配不合理：作业所申请的资源大于当前剩下的资源
                原因２：submit的作业设置的资源，真正跑起来，要大于这个资源
                
                解决:１、可以在j2ee上触发同时只有一个作业提交
                    ２、采用简单调度的方式，设置两个资源调度对列，长时间与短时间分开
                    ３、采用暴力执行，你的队列里面，无论何时，只会有一个作业在里面运行。那么此时，
                             就应该用我们之前讲过的性能调优的手段，去将每个队列能承载的最大的资源，
                             分配给你的每一个spark作业，比如80个executor；6G的内存；3个cpu core。
                             尽量让你的spark作业每一次运行，都达到最满的资源使用率，最快的速度，最好的性能；并行度，
                             240个cpu core，720个task。
                    具体解决：使用线程池，一个线程池就是一个资源队列，将这个线程池的容量设置为１（ExecutorService threadPool = Executors.newFixedThreadPool(1);）
                            然后，不同的作业类型放到不同的线程池，这个就是多个线程池方式
### 设置executor-core的个数

​    

    参数说明：这个参数决定可一个executor的并发处理task的能力,越多，越能够快速地执行完分配给自己的所有task线程
    参数建议：和上面参数一样
### 设置driver-memory

​    参数说明：该参数用于设置Driver的内存
    参数建议:通常设置１G,但是注意如果collect拉取到driver端,则要设置过大，防止OOM

### 设置spark.default.parallelism

​    参数说明：该参数用于设置每个stage的默认的task数量，这个参数及其重要
    参数调优建议：Spark作业的默认task数量为500~1000个较为合适。很多同学常犯的一个错误就是不去设置这个参数，那么此时就会导致Spark自己根据底层HDFS的block数量来设置task的数量，默认是一个HDFS block对应一个task。通常来说，Spark默认设置的数量是偏少的（比如就几十个task），如果task数量偏少的话，就会导致你前面设置好的Executor的参数都前功尽弃。试想一下，无论你的Executor进程有多少个，内存和CPU有多大，但是task只有1个或者10个，那么90%的Executor进程可能根本就没有task执行，也就是白白浪费了资源！因此Spark官网建议的设置原则是，设置该参数为num-executors * executor-cores的2~3倍较为合适，比如Executor的总CPU core数量为300个，那么设置1000个task是可以的，此时可以充分地利用Spark集群的资源。

### 设置 内存持久化大小（spark.storge.memoryFraction）

	参数说明：该参数用于RDD持久化到executor内存中能占的比例，默认是0.6，如果内存不够的话可以持久话到内存
	调优建议：如果作业中有太多的持久化操作可以内存给大点，如果少的的话可以调小点，当发现作业在执行的过程中有太多的gc，那就建议把这个值调小点，给作业执行的内存多一点

### 设置拉取shuffle需要的内存大小（spark.shuffle.memoryFtaction）

	参数说明：默认是0.2，如果超过了0.２他会溢写到磁盘
	调优建议:如果shuffle操作过多是，可以调大这个值，避免溢写到磁盘，如果发现作业频繁gc导致作业执行较慢，可以调低这个值

### 最后附上代码

	./bin/spark-submit \
	--master yarn-cluster \
	--num-executor 100 \
	--executor-core 4 \
	--executor-memory 6G \
	--driver-memory 1G \
	--conf spark.default.paralelism=1000 \
	--conf spark.storge.storge.memoryFraction=0.5 \
	--conf spark.shuffle.memoryFraction=0.3 \

## 开发调优


​                             
​                 
​                                  