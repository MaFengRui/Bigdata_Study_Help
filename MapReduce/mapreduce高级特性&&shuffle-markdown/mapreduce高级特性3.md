### mapreduce高级特性3

#### 回顾：

#### 今天任务

```
多个mr案例代码编写
```

#### 教学目标

```
掌握今天的代码实现的思想，熟练编写出代码。
```

#### 第一节：结合案例讲解mr重要知识点

##### 1.1  多表连接

```
第一张表的内容：
login：
uid	sexid	logindate
1	1	2017-04-17 08:16:20
2   2	2017-04-15 06:18:20
3   1	2017-04-16 05:16:24
4   2	2017-04-14 03:18:20
5   1	2017-04-13 02:16:25
6   2	2017-04-13 01:15:20
7   1	2017-04-12 08:16:34
8   2	2017-04-11 09:16:20
9   0	2017-04-10 05:16:50

第二张表的内容：
sex：
0	不知道
1	男
2	女
第三张表的内容：
user uname
1	小红
2   小行
3   小通
4   小闪
5   小镇
6   小振
7   小秀
8   小微
9   小懂
10	小明
11  小刚
12  小举
13  小黑
14  小白
15  小鹏
16  小习

最终输出效果：
loginuid	 sex		uname	logindate
1		男	            小红	 2017-04-17 08:16:20
2        女	 			小行	  2017-04-15 06:18:20
3        男	 			小通	  2017-04-16 05:16:24
4        女	 			小闪	  2017-04-14 03:18:20
5        男	 			小镇	  2017-04-13 02:16:25
6        女	 			小振	  2017-04-13 01:15:20
7        男	 			小秀	  2017-04-12 08:16:34
9       不知道			   小微	2017-04-10 05:16:50
8       女	 			小懂	  2017-04-11 09:16:20
```

思路：

```
map端join：map端join

核心思想：将小表文件缓存到分布式缓存中，然后再map端进行连接处理。

适用场景：有一个或者多个小表 和 一个或者多个大表文件。

优点：map端使用内存缓存小表数据，加载速度快；大大减少map端到reduce端的传输量；大大较少shuffle过程耗时。

缺点：解决的业务需要有小表。

semi join：半连接

解决map端的缺点，当多个大文件同时存在，且一个大文件中有效数据抽取出来是小文件时，

则可以单独抽取出来并缓存到分布式缓存中，然后再使用map端join来进行连接。

```

自定义一个writable类User

```java
import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;
import org.apache.hadoop.io.Writable;

/**
 * user 信息bean
 */
public class User implements Writable{

	public String uid;
	public String uname;
	public String gender;
	public String ldt;
	
	public User(){}
	
	public User(String uid, String uname, String gender, String ldt) {
		this.uid = uid;
		this.uname = uname;
		this.gender = gender;
		this.ldt = ldt;
	}

	@Override
	public void write(DataOutput out) throws IOException {
		out.writeUTF(uid);
		out.writeUTF(uname);
		out.writeUTF(gender);
		out.writeUTF(ldt);
	}

	@Override
	public void readFields(DataInput in) throws IOException {
		this.uid = in.readUTF();
		this.uname = in.readUTF();
		this.gender = in.readUTF();
		this.ldt = in.readUTF();
	}
	@Override
	public String toString() {
		return uid + "\t" + uname + "\t" + gender + "\t" + ldt;
	}
	public String getUid() {
		return uid;
	}
	public void setUid(String uid) {
		this.uid = uid;
	}
	public String getUname() {
		return uname;
	}
	public void setUname(String uname) {
		this.uname = uname;
	}
	public String getGender() {
		return gender;
	}
	public void setGender(String gender) {
		this.gender = gender;
	}
	public String getLdt() {
		return ldt;
	}
	public void setLdt(String ldt) {
		this.ldt = ldt;
	}
}
```

mr类MultipleTableJoin

```java
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.net.URI;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.Reducer.Context;
import org.apache.hadoop.mapreduce.filecache.DistributedCache;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.util.GenericOptionsParser;
import org.apache.hadoop.util.Tool;
import org.apache.hadoop.util.ToolRunner;

public class MultipleTableJoin extends ToolRunner implements Tool{

	/**
	 * 自定义的myMapper
	 */
	static class MyMapper extends Mapper<LongWritable, Text, User, NullWritable>{

		Map<String,String> sexMap = new ConcurrentHashMap<String, String>();
		Map<String,String> userMap = new ConcurrentHashMap<String, String>();
		
		//读取缓存文件
		@Override
		protected void setup(Context context)throws IOException, InterruptedException {
			Path [] paths = DistributedCache.getLocalCacheFiles(context.getConfiguration());
			for (Path p : paths) {
				String fileName = p.getName();
				if(fileName.equals("sex")){//读取 “性别表”
					BufferedReader sb = new BufferedReader(new FileReader(new File(p.toString())));
					String str = null;
					while((str = sb.readLine()) != null){
						String []  strs = str.split("\t");
						sexMap.put(strs[0], strs[1]);
					}
					sb.close();
				} else if(fileName.equals("user")){//读取“用户表”
					BufferedReader sb = new BufferedReader(new FileReader(new File(p.toString())));
					String str = null;
					while((str = sb.readLine()) != null){
						String []  strs = str.split("\t");
						userMap.put(strs[0], strs[1]);
					}
					sb.close();
				}
			}
		}

		@Override
		protected void map(LongWritable key, Text value,Context context)
				throws IOException, InterruptedException {
			
			String line = value.toString();
			String lines [] = line.split("\t");
			String uid = lines[0];
			String sexid = lines[1];
			String logindate = lines[2];
			
			//join连接操作
			if(sexMap.containsKey(sexid) && userMap.containsKey(uid)){
				String uname = userMap.get(uid);
				String gender = sexMap.get(sexid);
				//User user = new User(uid, uname, gender, logindate);
				//context.write(new Text(uid+"\t"+uname+"\t"+gender+"\t"+logindate), NullWritable.get());
				User user = new User(uid, uname, gender, logindate);
				context.write(user, NullWritable.get());
			}	
		}
	}
	
	/**
	 * 自定义MyReducer
	 * @author lyd
	 *
	 */
	/*static class MyReducer extends Reducer<Text, Text, Text, Text>{

		@Override
		protected void setup(Context context)throws IOException, InterruptedException {
		}
		
		@Override
		protected void reduce(Text key, Iterable<Text> value,Context context)
				throws IOException, InterruptedException {
		}
		
		@Override
		protected void cleanup(Context context)throws IOException, InterruptedException {
		}
	}*/
	
	
	@Override
	public void setConf(Configuration conf) {
		conf.set("fs.defaultFS", "hdfs://hadoop01:9000");
	}

	@Override
	public Configuration getConf() {
		return new Configuration();
	}
	
	/**
	 * 驱动方法
	 */
	@Override
	public int run(String[] args) throws Exception {
		//1、获取conf对象
		Configuration conf = getConf();
		//2、创建job
		Job job = Job.getInstance(conf, "model01");
		//3、设置运行job的class
		job.setJarByClass(MultipleTableJoin.class);
		//4、设置map相关属性
		job.setMapperClass(MyMapper.class);
		job.setMapOutputKeyClass(User.class);
		job.setMapOutputValueClass(NullWritable.class);
		FileInputFormat.addInputPath(job, new Path(args[0]));
		
		//设置缓存文件  
		job.addCacheFile(new URI(args[2]));
		job.addCacheFile(new URI(args[3]));
		
//		URI [] uris = {new URI(args[2]),new URI(args[3])};
//		job.setCacheFiles(uris);
		
	/*	DistributedCache.addCacheFile(new URI(args[2]), conf);
		DistributedCache.addCacheFile(new URI(args[3]), conf);*/
		
		/*//5、设置reduce相关属性
		job.setReducerClass(MyReducer.class);
		job.setOutputKeyClass(Text.class);
		job.setOutputValueClass(Text.class);*/
		//判断输出目录是否存在，若存在则删除
		FileSystem fs = FileSystem.get(conf);
		if(fs.exists(new Path(args[1]))){
			fs.delete(new Path(args[1]), true);
		}
		FileOutputFormat.setOutputPath(job, new Path(args[1]));
		
		//6、提交运行job
		int isok = job.waitForCompletion(true) ? 0 : 1;
		return isok;
	}
	
	/**
	 * job的主入口
	 * @param args
	 */
	public static void main(String[] args) {
		try {
			//对输入参数作解析
			String [] argss = new GenericOptionsParser(new Configuration(), args).getRemainingArgs();
			System.exit(ToolRunner.run(new MultipleTableJoin(), argss));
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}
```

##### 1.2 mr各组件之间数据传递

简单说就是在map中设置一个值，在reduce中能够获得这个值

```java
import java.io.IOException;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;


/**
 * 参数传递问题
 */
public class Param {
	/**
	 * 自定义的myMapper
	 */
	public static class MyMapper extends Mapper<LongWritable, Text, Text, Text>{
		Text word = new Text();
		Text one = new Text("1");

		@Override
		public void map(LongWritable key, Text value,Context context)
				throws IOException, InterruptedException {
			int sum = 1000;
			//获取行数据
			String line = value.toString();
			String []  words = line.split(" ");
			//循环数组
			for (String s : words) {
				word.set(s);
				context.write(word, one);
			}
			//context.getConfiguration().set("paraC", sum+"");
			context.getCounter("map firstPara", context.getConfiguration().get("ParaA"));
			//context.getCounter("map secondPara", context.getConfiguration().get("ParaB"));
		}
	}
	
	/**
	 * 自定义MyReducer
	 */
	public static class MyReducer extends Reducer<Text, Text, Text, Text>{
		
        Text sum = new Text();
		
		@Override
		public void reduce(Text key, Iterable<Text> value,Context context)
				throws IOException, InterruptedException {
			//定义一个计数器
			int counter = 0;
			//循环奇数
			for (Text i : value) {
				counter += Integer.parseInt(i.toString());
			}
			sum.set(counter+"");
			//reduce阶段的最终输出
			context.write(key, sum);
			context.getCounter("reduce firstPara", context.getConfiguration().get("ParaA"));
			//context.getCounter("reduce secondPara", context.getConfiguration().get("ParaB"));
			//context.getCounter("reduce thridPara", context.getConfiguration().get("ParaC"));
		}
	}
	
	/**
	 * job的主入口
	 */
	public static void main(String[] args) throws IOException, ClassNotFoundException, InterruptedException {
		//1、获取conf对象
				Configuration conf = new Configuration();
				conf.set("fs.defaultFS", "hdfs://hadoop01:9000");
				
				//读取配置文件中的属性
conf.addResource(Param.class.getResource("/resource/myConf.xml"));
	conf.set("paraA",args[0]);
				//conf.set("paraB", args[0]);
				//2、创建job
				Job job = Job.getInstance(conf, "model01");
				
				//3、设置运行job的class
				job.setJarByClass(Param.class);
				//4、设置map相关属性
				job.setMapperClass(MyMapper.class);
				job.setMapOutputKeyClass(Text.class);
				job.setMapOutputValueClass(Text.class);
FileInputFormat.addInputPath(job, new Path(conf.get("mr.input.dir")));
				
				//5、设置reduce相关属性
				job.setReducerClass(MyReducer.class);
				job.setOutputKeyClass(Text.class);
				job.setOutputValueClass(Text.class);
				//判断输出目录是否存在，若存在则删除
String outpath = conf.get("mr.output.dir");
				FileSystem fs = FileSystem.get(conf);
				if(fs.exists(new Path(outpath))){
					fs.delete(new Path(outpath), true);
				}
				FileOutputFormat.setOutputPath(job, new Path(outpath));
				
				//6、提交运行job
				int isok = job.waitForCompletion(true) ? 0 : 1;
				System.exit(isok);
	}

}
```

##### 1.3 mr中压缩设置（了解）

```
概念：
	这是mapreduce的一种优化策略：通过压缩编码对mapper或者reducer的输出进行压缩，以减少磁盘IO，提高MR程	 序运行速度（但相应增加了cpu运算负担）
	1、 Mapreduce支持将map输出的结果或者reduce输出的结果进行压缩，以减少网络IO或最终输出数据的体积
	2、 压缩特性运用得当能提高性能，但运用不当也可能降低性能
	3、 基本原则：
		运算密集型的job，少用压缩
		IO密集型的job，多用压缩
		
Reducer输出压缩
	在配置参数或在代码中都可以设置reduce的输出压缩
        1、在配置参数中设置 
         mapreduce.output.fileoutputformat.compress=false			    	   
         mapreduce.output.fileoutputformat.compress.codec=
        						org.apache.hadoop.io.compress.DefaultCodec
    	 mapreduce.output.fileoutputformat.compress.type=RECORD
        2、在代码中设置
		Job job = Job.getInstance(conf);
		FileOutputFormat.setCompressOutput(job, true);
		FileOutputFormat.setOutputCompressorClass(job, (Class<? extends CompressionCodec>) Class.forName(""));

Mapper输出压缩
	在配置参数或在代码中都可以设置reduce的输出压缩

	1、在配置参数中设置 
		mapreduce.map.output.compress=false
		mapreduce.map.output.compress.codec=org.apache.hadoop.io.compress.DefaultCodec
	2、在代码中设置：
		conf.setBoolean(Job.MAP_OUTPUT_COMPRESS, true);
		conf.setClass(Job.MAP_OUTPUT_COMPRESS_CODEC, GzipCodec.class, CompressionCodec.class);
```





```java
import java.io.IOException;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

public class CompressionDemo {
	/**
	 * 自定义map的内部类
	 */
	public static class MyMapper extends Mapper<LongWritable, Text, Text, Text>{
		
		Text word = new Text();
		Text one = new Text("1");
		
		@Override
		protected void map(LongWritable key, Text value,Context context)
				throws IOException, InterruptedException {
			//获取行数据
			String line = value.toString();
			//对数据进行拆分   [hello,qianfeng,hi,qianfeng] [hello,1603] [hi,hadoop,hi,spark]
			String []  words = line.split(" ");
			//循环数组
			for (String s : words) {
				word.set(s);
				context.write(word, one);
			}
		}
	}
	
	/**
	 * 自定义reducer类
	 */
	public static class MyReducer extends Reducer<Text, Text, Text, Text>{
		
		Text sum = new Text();
		
		@Override
		protected void reduce(Text key, Iterable<Text> value,Context context)
				throws IOException, InterruptedException {
			//定义一个计数器
			int counter = 0;
			//循环奇数
			for (Text i : value) {
				counter += Integer.parseInt(i.toString());
			}
			sum.set(counter+"");
			//reduce阶段的最终输出
			context.write(key, sum);
		}
	}
	
	/**
	 * job的主入口
	 */
	public static void main(String[] args) {
		
		try {
			//获取配置对象
			Configuration conf = new Configuration();
			conf.set("fs.defaultFS", "hdfs://hadoop01:9000");
			
//map阶段压缩设置
conf.setBoolean("mapreduce.map.output.compress", false);
conf.set("mapreduce.map.output.compress.codec", "org.apache.hadoop.io.compress.DefaultCodec");
			
//reduce端设置压缩属性
conf.setBoolean("mapreduce.output.fileoutputformat.compress", true);
//conf.set("mapreduce.output.fileoutputformat.compress.type", "RECORD");
conf.set("mapreduce.output.fileoutputformat.compress.codec","org.apache.hadoop.io.compress.DefaultCodec");
			
			//创建job
			Job job = new Job(conf, "wordcount");
			
			//为job设置运行主类
			job.setJarByClass(CompressionDemo.class);
			
			//设置map阶段的属性
			job.setMapperClass(MyMapper.class);
			FileInputFormat.addInputPath(job, new Path(args[0]));
			
			
			//设置reduce阶段的属性
			job.setReducerClass(MyReducer.class);
			job.setOutputKeyClass(Text.class);
			job.setOutputValueClass(Text.class);
			//判断输出目录是否存在，若存在则删除
			FileSystem fs = FileSystem.get(conf);
			if(fs.exists(new Path(args[1]))){
				fs.delete(new Path(args[1]), true);
			}
			FileOutputFormat.setOutputPath(job, new Path(args[1]));
			
			//提交运行作业job 并打印信息
			int isok = job.waitForCompletion(true)?0:1;
			//退出job
			System.exit(isok);
			
		} catch (IOException | ClassNotFoundException | InterruptedException e) {
			e.printStackTrace();
		}
	}
}
```

##### 1.4 多个job之间有序执行

每一个mr程序都封装成一个job，而多个job之间呢？后一个job输入的数据，就是前一个job的输出的数据。

本节就是演示这种场景：

- 顺序执行

  两个job执行是有先后顺序的

  ```java
  import java.io.IOException;
  
  import org.apache.hadoop.conf.Configuration;
  import org.apache.hadoop.fs.Path;
  import org.apache.hadoop.io.LongWritable;
  import org.apache.hadoop.io.Text;
  import org.apache.hadoop.mapreduce.Job;
  import org.apache.hadoop.mapreduce.Mapper;
  import org.apache.hadoop.mapreduce.Reducer;
  import org.apache.hadoop.mapreduce.Mapper.Context;
  import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
  import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
  
    /**
  
  	 chain链，，多个job之间依次执行。oozie、
       *过滤并统计：
       */
      public class ChainDemo02 {
    	//自定义myMapper
    			public static class MyMapper extends Mapper<LongWritable, Text, Text, Text>{
                  
    				Text k = new Text();
    				Text v = new Text();
    				
                  @Override
    				protected void map(LongWritable key, Text value,Context context)
    						throws IOException, InterruptedException {
    					String line = value.toString();
    					String scores [] = line.split("\t");
    					String chinese = scores[1];
    					String math = scores[2];
    					String english = scores[3];
    					if(Double.parseDouble(chinese) < 60 || Double.parseDouble(math) < 60 								|| Double.parseDouble(english) < 60){
    						context.write(value, new Text(""));
    					}
    				}
  			}
          
          	public static class CounterMapper extends Mapper<LongWritable,Text,Text,Text>{
  			
  				Text word = new Text();
  				Text one = new Text("1");
  			
                  @Override
                  protected void map(LongWritable key, Text value,Context context)
                          throws IOException, InterruptedException {
                      //获取行数据
                      String line = value.toString();
                      String []  words = line.split("\t");
                      //循环数组
                      for (String s : words) {
                          word.set(s);
                          context.write(word, one);
                      }
                  }
  		}
  		
  		/**
  		 * 自定义reducer类
  		 */
  		public static class CounterReducer extends Reducer<Text, Text, Text, Text>{
  			
  			Text sum = new Text();
  			
  			@Override
  			protected void reduce(Text key, Iterable<Text> value,Context context)
  					throws IOException, InterruptedException {
  				//定义一个计数器
  				int counter = 0;
  				//循环奇数
  				for (Text i : value) {
  					counter += Integer.parseInt(i.toString());
  				}
  				sum.set(counter+"");
  				//reduce阶段的最终输出
  				context.write(key, sum);
  			}
  		}
  	/**
  		 * job的主入口
  		 * @param args
  		 */
  		public static void main(String[] args) {
  			
  			try {
  				//获取配置对象
  				Configuration conf = new Configuration();
  				//创建job
  				Job grepjob = new Job(conf, "grep job");
  				//为job设置运行主类
  				grepjob.setJarByClass(ChainDemo02.class);
  				
  				//设置map阶段的属性
  				grepjob.setMapperClass(MyMapper.class);
  				grepjob.setMapOutputKeyClass(Text.class);
  				grepjob.setMapOutputValueClass(Text.class);
  				FileInputFormat.addInputPath(grepjob, new Path(args[0]));
                  	//设置reduce阶段的属性
  				//grepjob.setReducerClass(MyReducer.class);
  				FileOutputFormat.setOutputPath(grepjob, new Path(args[1]));
  				
  				//提交运行作业job 并打印信息
  				int isok = grepjob.waitForCompletion(true)?0:1;
  				if (isok == 0){
  					//创建job
  					Job countjob = new Job(conf, "counter job");
  					countjob.setJarByClass(ChainDemo02.class);
  					//设置map阶段的属性
  					countjob.setMapperClass(CounterMapper.class);
  					countjob.setMapOutputKeyClass(Text.class);
  					countjob.setMapOutputValueClass(Text.class);
  					FileInputFormat.addInputPath(countjob, new Path(args[1]));
                      //设置reduce阶段的属性
  					countjob.setReducerClass(CounterReducer.class);
  					countjob.setOutputKeyClass(Text.class);
  					countjob.setOutputValueClass(Text.class);
  					FileOutputFormat.setOutputPath(countjob, new Path(args[2]));
  					
  					//提交运行作业job 并打印信息
  					int isok1 = countjob.waitForCompletion(true)?0:1;
  					System.exit(isok1);
  				}
  			} catch (IOException | ClassNotFoundException | InterruptedException e) {
  				e.printStackTrace();
  			}
  		}
          }
  ```

  

- 依赖执行

  ```java
  多个job之间是有依赖关系的
  
    
    import java.io.IOException;
  
    import org.apache.hadoop.conf.Configuration;
    import org.apache.hadoop.fs.Path;
    import org.apache.hadoop.io.LongWritable;
    import org.apache.hadoop.io.Text;
    import org.apache.hadoop.mapreduce.Job;
    import org.apache.hadoop.mapreduce.Mapper;
    import org.apache.hadoop.mapreduce.Reducer;
    import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
    import org.apache.hadoop.mapreduce.lib.jobcontrol.ControlledJob;
    import org.apache.hadoop.mapreduce.lib.jobcontrol.JobControl;
    import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
  
  
    /**
     * chain链，，多个job之间依次执行。oozie、
     * @author lyd
     *
     *
     *过滤并统计：
     *顺序执行
     *
     */
    public class ChainDemo {
    	//自定义myMapper
    			public static class MyMapper extends Mapper<LongWritable, Text, Text, Text>{
    				Text k = new Text();
    				Text v = new Text();
    				@Override
    				protected void map(LongWritable key, Text value,Context context)
    						throws IOException, InterruptedException {
    					String line = value.toString();
    					String scores [] = line.split("\t");
    					String chinese = scores[1];
    					String math = scores[2];
    					String english = scores[3];
    					if(Double.parseDouble(chinese) < 60 || Double.parseDouble(math) < 60 || Double.parseDouble(english) < 60){
    						context.write(value, new Text(""));
    					}
    				}
    				
    				//map方法运行完后执行一次(仅执行一次)
    				@Override
    				protected void cleanup(Context context)
    						throws IOException, InterruptedException {
    				}
    			}
    			
    			
    			public static class CounterMapper extends Mapper<LongWritable, Text, Text, Text>{
    				
    				Text word = new Text();
    				Text one = new Text("1");
    				
    				@Override
    				protected void map(LongWritable key, Text value,Context context)
    						throws IOException, InterruptedException {
    					//获取行数据
    					String line = value.toString();
    					String []  words = line.split("\t");
    					//循环数组
    					for (String s : words) {
    						word.set(s);
    						context.write(word, one);
    					}
    					
    				}
    			}
    			
    			/**
    			 * 自定义reducer类
    			 * @author lyd
    			 *
    			 */
    			public static class CounterReducer extends Reducer<Text, Text, Text, Text>{
    				
    				Text sum = new Text();
    				
    				@Override
    				protected void reduce(Text key, Iterable<Text> value,Context context)
    						throws IOException, InterruptedException {
    					//定义一个计数器
    					int counter = 0;
    					//循环奇数
    					for (Text i : value) {
    						counter += Integer.parseInt(i.toString());
    					}
    					sum.set(counter+"");
    					//reduce阶段的最终输出
    					context.write(key, sum);
    				}
    			}
    			
    			
    			/**
    			 * job的主入口
    			 * @param args
    			 */
    			public static void main(String[] args) {
    				
    				try {
    					//获取配置对象
    					Configuration conf = new Configuration();
    					//创建job
    					Job grepjob = new Job(conf, "grep job");
    					//为job设置运行主类
    					grepjob.setJarByClass(ChainDemo.class);
    					
    					//设置map阶段的属性
    					grepjob.setMapperClass(MyMapper.class);
    					grepjob.setMapOutputKeyClass(Text.class);
    					grepjob.setMapOutputValueClass(Text.class);
    					FileInputFormat.addInputPath(grepjob, new Path(args[0]));
    					
    					//设置reduce阶段的属性
    					//grepjob.setReducerClass(MyReducer.class);
    					FileOutputFormat.setOutputPath(grepjob, new Path(args[1]));
    					
    					
    					//创建job
    					Job countjob = new Job(conf, "counter job");
    					countjob.setJarByClass(ChainDemo.class);
    					//设置map阶段的属性
    					countjob.setMapperClass(CounterMapper.class);
    					countjob.setMapOutputKeyClass(Text.class);
    					countjob.setMapOutputValueClass(Text.class);
    					FileInputFormat.addInputPath(countjob, new Path(args[1]));
    					
    					
    					//设置reduce阶段的属性
    					countjob.setReducerClass(CounterReducer.class);
    					countjob.setOutputKeyClass(Text.class);
    					countjob.setOutputValueClass(Text.class);
    					FileOutputFormat.setOutputPath(countjob, new Path(args[2]));
    					
    					//获取单个作业控制器 controlledJob
    					ControlledJob grepcj = new ControlledJob(grepjob.getConfiguration());
    					ControlledJob countercj = new ControlledJob(countjob.getConfiguration());
    					
    					//添加依赖
    					countercj.addDependingJob(grepcj);
    					
    					//获取总的作业控制器 JobControl
    					JobControl jc = new JobControl("grep and counter");
    					//将当个作业控制器添加到总的作业控制器中
    					jc.addJob(grepcj);
    					jc.addJob(countercj);
    					
    					//获取一个线程
    					Thread th = new Thread(jc);
    					//启动线程
    					th.start();
    					//判断jc中的作业是否执行完成
    					if(jc.allFinished()){
    						Thread.sleep(3000);
    						th.stop();
    						jc.stop();
    					}
    					
    				} catch (IOException | InterruptedException  e) {
    					e.printStackTrace();
    				}
    			}			
    }
  ```

  ​				

##### 1.5 自定义outputFormat

- 需求

  现有一些原始日志需要做增强解析处理，流程：

  ​	（1）从原始日志文件中读取数据

  ​	（2）根据日志中的一个URL字段到外部知识库中获取信息增强到原始日志

  ​	（3）如果成功增强，则输出到增强结果目录；如果增强失败，则抽取原始数据中URL字段输出到待爬清单目录。

  实现的需求是：

  ​	默认reduce执行后，输出数据的目的文件是固定的一个文件，那怎样实现根据数据的不同，相应的输出数据到多个不同的文件呢？本例就是解决这个问题

- 分析

  程序的关键点是要在一个mapreduce程序中根据数据的不同输出两类结果到不同目录，这类灵活的输出需求可以通过自定义outputformat来实现

- 实现

  实现要点：

  ​	在mapreduce中访问外部资源

  ​	自定义outputformat，改写其中的recordwriter，改写具体输出数据的方法write()

  数据库获取数据的工具

  ```JAVA
  	public class DBLoader {
  	 
  	        public static void dbLoader(HashMap<String, String> ruleMap) {
  	        
  	                Connection conn = null;
  	                Statement st = null;
  	                ResultSet res = null;
  	                
  	                try {
  	                        Class.forName("com.mysql.jdbc.Driver");
  	                        conn = DriverManager.getConnection("jdbc:mysql://hdp-node01:3306/urlknowledge", "root", "root");
  	                        st = conn.createStatement();
  	                        res = st.executeQuery("select url,content from urlcontent");
  	                        while (res.next()) {
  	                                ruleMap.put(res.getString(1), res.getString(2));
  	                        }
  	                } catch (Exception e) {
  	                        e.printStackTrace();
  	                } finally {
  	                        try{
  	                                if(res!=null){
  	                                        res.close();
  	                                }
  	                                if(st!=null){
  	                                        st.close();
  	                                }
  	                                if(conn!=null){
  	                                        conn.close();
  	                                }
  	                 
  	                        }catch(Exception e){
  	                                e.printStackTrace();
  	                        }
  	                        }
  	                }
  	                
  	                public static void main(String[] args) {
  	                DBLoader db = new DBLoader();
  	                HashMap<String, String> map = new HashMap<String,String>();
  	                db.dbLoader(map);
  	                System.out.println(map.size());
  	        }
  	}

  ```

  自定义一个outputformat

  ```java
  	public class LogEnhancerOutputFormat extends FileOutputFormat<Text, NullWritable>{
  	 
  	@Override
  	public RecordWriter<Text, NullWritable> getRecordWriter(TaskAttemptContext context) throws IOException, InterruptedException {
  	 
  	        FileSystem fs = FileSystem.get(context.getConfiguration());
  	        Path enhancePath = new Path("hdfs://hdp-node01:9000/flow/enhancelog/enhanced.log");
  	        Path toCrawlPath = new Path("hdfs://hdp-node01:9000/flow/tocrawl/tocrawl.log");
  	        FSDataOutputStream enhanceOut = fs.create(enhancePath);
  	        FSDataOutputStream toCrawlOut = fs.create(toCrawlPath);
  	        return new MyRecordWriter(enhanceOut,toCrawlOut);
  	}
  	static class MyRecordWriter extends RecordWriter<Text, NullWritable>{
  	        FSDataOutputStream enhanceOut = null;
  	        FSDataOutputStream toCrawlOut = null;
  	        public MyRecordWriter(FSDataOutputStream enhanceOut, FSDataOutputStream toCrawlOut) {
  	        this.enhanceOut = enhanceOut;
  	        this.toCrawlOut = toCrawlOut;
  	}
  	 
  	@Override
  	public void write(Text key, NullWritable value) throws IOException, InterruptedException {
  	 
  	//有了数据，你来负责写到目的地  —— hdfs
  	//判断，进来内容如果是带tocrawl的，就往待爬清单输出流中写 toCrawlOut
  	if(key.toString().contains("tocrawl")){
  	toCrawlOut.write(key.toString().getBytes());
  	}else{
  	enhanceOut.write(key.toString().getBytes());
  	}
  	}
  	 
  	@Override
  	public void close(TaskAttemptContext context) throws IOException, InterruptedException {
  	 
  	if(toCrawlOut!=null){
  	toCrawlOut.close();
  	}
  	if(enhanceOut!=null){
  	enhanceOut.close();
  	}
  	}
  	}
  	}

  ```

  开发mapreduce处理流程

  ```JAVA
  	/**
  	 * 这个程序是对每个小时不断产生的用户上网记录日志进行增强(将日志中的url所指向的网页内容分析结果信息追加到每一行原始日志后面)
  	 * 
  	 * @author
  	 * 
  	 */
  	public class LogEnhancer {
  	 
  	static class LogEnhancerMapper extends Mapper<LongWritable, Text, Text, NullWritable> {
  	 
  	HashMap<String, String> knowledgeMap = new HashMap<String, String>();
  	 
  	/**
  	 * maptask在初始化时会先调用setup方法一次 利用这个机制，将外部的知识库加载到maptask执行的机器内存中
  	 */
  	@Override
  	protected void setup(org.apache.hadoop.mapreduce.Mapper.Context context) throws IOException, InterruptedException {
  	 
  	DBLoader.dbLoader(knowledgeMap);
  	 
  	}
  	 
  	@Override
  	protected void map(LongWritable key, Text value, Context context) throws IOException, InterruptedException {
  	 
  	String line = value.toString();
  	 
  	String[] fields = StringUtils.split(line, "\t");
  	 
  	try {
  	String url = fields[26];
  	 
  	// 对这一行日志中的url去知识库中查找内容分析信息
  	String content = knowledgeMap.get(url);
  	 
  	// 根据内容信息匹配的结果，来构造两种输出结果
  	String result = "";
  	if (null == content) {
  	// 输往待爬清单的内容
  	result = url + "\t" + "tocrawl\n";
  	} else {
  	// 输往增强日志的内容
  	result = line + "\t" + content + "\n";
  	}
  	 
  	context.write(new Text(result), NullWritable.get());
  	} catch (Exception e) {
  	 
  	}
  	}
  	 
  	}
  	 
  	public static void main(String[] args) throws Exception {
  	 
  	Configuration conf = new Configuration();
  	 
  	Job job = Job.getInstance(conf);
  	 
  	job.setJarByClass(LogEnhancer.class);
  	 
  	job.setMapperClass(LogEnhancerMapper.class);
  	 
  	job.setOutputKeyClass(Text.class);
  	job.setOutputValueClass(NullWritable.class);
  	 
  	// 要将自定义的输出格式组件设置到job中
  	job.setOutputFormatClass(LogEnhancerOutputFormat.class);
  	 
  	FileInputFormat.setInputPaths(job, new Path(args[0]));
  	 
  	// 虽然我们自定义了outputformat，但是因为我们的outputformat继承自fileoutputformat
  	// 而fileoutputformat要输出一个_SUCCESS文件，所以，在这还得指定一个输出目录
  	FileOutputFormat.setOutputPath(job, new Path(args[1]));
  	 
  	job.waitForCompletion(true);
  	System.exit(0);
  	 
  	}
  	 
  	}

  ```

  ​















































