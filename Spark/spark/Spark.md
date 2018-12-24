#Spark
##Spark为什么比MR快？快在哪里呢？

	１，首先spark基于内存计算
	２，DAG计算引擎，中间结果尽量不落地到磁盘
	 3,MR在Map端与Reduce端都要进行排序
	 ４，MR任务调度与和启动开销大(待研究，但是可以设置jvm重用)，spark线程池模型减少task启动的开销


​		
==	

		面试题：
	SparkSql为什么比HIVe快？
	mr与spark区别
	spark为什么比mr快（金山
	saprk跟mr的区别?（北京点众科技）
	Spark-Sql和 hadoop哪个快，为什么？
==
##	spark集群启动流程：
		启动master进程
		Master进程启动完成后，会解析slaves配置文件，找到启动Worker的host，然后启动相应的Worker，并发送注册信息给Worker
		worker向master注册
		Master收到注册信息后，并保存到内存和磁盘里；Master给Worker发送注册成功的消息（MasterURL）
		Worker收到Master的URL信息后，开始与Master建立心跳

##RDD

	概念：RDD是并行在Spark集群的不可变的，可分区的，弹性的，分布式数据集
		＊弹性(Resilient)：
				１、RDD的数据可以存储在内存或者是磁盘中
				2、RDD中的分区是可以改变的		
				3、RDD出错后可自动重新计算（通过血缘自动容错）
				４、可checkpoint（设置检查点，用于容错），可persist或cache（缓存）
				５、里面的数据是分片的（也叫分区，partition），分片的大小可自由设置和细粒度调整
	
	*五大特点:
		*A list of  partitipns
			一个分区列表，RDD中的数据都存在一个分区列表中
		*A function for computing each split
			作用在每一个分区函数（分区函数）
		*A list of dependencies on other RDDs
			一个RDD依赖于其他多个RDD，RDD容错机制的重要体现
		*Optionally,a Partitioner for key-value RDD
			这针对key　Value的的分区函数，能决定了数据的来源以及数据处理
		*Optionally  　a list of　preferred locations to compute each split on (e.g. block locations for an HDFS file)
			*选取最右位置，比如checkpoint数据，本地数据


	RDD的属性:
	a,rddname:RDD的名称
	b,sparkcontext:为job入口，会包括RDDID,集群连接，累加器，广播变量，
	c,sparkconf：一些参数的设置，三种方式spark API,环境变量，日志配置（log4j.properties）
	d,parent:依赖父IDD的paritionID,通过dependencies可以查到RDD所依赖的Paritition的List集合
	e,dependency：窄依赖还是宽依赖
	f,partitioner：分区方式，（Hash和range分区）
	g,checkpoint：缓存机制
	h,storageLevel：存储级别
	
	RDD存储：
		初代RDD：处于血统的顶层，存储的是任务所需的数据的分区信息，还有单个分区数据读取的方法，没有依赖的RDD，因为它就是依赖的开始
		子代RDD：处于血统的下层，存储的东西就是初代RDD到底干了什么才会产生自己，还有就是初代RDD的引用
	数据读取：
		数据读取是发生在运行的Task中，也就是说，数据在任务分发的Executor上运行的时候读取的
		在spark中有两种Task，一种是ResultTask，一种是ShuffleTask，两种Task都是以相同的方式读取RDD的数据
	运行逻辑：
		在Spark应用中，整个执行流程在逻辑上运算之间会形成有向无环图。驱动器执行时，它会把这个逻辑图转换为物理执行计划，然
			后将逻辑计划转换为一系列的步骤（stage），每个步骤有多个任务组成
		Spark的调度方式与MapReduce有所不同。Spark根据RDD之间不同的依赖关系形成不同的阶段（Stage），一个阶段包含一系列函
			数进行流水线执行
	RDD分区：
		对RDD分区的认识：
		分区实际上就是RDD数据集的一个片段，对RDD进行操作，实际上是操作RDD中的每一个分区
		分区的数量决定了并行的数量，RDD基于每一个分区计算，所以RDD的分区数目决定了总的Task数目
		如果数据来自HDFS就是一个块就是一个HDFS,64M
		计算逻辑：
			getPartitions获取分区
			getSplits
			goalSize [totalSize / numSplits]
			blockSize
			minSize
		分区的个数：
	
		一个分片一定是来自某一个文件
		分片不会跨RDD
	==========================================================================================
	创建分区的意义：
		增加并行处理能力
		决定了shuffle输出的分片数量
	分片的大小如何计算：
		goalSize(totalSize,numSplits),blockSize,minSize

衍生题：
==什么是RDD，RDD的特点？（芸品绿）==
==RDD的数据结构是怎么样的？==
==DStream中的RDD和普通的RDD有什么区别？==
==rdd弹性分布式表现在哪（乐为金融）==
==Spark读取数据生成RDD分区默认多少？2（58同城）==
==说一下rdd的特性，分片计算函数有哪些==
==Rdd弹性原因==
==mr和spark区别，怎么理解spark-rdd==
==rdd分区（乐为金融）==
==spark中是怎样分区的（金山）==


##Spark工作流程
![Spark工作流程
](/home/mafenrgui/Desktop/技术文档/面试题/综合面试/面试题最终整理/Spark/Spark任务生成和提交过程.png  "Spark工作流程
")Spark工作流程
		
		0,　将作业通过spark-submit提交至driver端
		1，调用Spark-submit类，内部执行submit-->doRun-->通过反射获取相应的程序的主类对象－－>执行主类的main方法
		2，SparkConf,SparkContext,创建了SparkEnv对象(ActorSystem对象）TaskScheduler ,DAGScheduler
		3,ClientActor讲任务信息封装到ApplicationDescription对象发送到Master
		4,master将任务信息存放到内存，将任务放入到任务队列
		５，开始执行这个任务是，调用Scheduler方法，进行资源调度
		６，资源封装成LaunchExector并发送给Worker
		7,worker收到资源封装成一个ExectorRunner对象
		８，ExectorRunner.start方法，开始启动CoarseGrainedExecutorBacket对象
		９，Exector－>DriverActor反向注册
		10,在DriverActor上注册成功后，会创建一个线程池（Thread pool）来执行任务
		11,Sparkcontext初始化完毕,也就得到了sc对象
		12,开始执行APP代码，当触发了Action的RDD算子时，就触发了一个job，	
		13,这时就调用DAGScheduler对象进行stage 划分，划分好的stage按照分区生成一个的task，并且封装到TaskSet对象（集合）,然后通过TaskSet提交到TaskScheduler
		14,TaskScheduler收到序列化好的TaskSet对象,封装成LaunchExector并提交到DriverActor
		15,把LauchExecutor发送到Executor上
		16,Executor会将接收到的LauchExecutor，	会将其封装成TaskRunner,然后从线程池中获取线程来执行TaskRunner
		17,TaskRunner拿到反序列化器，序列化TaskSet,然后执行App代码，也就是对RDD分区上执行的算子和自定义函数




		     Spark提交参数:
			./bin/spark-submit \ 
	--master yarn-cluster \
	--num-executor 100 \
	--executor-core 4 \
	--executor-memory 6G \
	--driver-memory 1G \
	--conf spark.default.paralelism=1000 \
	--conf spark.storge.storge.memoryFraction=0.5 \
	--conf spark.shuffle.memoryFraction=0.3 \
==衍生题：画图，画图讲解spark工作流程。以及在集群上和各个角色的对应关系。==
==Spark任务提交流程==
==Spark任务提交参数==
==spark-submit提交流程，doRunMain方法获取主类对象的时候如何通过yarn进行获取==
==yarn的两种提交模式（spark）（艾曼数据）==
==spark的作业提交流程（哗啦啦）==
==spark submint参数设直级任务提交流程（哗啦啦）==
==spark提交任务的流程（金山）==



##Spark Stage划分
https://www.jianshu.com/p/50c5c1032206[源码]

		 1,DAGSchduler中的HandleJobSubmitted方法，通过该方法，传入finalRDD(其实就是DAG图中触发action操作的RDD)生成finalStage.
		 2,生成finalStage的过程中调用了getParentStagesAndId方法，通过该方法从最后一个RDD开始向上遍历RDD的依赖（可以理解为其父RDD），如果遇到其依赖为　shuffle过程，则调用getShuffleMapStage方法生成该shuffle过程所在的stage,完成RDD遍历后，所有的stage划分完成
		 ３，getShuffleMapStage方法从传入的RDD开始遍历，直到遍历到RDD的依赖为shuffle为止，生成一个stage
		 4,stage的划分就此结束

==stage 的划分（哗啦啦公司）==
==stage,task和job的区别与划分方式（旷世科技）==
==Task，partition和stage等 的关系==
##窄宽依赖是什么？
		
		窄依赖是指父RDD的每个分区只被子RDD的一个分区所使用，子RDD分区通常对应常数个父RDD分区(O(1)，与数据规模无关)相应的，也就是说父RDD到字RDD可以，指定到子RDD分区，,map ,filter
		宽依赖是指父RDD的每个分区都可能被多个子RDD分区所使用，子RDD分区通常对应所有的父RDD分区(O(n)，父RDD分区需要被消费到多个子RDD分区，与数据规模有关)
		总结：还是要把握住根本之处，就是父RDD中分区内的数据，是否在子类RDD中也完全处于一个分区，如果是，窄依赖，如果不是，宽依赖。

##Spark on Yarn
###client模式
![client](/home/mafenrgui/IdeaProjects/Bigdata_Study_Help/Spark/spark/Spark.assets/yarm-client.png  "client")


###cluster模式
![Cluster](/home/mafenrgui/IdeaProjects/Bigdata_Study_Help/Spark/spark/Spark.assets/yarn-cluster.png  "Cluster")


	cluster模式：Driver程序在YARN中运行，应用的运行结果不能在客户端显示，所以最好运行那些将结果最终保存在外部存储介质（如HDFS、Redis、Mysql）而非stdout输出的应用程序，客户端的终端显示的仅是作为YARN的job的简单运行状况。
	
	client模式：Driver运行在Client上，应用程序运行结果会在客户端显示，所有适合运行结果有输出的应用程序（如spark-shell）

==Yarn-client和Yarn-cluster的区别 :==
	yarn-cluster模式下,Dirver运行在ApplicationMaster中,负责申请资源并监控
	task运行状态和重试失败的task,当用户提交了作业之后就可以关掉client,作业
	会继续在yarn中运行,applicationmaster和driver合二为一;
	yarn-client模式下,Dirver运行在本地客户端,client不能离开。
	
​	
​	
		面试题：
		a,spark on yarn的两种模式? client 模式？ 和cluster模式？
		b,画图，画Spark的工作模式，部署分布架构图
		c,简要描述Spark分布式集群搭建的步骤
		d,spark原理  (京东)
			答：粗略的答题：就把各个组件的联系一说。
			如果再细的话分两方面答题。是Driver在客户端，Driver一个worker上，这和yarn的差不多，但是不能把yarn提上，他问的时候再提
		e,spark-submit提交流程，doRunMain方法获取主类对象的时候如何通过yarn进行获取
		f,yarn的两种提交模式（spark）（艾曼数据）
		g,Driver如何与Executer进行联系的。（58同城）

##算子

		Action操作 
		reduce(func) 	
		通过函数func聚集数据集中的所有元素，这个函数必须是关联性的，确保可以被正确的并发执行 
		collect() 
		在driver的程序中，以数组的形式，返回数据集的所有元素，这通常会在使用filter或者其它操作后，返回一个足够小的数据子集再使用 
		count() 
		返回数据集的元素个数 
		first() 
		返回数据集的第一个元素(类似于take(1)) 
		take(n) 
		返回一个数组，由数据集的前n个元素组成。注意此操作目前并非并行执行的，而是driver程序所在机器 
		takeSample(withReplacement,num,seed) 
		返回一个数组，在数据集中随机采样num个元素组成，可以选择是否用随机数替换不足的部分，seed用于指定的随机数生成器种子 
		saveAsTextFile(path) 
		将数据集的元素，以textfile的形式保存到本地文件系统hdfs或者任何其他hadoop支持的文件系统，spark将会调用每个元素的toString方法，并将它转换为文件中的一行文本 
		takeOrderd(n,[ordering]) 
		排序后的limit(n) 
		saveAsSequenceFile(path) 
		将数据集的元素，以sequencefile的格式保存到指定的目录下，本地系统，hdfs或者任何其他hadoop支持的文件系统，RDD的元素必须由key-value对组成。并都实现了hadoop的writable接口或隐式可以转换为writable 
		saveAsObjectFile(path) 
		使用java的序列化方法保存到本地文件，可以被sparkContext.objectFile()加载 
		countByKey() 
		对(K,V)类型的RDD有效，返回一个(K,Int)对的map，表示每一个可以对应的元素个数 
		foreache(func) 
		在数据集的每一个元素上，运行函数func,t通常用于更新一个累加器变量，或者和外部存储系统做交互

###map,flatmap,flatmapToPair.mapPartition,mapPartitionWithIndex
![RDD算子](RDD算子.png  "RDD算子")
		
		补充：在map中有N个元素就会执行N次函数，所以初始化次数就要N次,但是当数据过大时，会对内存中已经处理的数据进行回收，不易造成OOM
			mapPartition函数只对每个分区执行一次函数，所以初始化资源较少，由于采用拉去模式，容易造成OOM


==面试题：==
说一下rdd的特性，分片计算函数有哪些
map、mapPartition和flatmap区别？
mappartition和foreachpartition的区别（艾曼数据）
map和mappartition的区别，reduby和groupby的区别（嘟嘟一下）
flatmap和map的区别（哗啦啦）
flatMap 算子怎么压平的（哗啦啦）
foreach 和map  区别？  foreachRDD 用过吗？（58）
partition by  distribute by 区别（乐为金融）
sort by order by 区别（乐为金融）
groupByKey和reduceByKey区别（金山）
reduceBykey 能否替换掉 groupBykey（不能：那就问你 哪些情况不能”）（哗啦啦）
RDD常用算子。（嘟嘟一下）
aggregate和aggregatebykey（艾曼数据）https://blog.csdn.net/zhihaoma/article/details/52609503
reduce和reducebykey（艾曼数据）
哪些算子操作涉及到shuffle
groupbyKey与reduceByKey哪个会引起数据倾斜？
reduceByKey和groupByKey的区别与用法

###ReducebyKey,GroupbyKey,Reduce
		reduce:(Action)
		GroupbyKey():由于它不接收函数，spark只能先将所有的键值对(key-value pair)都移动，   这样的后果是集群节点之间的开销很大，导致传输延时。
		ReducebyKey:当采用reduceByKeyt时，Spark可以在每个分区移动数据之前将待输出数据与一个共用的key结合。(底层调用的是conbineBykey)
		combineBykey:两个函数，第一个函数，在本地，第二个在另一台机器
		因此，在对大数据进行复杂计算时，reduceByKey优于groupByKey。
		另外，如果仅仅是group处理，那么以下函数应该优先于 groupByKey(底层调用的是combineByKey) ：
		（1）combineByKey 组合数据，但是组合之后的数据类型与输入时值的类型不一样。
		（2）foldByKey合并每一个 key 的所有值，在级联函数和“零值”中使用。（底层调用的是combineByKey)
		

##Spark Shufffle
###什么是shuffle?
Shuffle过程本质上都是将，Map端获得的数据使用分区器进行划分，并将数据发送给对应的reduce端，前一个stage的ShuffleMapTask进行Shuffle　Write,把数据存储在BlackManger中，并将元数据信息上报给Dirver,下一个stage根据数据的位置元信息，进行shuffle Read，拉取上个stage的输出数据。

![shuffle策略](/home/mafenrgui/Desktop/技术文档/面试题/综合面试/面试题最终整理/Spark/shuffle.png  "shuffle策略")

 ShuffleMapTask的执行过程：先用pipeline计算得到finalRDD中对应partition的records，每得到一个record就将其送到对应的bucket里，每个bucket里面的数据会不断写到本地磁盘上，形成一个ShuffleBlockFile，或者称为**FileSegment**，之后的reducer会去fetch属于自己的FileSegment，进入shuffle read阶段

 版本：
 2.0之前将hash shuffle移除
 (1.2-至今)sort shuffle存在，有三种策略:
 1.UnsafeShuffleWriter
 2.SortShuffleWriter
 3.BypassMergeSortShuffleWriter

面试题：
说一下spark的shuffle过程（58同城）
shuffle过程中，哪里用内存最多（58同城）
shuffle中的reduce怎么知道要去哪里拉取对应的key（58同城）（driver）
Spark的shuffle有几种方式啊
Sparkshuffle和MRshuffle的区别(岩心科技)
哪些算子操作涉及到shuffle


###Rdd,DataSet,DataFrame区别～～

![区别](三者区别.png  "区别")


面试题
RDD、DataFrame、DataSet的区别，Spark Streaming和Spark Structed Streaming有什么区别，让你用DataSet和RDD做选择，你选择哪个开发？为什么？（金山）

##coalesce与repartition
==小分区合并问题介绍==

		在使用Spark进行数据处理的过程中，常常会使用filter方法来对数据进行一些预处理，过滤掉一些不符合条件的数据。在使用该方法对数据进行频繁过滤或者是过滤掉的数据量过大的情况下就会造成大量小分区的生成。在Spark内部会对每一个分区分配一个task执行，如果task过多，那么每个task处理的数据量很小，就会造成线程频繁的在task之间切换，使得资源开销较大，且很多任务等待执行，并行度不高，这会造成集群工作效益低下。

为了解决这一个问题，常采用RDD中重分区的函数（coalesce函数或rePartition函数）来进行数据紧缩，减少分区数量，将小分区合并为大分区，从而提高效率

通过源码可以看出两者的区别：coalesce()方法的参数shuffle默认设置为false，repartition()方法就是coalesce()方法shuffle为true的情况。

		使用情景
		假设RDD有N个分区，需要重新划分成M个分区：
	
		N < M: 一般情况下N个分区有数据分布不均匀的状况，利用HashPartitioner函数将数据重新分区为M个，这时需要将shuffle设置为true。因为重分区前后相当于宽依赖，会发生shuffle过程，此时可以使用coalesce(shuffle=true)，或者直接使用repartition()。
	
		如果N > M并且N和M相差不多(假如N是1000，M是100): 那么就可以将N个分区中的若干个分区合并成一个新的分区，最终合并为M个分区，这是前后是窄依赖关系，可以使用coalesce(shuffle=false)。
	
		如果 N> M并且两者相差悬殊: 这时如果将shuffle设置为false，父子ＲＤＤ是窄依赖关系，他们同处在一个Ｓｔａｇｅ中，就可能造成spark程序的并行度不够，从而影响性能，如果在M为1的时候，为了使coalesce之前的操作有更好的并行度，可以将shuffle设置为true。

总结
如果传入的参数大于现有的分区数目，而shuffle为false，RDD的分区数不变，也就是说不经过shuffle，是无法将RDDde分区数变多的。

==面试题：==

		 哪些算子操作涉及到shuffle
		distinct、groupByKey、reduceByKey、aggregateByKey、join、cogroup、repartition
		spark优化

##spark容错
==容错都有哪几种？==　
   一个是RDD，血统解决
   一个是集群，资源调度解决
   		
   RDD容错：
  在RDD计算，通过checkpoint进行容错，
   做checkpoint有两种方式，
   一个是checkpoint data，
  一个是logging the updates。
    用户可以控制采用哪种方式来实现容错，默认是logging the updates方式，
==    logging the updates方式==
    通过记录跟踪所有生成RDD的转换（transformations）
    也就是记录每个RDD的lineage（血统）来重新计算生成丢失的分区数据。
    RDD数据集通过“血缘关系”记住了它是如何从其它RDD中演变过来的，血缘关系记录的是粗颗粒度的转换操作行为，
    当这个RDD的部分分区数据丢失时，它可以通过血缘关系获取足够的信息来重新运算和恢复丢失的数据分区，
    由此带来了性能的提升。相对而言，在两种依赖关系中，窄依赖的失败恢复更为高效，
    它只需要根据父RDD分区重新计算丢失的分区即可（不需要重新计算所有分区），
    而且可以并行地在不同节点进行重新计算。而对于宽依赖而言，单个节点失效通常意味着重新计算过程会涉及多个父RDD分区， 开销较大。
   == checkpoint方式==（transfromtion算子）
   场景：
   		在spark计算里面 计算流程DAG特别长,服务器需要将整个DAG计算完成得出结果,但是如果在这很长的计算流程中突然中间算出的数据丢失了,spark又会根据RDD的依赖关系从头到尾计算一遍,这样子就很费性能
   用法：
   	在checkpoint的时候强烈建议先进行cache,并且当你checkpoint执行成功了,那么前面所有的RDD依赖都会被销毁,
  sc.setCheckpointDir("hdfs://lijie:9000/checkpoint0727")
 rdd.cache()　//
rdd.checkpoint()　//少计算一次
rdd.collect
   		
   		
### cache,persist
==一、Cache的用法注意点==：
（1）cache之后一定不能立即有其它算子，不能直接去接算子。因为在实际工作的时候，cache后有算子的话，它每次都会重新触发这个计算过程。

（2）cache不是一个action，运行它的时候没有执行一个作业。

（3）cache缓存如何让它失效：unpersist，它是立即执行的。persist是lazy级别的（没有计算），unpersist时eager级别的。

cache是persist的一种特殊情况
cache放在内存中只有一份副本,只放在内存中，放在内存的Heap中。不会保存在什么目录或者HDFS上，有可能在很多机器的内存，数据量比较小，也有可能在一台机器的内存中。

==、Persist使用场合==
1，某步骤计算特别耗时；

2，计算链条特别长；

3，checkpoint所在的RDD也一定要persist（在checkpoint之前，手动进行persist）持久化数据，为什么？checkpoint的工作机制，是lazy级别的，在触发一个作业的时候，开始计算job，job算完之后，转过来spark的调度框架发现RDD有checkpoint标记，转过来框架本身又基于这个checkpoint再提交一个作业，checkpoint会触发一个新的作业，如果不进行持久化，进行checkpoint的时候会重算，如果第一次计算的时候就进行了persist，那么进行checkpoint的时候速度会非常的快。

4，shuffle之后；

5，shuffle之前（框架默认帮助我们数据持久化到本地磁盘）

persist内存不够用时数据保存在磁盘的哪里？？？

Executor local directory，executor运行的时候，有一个local direcory(本地目录，这是可以配置的)

cache通过unpersit强制把数据从内存中清除掉，如果计算的时候，肯定会先考虑计算需要的内存，这个时候，cache的数据就与可能丢失。
==区别：==
==cache与checkpoint的区别==
cache 和 checkpoint 之间有一个重大的区别，cache 将 RDD 以及 RDD 的血统(记录了这个RDD如何产生)缓存到内存中，当缓存的 RDD 失效的时候(如内存损坏)，它们可以通过血统重新计算来进行恢复。但是 checkpoint 将 RDD 缓存到了 HDFS 中，同时忽略了它的血统(也就是RDD之前的那些依赖)。为什么要丢掉依赖？因为可以利用 HDFS 多副本特性保证容错！
==persist与checkpoint的区别==

rdd.persist(StorageLevel.DISK_ONLY) 与 checkpoint 也有区别。前者虽然可以将 RDD 的 partition 持久化到磁盘，但该 partition 由 blockManager 管理。一旦 driver program 执行结束，也就是 executor 所在进程 CoarseGrainedExecutorBackend stop，blockManager 也会 stop，被 cache 到磁盘上的 RDD 也会被清空（整个 blockManager 使用的 local 文件夹被删除）。而 checkpoint 将 RDD 持久化到 HDFS 或本地文件夹，如果不被手动 remove 掉，是一直存在的，也就是说可以被下一个 driver program 使用，而 cached RDD 不能被其他 dirver program 使用。
==cache与peisist的区别==
，cache 底层调用的是 persist 方法，存储等级为: memory only，persist 的默认存储级别也是 memory only


==  面试题：==
  	cache与checkpoint 区别(知呱呱)
  	checkpoint和persist（only disk）的区别（艾曼数据）
  	cache是怎么使用的（艾曼数据）
  	cache缓存级别以及cache缓存参数设置（环球恒通）
  	checkpoint的作用（环球恒通）
  	
  	
##spark 如何防止内存溢出
==①driver端的内存溢出 ==
可以增大driver的内存参数：spark.driver.memory (default 1g)
这个参数用来设置Driver的内存。在Spark程序中，SparkContext，DAGScheduler都是运行在Driver端的。对应rdd的Stage切分也是在Driver端运行，如果用户自己写的程序有过多的步骤，切分出过多的Stage，这部分信息消耗的是Driver的内存，这个时候就需要调大Driver的内存。

==②map过程产生大量对象导致内存溢出== 
这种溢出的原因是在单个map中产生了大量的对象导致的，例如：rdd.map(x=>for(i <- 1 to 10000) yield i.toString)，这个操作在rdd中，每个对象都产生了10000个对象，这肯定很容易产生内存溢出的问题。针对这种问题，在不增加内存的情况下，可以通过减少每个Task的大小，以便达到每个Task即使产生大量的对象Executor的内存也能够装得下。具体做法可以在会产生大量对象的map操作之前调用repartition方法，分区成更小的块传入map。例如：rdd.repartition(10000).map(x=>for(i <- 1 to 10000) yield i.toString)。 
面对这种问题注意，不能使用rdd.coalesce方法，这个方法只能减少分区，不能增加分区，不会有shuffle的过程。

==③数据不平衡导致内存溢出 ==
数据不平衡除了有可能导致内存溢出外，也有可能导致性能的问题，解决方法和上面说的类似，就是调用repartition重新分区。这里就不再累赘了。

==④shuffle后内存溢出 ==
shuffle内存溢出的情况可以说都是shuffle后，单个文件过大导致的。在Spark中，join，reduceByKey这一类型的过程，都会有shuffle的过程，在shuffle的使用，需要传入一个partitioner，大部分Spark中的shuffle操作，默认的partitioner都是HashPatitioner，默认值是父RDD中最大的分区数,这个参数通过spark.default.parallelism控制(在spark-sql中用spark.sql.shuffle.partitions) ， spark.default.parallelism参数只对HashPartitioner有效，所以如果是别的Partitioner或者自己实现的Partitioner就不能使用spark.default.parallelism这个参数来控制shuffle的并发量了。如果是别的partitioner导致的shuffle内存溢出，就需要从partitioner的代码增加partitions的数量。

==⑤standalone模式下资源分配不均匀导致内存溢出==

在standalone的模式下如果配置了–total-executor-cores 和 –executor-memory 这两个参数，但是没有配置–executor-cores这个参数的话，就有可能导致，每个Executor的memory是一样的，但是cores的数量不同，那么在cores数量多的Executor中，由于能够同时执行多个Task，就容易导致内存溢出的情况。这种情况的解决方法就是同时配置–executor-cores或者spark.executor.cores参数，确保Executor资源分配均匀。
使用rdd.persist(StorageLevel.MEMORY_AND_DISK_SER)代替rdd.cache()

rdd.cache()和rdd.persist(Storage.MEMORY_ONLY)是等价的，在内存不足的时候rdd.cache()的数据会丢失，再次使用的时候会重算，而rdd.persist(StorageLevel.MEMORY_AND_DISK_SER)在内存不足的时候会存储在磁盘，避免重算，只是消耗点IO时间。

##spark中的数据倾斜的现象、原因、后果
==(1)、数据倾斜的现象 ==
多数task执行速度较快,少数task执行时间非常长，或者等待很长时间后提示你内存不足，执行失败。

==(2)、数据倾斜的原因 ==
①数据问题 
1、key本身分布不均衡（包括大量的key为空）
2、key的设置不合理
②spark使用问题 
1、shuffle时的并发度不够
2、计算方式有误

==(3)、数据倾斜的后果 ==
1、spark中的stage的执行时间受限于最后那个执行完成的task,因此运行缓慢的任务会拖垮整个程序的运行速度（分布式程序运行的速度是由最慢的那个task决定的）。
2、过多的数据在同一个task中运行，将会把executor撑爆。

##如何解决spark中的数据倾斜问题
发现数据倾斜的时候，不要急于提高executor的资源，修改参数或是修改程序，首先要检查数据本身，是否存在异常数据。

==1、数据问题造成的数据倾斜==

==找出异常的key== 
如果任务长时间卡在最后最后1个(几个)任务，首先要对key进行抽样分析，判断是哪些key造成的。 
选取key，对数据进行抽样，统计出现的次数，根据出现次数大小排序取出前几个。
比如: df.select(“key”).sample(false,0.1).(k=>(k,1)).reduceBykey(+).map(k=>(k._2,k._1)).sortByKey(false).take(10)
如果发现多数数据分布都较为平均，而个别数据比其他数据大上若干个数量级，则说明发生了数据倾斜。
经过分析，倾斜的数据主要有以下三种情况: 
1、null（空值）或是一些无意义的信息()之类的,大多是这个原因引起。
2、无效数据，大量重复的测试数据或是对结果影响不大的有效数据。
3、有效数据，业务导致的正常数据分布。
解决办法 
第1，2种情况，直接对数据进行过滤即可（因为该数据对当前业务不会产生影响）。
第3种情况则需要进行一些特殊操作，常见的有以下几种做法 
(1) 隔离执行，将异常的key过滤出来单独处理，最后与正常数据的处理结果进行union操作。
(2) 对key先添加随机值，进行操作后，去掉随机值，再进行一次操作。
(3) 使用reduceByKey 代替 groupByKey(reduceByKey用于对每个key对应的多个value进行merge操作，最重要的是它能够在本地先进行merge操作，并且merge操作可以通过函数自定义.)
(4) 使用map join。
案例 
==如果使用reduceByKey因为数据倾斜造成运行失败的问题。==具体操作流程如下: 
(1) 将原始的 key 转化为 key + 随机值(例如Random.nextInt)
(2) 对数据进行 reduceByKey(func)
(3) 将 key + 随机值 转成 key
(4) 再对数据进行 reduceByKey(func)
案例操作流程分析： 
假设说有倾斜的Key，我们给所有的Key加上一个随机数，然后进行reduceByKey操作；此时同一个Key会有不同的随机数前缀，在进行reduceByKey操作的时候原来的一个非常大的倾斜的Key就分而治之变成若干个更小的Key，不过此时结果和原来不一样，怎么破？进行map操作，目的是把随机数前缀去掉，然后再次进行reduceByKey操作。（当然，如果你很无聊，可以再次做随机数前缀），这样我们就可以把原本倾斜的Key通过分而治之方案分散开来，最后又进行了全局聚合
注意1: 如果此时依旧存在问题，建议筛选出倾斜的数据单独处理。最后将这份数据与正常的数据进行union即可。
注意2: 单独处理异常数据时，可以配合使用Map Join解决。
2、spark使用不当造成的数据倾斜

==提高shuffle并行度==

dataFrame和sparkSql可以设置spark.sql.shuffle.partitions参数控制shuffle的并发度，默认为200。
rdd操作可以设置spark.default.parallelism控制并发度，默认参数由不同的Cluster Manager控制。
局限性: 只是让每个task执行更少的不同的key。无法解决个别key特别大的情况造成的倾斜，如果某些key的大小非常大，即使一个task单独执行它，也会受到数据倾斜的困扰。
==使用map join 代替reduce join==

在小表不是特别大(取决于你的executor大小)的情况下使用，可以使程序避免shuffle的过程，自然也就没有数据倾斜的困扰了.（详细见http://blog.csdn.net/lsshlsw/article/details/50834858、http://blog.csdn.net/lsshlsw/article/details/48694893）
局限性: 因为是先将小数据发送到每个executor上，所以数据量不能太大。
#Spark Streaming
==所有介绍：https://www.cnblogs.com/shishanyuan/p/4747735.html==
##简单介绍：
Spark的各个子框架，都是基于核心Spark的，Spark Streaming在内部的处理机制是，接收实时流的数据，并根据一定的时间间隔拆分成一批批的数据，然后通过Spark Engine处理这些批数据，最终得到处理后的一批批结果数据。

对应的批数据，在Spark内核对应一个RDD实例，因此，对应流数据的DStream可以看成是一组RDDs，即RDD的一个序列。通俗点理解的话，在流数据分成一批一批后，通过一个先进先出的队列，然后 Spark Engine从该队列中依次取出一个个批数据，把批数据封装成一个RDD，然后进行处理，这是一个典型的生产者消费者模型，对应的就有生产者消费者模型的问题，即如何协调生产速率和消费速率。

##术语定义：
离散流（discretized stream）或DStream：这是Spark Streaming对内部持续的实时数据流的抽象描述，即我们处理的一个实时数据流，在Spark Streaming中对应于一个DStream 实例。

批数据（batch data）：这是化整为零的第一步，将实时流数据以时间片为单位进行分批，将流处理转化为时间片数据的批处理。随着持续时间的推移，这些处理结果就形成了对应的结果数据流了。

时间片或批处理时间间隔（ batch interval）：这是人为地对流数据进行定量的标准，以时间片作为我们拆分流数据的依据。一个时间片的数据对应一个RDD实例。

窗口长度（window length）：一个窗口覆盖的流数据的时间长度。必须是批处理时间间隔的倍数，

滑动时间间隔：前一个窗口到后一个窗口所经过的时间长度。必须是批处理时间间隔的倍数

Input DStream :一个input DStream是一个特殊的DStream，将Spark Streaming连接到一个外部数据源来读取数据。
##过程

1.初始化==StreamingContext==对象，在该对象启动过程中实例化==DStreamGraph==和==JobScheduler==，其中==DStreamGraph==用于存放==DStream以及DStream之间的依赖关系==等信息，而JobScheduler中包括==ReceiverTracker和JobGenerator==。其中ReceiverTracker为==Driver端流数据接收器（Receiver）的管理者==，JobGenerator为==批处理作业生成器==。在ReceiverTracker启动过程中，根据==流数据接收器分发策略==通知对应的Executor中的==流数据接收管理器（ReciverSupervisor）==启动，再由==ReciverSupervisor==启动流数据接收器。
2.当流数据接收器==Receiver启动==后，持续不断地接收实时流数据，根据传过来数据的大小进行判断，如果数据量很小，则==攒多条数据成==一块，然后再进行==块存储==，如果==数据量大==，则==直接进行块存储==。对于这些数据Receiver直接交给ReciverSupervisor，由其进行数据转储操作。==块存储==根据设置是否==预写日志==分为两种，一种是使用==非预写日志====BlockManagerBasedBlockHandler==方法直接==写==到Worker的==内存==或==磁盘==中，另一种是进行==预写日志==WriteAheadLogBasedBlockHandler方法，即在==预写日志====同时==把数据写入到==Worker的内存或磁盘==中。数据存储完毕后，ReciverSupervisor会把数据存储的元信息上报给ReceiverTracker，ReceiverTracker再把这些信息转发给ReceivedBlockTracker，由它负责管理收到数据块的元信息。
3.在StreamingContext的JobGenerator中维护一个定时器，该定时器在批处理时间到来时会进行生成作业的操作。在该操作中进行：

		i.通知ReceiverTracker将接收到的数据进行提交，在提交时采用synchronized 关键字进行处理，保证每条数据被划入一个且只被划入一个批中；
		ii.要求DStreamGraph根据DStream依赖关系生成作业序列Seq[Job]；
		iii.从第一步中ReceiverTracker获取本批次数据的元数据；
		iv.把批处理时间time，作业序列Seq[Job]和本批次数据的元数据包装为JobSet，调用JobScheduler.submitJobSet(JobSet) 提交给 JobScheduler，JobScheduler将把这些作业发送给Spark核心进行处理，由于该执行为异步，因此本步将非常快；
		v.只要提交结束（不管作业是否执行情况），Spark Streaming对整个系统做一个检查点（Checkpoint）。
4.在Spark核心的作业对数据进行处理，处理完毕后输出到外部系统，如数据库或文件系统，输出的数据可以被外部系统所使用。由于实时流数据的数据源源不断流入，Spark会周而复始地进行数据处理，相应也会持续不断地输出结果。



   





