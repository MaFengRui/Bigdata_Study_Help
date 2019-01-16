# 1. **kafka**相关问题

## 1.1. **kafka**在高并发的情况下,如何避免消息丢失和消息重复?

消息丢失解决方案:

首先对kafka进行限速， 其次启用重试机制，重试间隔时间设置长一些，最后Kafka设置acks=all，即需要相应的所有处于ISR的分区都确认收到该消息后，才算发送成功

消息重复解决方案:

消息可以使用唯一id标识 

生产者（ack=all 代表至少成功发送一次) 

消费者 （offset手动提交，业务逻辑成功处理后，提交offset） 

落表（主键或者唯一索引的方式，避免重复数据） 

业务逻辑处理（选择唯一主键存储到Redis或者mongdb中，先查询是否存在，若存在则不处理；若不存在，先插入Redis或Mongdb,再进行业务逻辑处理）

## 1.2. **kafka怎么保证数据消费一次且仅消费一次**

幂等producer：保证发送单个分区的消息只会发送一次，不会出现重复消息

事务(transaction)：保证原子性地写入到多个分区，即写入到多个分区的消息要么全部成功，要么全部回滚

流处理EOS：流处理本质上可看成是“读取-处理-写入”的管道。此EOS保证整个过程的操作是原子性。注意，这只适用于Kafka Streams

 

## 1.3. **kafka保证数据一致性和可靠性**

数据一致性保证

一致性定义：若某条消息对client可见，那么即使Leader挂了，在新Leader上数据依然可以被读到

HW-HighWaterMark: client可以从Leader读到的最大msg offset，即对外可见的最大offset， HW=max(replica.offset)

对于Leader新收到的msg，client不能立刻消费，Leader会等待该消息被所有ISR中的replica同步后，更新HW，此时该消息才能被client消费，这样就保证了如果Leader fail，该消息仍然可以从新选举的Leader中获取。

对于来自内部Broker的读取请求，没有HW的限制。同时，Follower也会维护一份自己的HW，Folloer.HW = min(Leader.HW, Follower.offset)

数据可靠性保证

当Producer向Leader发送数据时，可以通过acks参数设置数据可靠性的级别

0: 不论写入是否成功，server不需要给Producer发送Response，如果发生异常，server会终止连接，触发Producer更新meta数据；

1: Leader写入成功后即发送Response，此种情况如果Leader fail，会丢失数据

-1: 等待所有ISR接收到消息后再给Producer发送Response，这是最强保证

 

## 1.4. **kafka到spark streaming怎么保证数据完整性，怎么保证数据不重复消费？**

**保证数据不丢失（at-least）**

spark RDD内部机制可以保证数据at-least语义。

**Receiver方式**

开启WAL（预写日志），将从kafka中接受到的数据写入到日志文件中，所有数据从失败中可恢复。

**Direct方式**

依靠checkpoint机制来保证。

**保证数据不重复（exactly-once）**

要保证数据不重复，即Exactly once语义。 

\- 幂等操作：重复执行不会产生问题，不需要做额外的工作即可保证数据不重复。 

\- 业务代码添加事务操作

就是说针对每个partition的数据，产生一个uniqueId，只有这个partition的所有数据被完全消费，则算成功，否则算失效，要回滚。下次重复执行这个uniqueId时，如果已经被执行成功，则skip掉。

## 1.5. **kafka的消费者高阶和低阶API有什么区别**

kafka 提供了两套 consumer API：The high-level Consumer API和 The SimpleConsumer API

其中 high-level consumer API 提供了一个从 kafka 消费数据的高层抽象，而 SimpleConsumer API 则需要开发人员更多地关注细节。

The high-level consumer API

high-level consumer API 提供了 consumer group 的语义，一个消息只能被 group 内的一个 consumer 所消费，且 consumer 消费消息时不关注 offset，最后一个 offset 由 zookeeper 保存。

**使用 high-level consumer API 可以是多线程的应用，应当注意：**

如果消费线程大于 patition 数量，则有些线程将收不到消息

如果 patition 数量大于线程数，则有些线程多收到多个 patition 的消息

如果一个线程消费多个 patition，则无法保证你收到的消息的顺序，而一个 patition 内的消息是有序的

The SimpleConsumer API

**如果你想要对 patition 有更多的控制权，那就应该使用 SimpleConsumer API，比如：**

多次读取一个消息

只消费一个 patition 中的部分消息

使用事务来保证一个消息仅被消费一次但是使用此 API 时，partition、offset、broker、leader 等对你不再透明，需要自己去管理。你需要做大量的额外工作：

必须在应用程序中跟踪 offset，从而确定下一条应该消费哪条消息

应用程序需要通过程序获知每个 Partition 的 leader 是谁

需要处理 leader 的变更

 

## 1.6. **kafka的exactly-once**

幂等producer：保证发送单个分区的消息只会发送一次，不会出现重复消息

事务(transaction)：保证原子性地写入到多个分区，即写入到多个分区的消息要么全部成功，要么全部回滚

流处理EOS：流处理本质上可看成是“读取-处理-写入”的管道。此EOS保证整个过程的操作是原子性。注意，这只适用于Kafka Streams

## 1.7. **如何保证从Kafka获取数据不丢失?**

 

1.生产者数据的不丢失

kafka的ack机制：在kafka发送数据的时候，每次发送消息都会有一个确认反馈机制，确保消息正常的能够被收到。

 

2.消费者数据的不丢失

通过offset commit 来保证数据的不丢失，kafka自己记录了每次消费的offset数值，下次继续消费的时候，接着上次的offset进行消费即可。

 

## 1.8. **如果想消费已经被消费过的数据**

consumer是底层采用的是一个阻塞队列，只要一有producer生产数据，那consumer就会将数据消费。当然这里会产生一个很严重的问题，如果你重启一消费者程序，那你连一条数据都抓不到，但是log文件中明明可以看到所有数据都好好的存在。换句话说，一旦你消费过这些数据，那你就无法再次用同一个groupid消费同一组数据了。

原因：消费者消费了数据并不从队列中移除，只是记录了offset偏移量。同一个consumergroup的所有consumer合起来消费一个topic，并且他们每次消费的时候都会保存一个offset参数在zookeeper的root上。如果此时某个consumer挂了或者新增一个consumer进程，将会触发kafka的负载均衡，暂时性的重启所有consumer，重新分配哪个consumer去消费哪个partition，然后再继续通过保存在zookeeper上的offset参数继续读取数据。注意:offset保存的是consumer 组消费的消息偏移。 

要消费同一组数据，你可以

1) 采用不同的group。

2) 通过一些配置，就可以将线上产生的数据同步到镜像中去，然后再由特定的集群区处理大批量的数据。

![img](/home/mafenrgui/IdeaProjects/Bigdata_Study_Help/kafka/kafka常见面试题.assets/wps4Va4gS.png) 

## 1.9. **如何自定义去消费已经消费过的数据**

Conosumer.properties配置文件中有两个重要参数

auto.commit.enable：如果为true，则consumer的消费偏移offset会被记录到zookeeper。下次consumer启动时会从此位置继续消费。

auto.offset.reset  该参数只接受两个常量largest和Smallest,分别表示将当前offset指到日志文件的最开始位置和最近的位置。 

如果进一步想控制时间，则需要调用SimpleConsumer，自己去设置相关参数。比较重要的参数是 kafka.api.OffsetRequest.EarliestTime()和kafka.api.OffsetRequest.LatestTime()分别表示从日志（数据）的开始位置读取和只读取最新日志。

如何使用SimpleConsumer

首先，你必须知道读哪个topic的哪个partition

然后，找到负责该partition的broker leader，从而找到存有该partition副本的那个broker

再者，自己去写request并fetch数据

最终，还要注意需要识别和处理brokerleader的改变

## 1.10. **kafka partition和consumer数目关系** 

1) 如果consumer比partition多，是浪费，因为kafka的设计是在一个partition上是不允许并发的，所以consumer数不要大于partition数 。

2) 如果consumer比partition少，一个consumer会对应于多个partitions，这里主要合理分配consumer数和partition数，否则会导致partition里面的数据被取的不均匀 。最好partiton数目是consumer数目的整数倍，所以partition数目很重要，比如取24，就很容易设定consumer数目 。

3) 如果consumer从多个partition读到数据，不保证数据间的顺序性，kafka只保证在一个partition上数据是有序的，但多个partition，根据你读的顺序会有不同 

4) 增减consumer，broker，partition会导致rebalance，所以rebalance后consumer对应的partition会发生变化 

## 1.11. **kafka topic 副本问题**

Kafka尽量将所有的Partition均匀分配到整个集群上。一个典型的部署方式是一个Topic的Partition数量大于Broker的数量。

1) 如何分配副本:

Producer在发布消息到某个Partition时，先通过ZooKeeper找到该Partition的Leader，然后无论该Topic的Replication Factor为多少（也即该Partition有多少个Replica），Producer只将该消息发送到该Partition的Leader。Leader会将该消息写入其本地Log。每个Follower都从Leader pull数据。这种方式上，Follower存储的数据顺序与Leader保持一致。

2) Kafka分配Replica的算法如下：

将所有Broker（假设共n个Broker）和待分配的Partition排序

将第i个Partition分配到第（imod n）个Broker上

将第i个Partition的第j个Replica分配到第（(i + j) mode n）个Broker上 

## 1.12. **kafka如何设置生存周期与清理数据**

日志文件的删除策略非常简单:启动一个后台线程定期扫描log file列表,把保存时间超过阈值的文件直接删除(根据文件的创建时间).清理参数在server.properties文件中：

![img](/home/mafenrgui/IdeaProjects/Bigdata_Study_Help/kafka/kafka常见面试题.assets/wpskwRUrN.jpg) 

## 1.13. **zookeeper如何管理kafka**   

1) Producer端使用zookeeper用来"发现"broker列表,以及和Topic下每个partition leader建立socket连接并发送消息.

2) Broker端使用zookeeper用来注册broker信息,以及监测partition leader存活性.

3) Consumer端使用zookeeper用来注册consumer信息,其中包括consumer消费的partition列表等,同时也用来发现broker列表,并和partition leader建立socket连接,并获取消息.

## 1.14. **SparkStreaming之Kafka的Receiver和Direct方式讲解**

### **Receiver方式**

Receiver是使用Kafka的high level的consumer API来实现的。Receiver从Kafka中获取数据都是存储在Spark Executor内存中的，然后Spark Streaming启动的job会去处理那些数据

 

然而这种方式很可能会丢失数据，如果要启用高可靠机制，让数据零丢失，就必须启动Spark Streaming预写日志机制。该机制会同步地接收到Kafka数据写入分布式文件系统，比如HDFS上的预写日志中。所以底层节点出现了失败，也可以使用预写日志的数据进行恢复

### **Direct方式**

它会周期性的查询kafka，来获取每个topic + partition的最新offset，从而定义每一个batch的offset的范围。当处理数据的job启动时，就会使用kafka简单的消费者API来获取kafka指定offset的范围的数据。

 

1）它简化了并行读取：如果要读取多个partition，不需要创建多个输入DStream然后对他们进行union操作。Spark会创建跟kafka partition一样多的RDD partition，并且会并行从kafka中读取数据。所以在kafka partition和RDD partition之间有一个一一对应的映射关系。

 

2）高性能：如果要保证数据零丢失，基于Receiver的机制需要开启WAL机制，这种方式其实很低效，因为数据实际上被copy了2分，kafka自己本身就有可靠的机制，会对数据复制一份，而这里又复制一份到WAL中。基于Direct的方式，不依赖于Receiver，不需要开启WAL机制,只要kafka中做了数据的复制，那么就可以通过kafka的副本进行恢复。

 

3）一次仅且一次的事务机制

基于Receiver的方式，是使用Kafka High Level的API在zookeeper中保存消费过的offset的。这是消费kafka数据的传统方式，这种方式配合这WAL机制可以保证数据零丢失，但是无法保证数据只被处理一次的且仅且一次，可能会两次或者更多，因为spark和zookeeper可能是不同步的。

 

4）降低资源

Direct不需要Receivers，其申请的Executors全部参与到计算任务中；而Receiver-based则需要专门的Receivers来读取Kafka数据且不参与计算。因此相同的资源申请，Direct 能够支持更大的业务。

 

5）降低内存 

Receiver-based的Receiver与其他Exectuor是异步的，并持续不断接收数据，对于小业务量的场景还好，如果遇到大业务量时，需要提高Receiver的内存，但是参与计算的Executor并无需那么多的内存。而Direct 因为没有Receiver，而是在计算时读取数据，然后直接计算，所以对内存的要求很低。实际应用中我们可以把原先的10G降至现在的2-4G左右。

 

6）不会出现数据堆积 

Receiver-based方法需要Receivers来异步持续不断的读取数据，因此遇到网络、存储负载等因素，导致实时任务出现堆积，但Receivers却还在持续读取数据，此种情况很容易导致计算崩溃。Direct 则没有这种顾虑，其Driver在触发batch 计算任务时，才会读取数据并计算。队列出现堆积并不会引起程序的失败。

 

基于direct的方式，使用kafka的简单api，Spark Streaming自己就负责追踪消费的offset，并保存在checkpoint中。Spark自己一定是同步的，因此可以保证数据是消费一次且仅消费一次。

## 1.15. **幂等producer的实现?**

http://www.mamicode.com/info-detail-2058306.html

 

 

 