- [9张图，32个案例带你轻松玩转Java stream](https://mp.weixin.qq.com/s/GKi3f18Kks-rD8UNAiowKQ)

Java8 中增加了 Stream 处理，可以配合 Lambda 表达式来使用，让操作集合非常便利。虽然我们平时经常使用 Stream，但用到的方法其实非常少，这篇文章就来完整的介绍 Stream 的使用。

![image-20220125204153526](https://gitee.com/er-huomeng/img/raw/master/img/image-20220125204153526.png)

Stream 提供的方法非常多，按照调用当前方法是否结束流处理，可以分为中间操作和结束操作。

对于中间操作，又可以分为有状态的操作和无状态操作：

- 无状态的操作是指当前元素的操作不受前面元素的影响。
- 有状态的操作是指当前元素的操作需要等所有元素处理完之后才能进行。

对于结束操作，又可以分为短路操作和非短路操作，具体如下：

- 短路操作是指不需要处理完全部的元素就可以结束。
- 非短路操作是指必须处理完所有元素才能结束。

## 1 创建 Stream

### 1.1 使用集合创建

```
List<Integer> list = Arrays.asList(5, 2, 3, 1, 4);
Stream stream = list.stream();
```

### 1.2 使用数组创建

```
String[] array={"ab", "abc", "abcd", "abcde", "abcdef" };
Stream<String> stream = Arrays.stream(array);
```

### 1.3 使用 Stream 静态方法

```
Stream<String> stream = Stream.of("ab", "abc", "abcd", "abcde", "abcdef");

Stream<Integer> stream2 = Stream.iterate(0, (x) -> x + 3).limit(5);
stream2.forEach(r -> System.out.print(r + " "));

System.out.println();

Stream<Integer> stream3 = Stream.generate(new Random()::nextInt).limit(3);
stream3.forEach(r -> System.out.print(r + " "));
```

上面代码输出如下：

> 0 3 6 9 12 
>
> -150231306 -1769565695 102740625

## 2 无状态操作

![image-20220125204214680](https://gitee.com/er-huomeng/img/raw/master/img/image-20220125204214680.png)

### 2.1 map

接收一个函数作为入参，把这个函数应用到每个元素上，执行结果组成一个新的 stream 返回。

![image-20220125204223913](https://gitee.com/er-huomeng/img/raw/master/img/image-20220125204223913.png)

案例 1：对整数数组每个元素加 3 ：

```
List<Integer> list = Arrays.asList(5, 2, 3, 1, 4);
List<Integer> newList = list.stream().map(x -> x + 3).collect(Collectors.toList());
System.out.println("newList:" + newList);
```

上面代码输出结果如下：

> newList:[8, 5, 6, 4, 7]

案例 2：把字符串数组的每个元素转换为大写：

```
List<String> list = Arrays.asList("ab", "abc", "abcd", "abcde", "abcdef");
List<String> newList = list.stream().map(String::toUpperCase).collect(Collectors.toList());
System.out.println("newList:" + newList);
```

上面代码输出结果如下：

> newList:[AB, ABC, ABCD, ABCDE, ABCDEF]

### 2.2 mapToXXX

包括三个方法：mapToInt、mapToDouble、mapToLong

案例 3：把字符串数组转为整数数组：

```
List<String> list = Arrays.asList("ab", "abc", "abcd", "abcde", "abcdef");
int[] newList = list.stream().mapToInt(r -> r.length()).toArray();
System.out.println("newList:" + Arrays.toString(newList));
```

上面代码输出结果如下：

> newList:[2, 3, 4, 5, 6]

### 2.3 flatMap

flatMap接收函数作为入参，然后把集合中每个元素转换成一个 stream，再把这些 stream 组成一个新的 stream，是拆分单词很好的工具。如下图：

![image-20220125204235417](https://gitee.com/er-huomeng/img/raw/master/img/image-20220125204235417.png)

案例 4：把一个字符串数组转成另一个字符串数组：

```
List<String> list = Arrays.asList("ab-abc-abcd-abcde-abcdef", "5-2-3-1-4");
List<String> newList = list.stream().flatMap(s -> Arrays.stream(s.split("-"))).collect(Collectors.toList());
System.out.println("newList：" + newList);
```

上面代码输出结果：

> newList：[ab, abc, abcd, abcde, abcdef, 5, 2, 3, 1, 4]

### 2.4 flatMapToXXX

类似于 flatMap，返回一个 XXXStream。

包括三个方法：flatMapToInt、flatMapToLong、flatMapToDouble

案例 5：对给定的二维整数数组求和:

```
int[][] data = {{1,2},{3,4},{5,6}};
IntStream intStream = Arrays.stream(data).flatMapToInt(row -> Arrays.stream(row));
System.out.println(intStream.sum());
```

输出结果为：21。

### 2.5 filter

筛选功能，按照一定的规则将符合条件的元素提取到新的流中。

定义一个学生类，包含姓名、年龄、性别、考试成绩四个属性：

```
class Student{
    private String name;
    private Integer age;
    private String sex;
    private Integer score;

    public Student(String name, Integer age, String sex, Integer score){
        this.name = name;
        this.age = age;
        this.score = score;
        this.sex = sex;
    }
    //省略getters/setters
}
```

案例 6：找出考试成绩在 90 分以上的学生姓名：

```
List<Student> students = new ArrayList<>();
students.add(new Student("Mike", 10, "male", 88));
students.add(new Student("Jack", 13,"male", 90));
students.add(new Student("Lucy", 15,"female", 100));
students.add(new Student("Jessie", 12,"female", 78));
students.add(new Student("Allon", 16,"female", 92));
students.add(new Student("Alis", 22,"female", 50));

List<String> nameList = students.stream().filter(x -> x.getScore() >= 90).map(Student::getName).collect(Collectors.toList());
System.out.print("考试成绩90分以上的学生姓名：" + nameList);
```

输出如下：

> 考试成绩90分以上的学生姓名：[Jack, Lucy, Allon]

### 2.6 peek

返回由 stream 中元素组成的新 stream，用给定的函数作用在新 stream 的每个元素上。传入的函数是一个 Consume  类型的，没有返回值，因此并不会改变原 stream 中元素的值。peek 主要用是 debug，可以方便地 查看流处理结果是否正确。

案例 7：过滤出 stream 中长度大于 3 的字符串并转为大写：

```
Stream.of("one", "two", "three", "four")
             .filter(e -> e.length() > 3)
             .peek(e -> System.out.println("Filtered value: " + e))
             .map(String::toUpperCase)
             .peek(e -> System.out.println("Mapped value: " + e))
             .collect(Collectors.toList());
```

输出结果如下：

> Filtered value: three 
>
> Mapped value: THREE 
>
> Filtered value: four 
>
> Mapped value: FOUR

### 2.7 unordered

把一个有序的 stream 转成一个无序 stream ，如果原 stream 本身就是无序的，可能会返回原始的 stream。

案例 8：把一个有序数组转成无序

```
Arrays.asList("1", "2", "3", "4", "5")
                .parallelStream()
                .unordered()
                .forEach(r -> System.out.print(r + " "));
```

每次执行输出的结果不一样，下面是一次输出的结果：

> 3 5 4 2 1

## 3 有状态操作

![图片](data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQImWNgYGBgAAAABQABh6FO1AAAAABJRU5ErkJggg==)

### 3.1 distinct

去重功能。

案例 9 ：去掉字符串数组中的重复字符串

```
String[] array = { "a", "b", "b", "c", "c", "d", "d", "e", "e"};
List<String> newList = Arrays.stream(array).distinct().collect(Collectors.toList());
System.out.println("newList:" + newList);
```

输出结果：

> newList:[a, b, c, d, e]

### 3.2 limit

限制从 stream 中获取前 n 个元素。

案例 10 ：从数组中获取前 5 个元素

```
String[] array = { "c", "c", "a", "b", "b", "e", "e", "d", "d"};
List<String> newList = Arrays.stream(array).limit(5).collect(Collectors.toList());
System.out.println("newList:" + newList);
```

输出结果：

> newList:[c, c, a, b, b]

### 3.3 skip

跳过 Stream 中前 n 个元素

案例 11：从数组中获取第 5 个元素之后的元素

```
String[] array = { "a", "b", "c", "d", "e", "f", "g", "h", "i"};
List<String> newList = Arrays.stream(array).skip(5).collect(Collectors.toList());
System.out.println("newList:" + newList);
```

输出结果：

> newList:[f, g, h, i]

### 3.4 sorted

排序功能。

案例 12：对给定数组进行排序

```
String[] array = { "c", "c", "a", "b", "b", "e", "e", "d", "d"};
List<String> newList = Arrays.stream(array).sorted().collect(Collectors.toList());
System.out.println("newList:" + newList);
```

输出结果：

> newList:[a, b, b, c, c, d, d, e, e]

案例 13：按照学生成绩进行排序

```
List<Student> students = new ArrayList<>();
students.add(new Student("Mike", 10, "male", 88));
students.add(new Student("Jack", 13,"male", 90));
students.add(new Student("Lucy", 15,"female", 100));
students.add(new Student("Jessie", 12,"female", 78));
students.add(new Student("Allon", 16,"female", 92));
students.add(new Student("Alis", 22,"female", 50));

List<String> nameList = students.stream().sorted(Comparator.comparing(Student::getScore)).map(Student::getName).collect(Collectors.toList());
System.out.print("按成绩排序输出学生姓名：" + nameList);
```

输出结果：

> 考试成绩90分以上的学生姓名：[Alis, Jessie, Mike, Jack, Allon, Lucy]

## 4 短路操作

![image-20220125204247933](https://gitee.com/er-huomeng/img/raw/master/img/image-20220125204247933.png)

### 4.1 findAny

找出 stream 中任何一个满足过滤条件的元素。

案例 14：找出任何一个成绩高于 90 分的学生

```
List<Student> students = new ArrayList<>();
students.add(new Student("Mike", 10, "male", 88));
students.add(new Student("Jack", 13,"male", 90));
students.add(new Student("Lucy", 15,"female", 100));
students.add(new Student("Jessie", 12,"female", 78));
students.add(new Student("Allon", 16,"female", 92));
students.add(new Student("Alis", 22,"female", 50));

Optional<Student> studentFindAny = students.stream().filter(x -> x.getScore() > 90).findAny();
System.out.print("找出任意一个考试成绩在90分以上的学生姓名：" + studentFindAny.orElseGet(null).getName());
```

输出结果：

> 找出任意一个考试成绩在90分以上的学生姓名：Lucy

### 4.2 anyMatch

是否存在任意一个满足给定条件的元素。

案例 15：是否存在成绩高于 90 分的学生，是否存在成绩低于 50 分的学生。还是采用上面案例 14 中的学生集合。

```
boolean result1 = students.stream().anyMatch(x -> x.getScore() > 90);
System.out.println("是否存在成绩高于 90 分的学生：" + result1);
boolean result2 = students.stream().anyMatch(x -> x.getScore() < 50);
System.out.print("是否存在成绩低于 50 分的学生：" + result2);
```

输出结果：

> 是否存在成绩高于 90 分的学生：true
>
> 是否存在成绩低于 50 分的学生：false

### 4.3 allMatch

是否集合中所有元素都满足给定的条件，如果集合是空，则返回 true。

案例 16：学生成绩是否都高于 90 分，是否都高于 50 分。还是采用上面案例 14 中的学生集合。

```
boolean result1 = students.stream().allMatch(x -> x.getScore() > 90);
System.out.println("是否所有学生的成绩都高于90分：" + result1);
boolean result2 = students.stream().allMatch(x -> x.getScore() > 50);
System.out.print("是否所有学生的成绩都高于50分：" + result2);
```

输出结果：

> 是否所有学生的成绩都高于90分：false
>
> 是否所有学生的成绩都高于50分：true

### 4.4 noneMatch

是否没有元素能匹配给定的条件，如果集合是空，则返回 true。

案例 17：是不是没有学生成绩在 90 分以上，是否没有学生成绩在 50 分以下。还是采用上面案例 14 中的学生集合。

```
boolean result1 = students.stream().noneMatch(x -> x.getScore() > 90);
System.out.println("是不是没有学生成绩在 90 分以上：" + result1);
boolean result2 = students.stream().noneMatch(x -> x.getScore() < 50);
System.out.print("是不是没有学生成绩在 50 分以下：" + result2);
```

输出结果：

> 是不是没有学生成绩在 90 分以上：false
>
> 是不是没有学生成绩在 50 分以下：true

### 4.5 findFirst

找出第一个符合条件的元素。

案例 18：找出第一个成绩在 90 分以上的学生。还是采用上面案例 14 中的学生集合。

```
Optional<Student> studentFindAny = students.stream().filter(x -> x.getScore() > 90).findFirst();
System.out.print("第一个成绩在 90 分以上的学生姓名：" + studentFindAny.orElseGet(null).getName());
```

输出结果：

> 第一个成绩在 90 分以上的学生姓名：Lucy

## 5 非短路操作

![image-20220125204255819](https://gitee.com/er-huomeng/img/raw/master/img/image-20220125204255819.png)

### 5.1 forEach

遍历元素。

案例 19：遍历一个数组并打印

```
List<Integer> array = Arrays.asList(5, 2, 3, 1, 4);
array.stream().forEach(System.out :: println);
```

输出结果：

> 5 2 3 1 4

### 5.2 forEachOrdered

按照给定集合中元素的顺序输出。主要使用场景是在并行流的情况下，按照给定的顺序输出元素。

案例 20：用并行流遍历一个数组并按照给定数组的顺序输出结果

```
List<Integer> array = Arrays.asList(5, 2, 3, 1, 4);
array.parallelStream().forEachOrdered(System.out :: println);
```

输出结果：

> 5 2 3 1 4

### 5.3 toArray

返回包括给定 stream 中所有元素的数组。

案例 21：把给定字符串流转化成数组

```
Stream<String> stream = Arrays.asList("ab", "abc", "abcd", "abcde", "abcdef").stream();
String[] newArray1 = stream.toArray(str -> new String[5]);
String[] newArray2 = stream.toArray(String[]::new);
Object[] newArray3 = stream.toArray();
```

### 5.4 reduce

规约操作，把一个流的所有元素合并成一个元素，比如求和、求乘积、求最大最小值等。

案例 22：求整数数组元素之和、乘积和最大值

```
List<Integer> list = Arrays.asList(5, 2, 3, 1, 4);
Optional<Integer> sum = list.stream().reduce((x, y) -> x + y);
Optional<Integer> product = list.stream().reduce((x, y) -> x * y);
Optional<Integer> max = list.stream().reduce((x, y) -> x > y ? x : y);
System.out.println("数组元素之和：" + sum.get());
System.out.println("数组元素乘积：" + product.get());
System.out.println("数组元素最大值：" + max.get());
```

输出结果：

> 数组元素之和：15
>
> 数组元素乘积：120 
>
> 数组元素最大值：5

案例 23：求全班学生最高分、全班学生总分

```
List<Student> students = new ArrayList<>();
students.add(new Student("Mike", 10, "male", 88));
students.add(new Student("Jack", 13,"male", 90));
students.add(new Student("Lucy", 15,"female", 100));
students.add(new Student("Jessie", 12,"female", 78));
students.add(new Student("Allon", 16,"female", 92));
students.add(new Student("Alis", 22,"female", 50));
Optional<Integer> maxScore = students.stream().map(r -> r.getScore()).reduce(Integer::max);
Optional<Integer> sumScore = students.stream().map(r -> r.getScore()).reduce(Integer::sum);
System.out.println("全班学生最高分：" + maxScore.get());
System.out.println("全班学生总分：" + sumScore.get());
```

输出结果：

> 全班学生最高分：100 
>
> 全班学生总分：498

### 5.5 collect

把 stream 中的元素归集到新的集合或者归集成单个元素。

#### 5.5.1 归集成新集合

方法包括 toList、toSet、toMap。

案例 24：根据学生列表，归纳出姓名列表、不同分数列表、姓名分数集合，其中 Mike 和 Jessie 的分数都是 88。

```
List<Student> students = new ArrayList<>();
students.add(new Student("Mike", 10, "male", 88));
students.add(new Student("Jack", 13,"male", 90));
students.add(new Student("Lucy", 15,"female", 100));
students.add(new Student("Jessie", 12,"female", 88));
students.add(new Student("Allon", 16,"female", 92));
students.add(new Student("Alis", 22,"female", 50));
List<String> list = students.stream().map(r -> r.getName()).collect(Collectors.toList());
Set<Integer> set = students.stream().map(r -> r.getScore()).collect(Collectors.toSet());
Map<String, Integer> map = students.stream().collect(Collectors.toMap(Student::getName, Student::getScore));
System.out.println("全班学生姓名列表：" + list);
System.out.println("全班学生不同分数列表：" + set);
System.out.println("全班学生姓名分数集合：" + map);
```

输出结果：

> 全班学生姓名列表：[Mike, Jack, Lucy, Jessie, Allon, Alis] 
>
> 全班学生不同分数列表：[50, 100, 88, 90, 92] 
>
> 全班学生姓名分数集合：{Mike=88, Allon=92, Alis=50, Lucy=100, Jack=90, Jessie=88}

#### 5.5.2 统计功能

![image-20220125204304569](https://gitee.com/er-huomeng/img/raw/master/img/image-20220125204304569.png)

统计功能包括如下方法：

![image-20220125204311497](https://gitee.com/er-huomeng/img/raw/master/img/image-20220125204311497.png)

案例 25：求总数、求和、最大/最小/平均值

```
List<Integer> list = Arrays.asList(5, 2, 3, 1, 4);
long count = list.stream().collect(Collectors.counting());
int sum = list.stream().collect(Collectors.summingInt(r -> r));
double average = list.stream().collect(Collectors.averagingDouble(r -> r));
Optional<Integer> max = list.stream().collect(Collectors.maxBy(Integer::compare));
Optional<Integer> min = list.stream().collect(Collectors.maxBy((x, y) -> x > y ? y : x));
System.out.println("总数:" + count);
System.out.println("总和:" + sum);
System.out.println("平均值:" + average);
System.out.println("最大值:" + max.get());
System.out.println("最小值:" + min.get());
```

输出结果：

> 总数:5 
>
> 总和:15 
>
> 平均值:3.0 
>
> 最大值:5 
>
> 最小值:5

案例 26：求总和统计

```
List<Integer> list = Arrays.asList(5, 2, 3, 1, 4);
IntSummaryStatistics statistics = list.stream().collect(Collectors.summarizingInt(r -> r));
System.out.println("综合统计结果：" + statistics.toString());
```

输出结果：

> 综合统计结果：IntSummaryStatistics{count=5, sum=15, min=1, average=3.000000, max=5}

#### 5.5.3 分区和分组

主要包括两个函数：

- partitioningBy：把 stream 分成两个 map
- groupingBy：把 stream 分成多个 map

案例 27：将学生按照 80 分以上和以下分区

```
List<Student> students = new ArrayList<>();
students.add(new Student("Mike", 10, "male", 88));
students.add(new Student("Jack", 10,"male", 90));
students.add(new Student("Lucy", 12,"female", 100));
students.add(new Student("Jessie", 12,"female", 78));
students.add(new Student("Allon", 16,"female", 92));
students.add(new Student("Alis", 16,"female", 50));
Map<Boolean, List<Student>> partitionByScore = students.stream().collect(Collectors.partitioningBy(x -> x.getScore() > 80));
System.out.println("将学生按照考试成绩80分以上分区：");
partitionByScore.forEach((k,v ) -> {
    System.out.print(k ? "80分以上：" : "80分以下：");
    v.forEach(r -> System.out.print(r.getName() + ","));
    System.out.println();
});
System.out.println();
```

分区结果是把 Student 列表分成 key 只有 true 和 false 两个值的 map，输出如下：

> 将学生按照考试成绩80分以上分区：
>
> 80分以下：Jessie,Alis,
>
> 80分以上：Mike,Jack,Lucy,Allon,

案例 28：将学生按照性别、年龄分组

```
Map<String, Map<Integer, List<Student>>> group = students.stream().collect(Collectors.groupingBy(Student::getSex, Collectors.groupingBy(Student::getAge)));
System.out.println("将学生按照性别、年龄分组：");
group.forEach((k,v ) -> {
    System.out.println(k +"：");
    v.forEach((k1,v1) -> {
        System.out.print("      " + k1 + ":" );
        v1.forEach(r -> System.out.print(r.getName() + ","));
        System.out.println();
    });
});
```

输出如下：

> 将学生按照性别、年龄分组：
>
> female：
>
>    16:Allon,Alis, 
>
>    12:Lucy,Jessie, 
>
> male：
>
>    10:Mike,Jack,

#### 5.5.4 连接

将 stream 中的元素用指定的连接符合并，连接符可以是空。

案例 29：输出所有学生的姓名，用逗号分隔，这里还是使用案例 27 中的学生列表

```
String studentNames = students.stream().map(r -> r.getName()).collect(Collectors.joining(","));
System.out.println("所有学生姓名列表：" + studentNames);
```

输出如下：

> 所有学生姓名列表：Mike,Jack,Lucy,Jessie,Allon,Alis

#### 5.5.5 规约

在 5.4 节已经讲过规约了，这里的规约支持更强大的自定义规约。

案例 30：数组中每个元素加 1 后求总和

```
List<Integer> list = Arrays.asList(5, 2, 3, 1, 4);
int listSum = list.stream().collect(Collectors.reducing(0, x -> x + 1, (sum, b) -> sum + b));
System.out.println("数组中每个元素加 1 后总和：" + listSum);
```

输出结果：

> 数组中每个元素加 1 后总和：20

### 5.6 max、min、count

stream 提供的方便统计的方法。

案例 31：统计整数数组中最大值、最小值、大于 3 的元素个数

```
List<Integer> list = Arrays.asList(5, 2, 3, 1, 4);
System.out.println("数组元素最大值："+list.stream().max(Integer::compareTo).get());
System.out.println("数组元素最小值："+list.stream().min(Integer::compareTo).get());
System.out.println("数组中大于3的元素个数："+list.stream().filter(x -> x > 3).count());
```

输出结果：

> 数组元素最大值：5 
>
> 数组元素最小值：1 
>
> 数组中大于3的元素个数：2

案例 32：统计分数最高的学生姓名

```
List<Student> students = new ArrayList<>();
students.add(new Student("Mike", 10, "male", 88));
students.add(new Student("Jack", 10,"male", 90));
students.add(new Student("Lucy", 12,"female", 100));
students.add(new Student("Jessie", 12,"female", 78));
students.add(new Student("Allon", 16,"female", 92));
students.add(new Student("Alis", 16,"female", 50));
Optional<Student> optional = students.stream().max(Comparator.comparing(r -> r.getScore()));
System.out.println("成绩最高的学生姓名：" + optional.get().getName());
```

输出结果：

> 成绩最高的学生姓名：Lucy