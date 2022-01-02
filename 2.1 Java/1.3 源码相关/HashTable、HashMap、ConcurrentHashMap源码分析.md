- [HashTable、HashMap、ConcurrentHashMap源码分析](https://blog.noheart.cn/archives/hashjava#%E4%B8%83%E4%B8%89%E8%80%85%E7%9A%84%E5%BC%82%E5%90%8C)

说这三个数据结构之前，得先讲讲什么是Hash算法。

## 一、Hash算法。

官方说法：

```java
Hash，一般翻译做散列、杂凑，或音译为哈希，是把任意长度的输入（又叫做预映射pre-image）
通过散列算法变换成固定长度的输出，该输出就是散列值。这种转换是一种压缩映射,
也就是，散列值的空间通常远小于输入的空间，不同的输入可能会散列成相同的输出，所以不可能从散列值来确定唯一的输入值。
简单的说就是一种将任意长度的消息压缩到某一固定长度的消息摘要的函数。
```

需要注意的是，Hash算法 不是某个固定的算法，它代表的是一类算法。

### 1.1 常见hash算法的原理

#### 1.1.1 散列表

- 它是基于快速存取的角度设计的，也是一种典型的“空间换时间”的做法。顾名思义，该数据结构可以理解为一个线性表，但是其中的元素不是紧密排列的，而是可能存在空隙。
- 散列表（Hash table，也叫哈希表），是根据关键码值（Key value）而直接进行访问的数据结构。也就是说，它通过把关键码值映射到表中一个位置来访问记录，以加快查找的速度。这个映射函数叫做散列函数，存放记录的数组叫做散列表。
- 比如我们存储70个元素，但我们可能为这70个元素申请了100个元素的空间。70/100=0.7，这个数字称为**负载因子**。我们之所以这样做，也是为了“快速存取”的目的。
- 我们基于一种结果尽可能随机平均分布的固定函数H为每个元素安排存储位置，这样就可以避免遍历性质的线性搜索，以达到快速存取。但是由于此随机性，也必然导致一个问题就是冲突。
- 所谓冲突，即两个元素通过散列函数H得到的地址相同，那么这两个元素称为“同义词”。
- 这类似于70个人去一个有100个椅子的饭店吃饭。散列函数的计算结果是一个存储单位地址，每个存储单位称为“桶”。设一个散列表有m个桶，则散列函数的值域应为［0，m-1］。

#### 1.1.2 举个例子：一个很简单的算法,对数组长度取模。

这样就会出现一个问题，这样算难免会出现算出来的数字是一样的：

比如数组长度为16，我们要放入数字1和17，那么他们经过对数组长度取模后位置是一样的，都要放到1这个位置，这样就产生了**Hash冲突**。我们就可以在数组下拉出一个链表去存储这个数字

![hash](https://icefiredb-1300435688.piccd.myqcloud.com/betsy/hash_1601303554386.png)

#### 1.1.3 解决冲突是一个复杂问题

冲突主要取决于：

1. 散列函数，一个好的散列函数的值应尽可能平均分布。
2. 处理冲突方法。
3. 负载因子的大小。太大不一定就好，而且浪费空间严重，负载因子和散列函数是联动的。

#### 1.1.4 解决冲突的办法

1. 线性探查法：冲突后，线性向前试探，找到最近的一个空位置。缺点是会出现堆积现象。存取时，可能不是同义词的词也位于探查序列，影响效率。
2. 双散列函数法：在位置d冲突后，再次使用另一个散列函数产生一个与散列表桶容量m互质的数c，依次试探（d+n*c）%m，使探查序列跳跃式分布。

#### 1.1.5 查找的性能分析

　　查找过程中，关键码的比较次数，取决于产生冲突的多少，产生的冲突少，查找效率就高，产生的冲突多，查找效率就低。因此，影响产生冲突多少的因素，也就是影响查找效率的因素。影响产生冲突多少有以下三个因素：

1. 散列函数是否均匀；
2. 处理冲突的方法；
3. 散列表的装填因子。
    散列表的装填因子定义为：α= 填入表中的元素个数 / 散列表的长度
    　α是散列表装满程度的标志因子。由于表长是定值，α与“填入表中的元素个数”成正比，所以，α越大，填入表中的元素较多，产生冲突的可能性就越大；α越小，填入表中的元素较少，产生冲突的可能性就越小。
    　实际上，散列表的平均查找长度是装填因子α的函数，只是不同处理冲突的方法有不同的函数。

#### 1.1.6 哈希表不可避免冲突（collision）现象：

　　对不同的关键字可能得到同一哈希地址  即key1≠key2，而hash（key1）=hash（key2）。因此，在建造哈希表时不仅要设定一个好的哈希函数，而且要设定一种处理冲突的方法。可如下描述哈希表：根据设定的哈希函数H（key）和所选中的处理冲突的方法，将一组关键字映象到一个有限的、地址连续的地址集（区间）上并以关键字在地址集中的“象”作为相应记录在表中的存储位置，这种表被称为哈希表。

> Hash表  是一种逻辑数据结构，Java中HashMap实现了散列表，而Hashtable比它多了一个线程安全性，但是由于使用了全局锁导致其性能较低，基本废弃，所以现在一般用ConcurrentHashMap来实现线程安全的HashMap（类似的，以上的数据结构在最新的java.util.concurrent的包中几乎都有对应的高性能的线程安全的类）。我们开始深入源码理解下，当然不是为了找虐，主要也是可以学习到优秀的代码、思想和设计模式。

说完了hash算法，我们开始步入正题，先说HashTable：

- 以下描述来自于HashTable的类注释：

```java
If a thread-safe implementation is not needed, it is recommended to use HashMap in place of Hashtable. 
If a thread-safe highly-concurrent implementation is desired, then it is recommended to use java.util.concurrent.ConcurrentHashMap in place of Hashtable.
```

- 虽然HashTable已经基本废弃不用了，但是读读源码理解下作者的思考角度也是有意思的一件事；

## 二、HashTable

- 跟HashMap一样，Hashtable 也是一个散列表，它存储的内容是键值对(key-value)映射。
- Hashtable 继承于Dictionary，实现了Map、Cloneable、java.io.Serializable接口。
- Hashtable 的函数都是同步的，这意味着它是线程安全的。它的key、value都不可以为null。
- Hashtable中的映射不是有序的。
- Hashtable是通过"拉链法"实现的哈希表。
- Hashtable 的实例有两个参数影响其性能：初始容量 和 加载因子。
- 容量 是哈希表中桶 的数量，初始容量 就是哈希表创建时的容量。
- 在发生“哈希冲突”的情况下，单个桶会存储多个条目，这些条目必须按顺序搜索。
- 加载因子 是对哈希表在其容量自动增加之前可以达到多满的一个尺度。初始容量和加载因子这两个参数只是对该实现的提示。
- 通常，默认加载因子是 0.75, 这是在时间和空间成本上寻求一种折衷。
- 加载因子过高虽然减少了空间开销，但同时也增加了查找某个条目的时间。
   如下图，为hashtable基本的结构图:
   ![hashtablem](https://icefiredb-1300435688.piccd.myqcloud.com/betsy/hashtablem_1601345922202.png)

### 2.1 Hashtable的构造函数:

```java
	public Hashtable(int initialCapacity, float loadFactor) {//可指定初始容量和加载因子  
        if (initialCapacity < 0)  
            throw new IllegalArgumentException("Illegal Capacity: "+  
                                               initialCapacity);  
        if (loadFactor <= 0 || Float.isNaN(loadFactor))  
            throw new IllegalArgumentException("Illegal Load: "+loadFactor);  
        if (initialCapacity==0)  
            initialCapacity = 1;//初始容量最小值为1  
        this.loadFactor = loadFactor;  
        table = new Entry[initialCapacity];//创建桶数组  
        threshold = (int)Math.min(initialCapacity * loadFactor, MAX_ARRAY_SIZE + 1);//初始化容量阈值  
        useAltHashing = sun.misc.VM.isBooted() &&  
                (initialCapacity >= Holder.ALTERNATIVE_HASHING_THRESHOLD);  
    }  
    /** 
     * Constructs a new, empty hashtable with the specified initial capacity 
     * and default load factor (0.75). 
     */  
    public Hashtable(int initialCapacity) {  
        this(initialCapacity, 0.75f);//默认负载因子为0.75  
    }  
    public Hashtable() {  
        this(11, 0.75f);//默认容量为11，负载因子为0.75  
    }  
    /** 
     * Constructs a new hashtable with the same mappings as the given 
     * Map.  The hashtable is created with an initial capacity sufficient to 
     * hold the mappings in the given Map and a default load factor (0.75). 
     */  
    public Hashtable(Map<? extends K, ? extends V> t) {  
        this(Math.max(2*t.size(), 11), 0.75f);  
        putAll(t);  
    }  
```

### 2.2 需注意的点：

1. Hashtable的默认容量为11，默认负载因子为0.75.(HashMap默认容量为16，默认负载因子也是0.75)
2. Hashtable的容量可以为任意整数，最小值为1，而HashMap的容量始终为2的n次方。
3. 为避免扩容带来的性能问题，建议指定合理容量。
4. 跟HashMap一样，Hashtable内部也有一个静态类叫Entry，其实是个键值对对象，保存了键和值的引用。
5. HashMap和Hashtable存储的是键值对对象，而不是单独的键或值。

#### 2.2.1 Hashtable的继承关系：

```java
	java.lang.Object
	   ↳     java.util.Dictionary<K, V>
			 ↳     java.util.Hashtable<K, V>
 
	public class Hashtable<K,V> extends Dictionary<K,V>
		implements Map<K,V>, Cloneable, java.io.Serializable { }
```

1. Hashtable继承于Dictionary类，实现了Map接口。
    Map是"key-value键值对"接口，Dictionary是声明了操作"键值对"函数接口的抽象类。
    Dictionary是个被废弃的抽象类。
2. Hashtable是通过"拉链法"实现的哈希表。
    它包括几个重要的成员变量：table, count, threshold, loadFactor, modCount。

- table是一个Entry[]数组类型，而Entry实际上就是一个单向链表。哈希表的"key-value键值对"都是存储在Entry数组中的。
- count是Hashtable的大小，它是Hashtable保存的键值对的数量。
- threshold是Hashtable的阈值，用于判断是否需要调整Hashtable的容量。threshold的值="容量*加载因子"。
- loadFactor就是加载因子。
- modCount是用来实现fail-fast机制的

### 2.3 Hashtable存取数据：

#### 2.3.1 存数据（put操作）:

```java
	public synchronized V put(K key, V value) {//向哈希表中添加键值对  
        // Make sure the value is not null  
        if (value == null) {//确保值不能为空  
            throw new NullPointerException();  
        }  
        // Makes sure the key is not already in the hashtable.  
        Entry tab[] = table;  
        int hash = hash(key);//根据键生成hash值---->若key为null，此方法会抛异常  
        int index = (hash & 0x7FFFFFFF) % tab.length;//通过hash值找到其存储位置  
        for (Entry<K,V> e = tab[index] ; e != null ; e = e.next) {/遍历链表  
            if ((e.hash == hash) && e.key.equals(key)) {//若键相同，则新值覆盖旧值  
                V old = e.value;  
                e.value = value;  
                return old;  
            }  
        }  
        modCount++;  
        if (count >= threshold) {//当前容量超过阈值。需要扩容  
            // Rehash the table if the threshold is exceeded  
            rehash();//重新构建桶数组，并对数组中所有键值对重哈希，耗时！  
            tab = table;  
            hash = hash(key);  
            index = (hash & 0x7FFFFFFF) % tab.length;//这里是取摸运算  
        }  
        // Creates the new entry.  
        Entry<K,V> e = tab[index];  
        //将新结点插到链表首部  
        tab[index] = new Entry<>(hash, key, value, e);//生成一个新结点  
        count++;  
        return null;  
    }
```

1. Hasbtable并不允许值和键为空（null），若为空，会抛空指针。
2. HashMap计算索引的方式是h&(length-1),而Hashtable用的是模运算，效率上是低于HashMap的。
3. 另外Hashtable计算索引时将hash值先与上0x7FFFFFFF,这是为了保证hash值始终为正数。
4. 特别需要注意的是这个方法包括下面要讲的若干方法都加了synchronized关键字，也就意味着这个Hashtable是个线程安全的类，这也是它和HashMap最大的不同点.

#### 2.3.2 Hashtable扩容方法rehash：

```java
	protected void rehash() {  
        int oldCapacity = table.length;//记录旧容量  
        Entry<K,V>[] oldMap = table;//记录旧的桶数组  
        // overflow-conscious code  
        int newCapacity = (oldCapacity << 1) + 1;//新容量为老容量的2倍加1  
        if (newCapacity - MAX_ARRAY_SIZE > 0) {  
            if (oldCapacity == MAX_ARRAY_SIZE)//容量不得超过约定的最大值  
                // Keep running with MAX_ARRAY_SIZE buckets  
                return;  
            newCapacity = MAX_ARRAY_SIZE;  
        }  
        Entry<K,V>[] newMap = new Entry[newCapacity];//创建新的数组  
        modCount++;  
        threshold = (int)Math.min(newCapacity * loadFactor, MAX_ARRAY_SIZE + 1);  
        boolean currentAltHashing = useAltHashing;  
        useAltHashing = sun.misc.VM.isBooted() &&  
                (newCapacity >= Holder.ALTERNATIVE_HASHING_THRESHOLD);  
        boolean rehash = currentAltHashing ^ useAltHashing;  
        table = newMap;  
        for (int i = oldCapacity ; i-- > 0 ;) {//转移键值对到新数组  
            for (Entry<K,V> old = oldMap[i] ; old != null ; ) {  
                Entry<K,V> e = old;  
                old = old.next;  
                if (rehash) {  
                    e.hash = hash(e.key);  
                }  
                int index = (e.hash & 0x7FFFFFFF) % newCapacity;  
                e.next = newMap[index];  
                newMap[index] = e;  
            }  
        }  
    }  	
```

Hashtable每次扩容，容量都为原来的2倍加1，而HashMap为原来的2倍。

#### 2.3.3 取数据（get）操作:

```java
        public synchronized V get(Object key) {//根据键取出对应索引  
      Entry tab[] = table;  
      int hash = hash(key);//先根据key计算hash值  
      int index = (hash & 0x7FFFFFFF) % tab.length;//再根据hash值找到索引  
      for (Entry<K,V> e = tab[index] ; e != null ; e = e.next) {//遍历entry链  
          if ((e.hash == hash) && e.key.equals(key)) {//若找到该键  
              return e.value;//返回对应的值  
          }  
      }  
      return null;//否则返回null  
	}
```

当然，如果你传的参数为null，是会抛空指针的。

### 2.4 Hashtable的API：

```java
 synchronized void                clear()
 synchronized Object              clone()
  boolean             contains(Object value)
 synchronized boolean             containsKey(Object key)
 synchronized boolean             containsValue(Object value)
 synchronized Enumeration<V>      elements()
 synchronized Set<Entry<K, V>>    entrySet()
 synchronized boolean             equals(Object object)
 synchronized V                   get(Object key)
 synchronized int                 hashCode()
 synchronized boolean             isEmpty()
 synchronized Set<K>              keySet()
 synchronized Enumeration<K>      keys()
 synchronized V                   put(K key, V value)
 synchronized void                putAll(Map<? extends K, ? extends V> map)
 synchronized V                   remove(Object key)
 synchronized int                 size()
 synchronized String              toString()
 synchronized Collection<V>       values()
```

### 2.5 Hashtable的主要对外接口：

#### 1.clear() 的作用是清空Hashtable。它是将Hashtable的table数组的值全部设为null.

```java
		public synchronized void clear() {
			Entry tab[] = table;
			modCount++;
			for (int index = tab.length; --index >= 0; )
				tab[index] = null;
			count = 0;
		}
```

#### 2.contains() 和 containsValue() 的作用都是判断Hashtable是否包含“值(value)”

```java
		public boolean containsValue(Object value) {
			return contains(value);
		}
 
		public synchronized boolean contains(Object value) {
			// Hashtable中“键值对”的value不能是null，
			// 若是null的话，抛出异常!
			if (value == null) {
				throw new NullPointerException();
			}
 
 
			// 从后向前遍历table数组中的元素(Entry)
			// 对于每个Entry(单向链表)，逐个遍历，判断节点的值是否等于value
			Entry tab[] = table;
			for (int i = tab.length ; i-- > 0 ;) {
				for (Entry<K,V> e = tab[i] ; e != null ; e = e.next) {
					if (e.value.equals(value)) {
						return true;
					}
				}
			}
			return false;
		}
```

#### 3.containsKey() 的作用是判断Hashtable是否包含key

```java
		public synchronized boolean containsKey(Object key) {
			Entry tab[] = table;
			int hash = key.hashCode();
			// 计算索引值，
			// % tab.length 的目的是防止数据越界
			int index = (hash & 0x7FFFFFFF) % tab.length;
			// 找到“key对应的Entry(链表)”，然后在链表中找出“哈希值”和“键值”与key都相等的元素
			for (Entry<K,V> e = tab[index] ; e != null ; e = e.next) {
				if ((e.hash == hash) && e.key.equals(key)) {
					return true;
				}
			}
			return false;
		}
```

#### 4.elements() 的作用是返回“所有value”的枚举对象

```java
		public synchronized Enumeration<V> elements() {
			return this.<V>getEnumeration(VALUES);
		}
 
		// 获取Hashtable的枚举类对象
		private <T> Enumeration<T> getEnumeration(int type) {
			if (count == 0) {
				return (Enumeration<T>)emptyEnumerator;
			} else {
				return new Enumerator<T>(type, false);
			}
		}
```

若Hashtable的实际大小为0,则返回“空枚举类”对象emptyEnumerator；
 否则，返回正常的Enumerator的对象。

EmptyEnumerator对象是如何实现的:

```java
	private static Enumeration emptyEnumerator = new EmptyEnumerator();
 
	// 空枚举类
	// 当Hashtable的实际大小为0；此时，又要通过Enumeration遍历Hashtable时，返回的是“空枚举类”的对象。
	private static class EmptyEnumerator implements Enumeration<Object> {
 
 
		EmptyEnumerator() {
		}
 
 
		// 空枚举类的hasMoreElements() 始终返回false
		public boolean hasMoreElements() {
			return false;
		}
 
 
		// 空枚举类的nextElement() 抛出异常
		public Object nextElement() {
			throw new NoSuchElementException("Hashtable Enumerator");
		}
	}
```

Enumerator的作用是提供了“通过elements()遍历Hashtable的接口” 和 “通过entrySet()遍历Hashtable的接口”。

```java
	private class Enumerator<T> implements Enumeration<T>, Iterator<T> {
		// 指向Hashtable的table
		Entry[] table = Hashtable.this.table;
		// Hashtable的总的大小
		int index = table.length;
		Entry<K,V> entry = null;
		Entry<K,V> lastReturned = null;
		int type;
 
 
		// Enumerator是 “迭代器(Iterator)” 还是 “枚举类(Enumeration)”的标志
		// iterator为true，表示它是迭代器；否则，是枚举类。
		boolean iterator;
 
 
		// 在将Enumerator当作迭代器使用时会用到，用来实现fail-fast机制。
		protected int expectedModCount = modCount;
 
 
		Enumerator(int type, boolean iterator) {
			this.type = type;
			this.iterator = iterator;
		}
 
 
		// 从遍历table的数组的末尾向前查找，直到找到不为null的Entry。
		public boolean hasMoreElements() {
			Entry<K,V> e = entry;
			int i = index;
			Entry[] t = table;
			/* Use locals for faster loop iteration */
			while (e == null && i > 0) {
				e = t[--i];
			}
			entry = e;
			index = i;
			return e != null;
		}
		//获取下一个元素
		// 注意：从hasMoreElements() 和nextElement() 可以看出“Hashtable的elements()遍历方式”
		// 首先，从后向前的遍历table数组。table数组的每个节点都是一个单向链表(Entry)。
		// 然后，依次向后遍历单向链表Entry。
		public T nextElement() {
			Entry<K,V> et = entry;
			int i = index;
			Entry[] t = table;
			/* Use locals for faster loop iteration */
			while (et == null && i > 0) {
				et = t[--i];
			}
			entry = et;
			index = i;
			if (et != null) {
				Entry<K,V> e = lastReturned = entry;
				entry = e.next;
				return type == KEYS ? (T)e.key : (type == VALUES ? (T)e.value : (T)e);
			}
			throw new NoSuchElementException("Hashtable Enumerator");
		}
 
 
		// 迭代器Iterator的判断是否存在下一个元素
		// 实际上，它是调用的hasMoreElements()
		public boolean hasNext() {
			return hasMoreElements();
		}
 
 
		// 迭代器获取下一个元素
		// 实际上，它是调用的nextElement()
		public T next() {
			if (modCount != expectedModCount)
				throw new ConcurrentModificationException();
			return nextElement();
		}
 
 
		// 迭代器的remove()接口。
		// 首先，它在table数组中找出要删除元素所在的Entry，
		// 然后，删除单向链表Entry中的元素。
		public void remove() {
			if (!iterator)
				throw new UnsupportedOperationException();
			if (lastReturned == null)
				throw new IllegalStateException("Hashtable Enumerator");
			if (modCount != expectedModCount)
				throw new ConcurrentModificationException();
 
 
			synchronized(Hashtable.this) {
				Entry[] tab = Hashtable.this.table;
				int index = (lastReturned.hash & 0x7FFFFFFF) % tab.length;
 
 
				for (Entry<K,V> e = tab[index], prev = null; e != null;
					 prev = e, e = e.next) {
					if (e == lastReturned) {
						modCount++;
						expectedModCount++;
						if (prev == null)
							tab[index] = e.next;
						else
							prev.next = e.next;
						count--;
						lastReturned = null;
						return;
					}
				}
				throw new ConcurrentModificationException();
			}
		}
	}
```

#### 5.get() 的作用就是获取key对应的value，没有的话返回null

```java
 public synchronized V get(Object key) {
 Entry tab[] = table;
 int hash = key.hashCode();
 // 计算索引值，
 int index = (hash & 0x7FFFFFFF) % tab.length;
 // 找到“key对应的Entry(链表)”，然后在链表中找出“哈希值”和“键值”与key都相等的元素
 for (Entry<K,V> e = tab[index] ; e != null ; e = e.next) {
 if ((e.hash == hash) && e.key.equals(key)) {
 return e.value;
 }
 }
 return null;
 }
```

#### 6.put() 的作用是对外提供接口，让Hashtable对象可以通过put()将“key-value”添加到Hashtable中。

```java
	public synchronized V put(K key, V value) {
		// Hashtable中不能插入value为null的元素！！！
		if (value == null) {
			throw new NullPointerException();
		}
 
		// 若“Hashtable中已存在键为key的键值对”，
		// 则用“新的value”替换“旧的value”
		Entry tab[] = table;
		int hash = key.hashCode();
		int index = (hash & 0x7FFFFFFF) % tab.length;
		for (Entry<K,V> e = tab[index] ; e != null ; e = e.next) {
			if ((e.hash == hash) && e.key.equals(key)) {
				V old = e.value;
				e.value = value;
				return old;
				}
		}
 
		// 若“Hashtable中不存在键为key的键值对”，
		// (01) 将“修改统计数”+1
		modCount++;
		// (02) 若“Hashtable实际容量” > “阈值”(阈值=总的容量 * 加载因子)
		//  则调整Hashtable的大小
		if (count >= threshold) {
			// Rehash the table if the threshold is exceeded
			rehash();
			tab = table;
			index = (hash & 0x7FFFFFFF) % tab.length;
		}
 
		// (03) 将“Hashtable中index”位置的Entry(链表)保存到e中
		Entry<K,V> e = tab[index];
		// (04) 创建“新的Entry节点”，并将“新的Entry”插入“Hashtable的index位置”，并设置e为“新的Entry”的下一个元素(即“新Entry”为链表表头)。        
		tab[index] = new Entry<K,V>(hash, key, value, e);
		// (05) 将“Hashtable的实际容量”+1
		count++;
		return null;
	}
```

#### 7.putAll() 的作用是将“Map(t)”的中全部元素逐一添加到Hashtable中

```java
 public synchronized void putAll(Map<? extends K, ? extends V> t) {
 for (Map.Entry<? extends K, ? extends V> e : t.entrySet())
 put(e.getKey(), e.getValue());
  }
```

8.remove() 的作用就是删除Hashtable中键为key的元素

```java
		public synchronized V remove(Object key) {
			Entry tab[] = table;
			int hash = key.hashCode();
			int index = (hash & 0x7FFFFFFF) % tab.length;
			// 找到“key对应的Entry(链表)”
			// 然后在链表中找出要删除的节点，并删除该节点。
			for (Entry<K,V> e = tab[index], prev = null ; e != null ; prev = e, e = e.next) {
				if ((e.hash == hash) && e.key.equals(key)) {
					modCount++;
					if (prev != null) {
						prev.next = e.next;
					} else {
						tab[index] = e.next;
					}
					count--;
					V oldValue = e.value;
					e.value = null;
					return oldValue;
				}
			}
			return null;
		}
```

#### 6、Hashtable实现的Cloneable接口

```java
Hashtable实现了Cloneable接口，即实现了clone()方法。
 clone()方法的作用很简单，就是克隆一个Hashtable对象并返回。

 // 克隆一个Hashtable，并以Object的形式返回。
 public synchronized Object clone() {
 try {
 Hashtable<K,V> t = (Hashtable<K,V>) super.clone();
 t.table = new Entry[table.length];
 for (int i = table.length ; i-- > 0 ; ) {
 t.table[i] = (table[i] != null)
 ? (Entry<K,V>) table[i].clone() : null;
 }
 t.keySet = null;
 t.entrySet = null;
 t.values = null;
 t.modCount = 0;
 return t;
 } catch (CloneNotSupportedException e) {
 // this shouldn't happen, since we are Cloneable
 throw new InternalError();
 }
 }
```

#### 7、Hashtable实现的Serializable接口

- Hashtable实现java.io.Serializable，分别实现了串行读取、写入功能。
- 串行写入函数就是将Hashtable的“总的容量，实际容量，所有的Entry”都写入到输出流中
- 串行读取函数：根据写入方式读出将Hashtable的“总的容量，实际容量，所有的Entry”依次读出

```java
	private synchronized void writeObject(java.io.ObjectOutputStream s)
		throws IOException
	{
		// Write out the length, threshold, loadfactor
		s.defaultWriteObject();
 
 
		// Write out length, count of elements and then the key/value objects
		s.writeInt(table.length);
		s.writeInt(count);
		for (int index = table.length-1; index >= 0; index--) {
			Entry entry = table[index];
 
 
			while (entry != null) {
			s.writeObject(entry.key);
			s.writeObject(entry.value);
			entry = entry.next;
			}
		}
	}
 
 
	private void readObject(java.io.ObjectInputStream s)
		 throws IOException, ClassNotFoundException
	{
		// Read in the length, threshold, and loadfactor
		s.defaultReadObject();
 
 
		// Read the original length of the array and number of elements
		int origlength = s.readInt();
		int elements = s.readInt();
 
 
		// Compute new size with a bit of room 5% to grow but
		// no larger than the original size.  Make the length
		// odd if it's large enough, this helps distribute the entries.
		// Guard against the length ending up zero, that's not valid.
		int length = (int)(elements * loadFactor) + (elements / 20) + 3;
		if (length > elements && (length & 1) == 0)
			length--;
		if (origlength > 0 && length > origlength)
			length = origlength;
 
 
		Entry[] table = new Entry[length];
		count = 0;
 
 
		// Read the number of elements and then all the key/value objects
		for (; elements > 0; elements--) {
			K key = (K)s.readObject();
			V value = (V)s.readObject();
				// synch could be eliminated for performance
				reconstitutionPut(table, key, value);
		}
		this.table = table;
	}
```

#### 8、遍历Hashtable的键值对(获取键值集)

- 第一步：根据entrySet()获取Hashtable的“键值对”的Set集合。
- 第二步：通过Iterator迭代器遍历“第一步”得到的集合。

```java
 // 假设table是Hashtable对象
 // table中的key是String类型，value是Integer类型
 Integer integ = null;
 Iterator iter = table.entrySet().iterator();
 while(iter.hasNext()) {
 Map.Entry entry = (Map.Entry)iter.next();
 // 获取key
 key = (String)entry.getKey();
 // 获取value
 integ = (Integer)entry.getValue();
 }
```

#### 9、通过Iterator遍历Hashtable的键（获取键集）

- 第一步：根据keySet()获取Hashtable的“键”的Set集合。
- 第二步：通过Iterator迭代器遍历“第一步”得到的集合。

```java
 // 前提table是Hashtable对象
 // table中的key是String类型，value是Integer类型
 String key = null;
 Integer integ = null;
 Iterator iter = table.keySet().iterator();
 while (iter.hasNext()) {
 // 获取key
 key = (String)iter.next();
 // 根据key，获取value
 integ = (Integer)table.get(key);
 }
```

#### 10、通过Iterator遍历Hashtable的值（获取值集）

- 第一步：根据value()获取Hashtable的“值”的集合。
- 第二步：通过Iterator迭代器遍历“第一步”得到的集合。

```java
// 前提table是Hashtable对象
 // table中的key是String类型，value是Integer类型
 Integer value = null;
 Collection c = table.values();
 Iterator iter= c.iterator();
 while (iter.hasNext()) {
 value = (Integer)iter.next();
 }
```

#### 11、通过Enumeration遍历Hashtable的键（获取键集）

- 第一步：根据keys()获取Hashtable的集合。
- 第二步：通过Enumeration遍历“第一步”得到的集合。

```java
 Enumeration enu = table.keys();
 while(enu.hasMoreElements()) {
 System.out.println(enu.nextElement());
 }   
```

#### 12、通过Enumeration遍历Hashtable的值（获取值集）

- 第一步：根据elements()获取Hashtable的集合。
- 第二步：通过Enumeration遍历“第一步”得到的集合。

```java
 Enumeration enu = table.elements();
 while(enu.hasMoreElements()) {
 System.out.println(enu.nextElement());
 }
```

#### 13、HashTable总结：

1. Hashtable是个线程安全的类（HashMap线程安全）；
2. Hasbtable并不允许值和键为空（null），若为空，会抛空指针（HashMap可以）；
3. Hashtable不允许键重复，若键重复，则新插入的值会覆盖旧值（同HashMap）；
4. Hashtable同样是通过链表法解决冲突；
5. Hashtable根据hashcode计算索引时将hashcode值先与上0x7FFFFFFF,这是为了保证hash值始终为正数;
6. Hashtable的容量为任意正数（最小为1），而HashMap的容量始终为2的n次方。Hashtable默认容量为11，HashMap默认容量为16；
7. Hashtable每次扩容，新容量为旧容量的2倍加1，而HashMap为旧容量的2倍；
8. Hashtable和HashMap默认负载因子都为0.75;

## 三、Java7 HashMap

HashMap 是比较简单的，一来我们常用，二来就是它不支持并发，所以源码也相对简单。

首先，我们用下面这张图来介绍 HashMap 的结构。

![19coding](https://icefiredb-1300435688.piccd.myqcloud.com/betsy/java7hashmap_1601298343390.png)

这个仅仅是示意图，因为没有考虑到数组要扩容的情况，具体的后面会讲到。

大方向上，HashMap 里面是一个数组，然后数组中每个元素是一个单向链表。

上图中，每个绿色的实体是嵌套类 Entry 的实例，Entry 包含四个属性：key, value, hash 值和用于单向链表的 next。

capacity：当前数组容量，始终保持 2^n，可以扩容，扩容后数组大小为当前的 2 倍。

loadFactor：负载因子，默认为 0.75。

threshold：扩容的阈值，等于 capacity * loadFactor

### 3.1 put 操作分析

还是比较简单的，跟着代码走一遍吧。

```java
public V put(K key, V value) {
    // 当插入第一个元素的时候，需要先初始化数组大小
    if (table == EMPTY_TABLE) {
        inflateTable(threshold);
    }
    // 如果 key 为 null，感兴趣的可以往里看，最终会将这个 entry 放到 table[0] 中
    if (key == null)
        return putForNullKey(value);
    // 1. 求 key 的 hash 值
    int hash = hash(key);
    // 2. 找到对应的数组下标
    int i = indexFor(hash, table.length);
    // 3. 遍历一下对应下标处的链表，看是否有重复的 key 已经存在，
    //    如果有，直接覆盖，put 方法返回旧值就结束了
    for (Entry<K,V> e = table[i]; e != null; e = e.next) {
        Object k;
        if (e.hash == hash && ((k = e.key) == key || key.equals(k))) {
            V oldValue = e.value;
            e.value = value;
            e.recordAccess(this);
            return oldValue;
        }
    }

    modCount++;
    // 4. 不存在重复的 key，将此 entry 添加到链表中，细节后面说
    addEntry(hash, key, value, i);
    return null;
}
```

### 3.2 数组初始化

在第一个元素插入 HashMap 的时候做一次数组的初始化，就是先确定初始的数组大小，并计算数组扩容的阈值。

```java
private void inflateTable(int toSize) {
    // 保证数组大小一定是 2 的 n 次方。
    // 比如这样初始化：new HashMap(20)，那么处理成初始数组大小是 32
    int capacity = roundUpToPowerOf2(toSize);
    // 计算扩容阈值：capacity * loadFactor
    threshold = (int) Math.min(capacity * loadFactor, MAXIMUM_CAPACITY + 1);
    // 算是初始化数组吧
    table = new Entry[capacity];
    initHashSeedAsNeeded(capacity); //ignore
}
```

这里有一个将数组大小保持为 2 的 n 次方的做法，Java7 和 Java8 的 HashMap 和 ConcurrentHashMap 都有相应的要求，只不过实现的代码稍微有些不同，后面再看到的时候就知道了。

### 3.3 计算具体数组位置

这个简单，我们自己也能 YY 一个：使用 key 的 hash 值对数组长度进行取模就可以了。

```java
static int indexFor(int hash, int length) {
    // assert Integer.bitCount(length) == 1 : "length must be a non-zero power of 2";
    return hash & (length-1);
}
```

这个方法很简单，简单说就是取 hash 值的低 n 位。如在数组长度为 32 的时候，其实取的就是 key 的 hash 值的低 5 位，作为它在数组中的下标位置。

### 3.4 添加节点到链表中

找到数组下标后，会先进行 key 判重，如果没有重复，就准备将新值放入到链表的表头。

```java
void addEntry(int hash, K key, V value, int bucketIndex) {
    // 如果当前 HashMap 大小已经达到了阈值，并且新值要插入的数组位置已经有元素了，那么要扩容
    if ((size >= threshold) && (null != table[bucketIndex])) {
        // 扩容，后面会介绍一下
        resize(2 * table.length);
        // 扩容以后，重新计算 hash 值
        hash = (null != key) ? hash(key) : 0;
        // 重新计算扩容后的新的下标
        bucketIndex = indexFor(hash, table.length);
    }
    // 往下看
    createEntry(hash, key, value, bucketIndex);
}
// 这个很简单，其实就是将新值放到链表的表头，然后 size++
void createEntry(int hash, K key, V value, int bucketIndex) {
    Entry<K,V> e = table[bucketIndex];
    table[bucketIndex] = new Entry<>(hash, key, value, e);
    size++;
}
```

这个方法的主要逻辑就是先判断是否需要扩容，需要的话先扩容，然后再将这个新的数据插入到扩容后的数组的相应位置处的链表的表头。

### 3.5 数组扩容

前面我们看到，在插入新值的时候，如果当前的 size 已经达到了阈值，并且要插入的数组位置上已经有元素，那么就会触发扩容，扩容后，数组大小为原来的 2 倍。

```java
void resize(int newCapacity) {
    Entry[] oldTable = table;
    int oldCapacity = oldTable.length;
    if (oldCapacity == MAXIMUM_CAPACITY) {
        threshold = Integer.MAX_VALUE;
        return;
    }
    // 新的数组
    Entry[] newTable = new Entry[newCapacity];
    // 将原来数组中的值迁移到新的更大的数组中
    transfer(newTable, initHashSeedAsNeeded(newCapacity));
    table = newTable;
    threshold = (int)Math.min(newCapacity * loadFactor, MAXIMUM_CAPACITY + 1);
}
```

扩容就是用一个新的大数组替换原来的小数组，并将原来数组中的值迁移到新的数组中。

由于是双倍扩容，迁移过程中，会将原来 table[i] 中的链表的所有节点，分拆到新的数组的 newTable[i] 和  newTable[i + oldLength] 位置上。如原来数组长度是 16，那么扩容后，原来 table[0]  处的链表中的所有元素会被分配到新数组中 newTable[0] 和 newTable[16] 这两个位置。代码比较简单，这里就不展开了。

### 3.6 get 操作分析

相对于 put 过程，get 过程是非常简单的。

1. 根据 key 计算 hash 值。
2. 找到相应的数组下标：hash & (length - 1)。
3. 遍历该数组位置处的链表，直到找到相等(==或equals)的 key。

```java
public V get(Object key) {
    // 之前说过，key 为 null 的话，会被放到 table[0]，所以只要遍历下 table[0] 处的链表就可以了
    if (key == null)
        return getForNullKey();
    // 
    Entry<K,V> entry = getEntry(key);

    return null == entry ? null : entry.getValue();
}

final Entry<K,V> getEntry(Object key) {
    if (size == 0) {
        return null;
    }
int hash = (key == null) ? 0 : hash(key);
    // 确定数组下标，然后从头开始遍历链表，直到找到为止
    for (Entry<K,V> e = table[indexFor(hash, table.length)];
         e != null;
         e = e.next) {
        Object k;
        if (e.hash == hash &&
            ((k = e.key) == key || (key != null && key.equals(k))))
            return e;
    }
    return null;
}
```

## 四、Java8 HashMap

Java8 对 HashMap 进行了一些修改，最大的不同就是利用了红黑树，所以其由 数组+链表+红黑树 组成。

根据 Java7 HashMap 的介绍，我们知道，查找的时候，根据 hash 值我们能够快速定位到数组的具体下标，但是之后的话，需要顺着链表一个个比较下去才能找到我们需要的，时间复杂度取决于链表的长度，为 **O(n)**。

为了降低这部分的开销，在 Java8 中，当链表中的元素达到了 8 个时，会将链表转换为红黑树，在这些位置进行查找的时候可以降低时间复杂度为 **O(logN)**。

来一张图简单示意一下吧：
 ![java8hashmap](https://icefiredb-1300435688.piccd.myqcloud.com/betsy/java8hashmap_1601298356491.png)

> 注意，上图是示意图，主要是描述结构，达到这个状态的时候早就扩容了。

### 4.1 put 操作分析

```java
public V put(K key, V value) {
    return putVal(hash(key), key, value, false, true);
}

// 第三个参数 onlyIfAbsent 如果是 true，那么只有在不存在该 key 时才会进行 put 操作
// 第四个参数 evict 我们这里不关心
final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
               boolean evict) {
    Node<K,V>[] tab; Node<K,V> p; int n, i;
    // 第一次 put 值的时候，会触发下面的 resize()，类似 java7 的第一次 put 也要初始化数组长度
    // 第一次 resize 和后续的扩容有些不一样，因为这次是数组从 null 初始化到默认的 16 或自定义的初始容量
    if ((tab = table) == null || (n = tab.length) == 0)
        n = (tab = resize()).length;
    // 找到具体的数组下标，如果此位置没有值，那么直接初始化一下 Node 并放置在这个位置就可以了
    if ((p = tab[i = (n - 1) & hash]) == null)
        tab[i] = newNode(hash, key, value, null);

    else {// 数组该位置有数据
        Node<K,V> e; K k;
        // 首先，判断该位置的第一个数据和我们要插入的数据，key 是不是"相等"，如果是，取出这个节点
        if (p.hash == hash &&
            ((k = p.key) == key || (key != null && key.equals(k))))
            e = p;
        // 如果该节点是代表红黑树的节点，调用红黑树的插值方法，本文不展开说红黑树
        else if (p instanceof TreeNode)
            e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
        else {
            // 到这里，说明数组该位置上是一个链表
            for (int binCount = 0; ; ++binCount) {
                // 插入到链表的最后面(Java7 是插入到链表的最前面)
                if ((e = p.next) == null) {
                    p.next = newNode(hash, key, value, null);
                    // TREEIFY_THRESHOLD 为 8，所以，如果新插入的值是链表中的第 8 个
                    // 会触发下面的 treeifyBin，也就是将链表转换为红黑树
                    if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                        treeifyBin(tab, hash);
                    break;
                }
                // 如果在该链表中找到了"相等"的 key(== 或 equals)
                if (e.hash == hash &&
                    ((k = e.key) == key || (key != null && key.equals(k))))
                    // 此时 break，那么 e 为链表中[与要插入的新值的 key "相等"]的 node
                    break;
                p = e;
            }
        }
        // e!=null 说明存在旧值的key与要插入的key"相等"
        // 对于我们分析的put操作，下面这个 if 其实就是进行 "值覆盖"，然后返回旧值
        if (e != null) {
            V oldValue = e.value;
            if (!onlyIfAbsent || oldValue == null)
                e.value = value;
            afterNodeAccess(e);
            return oldValue;
        }
    }
    ++modCount;
    // 如果 HashMap 由于新插入这个值导致 size 已经超过了阈值，需要进行扩容
    if (++size > threshold)
        resize();
    afterNodeInsertion(evict);
    return null;
}
```

和 Java7 稍微有点不一样的地方就是，Java7 是先扩容后插入新值的，Java8 先插值再扩容，不过这个不重要。

### 4.2 数组扩容

resize() 方法用于初始化数组或数组扩容，每次扩容后，容量为原来的 2 倍，并进行数据迁移。

```java
final Node<K,V>[] resize() {
    Node<K,V>[] oldTab = table;
    int oldCap = (oldTab == null) ? 0 : oldTab.length;
    int oldThr = threshold;
    int newCap, newThr = 0;
    if (oldCap > 0) { // 对应数组扩容
        if (oldCap >= MAXIMUM_CAPACITY) {
            threshold = Integer.MAX_VALUE;
            return oldTab;
        }
        // 将数组大小扩大一倍
        else if ((newCap = oldCap << 1) < MAXIMUM_CAPACITY &&
                 oldCap >= DEFAULT_INITIAL_CAPACITY)
            // 将阈值扩大一倍
            newThr = oldThr << 1; // double threshold
    }
    else if (oldThr > 0) // 对应使用 new HashMap(int initialCapacity) 初始化后，第一次 put 的时候
        newCap = oldThr;
    else {// 对应使用 new HashMap() 初始化后，第一次 put 的时候
        newCap = DEFAULT_INITIAL_CAPACITY;
        newThr = (int)(DEFAULT_LOAD_FACTOR * DEFAULT_INITIAL_CAPACITY);
    }

    if (newThr == 0) {
        float ft = (float)newCap * loadFactor;
        newThr = (newCap < MAXIMUM_CAPACITY && ft < (float)MAXIMUM_CAPACITY ?
                  (int)ft : Integer.MAX_VALUE);
    }
    threshold = newThr;

    // 用新的数组大小初始化新的数组
    Node<K,V>[] newTab = (Node<K,V>[])new Node[newCap];
    table = newTab; // 如果是初始化数组，到这里就结束了，返回 newTab 即可

    if (oldTab != null) {
        // 开始遍历原数组，进行数据迁移。
        for (int j = 0; j < oldCap; ++j) {
            Node<K,V> e;
            if ((e = oldTab[j]) != null) {
                oldTab[j] = null;
                // 如果该数组位置上只有单个元素，那就简单了，简单迁移这个元素就可以了
                if (e.next == null)
                    newTab[e.hash & (newCap - 1)] = e;
                // 如果是红黑树，具体我们就不展开了
                else if (e instanceof TreeNode)
                    ((TreeNode<K,V>)e).split(this, newTab, j, oldCap);
                else { 
                    // 这块是处理链表的情况，
                    // 需要将此链表拆成两个链表，放到新的数组中，并且保留原来的先后顺序
                    // loHead、loTail 对应一条链表，hiHead、hiTail 对应另一条链表，代码还是比较简单的
                    Node<K,V> loHead = null, loTail = null;
                    Node<K,V> hiHead = null, hiTail = null;
                    Node<K,V> next;
                    do {
                        next = e.next;
                        if ((e.hash & oldCap) == 0) {
                            if (loTail == null)
                                loHead = e;
                            else
                                loTail.next = e;
                            loTail = e;
                        }
                        else {
                            if (hiTail == null)
                                hiHead = e;
                            else
                                hiTail.next = e;
                            hiTail = e;
                        }
                    } while ((e = next) != null);
                    if (loTail != null) {
                        loTail.next = null;
                        // 第一条链表
                        newTab[j] = loHead;
                    }
                    if (hiTail != null) {
                        hiTail.next = null;
                        // 第二条链表的新的位置是 j + oldCap，这个很好理解
                        newTab[j + oldCap] = hiHead;
                    }
                }
            }
        }
    }
    return newTab;
}
```

### 4.3 get 操作分析

相对于 put 来说，get 真的太简单了。

1. 计算 key 的 hash 值，根据 hash 值找到对应数组下标: hash & (length-1)
2. 判断数组该位置处的元素是否刚好就是我们要找的，如果不是，走第三步
3. 判断该元素类型是否是 TreeNode，如果是，用红黑树的方法取数据，如果不是，走第四步
4. 遍历链表，直到找到相等(==或equals)的 key

```java
public V get(Object key) {
    Node<K,V> e;
    return (e = getNode(hash(key), key)) == null ? null : e.value;
}
final Node<K,V> getNode(int hash, Object key) {
    Node<K,V>[] tab; Node<K,V> first, e; int n; K k;
    if ((tab = table) != null && (n = tab.length) > 0 &&
        (first = tab[(n - 1) & hash]) != null) {
        // 判断第一个节点是不是就是需要的
        if (first.hash == hash && // always check first node
            ((k = first.key) == key || (key != null && key.equals(k))))
            return first;
        if ((e = first.next) != null) {
            // 判断是否是红黑树
            if (first instanceof TreeNode)
                return ((TreeNode<K,V>)first).getTreeNode(hash, key);

            // 链表遍历
            do {
                if (e.hash == hash &&
                    ((k = e.key) == key || (key != null && key.equals(k))))
                    return e;
            } while ((e = e.next) != null);
        }
    }
    return null;
}
```

#### 4.3.1 HashMap的api

```java
void	clear() 
		从此映射中移除所有映射关系（可选操作）。

boolean	containsKey(Object key) 
		如果此映射包含指定键的映射关系，则返回 true。

boolean	containsValue(Object value) 
		如果此映射将一个或多个键映射到指定值，则返回 true。

Set<Map.Entry<K,V>>	entrySet() 
		返回此映射中包含的映射关系的 Set 视图。

boolean	equals(Object o) 
		比较指定的对象与此映射是否相等。

V	get(Object key) 
		返回指定键所映射的值；如果此映射不包含该键的映射关系，则返回 null。

int	hashCode() 
		返回此映射的哈希码值。

boolean	isEmpty() 
		如果此映射未包含键-值映射关系，则返回 true。

Set<K>	keySet() 
		返回此映射中包含的键的 Set 视图。

V	put(K key, V value) 
		将指定的值与此映射中的指定键关联（可选操作）。

void	putAll(Map<? extends K,? extends V> m) 
		从指定映射中将所有映射关系复制到此映射中（可选操作）。

V	remove(Object key) 
		如果存在一个键的映射关系，则将其从此映射中移除（可选操作）。

int	size() 
		返回此映射中的键-值映射关系数。

Collection<V>	values() 
		返回此映射中包含的值的 Collection 视图。
```

## 五、Java7 ConcurrentHashMap

ConcurrentHashMap 和 HashMap 思路是差不多的，但是因为它支持并发操作，所以要复杂一些。

整个 ConcurrentHashMap 由一个个 Segment 组成，Segment 代表”部分“或”一段“的意思，所以很多地方都会将其描述为分段锁。注意，行文中，我很多地方用了“槽”来代表一个 segment。

简单理解就是，ConcurrentHashMap 是一个 Segment 数组，Segment 通过继承 ReentrantLock  来进行加锁，所以每次需要加锁的操作锁住的是一个 segment，这样只要保证每个 Segment 是线程安全的，也就实现了全局的线程安全。

concurrencyLevel：并行级别、并发数、Segment 数，怎么翻译不重要，理解它。默认是 16，也就是说  ConcurrentHashMap 有 16 个 Segments，所以理论上，这个时候，最多可以同时支持 16  个线程并发写，只要它们的操作分别分布在不同的 Segment 上。这个值可以在初始化的时候设置为其他值，但是一旦初始化以后，它是不可以扩容的。

![java7conrenthashmap](https://icefiredb-1300435688.piccd.myqcloud.com/betsy/java7conrenthashmap_1601298343629.png)

再具体到每个 Segment 内部，其实每个 Segment 很像之前介绍的 HashMap，不过它要保证线程安全，所以处理起来要麻烦些。

### 5.1 初始化

initialCapacity：初始容量，这个值指的是整个 ConcurrentHashMap 的初始容量，实际操作的时候需要平均分给每个 Segment。

loadFactor：负载因子，之前我们说了，Segment 数组不可以扩容，所以这个负载因子是给每个 Segment 内部使用的。

```java
public ConcurrentHashMap(int initialCapacity,
                         float loadFactor, int concurrencyLevel) {
    if (!(loadFactor > 0) || initialCapacity < 0 || concurrencyLevel <= 0)
        throw new IllegalArgumentException();
    if (concurrencyLevel > MAX_SEGMENTS)
        concurrencyLevel = MAX_SEGMENTS;
    // Find power-of-two sizes best matching arguments
    int sshift = 0;
    int ssize = 1;
    // 计算并行级别 ssize，因为要保持并行级别是 2 的 n 次方
    while (ssize < concurrencyLevel) {
        ++sshift;
        ssize <<= 1;
    }
    // 我们这里先不要那么烧脑，用默认值，concurrencyLevel 为 16，sshift 为 4
    // 那么计算出 segmentShift 为 28，segmentMask 为 15，后面会用到这两个值
    this.segmentShift = 32 - sshift;
    this.segmentMask = ssize - 1;

    if (initialCapacity > MAXIMUM_CAPACITY)
        initialCapacity = MAXIMUM_CAPACITY;

    // initialCapacity 是设置整个 map 初始的大小，
    // 这里根据 initialCapacity 计算 Segment 数组中每个位置可以分到的大小
    // 如 initialCapacity 为 64，那么每个 Segment 或称之为"槽"可以分到 4 个
    int c = initialCapacity / ssize;
    if (c * ssize < initialCapacity)
        ++c;
    // 默认 MIN_SEGMENT_TABLE_CAPACITY 是 2，这个值也是有讲究的，因为这样的话，对于具体的槽上，
    // 插入一个元素不至于扩容，插入第二个的时候才会扩容
    int cap = MIN_SEGMENT_TABLE_CAPACITY; 
    while (cap < c)
        cap <<= 1;

    // 创建 Segment 数组，
    // 并创建数组的第一个元素 segment[0]
    Segment<K,V> s0 =
        new Segment<K,V>(loadFactor, (int)(cap * loadFactor),
                         (HashEntry<K,V>[])new HashEntry[cap]);
    Segment<K,V>[] ss = (Segment<K,V>[])new Segment[ssize];
    // 往数组写入 segment[0]
    UNSAFE.putOrderedObject(ss, SBASE, s0); // ordered write of segments[0]
    this.segments = ss;
}
```

初始化完成，我们得到了一个 Segment 数组。

我们就当是用 new ConcurrentHashMap() 无参构造函数进行初始化的，那么初始化完成后：

1. Segment 数组长度为 16，不可以扩容
2. Segment[i] 的默认大小为 2，负载因子是 0.75，得出初始阈值为 1.5，也就是以后插入第一个元素不会触发扩容，插入第二个会进行第一次扩容
3. 这里初始化了 segment[0]，其他位置还是 null，至于为什么要初始化 segment[0]，后面的代码会介绍
4. 当前 segmentShift 的值为 32 - 4 = 28，segmentMask 为 16 - 1 = 15，姑且把它们简单翻译为移位数和掩码，这两个值马上就会用到

### 5.2 put 操作分析

我们先看 put 的主流程，对于其中的一些关键细节操作，后面会进行详细介绍。

```java
public V put(K key, V value) {
    Segment<K,V> s;
    if (value == null)
        throw new NullPointerException();
    // 1. 计算 key 的 hash 值
    int hash = hash(key);
    // 2. 根据 hash 值找到 Segment 数组中的位置 j
    //    hash 是 32 位，无符号右移 segmentShift(28) 位，剩下高 4 位，
    //    然后和 segmentMask(15) 做一次与操作，也就是说 j 是 hash 值的高 4 位，也就是槽的数组下标
    int j = (hash >>> segmentShift) & segmentMask;
    // 刚刚说了，初始化的时候初始化了 segment[0]，但是其他位置还是 null，
    // ensureSegment(j) 对 segment[j] 进行初始化
    if ((s = (Segment<K,V>)UNSAFE.getObject          // nonvolatile; recheck
         (segments, (j << SSHIFT) + SBASE)) == null) //  in ensureSegment
        s = ensureSegment(j);
    // 3. 插入新值到 槽 s 中
    return s.put(key, hash, value, false);
}
```

最外层很简单，根据 hash 值很快就能找到相应的 Segment，之后就是 Segment 内部的 put 操作了。
 Segment 内部是由 **数组+链表** 组成的。

```java
final V put(K key, int hash, V value, boolean onlyIfAbsent) {
    // 在往该 segment 写入前，需要先获取该 segment 的独占锁
    //    先看主流程，后面还会具体介绍这部分内容
    HashEntry<K,V> node = tryLock() ? null :
        scanAndLockForPut(key, hash, value);
    V oldValue;
    try {
        // 这个是 segment 内部的数组
        HashEntry<K,V>[] tab = table;
        // 再利用 hash 值，求应该放置的数组下标
        int index = (tab.length - 1) & hash;
        // first 是数组该位置处的链表的表头
        HashEntry<K,V> first = entryAt(tab, index);

        // 下面这串 for 循环虽然很长，不过也很好理解，想想该位置没有任何元素和已经存在一个链表这两种情况
        for (HashEntry<K,V> e = first;;) {
            if (e != null) {
                K k;
                if ((k = e.key) == key ||
                    (e.hash == hash && key.equals(k))) {
                    oldValue = e.value;
                    if (!onlyIfAbsent) {
                        // 覆盖旧值
                        e.value = value;
                        ++modCount;
                    }
                    break;
                }
                // 继续顺着链表走
                e = e.next;
            }
            else {
                // node 到底是不是 null，这个要看获取锁的过程，不过和这里都没有关系。
                // 如果不为 null，那就直接将它设置为链表表头；如果是null，初始化并设置为链表表头。
                if (node != null)
                    node.setNext(first);
                else
                    node = new HashEntry<K,V>(hash, key, value, first);

                int c = count + 1;
                // 如果超过了该 segment 的阈值，这个 segment 需要扩容
                if (c > threshold && tab.length < MAXIMUM_CAPACITY)
                    rehash(node); // 扩容后面也会具体分析
                else
                    // 没有达到阈值，将 node 放到数组 tab 的 index 位置，
                    // 其实就是将新的节点设置成原链表的表头
                    setEntryAt(tab, index, node);
                ++modCount;
                count = c;
                oldValue = null;
                break;
            }
        }
    } finally {
        // 解锁
        unlock();
    }
    return oldValue;
}
```

整体流程还是比较简单的，由于有独占锁的保护，所以 segment 内部的操作并不复杂。至于这里面的并发问题，我们稍后再进行介绍。

到这里 put 操作就结束了，接下来，我们说一说其中几步关键的操作。

#### 5.2.1 初始化槽: ensureSegment

ConcurrentHashMap 初始化的时候会初始化第一个槽 segment[0]，对于其他槽来说，在插入第一个值的时候进行初始化。

这里需要考虑并发，因为很可能会有多个线程同时进来初始化同一个槽 segment[k]，不过只要有一个成功了就可以。

```java
private Segment<K,V> ensureSegment(int k) {
    final Segment<K,V>[] ss = this.segments;
    long u = (k << SSHIFT) + SBASE; // raw offset
    Segment<K,V> seg;
    if ((seg = (Segment<K,V>)UNSAFE.getObjectVolatile(ss, u)) == null) {
        // 这里看到为什么之前要初始化 segment[0] 了，
        // 使用当前 segment[0] 处的数组长度和负载因子来初始化 segment[k]
        // 为什么要用“当前”，因为 segment[0] 可能早就扩容过了
        Segment<K,V> proto = ss[0];
        int cap = proto.table.length;
        float lf = proto.loadFactor;
        int threshold = (int)(cap * lf);

        // 初始化 segment[k] 内部的数组
        HashEntry<K,V>[] tab = (HashEntry<K,V>[])new HashEntry[cap];
        if ((seg = (Segment<K,V>)UNSAFE.getObjectVolatile(ss, u))
            == null) { // 再次检查一遍该槽是否被其他线程初始化了。

            Segment<K,V> s = new Segment<K,V>(lf, threshold, tab);
            // 使用 while 循环，内部用 CAS，当前线程成功设值或其他线程成功设值后，退出
            while ((seg = (Segment<K,V>)UNSAFE.getObjectVolatile(ss, u))
                   == null) {
                if (UNSAFE.compareAndSwapObject(ss, u, null, seg = s))
                    break;
            }
        }
    }
    return seg;
}
```

总的来说，ensureSegment(int k) 比较简单，对于并发操作使用 CAS 进行控制。
 注意这里有个while 循环，如果当前线程 CAS 失败，这里的 while 循环是为了将 seg 赋值返回。

#### 5.2.2 获取写入锁: scanAndLockForPut

前面我们看到，在往某个 segment 中 put 的时候，首先会调用 node = tryLock() ? null :  scanAndLockForPut(key, hash, value)，也就是说先进行一次 tryLock() 快速获取该 segment  的独占锁，如果失败，那么进入到 scanAndLockForPut 这个方法来获取锁。

下面我们来具体分析这个方法中是怎么控制加锁的。

```java
private HashEntry<K,V> scanAndLockForPut(K key, int hash, V value) {
    HashEntry<K,V> first = entryForHash(this, hash);
    HashEntry<K,V> e = first;
    HashEntry<K,V> node = null;
    int retries = -1; // negative while locating node

    // 循环获取锁
    while (!tryLock()) {
        HashEntry<K,V> f; // to recheck first below
        if (retries < 0) {
            if (e == null) {
                if (node == null) // speculatively create node
                    // 进到这里说明数组该位置的链表是空的，没有任何元素
                    // 当然，进到这里的另一个原因是 tryLock() 失败，所以该槽存在并发，不一定是该位置
                    node = new HashEntry<K,V>(hash, key, value, null);
                retries = 0;
            }
            else if (key.equals(e.key))
                retries = 0;
            else
                // 顺着链表往下走
                e = e.next;
        }
        // 重试次数如果超过 MAX_SCAN_RETRIES（单核1多核64），那么不抢了，进入到阻塞队列等待锁
        //    lock() 是阻塞方法，直到获取锁后返回
        else if (++retries > MAX_SCAN_RETRIES) {
            lock();
            break;
        }
        else if ((retries & 1) == 0 &&
                 // 这个时候是有大问题了，那就是有新的元素进到了链表，成为了新的表头
                 //     所以这边的策略是，相当于重新走一遍这个 scanAndLockForPut 方法
                 (f = entryForHash(this, hash)) != first) {
            e = first = f; // re-traverse if entry changed
            retries = -1;
        }
    }
    return node;
}
```

这个方法有两个出口，一个是 tryLock() 成功了，循环终止，另一个就是重试次数超过了 MAX_SCAN_RETRIES，进到 lock() 方法，此方法会阻塞等待，直到成功拿到独占锁。

这个方法就是看似复杂，但是其实就是做了一件事，那就是获取该 segment 的独占锁，如果需要的话顺便实例化了一下 node。

### 5.3 扩容: rehash

重复一下，segment 数组不能扩容，扩容是 segment 数组某个位置内部的数组 HashEntry<K,V>[] 进行扩容，扩容后，容量为原来的 2 倍。

首先，我们要回顾一下触发扩容的地方，put 的时候，如果判断该值的插入会导致该 segment 的元素个数超过阈值，那么先进行扩容，再插值，读者这个时候可以回去 put 方法看一眼。

该方法不需要考虑并发，因为到这里的时候，是持有该 segment 的独占锁的。

```java
// 方法参数上的 node 是这次扩容后，需要添加到新的数组中的数据。
private void rehash(HashEntry<K,V> node) {
    HashEntry<K,V>[] oldTable = table;
    int oldCapacity = oldTable.length;
    // 2 倍
    int newCapacity = oldCapacity << 1;
    threshold = (int)(newCapacity * loadFactor);
    // 创建新数组
    HashEntry<K,V>[] newTable =
        (HashEntry<K,V>[]) new HashEntry[newCapacity];
    // 新的掩码，如从 16 扩容到 32，那么 sizeMask 为 31，对应二进制 ‘000...00011111’
    int sizeMask = newCapacity - 1;

    // 遍历原数组，老套路，将原数组位置 i 处的链表拆分到 新数组位置 i 和 i+oldCap 两个位置
    for (int i = 0; i < oldCapacity ; i++) {
        // e 是链表的第一个元素
        HashEntry<K,V> e = oldTable[i];
        if (e != null) {
            HashEntry<K,V> next = e.next;
            // 计算应该放置在新数组中的位置，
            // 假设原数组长度为 16，e 在 oldTable[3] 处，那么 idx 只可能是 3 或者是 3 + 16 = 19
            int idx = e.hash & sizeMask;
            if (next == null)   // 该位置处只有一个元素，那比较好办
                newTable[idx] = e;
            else { // Reuse consecutive sequence at same slot
                // e 是链表表头
                HashEntry<K,V> lastRun = e;
                // idx 是当前链表的头结点 e 的新位置
                int lastIdx = idx;

                // 下面这个 for 循环会找到一个 lastRun 节点，这个节点之后的所有元素是将要放到一起的
                for (HashEntry<K,V> last = next;
                     last != null;
                     last = last.next) {
                    int k = last.hash & sizeMask;
                    if (k != lastIdx) {
                        lastIdx = k;
                        lastRun = last;
                    }
                }
                // 将 lastRun 及其之后的所有节点组成的这个链表放到 lastIdx 这个位置
                newTable[lastIdx] = lastRun;
                // 下面的操作是处理 lastRun 之前的节点，
                //    这些节点可能分配在另一个链表中，也可能分配到上面的那个链表中
                for (HashEntry<K,V> p = e; p != lastRun; p = p.next) {
                    V v = p.value;
                    int h = p.hash;
                    int k = h & sizeMask;
                    HashEntry<K,V> n = newTable[k];
                    newTable[k] = new HashEntry<K,V>(h, p.key, v, n);
                }
            }
        }
    }
    // 将新来的 node 放到新数组中刚刚的 两个链表之一 的 头部
    int nodeIndex = node.hash & sizeMask; // add the new node
    node.setNext(newTable[nodeIndex]);
    newTable[nodeIndex] = node;
    table = newTable;
}
```

这里的扩容比之前的 HashMap 要复杂一些，代码难懂一点。上面有两个挨着的 for 循环，第一个 for 有什么用呢？

仔细一看发现，如果没有第一个 for 循环，也是可以工作的，但是，这个 for 循环下来，如果 lastRun  的后面还有比较多的节点，那么这次就是值得的。因为我们只需要克隆 lastRun 前面的节点，后面的一串节点跟着 lastRun  走就是了，不需要做任何操作。

我觉得 Doug Lea 的这个想法也是挺有意思的，不过比较坏的情况就是每次 lastRun 都是链表的最后一个元素或者很靠后的元素，那么这次遍历就有点浪费了。不过 Doug Lea 也说了，根据统计，如果使用默认的阈值，大约只有 1/6 的节点需要克隆。

### 5.4 get 操作分析

相对于 put 来说，get 真的不要太简单。

计算 hash 值，找到 segment 数组中的具体位置，或我们前面用的“槽”
 槽中也是一个数组，根据 hash 找到数组中具体的位置
 到这里是链表了，顺着链表进行查找即可

```java
public V get(Object key) {
    Segment<K,V> s; // manually integrate access methods to reduce overhead
    HashEntry<K,V>[] tab;
    // 1. hash 值
    int h = hash(key);
    long u = (((h >>> segmentShift) & segmentMask) << SSHIFT) + SBASE;
    // 2. 根据 hash 找到对应的 segment
    if ((s = (Segment<K,V>)UNSAFE.getObjectVolatile(segments, u)) != null &&
        (tab = s.table) != null) {
        // 3. 找到segment 内部数组相应位置的链表，遍历
        for (HashEntry<K,V> e = (HashEntry<K,V>) UNSAFE.getObjectVolatile
                 (tab, ((long)(((tab.length - 1) & h)) << TSHIFT) + TBASE);
             e != null; e = e.next) {
            K k;
            if ((k = e.key) == key || (e.hash == h && key.equals(k)))
                return e.value;
        }
    }
    return null;
}
```

#### 5.4.1 并发问题分析

现在我们已经说完了 put 过程和 get 过程，我们可以看到 get 过程中是没有加锁的，那自然我们就需要去考虑并发问题。

添加节点的操作 put 和删除节点的操作 remove 都是要加 segment 上的独占锁的，所以它们之间自然不会有问题，我们需要考虑的问题就是 get 的时候在同一个 segment 中发生了 put 或 remove 操作。

##### 1. put 操作的线程安全性。

- 初始化槽，这个我们之前就说过了，使用了 CAS 来初始化 Segment 中的数组。
- 添加节点到链表的操作是插入到表头的，所以，如果这个时候 get 操作在链表遍历的过程已经到了中间，是不会影响的。当然，另一个并发问题就是 get 操作在 put 之后，需要保证刚刚插入表头的节点被读取，这个依赖于 setEntryAt 方法中使用的  UNSAFE.putOrderedObject。
- 扩容。扩容是新创建了数组，然后进行迁移数据，最后面将 newTable 设置给属性 table。所以，如果 get  操作此时也在进行，那么也没关系，如果 get 先行，那么就是在旧的 table 上做查询操作；而 put 先行，那么 put  操作的可见性保证就是 table 使用了 volatile 关键字。

##### 2. remove 操作的线程安全性。

remove 操作我们没有分析源码，所以这里说的读者感兴趣的话还是需要到源码中去求实一下的。

get 操作需要遍历链表，但是 remove 操作会"破坏"链表。

如果 remove 破坏的节点 get 操作已经过去了，那么这里不存在任何问题。

如果 remove 先破坏了一个节点，分两种情况考虑。 1、如果此节点是头结点，那么需要将头结点的 next  设置为数组该位置的元素，table 虽然使用了 volatile 修饰，但是 volatile  并不能提供数组内部操作的可见性保证，所以源码中使用了 UNSAFE 来操作数组，请看方法  setEntryAt。2、如果要删除的节点不是头结点，它会将要删除节点的后继节点接到前驱节点中，这里的并发保证就是 next 属性是  volatile 的。

## 六、Java8 ConcurrentHashMap

Java7 中实现的 ConcurrentHashMap 说实话还是比较复杂的，Java8 对 ConcurrentHashMap  进行了比较大的改动。建议读者可以参考 Java8 中 HashMap 相对于 Java7 HashMap 的改动，对于  ConcurrentHashMap，Java8 也引入了红黑树。

说实在的，Java8 ConcurrentHashMap 源码真心挺复杂的，最难的在于数据迁移操作，扩容这一块。

我们先用一个示意图来描述下其结构：
 ![heishenhua04](https://icefiredb-1300435688.piccd.myqcloud.com/betsy/java8currenthash_1601298351950.png)
 结构上和 Java8 的 HashMap 基本上一样，不过它要保证线程安全性，所以在源码上确实要复杂点。

### 6.1 初始化

```java
// 这构造函数里，什么都不干
public ConcurrentHashMap() {
}
public ConcurrentHashMap(int initialCapacity) {
    if (initialCapacity < 0)
        throw new IllegalArgumentException();
    int cap = ((initialCapacity >= (MAXIMUM_CAPACITY >>> 1)) ?
               MAXIMUM_CAPACITY :
               tableSizeFor(initialCapacity + (initialCapacity >>> 1) + 1));
    this.sizeCtl = cap;
}
```

这个初始化方法有点意思，通过提供初始容量，计算了 sizeCtl，sizeCtl = 【 (1.5 * initialCapacity + 1)，然后向上取最近的 2 的 n 次方】。如 initialCapacity 为 10，那么得到 sizeCtl 为 16，如果  initialCapacity 为 11，得到 sizeCtl 为 32。

sizeCtl 这个属性使用的场景很多，不过只要跟着文章的思路来，就不会被它搞晕了。

如果你爱折腾，也可以看下另一个有三个参数的构造方法，这里我就不说了，大部分时候，我们会使用无参构造函数进行实例化，我们也按照这个思路来进行源码分析吧。

### 6.2 put 操作分析

仔细地一行一行代码看下去：

```java
public V put(K key, V value) {
    return putVal(key, value, false);
}
final V putVal(K key, V value, boolean onlyIfAbsent) {
    if (key == null || value == null) throw new NullPointerException();
    // 得到 hash 值
    int hash = spread(key.hashCode());
    // 用于记录相应链表的长度
    int binCount = 0;
    for (Node<K,V>[] tab = table;;) {
        Node<K,V> f; int n, i, fh;
        // 如果数组"空"，进行数组初始化
        if (tab == null || (n = tab.length) == 0)
            // 初始化数组，后面会详细介绍
            tab = initTable();

        // 找该 hash 值对应的数组下标，得到第一个节点 f
        else if ((f = tabAt(tab, i = (n - 1) & hash)) == null) {
            // 如果数组该位置为空，
            //    用一次 CAS 操作将这个新值放入其中即可，这个 put 操作差不多就结束了，可以拉到最后面了
            //          如果 CAS 失败，那就是有并发操作，进到下一个循环就好了
            if (casTabAt(tab, i, null,
                         new Node<K,V>(hash, key, value, null)))
                break;                   // no lock when adding to empty bin
        }
        // hash 居然可以等于 MOVED，这个需要到后面才能看明白，不过从名字上也能猜到，肯定是因为在扩容
        else if ((fh = f.hash) == MOVED)
            // 帮助数据迁移，这个等到看完数据迁移部分的介绍后，再理解这个就很简单了
            tab = helpTransfer(tab, f);

        else { // 到这里就是说，f 是该位置的头结点，而且不为空

            V oldVal = null;
            // 获取数组该位置的头结点的监视器锁
            synchronized (f) {
                if (tabAt(tab, i) == f) {
                    if (fh >= 0) { // 头结点的 hash 值大于 0，说明是链表
                        // 用于累加，记录链表的长度
                        binCount = 1;
                        // 遍历链表
                        for (Node<K,V> e = f;; ++binCount) {
                            K ek;
                            // 如果发现了"相等"的 key，判断是否要进行值覆盖，然后也就可以 break 了
                            if (e.hash == hash &&
                                ((ek = e.key) == key ||
                                 (ek != null && key.equals(ek)))) {
                                oldVal = e.val;
                                if (!onlyIfAbsent)
                                    e.val = value;
                                break;
                            }
                            // 到了链表的最末端，将这个新值放到链表的最后面
                            Node<K,V> pred = e;
                            if ((e = e.next) == null) {
                                pred.next = new Node<K,V>(hash, key,
                                                          value, null);
                                break;
                            }
                        }
                    }
                    else if (f instanceof TreeBin) { // 红黑树
                        Node<K,V> p;
                        binCount = 2;
                        // 调用红黑树的插值方法插入新节点
                        if ((p = ((TreeBin<K,V>)f).putTreeVal(hash, key,
                                                       value)) != null) {
                            oldVal = p.val;
                            if (!onlyIfAbsent)
                                p.val = value;
                        }
                    }
                }
            }

            if (binCount != 0) {
                // 判断是否要将链表转换为红黑树，临界值和 HashMap 一样，也是 8
                if (binCount >= TREEIFY_THRESHOLD)
                    // 这个方法和 HashMap 中稍微有一点点不同，那就是它不是一定会进行红黑树转换，
                    // 如果当前数组的长度小于 64，那么会选择进行数组扩容，而不是转换为红黑树
                    //    具体源码我们就不看了，扩容部分后面说
                    treeifyBin(tab, i);
                if (oldVal != null)
                    return oldVal;
                break;
            }
        }
    }
    // 
    addCount(1L, binCount);
    return null;
}
```

put 的主流程看完了，但是至少留下了几个问题，第一个是初始化，第二个是扩容，第三个是帮助数据迁移，这些我们都会在后面进行一一介绍。

### 6.3 初始化数组：initTable

这个比较简单，主要就是初始化一个合适大小的数组，然后会设置 sizeCtl。

初始化方法中的并发问题是通过对 sizeCtl 进行一个 CAS 操作来控制的。

```java
private final Node<K,V>[] initTable() {
    Node<K,V>[] tab; int sc;
    while ((tab = table) == null || tab.length == 0) {
        // 初始化的"功劳"被其他线程"抢去"了
        if ((sc = sizeCtl) < 0)
            Thread.yield(); // lost initialization race; just spin
        // CAS 一下，将 sizeCtl 设置为 -1，代表抢到了锁
        else if (U.compareAndSwapInt(this, SIZECTL, sc, -1)) {
            try {
                if ((tab = table) == null || tab.length == 0) {
                    // DEFAULT_CAPACITY 默认初始容量是 16
                    int n = (sc > 0) ? sc : DEFAULT_CAPACITY;
                    // 初始化数组，长度为 16 或初始化时提供的长度
                    Node<K,V>[] nt = (Node<K,V>[])new Node<?,?>[n];
                    // 将这个数组赋值给 table，table 是 volatile 的
                    table = tab = nt;
                    // 如果 n 为 16 的话，那么这里 sc = 12
                    // 其实就是 0.75 * n
                    sc = n - (n >>> 2);
                }
            } finally {
                // 设置 sizeCtl 为 sc，我们就当是 12 吧
                sizeCtl = sc;
            }
            break;
        }
    }
    return tab;
}
```

### 6.4 链表转红黑树: treeifyBin

前面我们在 put 源码分析也说过，treeifyBin 不一定就会进行红黑树转换，也可能是仅仅做数组扩容。我们还是进行源码分析吧。

```java
private final void treeifyBin(Node<K,V>[] tab, int index) {
    Node<K,V> b; int n, sc;
    if (tab != null) {
        // MIN_TREEIFY_CAPACITY 为 64
        // 所以，如果数组长度小于 64 的时候，其实也就是 32 或者 16 或者更小的时候，会进行数组扩容
        if ((n = tab.length) < MIN_TREEIFY_CAPACITY)
            // 后面我们再详细分析这个方法
            tryPresize(n << 1);
        // b 是头结点
        else if ((b = tabAt(tab, index)) != null && b.hash >= 0) {
            // 加锁
            synchronized (b) {

                if (tabAt(tab, index) == b) {
                    // 下面就是遍历链表，建立一颗红黑树
                    TreeNode<K,V> hd = null, tl = null;
                    for (Node<K,V> e = b; e != null; e = e.next) {
                        TreeNode<K,V> p =
                            new TreeNode<K,V>(e.hash, e.key, e.val,
                                              null, null);
                        if ((p.prev = tl) == null)
                            hd = p;
                        else
                            tl.next = p;
                        tl = p;
                    }
                    // 将红黑树设置到数组相应位置中
                    setTabAt(tab, index, new TreeBin<K,V>(hd));
                }
            }
        }
    }
}
```

### 6.5 扩容：tryPresize

要说Java8 ConcurrentHashMap 的源码复杂，那么说的就是迁移操作和扩容操作。

这个方法要完完全全看懂还需要看之后的 transfer 方法，读者应该提前知道这点。

这里的扩容也是做翻倍扩容的，扩容后数组容量为原来的 2 倍。

```java
// 首先要说明的是，方法参数 size 传进来的时候就已经翻了倍了
private final void tryPresize(int size) {
    // c：size 的 1.5 倍，再加 1，再往上取最近的 2 的 n 次方。
    int c = (size >= (MAXIMUM_CAPACITY >>> 1)) ? MAXIMUM_CAPACITY :
        tableSizeFor(size + (size >>> 1) + 1);
    int sc;
    while ((sc = sizeCtl) >= 0) {
        Node<K,V>[] tab = table; int n;

        // 这个 if 分支和之前说的初始化数组的代码基本上是一样的，在这里，我们可以不用管这块代码
        if (tab == null || (n = tab.length) == 0) {
            n = (sc > c) ? sc : c;
            if (U.compareAndSwapInt(this, SIZECTL, sc, -1)) {
                try {
                    if (table == tab) {
                        @SuppressWarnings("unchecked")
                        Node<K,V>[] nt = (Node<K,V>[])new Node<?,?>[n];
                        table = nt;
                        sc = n - (n >>> 2); // 0.75 * n
                    }
                } finally {
                    sizeCtl = sc;
                }
            }
        }
        else if (c <= sc || n >= MAXIMUM_CAPACITY)
            break;
        else if (tab == table) {
            // 我没看懂 rs 的真正含义是什么，不过也关系不大
            int rs = resizeStamp(n);

            if (sc < 0) {
                Node<K,V>[] nt;
                if ((sc >>> RESIZE_STAMP_SHIFT) != rs || sc == rs + 1 ||
                    sc == rs + MAX_RESIZERS || (nt = nextTable) == null ||
                    transferIndex <= 0)
                    break;
                // 2. 用 CAS 将 sizeCtl 加 1，然后执行 transfer 方法
                //    此时 nextTab 不为 null
                if (U.compareAndSwapInt(this, SIZECTL, sc, sc + 1))
                    transfer(tab, nt);
            }
            // 1. 将 sizeCtl 设置为 (rs << RESIZE_STAMP_SHIFT) + 2)
            //     我是没看懂这个值真正的意义是什么？不过可以计算出来的是，结果是一个比较大的负数
            //  调用 transfer 方法，此时 nextTab 参数为 null
            else if (U.compareAndSwapInt(this, SIZECTL, sc,
                                         (rs << RESIZE_STAMP_SHIFT) + 2))
                transfer(tab, null);
        }
    }
}
```

这个方法的核心在于 sizeCtl 值的操作，首先将其设置为一个负数，然后执行 transfer(tab, null)，再下一个循环将  sizeCtl 加 1，并执行 transfer(tab, nt)，之后可能是继续 sizeCtl 加 1，并执行 transfer(tab,  nt)。

所以，可能的操作就是执行 **1 次 transfer(tab, null) + 多次 transfer(tab, nt)**，这里怎么结束循环的需要看完 transfer 源码才清楚。

#### 6.5.1 数据迁移：transfer

下面这个方法有点长，将原来的 tab 数组的元素迁移到新的 nextTab 数组中。

虽然我们之前说的 tryPresize 方法中多次调用 transfer 不涉及多线程，但是这个 transfer  方法可以在其他地方被调用，典型地，我们之前在说 put 方法的时候就说过了，请往上看 put 方法，是不是有个地方调用了  helpTransfer 方法，helpTransfer 方法会调用 transfer 方法的。

此方法支持多线程执行，外围调用此方法的时候，会保证第一个发起数据迁移的线程，nextTab 参数为 null，之后再调用此方法的时候，nextTab 不会为 null。

阅读源码之前，先要理解并发操作的机制。原数组长度为 n，所以我们有 n  个迁移任务，让每个线程每次负责一个小任务是最简单的，每做完一个任务再检测是否有其他没做完的任务，帮助迁移就可以了，而 Doug Lea  使用了一个 stride，简单理解就是步长，每个线程每次负责迁移其中的一部分，如每次迁移 16  个小任务。所以，我们就需要一个全局的调度者来安排哪个线程执行哪几个任务，这个就是属性 transferIndex 的作用。

第一个发起数据迁移的线程会将 transferIndex 指向原数组最后的位置，然后从后往前的 stride 个任务属于第一个线程，然后将 transferIndex 指向新的位置，再往前的 stride  个任务属于第二个线程，依此类推。当然，这里说的第二个线程不是真的一定指代了第二个线程，也可以是同一个线程，这个读者应该能理解吧。其实就是将一个大的迁移任务分为了一个个任务包。

```java
private final void transfer(Node<K,V>[] tab, Node<K,V>[] nextTab) {
    int n = tab.length, stride;

    // stride 在单核下直接等于 n，多核模式下为 (n>>>3)/NCPU，最小值是 16
    // stride 可以理解为”步长“，有 n 个位置是需要进行迁移的，
    //   将这 n 个任务分为多个任务包，每个任务包有 stride 个任务
    if ((stride = (NCPU > 1) ? (n >>> 3) / NCPU : n) < MIN_TRANSFER_STRIDE)
        stride = MIN_TRANSFER_STRIDE; // subdivide range

    // 如果 nextTab 为 null，先进行一次初始化
    //    前面我们说了，外围会保证第一个发起迁移的线程调用此方法时，参数 nextTab 为 null
    //       之后参与迁移的线程调用此方法时，nextTab 不会为 null
    if (nextTab == null) {
        try {
            // 容量翻倍
            Node<K,V>[] nt = (Node<K,V>[])new Node<?,?>[n << 1];
            nextTab = nt;
        } catch (Throwable ex) {      // try to cope with OOME
            sizeCtl = Integer.MAX_VALUE;
            return;
        }
        // nextTable 是 ConcurrentHashMap 中的属性
        nextTable = nextTab;
        // transferIndex 也是 ConcurrentHashMap 的属性，用于控制迁移的位置
        transferIndex = n;
    }

    int nextn = nextTab.length;

    // ForwardingNode 翻译过来就是正在被迁移的 Node
    // 这个构造方法会生成一个Node，key、value 和 next 都为 null，关键是 hash 为 MOVED
    // 后面我们会看到，原数组中位置 i 处的节点完成迁移工作后，
    //    就会将位置 i 处设置为这个 ForwardingNode，用来告诉其他线程该位置已经处理过了
    //    所以它其实相当于是一个标志。
    ForwardingNode<K,V> fwd = new ForwardingNode<K,V>(nextTab);


    // advance 指的是做完了一个位置的迁移工作，可以准备做下一个位置的了
    boolean advance = true;
    boolean finishing = false; // to ensure sweep before committing nextTab

    /*
     * 下面这个 for 循环，最难理解的在前面，而要看懂它们，应该先看懂后面的，然后再倒回来看
     * 
     */

    // i 是位置索引，bound 是边界，注意是从后往前
    for (int i = 0, bound = 0;;) {
        Node<K,V> f; int fh;

        // 下面这个 while 真的是不好理解
        // advance 为 true 表示可以进行下一个位置的迁移了
        //   简单理解结局：i 指向了 transferIndex，bound 指向了 transferIndex-stride
        while (advance) {
            int nextIndex, nextBound;
            if (--i >= bound || finishing)
                advance = false;

            // 将 transferIndex 值赋给 nextIndex
            // 这里 transferIndex 一旦小于等于 0，说明原数组的所有位置都有相应的线程去处理了
            else if ((nextIndex = transferIndex) <= 0) {
                i = -1;
                advance = false;
            }
            else if (U.compareAndSwapInt
                     (this, TRANSFERINDEX, nextIndex,
                      nextBound = (nextIndex > stride ?
                                   nextIndex - stride : 0))) {
                // 看括号中的代码，nextBound 是这次迁移任务的边界，注意，是从后往前
                bound = nextBound;
                i = nextIndex - 1;
                advance = false;
            }
        }
        if (i < 0 || i >= n || i + n >= nextn) {
            int sc;
            if (finishing) {
                // 所有的迁移操作已经完成
                nextTable = null;
                // 将新的 nextTab 赋值给 table 属性，完成迁移
                table = nextTab;
                // 重新计算 sizeCtl：n 是原数组长度，所以 sizeCtl 得出的值将是新数组长度的 0.75 倍
                sizeCtl = (n << 1) - (n >>> 1);
                return;
            }

            // 之前我们说过，sizeCtl 在迁移前会设置为 (rs << RESIZE_STAMP_SHIFT) + 2
            // 然后，每有一个线程参与迁移就会将 sizeCtl 加 1，
            // 这里使用 CAS 操作对 sizeCtl 进行减 1，代表做完了属于自己的任务
            if (U.compareAndSwapInt(this, SIZECTL, sc = sizeCtl, sc - 1)) {
                // 任务结束，方法退出
                if ((sc - 2) != resizeStamp(n) << RESIZE_STAMP_SHIFT)
                    return;

                // 到这里，说明 (sc - 2) == resizeStamp(n) << RESIZE_STAMP_SHIFT，
                // 也就是说，所有的迁移任务都做完了，也就会进入到上面的 if(finishing){} 分支了
                finishing = advance = true;
                i = n; // recheck before commit
            }
        }
        // 如果位置 i 处是空的，没有任何节点，那么放入刚刚初始化的 ForwardingNode ”空节点“
        else if ((f = tabAt(tab, i)) == null)
            advance = casTabAt(tab, i, null, fwd);
        // 该位置处是一个 ForwardingNode，代表该位置已经迁移过了
        else if ((fh = f.hash) == MOVED)
            advance = true; // already processed
        else {
            // 对数组该位置处的结点加锁，开始处理数组该位置处的迁移工作
            synchronized (f) {
                if (tabAt(tab, i) == f) {
                    Node<K,V> ln, hn;
                    // 头结点的 hash 大于 0，说明是链表的 Node 节点
                    if (fh >= 0) {
                        // 下面这一块和 Java7 中的 ConcurrentHashMap 迁移是差不多的，
                        // 需要将链表一分为二，
                        //   找到原链表中的 lastRun，然后 lastRun 及其之后的节点是一起进行迁移的
                        //   lastRun 之前的节点需要进行克隆，然后分到两个链表中
                        int runBit = fh & n;
                        Node<K,V> lastRun = f;
                        for (Node<K,V> p = f.next; p != null; p = p.next) {
                            int b = p.hash & n;
                            if (b != runBit) {
                                runBit = b;
                                lastRun = p;
                            }
                        }
                        if (runBit == 0) {
                            ln = lastRun;
                            hn = null;
                        }
                        else {
                            hn = lastRun;
                            ln = null;
                        }
                        for (Node<K,V> p = f; p != lastRun; p = p.next) {
                            int ph = p.hash; K pk = p.key; V pv = p.val;
                            if ((ph & n) == 0)
                                ln = new Node<K,V>(ph, pk, pv, ln);
                            else
                                hn = new Node<K,V>(ph, pk, pv, hn);
                        }
                        // 其中的一个链表放在新数组的位置 i
                        setTabAt(nextTab, i, ln);
                        // 另一个链表放在新数组的位置 i+n
                        setTabAt(nextTab, i + n, hn);
                        // 将原数组该位置处设置为 fwd，代表该位置已经处理完毕，
                        //    其他线程一旦看到该位置的 hash 值为 MOVED，就不会进行迁移了
                        setTabAt(tab, i, fwd);
                        // advance 设置为 true，代表该位置已经迁移完毕
                        advance = true;
                    }
                    else if (f instanceof TreeBin) {
                        // 红黑树的迁移
                        TreeBin<K,V> t = (TreeBin<K,V>)f;
                        TreeNode<K,V> lo = null, loTail = null;
                        TreeNode<K,V> hi = null, hiTail = null;
                        int lc = 0, hc = 0;
                        for (Node<K,V> e = t.first; e != null; e = e.next) {
                            int h = e.hash;
                            TreeNode<K,V> p = new TreeNode<K,V>
                                (h, e.key, e.val, null, null);
                            if ((h & n) == 0) {
                                if ((p.prev = loTail) == null)
                                    lo = p;
                                else
                                    loTail.next = p;
                                loTail = p;
                                ++lc;
                            }
                            else {
                                if ((p.prev = hiTail) == null)
                                    hi = p;
                                else
                                    hiTail.next = p;
                                hiTail = p;
                                ++hc;
                            }
                        }
                        // 如果一分为二后，节点数少于 8，那么将红黑树转换回链表
                        ln = (lc <= UNTREEIFY_THRESHOLD) ? untreeify(lo) :
                            (hc != 0) ? new TreeBin<K,V>(lo) : t;
                        hn = (hc <= UNTREEIFY_THRESHOLD) ? untreeify(hi) :
                            (lc != 0) ? new TreeBin<K,V>(hi) : t;

                        // 将 ln 放置在新数组的位置 i
                        setTabAt(nextTab, i, ln);
                        // 将 hn 放置在新数组的位置 i+n
                        setTabAt(nextTab, i + n, hn);
                        // 将原数组该位置处设置为 fwd，代表该位置已经处理完毕，
                        //    其他线程一旦看到该位置的 hash 值为 MOVED，就不会进行迁移了
                        setTabAt(tab, i, fwd);
                        // advance 设置为 true，代表该位置已经迁移完毕
                        advance = true;
                    }
                }
            }
        }
    }
}
```

说到底，transfer 这个方法并没有实现所有的迁移任务，每次调用这个方法只实现了 transferIndex 往前 stride 个位置的迁移工作，其他的需要由外围来控制。

这个时候，再回去仔细看 tryPresize 方法可能就会更加清晰一些了。

### 6.6 get 操作分析

get 方法从来都是最简单的，这里也不例外：

1. 计算 hash 值
2. 根据 hash 值找到数组对应位置: (n - 1) & h
3. 根据该位置处结点性质进行相应查找

- 如果该位置为 null，那么直接返回 null 就可以了
- 如果该位置处的节点刚好就是我们需要的，返回该节点的值即可
- 如果该位置节点的 hash 值小于 0，说明正在扩容，或者是红黑树，后面我们再介绍 find 方法
- 如果以上 3 条都不满足，那就是链表，进行遍历比对即可

```java
public V get(Object key) {
    Node<K,V>[] tab; Node<K,V> e, p; int n, eh; K ek;
    int h = spread(key.hashCode());
    if ((tab = table) != null && (n = tab.length) > 0 &&
        (e = tabAt(tab, (n - 1) & h)) != null) {
        // 判断头结点是否就是我们需要的节点
        if ((eh = e.hash) == h) {
            if ((ek = e.key) == key || (ek != null && key.equals(ek)))
                return e.val;
        }
        // 如果头结点的 hash 小于 0，说明 正在扩容，或者该位置是红黑树
        else if (eh < 0)
            // 参考 ForwardingNode.find(int h, Object k) 和 TreeBin.find(int h, Object k)
            return (p = e.find(h, key)) != null ? p.val : null;

        // 遍历链表
        while ((e = e.next) != null) {
            if (e.hash == h &&
                ((ek = e.key) == key || (ek != null && key.equals(ek))))
                return e.val;
        }
    }
    return null;
}
```

#### 6.6.1 ConcurrentHashMap API

- 练手

```java
package test.java.util.concurrent;
 
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import org.junit.Test;
 
/**
 * ConcurrentHashMap Test Class
 *
 * @date 2020-09-28 23:15:10
 */
public class ConcurrentHashMapTest {
        /**
        *无参构造函数
        * @Param
        */
        @Test           
        public void testConstruct0()throws Exception{
                ConcurrentHashMap map=new ConcurrentHashMap();
                System.out.println(map.get("3333"));
        }
        /**
        * 按照容量初始化
         * 需要计算
        * @Param
        */
        @Test
        public void testConstruct1()throws Exception{
                ConcurrentHashMap map=new ConcurrentHashMap(3);
                System.out.println(map.get("3333"));
        }
        /**
        * 根据已有map初始化
        * @Param
        */
        @Test
        public void testConstruct2()throws Exception{
                Map<String,String> param=new ConcurrentHashMap<>();
                param.put("1","1");
                param.put("2","2");
                param.put("3","3");
                ConcurrentHashMap map=new ConcurrentHashMap(param);
                System.out.println(map.get("3"));
        }
        /**
        *   根据容量及负载因子初始化
        * @Param
        */
        @Test
        public void testConstruct3()throws Exception{
                ConcurrentHashMap map=new ConcurrentHashMap(3,34f);
                System.out.println(map.size());
        }
        /**
        *根据容量及负载因子和并发级别初始化初始化
        * @Param
        */
        @Test
        public void testConstruct4()throws Exception{
                ConcurrentHashMap map=new ConcurrentHashMap(3,34f,3);
                System.out.println(map.size());
        }
        /**
         * map中键值对数量
         * @Param
         */
        @Test
        public void testSize()throws Exception{
                ConcurrentHashMap map=new ConcurrentHashMap();
                map.put("1","1");
                map.put("2","2");
                map.put("3","3");
                System.out.println(map.size());
        }
        /**
         *是否为空
         * @Param
         */
        @Test
        public void testIsEmpty()throws Exception{
                ConcurrentHashMap map=new ConcurrentHashMap();
                map.put("1","1");
                map.put("2","2");
                map.put("3","3");
                System.out.println(map.isEmpty());
        }
        /**
         * 根据key获取value
         * @Param
         */
        @Test
        public void testGet()throws Exception{
                ConcurrentHashMap map=new ConcurrentHashMap();
                map.put("123","1");
                map.put("123","2");
                map.put("3","3");
                System.out.println(map.get("123"));
        }
        /**
         *是否包含key
         * @Param
         */
        @Test
        public void testContainsKey()throws Exception{
                ConcurrentHashMap map=new ConcurrentHashMap();
                map.put("123","1");
                map.put("123","2");
                map.put("3","3");
                System.out.println(map.containsKey("123"));
        }
        /**
         *是否包含value
         * @Param
         */
        @Test
        public void testContainsValue()throws Exception{
                ConcurrentHashMap map=new ConcurrentHashMap();
                map.put("1","31");
                map.put("123","2");
                map.put("3","3");
                System.out.println(map.containsValue("31"));
        }
        /**
         * 存放值onlyIfAbsent  如果当前位置已存在一个值，是否替换，false是替换，true是不替换
         *
         * @Param
         */
        @Test
        public void testPut()throws Exception{
                ConcurrentHashMap map=new ConcurrentHashMap();
                map.put("1","31");
                map.put("123","2");
                map.put("3","3");
                System.out.println(map.containsValue("31"));
        }
        /**
         *将map中的键值对放入map1中
         * @Param
         */
        @Test
        public void testPutAll()throws Exception{
                ConcurrentHashMap map=new ConcurrentHashMap();
                map.put("1","31");
                map.put("123","2");
                map.put("3","3");
                ConcurrentHashMap map1=new ConcurrentHashMap();
                map1.putAll(map);
                System.out.println(map1.get("1"));
                System.out.println(map.get("1"));
        }
        /**
         * 移除key为1的键值对
         * @Param
         */
        @Test
        public void testRemove1()throws Exception{
                ConcurrentHashMap map=new ConcurrentHashMap();
                map.put("1","31");
                map.put("123","2");
                map.put("3","3");
                System.out.println(map.remove("1"));
                System.out.println(map.get("1"));
        }
 
        /**
         *清空map
         * @Param
         */
        @Test
        public void testClear()throws Exception{
                ConcurrentHashMap map=new ConcurrentHashMap();
                map.put("1","31");
                map.put("123","2");
                map.put("3","3");
                map.clear();
                System.out.println(map.get("1"));
        }
        /**
         * 获取key的set集合
         * @Param
         */
        @Test
        public void testKeySet1()throws Exception{
                ConcurrentHashMap map=new ConcurrentHashMap();
                map.put("1","31");
                map.put("123","2");
                map.put("3","3");
                ConcurrentHashMap.KeySetView keySetView=map.keySet();
                Iterator iterator=keySetView.iterator();
                while (iterator.hasNext()){
                        System.out.println(iterator.next());
                }
                System.out.println(keySetView.size());
        }
        /**
         * 获取value集合
         * @Param
         */
        @Test
        public void testValues()throws Exception{
                ConcurrentHashMap map=new ConcurrentHashMap();
                map.put("1","31");
                map.put("123","2");
                map.put("3","3");
                Collection collection=map.values();
                Iterator iterator=collection.iterator();
                while (iterator.hasNext()){
                        System.out.println(iterator.next());
                }
        }
        /**
         * Map.Entry遍历所有键值对
         * @Param
         */
        @Test
        public void testEntrySet()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("123","2");
            map.put("3","3");
            Set<Map.Entry<String,String>> entries=map.entrySet();
            Iterator iterator=entries.iterator();
            while (iterator.hasNext()){
                Map.Entry entry= (Map.Entry) iterator.next();
                System.out.println(entry.getKey()+":"+entry.getValue());
            }
        }
        /**
         *hashcode计算key+value的hashcode
         * 再求和
         * @Param
         */
        @Test
        public void testHashCode()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("123","2");
            map.put("3","3");
            System.out.println(map.hashCode());
        }
        /**
         *{1=31, 123=2, 3=3}
         *
         * @Param
         */
        @Test
        public void testToString()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("123","2");
            map.put("3","3");
            System.out.println(map.toString());
        }
 
        /**
         * 比较的是所有key和所有value
         * @Param
         */
        @Test
        public void testEquals()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("123","2");
            map.put("3","3");
            ConcurrentHashMap<String,String> map1=new ConcurrentHashMap();
            map1.put("1","31");
            map1.put("3","3");
            map1.put("123","2");
            System.out.println(map.equals(map));
            System.out.println(map.equals(map1));
        }
        /**
         *如果key对应的value已经存在则返回value不存放新value
         * 如果key对应value不存在，则放入value，并返回null
         * @Param
         */
        @Test
        public void testPutIfAbsent()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("3","3");
            map.put("123","2");
            System.out.println(map.putIfAbsent("1231","22"));
            System.out.println(map.get("1231"));
            System.out.println(map.get("123"));
        }
        /**
         * 按照键值对删除元素
         * @Param
         */
        @Test
        public void testRemove()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("3","3");
            map.put("123","2");
            map.remove("123","2w");
            System.out.println(map.get("123"));
        }
        /**
         * 替换掉key所对应的value值
         * @Param
         */
        @Test
        public void testReplace1()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("3","3");
            map.put("123","2");
            map.replace("123","2","13");
            System.out.println(map.get("123"));
        }
        /**
         * 替换掉key所对应的值
         * @Param
         */
        @Test
        public void testReplace()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("3","3");
            map.put("123","2");
            map.replace("123","22321");
            System.out.println(map.get("123"));
        }
        /**
         * 获取key对应的value值，如果没有则返回指定默认值
         * @Param
         */
        @Test
        public void testGetOrDefault()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("3","3");
            map.put("123","2");
            System.out.println(map.getOrDefault("1233","13321"));
        }
        /**
         * forEach:使用BIConsumer遍历map
         * @Param
         */
        @Test
        public void testForEach2()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("3","3");
            map.put("123","2");
            map.forEach((key,val)-> System.out.println(key+":"+val));
 
        }
        /**
         * 用BiFunction计算的结果替换掉所有map中的key所对应的value值
         * @Param
         */
        @Test
        public void testReplaceAll()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("3","3");
            map.put("123","2");
            map.replaceAll((key,oldVal)-> key+":"+oldVal);
            Set<Map.Entry<String,String>> entrySet= (Set<Map.Entry<String, String>>) map.entrySet();
            Iterator iterator=entrySet.iterator();
            while (iterator.hasNext()){
                Map.Entry entry= (Map.Entry) iterator.next();
                System.out.println(entry.getKey()+"-"+entry.getValue());
            }
        }
        /**
         *  如果key对应的value为空则将用Function计算得到的值存入
         * @Param
         */
        @Test
        public void testComputeIfAbsent()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("3","3");
            map.put("123","2");
            map.computeIfAbsent("1231",(key)-> key+"113123");
            System.out.println(map.get("1234"));
            Set<Map.Entry<String,String>> entrySet= (Set<Map.Entry<String, String>>) map.entrySet();
            Iterator iterator=entrySet.iterator();
            while (iterator.hasNext()){
                Map.Entry entry= (Map.Entry) iterator.next();
                System.out.println(entry.getKey()+"-"+entry.getValue());
            }
        }
        /**
         *如果key对应的value存在，则替换为通过BiFunction计算得到的value，如果不存在则不存入
         * @Param
         */
        @Test
        public void testComputeIfPresent()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("3","3");
            map.put("123","2");
            System.out.println(map.get("123"));
            map.computeIfPresent("123",(key,val)-> key+"-"+val);
            System.out.println(map.get("123"));
        }
        /**
         *  无论key是否存在，都将BiFunction计算的值存入，存在则覆盖，不存在则新增
         * @Param
         */
        @Test
        public void testCompute()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("3","3");
            map.put("123","2");
            System.out.println(map.get("123"));
            map.compute("1234",(key,val)-> key+"-"+val);
            System.out.println(map.get("1234"));
        }
        /**
         * 如果key对应的值存在，则将BiFunction计算后的值替换调旧值，如果不存在则新增计算后的值
         * @Param
         */
        @Test
        public void testMerge()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("3","3");
            map.put("123","2");
            System.out.println(map.get("123"));
            map.merge("1234","1234",(oldVal,newVal)-> oldVal+"-"+newVal);
            System.out.println(map.get("1234"));
        }
        /**
         * 是否包含指定value值
         * @Param
         */
        @Test
        public void testContains()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("3","3");
            map.put("123","2");
            System.out.println(map.contains("2"));
        }
 
        /**
         * 通过枚举key遍历
         * @Param
         */
        @Test
        public void testKeys()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("3","3");
            map.put("123","2");
            Enumeration<String> enumeration=map.keys();
            while (enumeration.hasMoreElements()){
                String key=enumeration.nextElement();
                System.out.println(key+":"+map.get(key));
            }
        }
        /**
         * 通过枚举遍历value
         * @Param
         */
        @Test
        public void testElements()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("3","3");
            map.put("123","2");
            Enumeration<String> values=map.elements();
            while (values.hasMoreElements()){
                System.out.println(values.nextElement());
            }
        }
        /**
         * 所有键值对映射的数量
         * @Param
         */
        @Test
        public void testMappingCount()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("3","3");
            map.put("123","2");
            System.out.println(map.mappingCount());
        }
        /**
         * 创建一个新的内部keysetview对象，其中包含一个新的concurrentHashMap和一个boolean值
         * @Param
         */
        @Test
        public void testNewKeySet1()throws Exception{
            System.out.println(ConcurrentHashMap.newKeySet().getMappedValue());
        }
        /**
         *创建一个新的内部keysetview对象，其中包含一个给定容量的新的concurrentHashMap和一个boolean值
         * @Param
         */
        @Test
        public void testNewKeySet()throws Exception{
            System.out.println(ConcurrentHashMap.newKeySet(2).getMappedValue());
        }
 
        /**
         * 通过keysetview遍历所有键值对
         * @Param
         */
        @Test
        public void testKeySet()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("3","3");
            map.put("123","2");
            ConcurrentHashMap.KeySetView keySetView=map.keySet();
            Iterator<String> iterator=keySetView.iterator();
            while (iterator.hasNext()){
                String key=iterator.next();
                System.out.println(key+":"+map.get(key));
            }
        }
        /**
         * 通过BIConsumer 遍历,第一个参数parallelismThreshold为并行子任务数量
         * 用ForkJoinPool实现
         * @Param
         */
        @Test
        public void testForEach1()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("3","3");
            map.put("123","2");
            map.forEach(1, (key,val) -> System.out.println(key+":"+val));
        }
        /**
         *并行子任务数，通过BiConsumer处理key val的结果传给Consumer再次计算
         * @Param
         */
        @Test
        public void testForEach()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("3","3");
            map.put("123","2");
            map.forEach(2,(key,val)-> key+"-"+val,key-> System.out.println(key+":"+map.get(key)) );
        }
        /**
         * 通过Bifunction自己编写查找处理结果
         * @Param
         */
        @Test
        public void testSearch()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("3","3");
            map.put("123","2");
            Integer ff=map.search(3, (key, val) -> {
                if (key.equals("3")){
                    return 321321;
                }
                return null;
            });
            System.out.println(ff);
        }
        /**
         *mapreduce计算
         * @Param
         */
        @Test
        public void testReduce()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","31");
            map.put("3","3");
            map.put("123","2");
            System.out.println(map.reduce(3,(key,val)->key+":"+val,(key,val)->key+"2"+val).toUpperCase());
        }
        /**
         *并行执行，  ToDoubleBiFunction将key和val转成double进行计算，
         *连续加两次basis值，将结果放入DoubleBinaryOperator中进行计算返回结果
         * @Param
         */
        @Test
        public void testReduceToDouble()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            System.out.println( map.reduceToDouble(3,(key,val)->Double.parseDouble(key)+Double.parseDouble(val),2,((left, right) ->left+right )));
        }
        /**
         *并行执行，  ToLongBiFunction将key和val转成long进行计算，
         *连续加两次basis值，将结果放入LongBinaryOperator中进行计算返回结果
         */
        @Test
        public void testReduceToLong()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            System.out.println( map.reduceToLong(3,(key,val)->Long.parseLong(key)+Long.parseLong(val),2,((left, right) ->left+right )));
        }
        /**
         *并行执行，ToIntBiFunction将key和val转成double进行计算，
         *连续加两次basis值，将结果放入IntBinaryOperator中进行计算返回结果
         * @Param
         */
        @Test
        public void testReduceToInt()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            System.out.println( map.reduceToInt(3,(key,val)->Integer.parseInt(key)+Integer.parseInt(val),2,((left, right) ->left+right )));
        }
        /**
         * 遍历所有key，并通过consumer消费key
         * @Param
         */
        @Test
        public void testForEachKey1()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            map.forEachKey(3,s -> System.out.println(s+":"+map.get(s)));
        }
        /**
         *遍历所有key，并将key传给Function计算，将结果传给consumer消费
         * @Param
         */
        @Test
        public void testForEachKey()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            map.forEachKey(3,key -> map.get(key),s -> System.out.println(s+":"+map.get(s)));
        }
        /**
         * 通过function 查找key进行处理对应的键值对
         * @Param
         */
        @Test
        public void testSearchKeys()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            String dd=map.searchKeys(3,s -> {
                if (s.equals("3")){
                    return map.get(s);
                }
                return null;
            });
            System.out.println(dd);
        }
        /**
         * 取出所有key进行计算
         * @Param
         */
        @Test
        public void testReduceKeys1()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            System.out.println(map.reduceKeys(3, (key, val) -> key + ":" + val));
        }
        /**
         *计算所有key，通过function，将结果传递给BiFunction并计算返回
         * @Param
         */
        @Test
        public void testReduceKeys()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            System.out.println(map.reduceKeys(3, key -> key + ":", (key, val) -> key + "--" + val).toUpperCase());
        }
        /**
         *并行执行，  ToDoubleFunction将key和val转成double进行计算，
         *连续加两次basis值，将结果放入DoubleBinaryOperator中进行计算返回结果
         * @Param
         */
        @Test
        public void testReduceKeysToDouble()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            System.out.println( map.reduceKeysToDouble(3,(key)->Double.parseDouble(key),2,((left, right) ->left+right )));
        }
        /**
         *并行执行，  ToLongBiFunction将key和val转成long进行计算，
         * 连续加两次basis值，将结果放入LongBinaryOperator中进行计算返回结果
         * @Param
         */
        @Test
        public void testReduceKeysToLong()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            System.out.println( map.reduceKeysToLong(3,(key)->Long.parseLong(key),2,((left, right) ->left+right )));
        }
        /**
         *并行执行，ToIntBiFunction将key和val转成double进行计算，
         *连续加两次basis值，将结果放入IntBinaryOperator中进行计算返回结果
         * @Param
         */
        @Test
        public void testReduceKeysToInt()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            System.out.println( map.reduceKeysToInt(3,(key)->Integer.parseInt(key),2,((left, right) ->left+right )));
        }
        /**
         *遍历所有value，并将key传给Function计算，将结果传给consumer消费
         * @Param
         */
        @Test
        public void testForEachValue1()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            map.forEachValue(3,s -> System.out.println(s+":"+map.get(s)));
        }
        /**
         *遍历所有value，并将key传给Function计算，将结果传给consumer消费
         * @Param
         */
        @Test
        public void testForEachValue()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            map.forEachValue(3,key -> key+"--",s -> System.out.println(s+":"+map.get(s)));
        }
        /**
         *通过function 查找value进行处理返回结果
         * @Param
         */
        @Test
        public void testSearchValues()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            Integer dd=map.searchValues(3,s -> {
                if (s.equals("2")){
                    return 3243;
                }
                return null;
            });
            System.out.println(dd);
        }
        /**
         *通过Bifunction规则计算并返回每次计算结果用于下次计算
         * @Param
         */
        @Test
        public void testReduceValues1()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            System.out.println(map.reduceValues(3, (val1, val2) -> val1 + "--"+val2));
        }
 
        /**
         *计算所有value，通过function，将结果传递给BiFunction并计算返回
         * @Param
         */
        @Test
        public void testReduceValues()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            System.out.println(map.reduceValues(3, val -> val + ":", (key, val) -> key + "--" + val).toUpperCase());
        }
 
        /**
         *并行执行，  ToDoubleFunction将key和val转成double进行计算，
         *连续加两次basis值，将结果放入DoubleBinaryOperator中进行计算返回结果
         * @Param
         */
        @Test
        public void testReduceValuesToDouble()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            System.out.println( map.reduceValuesToDouble(3,(key)->Double.parseDouble(key),2,((left, right) ->left+right )));
        }
        /**
         *并行执行，  ToLongBiFunction将key和val转成long进行计算，
         * 连续加两次basis值，将结果放入LongBinaryOperator中进行计算返回结果
         * @Param
         */
        @Test
        public void testReduceValuesToLong()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            System.out.println( map.reduceValuesToLong(3,(key)->Long.parseLong(key),2,((left, right) ->left+right )));
        }
        /**
         *并行执行，ToIntBiFunction将key和val转成double进行计算，
         * 连续加两次basis值，将结果放入IntBinaryOperator中进行计算返回结果
         * @Param
         */
        @Test
        public void testReduceValuesToInt()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            System.out.println( map.reduceValuesToInt(3,(key)->Integer.parseInt(key),2,((left, right) ->left+right )));
        }
        /**
         *遍历所有Entry，传给consumer消费
         * @Param
         */
        @Test
        public void testForEachEntry1()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            map.forEachEntry(3,s -> System.out.println(s.getKey()+":"+s.getValue()));
        }
        /**
         *遍历所有value，并将key传给Function计算，将结果传给consumer消费
         * @Param
         */
        @Test
        public void testForEachEntry()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            map.forEachEntry(3,key -> key+"--",s -> System.out.println(s+":"+map.get(s)));
        }
        /**
         *通过function 查找entry进行处理返回结果
         * @Param
         */
        @Test
        public void testSearchEntries()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            String dd=map.searchEntries(3,s -> {
                if (s.getValue().equals("2")){
                    return s.getKey();
                }
                return null;
            });
            System.out.println(dd);
        }
        /**
         *通过Bifunction规则计算并返回每次计算结果用于下次计算
         * @Param
         */
        @Test
        public void testReduceEntries1()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            System.out.println(map.reduceEntries(3, (val1, val2) -> val1));
        }
        /**
         *计算所有entry，通过function，将结果传递给BiFunction并计算返回
         * @Param
         */
        @Test
        public void testReduceEntries()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            System.out.println(map.reduceEntries(3, val -> val + ":", (key, val) -> key + "--" + val).toUpperCase());
        }
        /**
         *并行执行，  ToDoubleFunction将key和val转成double进行计算，
         *连续加两次basis值，将结果放入DoubleBinaryOperator中进行计算返回结果
         * @Param
         */
        @Test
        public void testReduceEntriesToDouble()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            System.out.println( map.reduceEntriesToDouble(3,entry->Double.parseDouble(entry.getKey()),2,((left, right) ->left+right )));
        }
        /**
         *并行执行，  ToLongBiFunction将key和val转成long进行计算，
         *连续加两次basis值，将结果放入LongBinaryOperator中进行计算返回结果
         * @Param
         */
        @Test
        public void testReduceEntriesToLong()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            System.out.println( map.reduceEntriesToLong(3,(entry)->Long.parseLong(entry.getValue()),2,((left, right) ->left+right )));
        }
        /**
         *并行执行，ToIntBiFunction将key和val转成double进行计算，
         * 连续加两次basis值，将结果放入IntBinaryOperator中进行计算返回结果
         * @Param
         */
        @Test
        public void testReduceEntriesToInt()throws Exception{
            ConcurrentHashMap<String,String> map=new ConcurrentHashMap();
            map.put("1","2");
            map.put("3","4");
            map.put("5","6");
            map.put("7","8");
            map.put("9","10");
            System.out.println( map.reduceEntriesToInt(3,(entry)->Integer.parseInt(entry.getValue()),2,((left, right) ->left+right )));
        }
 
}
```

上述代码通过单元测试把所有Public API方法跑了一遍，大致了解了底层实现.

一些理解

- 从上可以看出JDK1.8版本的ConcurrentHashMap的数据结构已经接近HashMap，相对而言，ConcurrentHashMap只是增加了同步的操作来控制并发，从JDK1.7版本的ReentrantLock+Segment+HashEntry，到JDK1.8版本中synchronized+CAS+HashEntry+红黑树,相对而言，总结如下思考

1. JDK1.8的实现降低锁的粒度，JDK1.7版本锁的粒度是基于Segment的，包含多个HashEntry，而JDK1.8锁的粒度就是HashEntry（首节点）
2. JDK1.8版本的数据结构变得更加简单，使得操作也更加清晰流畅，因为已经使用synchronized来进行同步，所以不需要分段锁的概念，也就不需要Segment这种数据结构了，由于粒度的降低，实现的复杂度也增加了
3. JDK1.8使用红黑树来优化链表，基于长度很长的链表的遍历是一个很漫长的过程，而红黑树的遍历效率是很快的，代替一定阈值的链表，这样形成一个最佳拍档；
4. JDK1.8为什么使用内置锁synchronized来代替重入锁ReentrantLock?

- 减少内存开销 假设使用可重入锁来获得同步支持，那么每个节点都需要通过继承AQS来获得同步支持。但并不是每个节点都需要获得同步支持的，只有链表的头节点（红黑树的根节点）需要同步，这无疑带来了巨大内存浪费。
- 获得JVM的支持 可重入锁毕竟是API这个级别的，后续的性能优化空间很小。  synchronized则是JVM直接支持的，JVM能够在运行时作出相应的优化措施：锁粗化、锁消除、锁自旋等等。这就使得synchronized能够随着JDK版本的升级而不改动代码的前提下获得性能上的提升。

## 七、三者的异同

说下这三个数据结构的异同 HashTable、HashMap、ConcurrentHashMap：

### 7.1 HashTable

- 底层数组+链表实现，无论key还是value都不能为null，线程安全，
- 实现线程安全的方式是在修改数据时锁住整个HashTable，效率低，ConcurrentHashMap做了相关优化
- 初始size为11，扩容：newsize = olesize*2+1
- Hashtable在求hash值对应的位置索引时，用取模运算，而HashMap在求位置索引时，则用与运算，且这里一般先用hash  & 0x7FFFFFFF后，再对length取模，&  0x7FFFFFFF的目的是为了将负的hash值转化为正值，因为hash值有可能为负数，而&  0x7FFFFFFF后，只有符号外改变，而后面的位都不变。
- Hashtable计算hash值，直接用key的hashCode()，而HashMap重新计算了key的hash值，计算index的方法：index = (hash & 0x7FFFFFFF) % tab.length

### 7.2 HashMap

- 底层数组+链表实现，可以存储null键和null值，线程不安全
- 初始size为16，扩容：newsize = oldsize*2，size一定为2的n次幂
- 扩容针对整个Map，每次扩容时，原来数组中的元素依次重新计算存放位置，并重新插入
- 插入元素后才判断该不该扩容，有可能无效扩容（插入后如果扩容，如果没有再次插入，就会产生无效扩容）
- 当Map中元素总数超过Entry数组的75%，触发扩容操作，为了减少链表长度，元素分配更均匀
- 计算index方法：index = hash & (tab.length – 1)
   HashMap的初始值还要考虑加载因子 load factor:
- **哈希冲突**：若干Key的哈希值按数组大小取模后，如果落在同一个数组下标上，将组成一条Entry链，对Key的查找需要遍历Entry链上的每个元素执行equals()比较。
- **加载因子**：为了降低哈希冲突的概率，默认当HashMap中的键值对达到数组大小的75%时，即会触发扩容。因此，如果预估容量是100，即需要设定100/0.75＝134的数组大小。
- **空间换时间**：如果希望加快Key查找的时间，还可以进一步降低加载因子，加大初始大小，以降低哈希冲突的概率。
   HashMap和Hashtable都是用hash算法来决定其元素的存储，因此HashMap和Hashtable的hash表包含如下属性：
- 容量（capacity）：hash表中桶的数量
- 初始化容量（initial capacity）：创建hash表时桶的数量，HashMap允许在构造器中指定初始化容量
- 尺寸（size）：当前hash表中记录的数量
- 负载因子（load factor）：负载因子等于“size/capacity”。负载因子为0，表示空的hash表，0.5表示半满的散列表，依此类推。轻负载的散列表具有冲突少、适宜插入与查询的特点（但是使用Iterator迭代元素时比较慢）
   　除此之外，hash表里还有一个“负载极限”，“负载极限”是一个0～1的数值，“负载极限”决定了hash表的最大填满程度。当hash表中的负载因子达到指定的“负载极限”时，hash表会自动成倍地增加容量（桶的数量），并将原有的对象重新分配，放入新的桶内，这称为rehashing。

HashMap和Hashtable的构造器允许指定一个负载极限，HashMap和Hashtable默认的“负载极限”为0.75，这表明当该hash表的3/4已经被填满时，hash表会发生rehashing。

“负载极限”的默认值（0.75）是时间和空间成本上的一种折中：

- 较高的“负载极限”可以降低hash表所占用的内存空间，但会增加查询数据的时间开销，而查询是最频繁的操作（HashMap的get()与put()方法都要用到查询）
- 较低的“负载极限”会提高查询数据的性能，但会增加hash表所占用的内存开销
   程序猿可以根据实际情况来调整“负载极限”值。

### 7.3 ConcurrentHashMap

- 底层采用分段的数组+链表实现，线程安全
- 通过把整个Map分为N个Segment，可以提供相同的线程安全，但是效率提升N倍，默认提升16倍。(读操作不加锁，由于HashEntry的value变量是 volatile的，也能保证读取到最新的值。)
- Hashtable的synchronized是针对整张Hash表的，即每次锁住整张表让线程独占，ConcurrentHashMap允许多个修改操作并发进行，其关键在于使用了锁分离技术
- 有些方法需要跨段，比如size()和containsValue()，它们可能需要锁定整个表而而不仅仅是某个段，这需要按顺序锁定所有段，操作完毕后，又按顺序释放所有段的锁
- 扩容：段内扩容（段内元素超过该段对应Entry数组长度的75%触发扩容，不会对整个Map进行扩容），插入前检测需不需要扩容，有效避免无效扩容
- Hashtable和HashMap都实现了Map接口，但是Hashtable的实现是基于Dictionary抽象类的。
- Java5提供了ConcurrentHashMap，它是HashTable的替代，比HashTable的扩展性更好。

## 八、查阅资料:

1. [JDK1.8在线API](https://www.matools.com/api/java8)
2. [Hashtable源码解析（JDK1.8）](https://www.cnblogs.com/wupeixuan/p/8620197.html)
3. [HashMap源码解析（JDK1.8）](https://www.cnblogs.com/wupeixuan/p/8620173.html)
4. [HashMap和ConcurrentHashMap](https://study.bestzuo.cn/#/HashMap和ConcurrentHashMap)
5. [并发编程——ConcurrentHashMap#transfer() 扩容逐行分析](https://www.jianshu.com/p/2829fe36a8dd)
6. [ConcurrentHashMap底层实现原理(JDK1.7 & 1.8)](https://www.jianshu.com/p/865c813f2726)