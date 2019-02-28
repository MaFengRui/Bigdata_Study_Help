# Scala

## 什么是函数式编程？

```
面向函数
纯函数概念，
函数在当做变量使用，当参数，返回值，高阶函数
```

```
scala 静态语言
推断机制,

python是虽然有推断机制但是他是动态原因

val 推荐使用，效率高，官方使用，垃圾回收优先

与java比较只有++ --,不一样， 在scala中是-= ，+=

表达式的特点：有返回值，最后一句。scala中的表达式是有值的, 所以可以把表达式当做参数来传递, 那么接受表达式的形参定义一般是: block: =>Unit   , 没有形参,返回类型Unit。
```

```
跳出循环
breakable 如何实现breake与cuntine
```

````
方法与函数的区别？
````

## 隐式转换

出现的原因：我们可以随便修改自己的代码和库函数，但是使用别人的只能原封不动的使用

出现的时机： 隐式转换的发生时机:

    1、调用某个函数，但是给函数传入的参数类型，与函数定义的签名不匹配。

    2、使用某个类型对象，调用某个方法，而这个方法并不存在于该类型时。

​    3、使用某个类型对象，调用某个方法，虽然该类型有这个方法，但是给方法传入的参数类型与签名并不一致的时候



 ```
隐式转换就是扩充现有的方法库，使用起来更加灵活！
scala的办法是隐式转换和隐式参数
 ```

## 类与对象

类是对象的抽象，而对象是类的具体实例。类是抽象的，不占用内存，而对象是具体的，占用存储空间。类是用于创建对象的蓝图，它是一个定义包括在特定类型的对象中的方法和变量的软件模板。

我们可以使用 new 关键字来创建类的对象，实例如下：

```scala
Scala 的类定义可以有参数，称为类参数 xc, yc，类参数在整个类中都可以访问。
class Point(xc: Int, yc: Int) {
   var x: Int = xc
   var y: Int = yc
   def move(dx: Int, dy: Int) {
      x = x + dx
      y = y + dy
      println ("x 的坐标点: " + x);
      println ("y 的坐标点: " + y);
   }
}
//Scala中的类不声明为public，一个Scala源文件中可以有多个类。
//以上实例的类定义了两个变量 x 和 y ，一个方法：move，方法没有返回值。
```

接着我们可以使用 new 来实例化类，并访问类中的方法和变量：

```scala
import java.io._

class Point(xc: Int, yc: Int) {
   var x: Int = xc
   var y: Int = yc

   def move(dx: Int, dy: Int) {
      x = x + dx
      y = y + dy
      println ("x 的坐标点: " + x);
      println ("y 的坐标点: " + y);
   }
}

object Test {
   def main(args: Array[String]) {
      val pt = new Point(10, 20);

      // 移到一个新的位置
      pt.move(10, 10);
   }
}
```

## Scala 单例对象

在 Scala 中，是没有 static 这个东西的，但是它也为我们提供了单例模式的实现方法，那就是使用关键字 object。

Scala 中使用单例模式时，除了定义的类之外，还要定义一个同名的 object 对象，它和类的区别是，object对象不能带参数。

当单例对象与某个类共享同一个名称时，他被称作是这个类的伴生对象：companion object。你必须在同一个源文件里定义类和它的伴生对象。类被称为是这个单例对象的伴生类：companion class。类和它的伴生对象可以互相访问其私有成员。

```

```

## option

## Product

## truit

## Case Class

Case Class是Scala语言[模式匹配](http://en.wikipedia.org/wiki/Pattern_matching)功能的基础。如果定义类的时候加上**case**关键字，那么它就变成了Case Class，比如下面这个简单的类CC：

```scala
case class CC(x: Int, y: Int)
```

### 	好处

①Scala默认会创建一个单例对象

````java

public final class CC$ extends scala.runtime.AbstractFunction2 implements scala.Serializable { 
    public static final CC$ MODULE$;
    static {
        new CC$();
    }
    private CC$() {
        MODULE$ = this;
    }
    public Object readResolve() {
        return MODULE$;
    }
````

②自带apply(不用new),与unapply方法，不需要手动创建

```java
public final class CC$ ... {
    ...
    public CC apply(int x, int y) {
        return new CC(x, y);
    }
    public scala.Option<scala.Tuple2<Object, Object>> unapply(CC cc) {
        if (cc == null) {
            return scala.None$.MODULE$;
        }
        return new scala.Some(new scala.Tuple2$mcll$sp(cc.x, cc.y))
    } 
```



③Case Class默认是Immutable

````java

public class CC implements scala.Product, scala.Serializable {
    
    private final int x;
    private final int y;
 
    public CC(int x, int y) {
        this.x = x;
        this.y = y;
        scala.Product$class.$init$(this);
    }
 
    public int x() {
        return x;
    }
    public int y() {
        return y;
    }
````

④实现Product和Serializable接口

Case类还实现了scala.Product和scala.Serializable接口（Product和Serializable实际上都是Traits）。







