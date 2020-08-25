[TOC]

# 1、pom.xml
```xml
<!-- Dom4j组件 -->
<dependency>
   <groupId>dom4j</groupId>
   <artifactId>dom4j</artifactId>
<version>1.6.1</version>
</dependency>
<dependency>
   <groupId>jaxen</groupId>
   <artifactId>jaxen</artifactId>
<version>1.1.6</version>
</dependency>
```

# 2、XmlUtil
```java
import org.dom4j.Document;
import org.dom4j.DocumentHelper;
import org.dom4j.Element;
import org.dom4j.io.OutputFormat;
import org.dom4j.io.SAXReader;
import org.dom4j.io.XMLWriter;
import java.io.File;
import java.io.FileOutputStream;
import java.util.Iterator;
import java.util.List;

public class XmlUtil {
    /**
     * 创建文档
     */
    public static Document getDocument (String filename) {
        File xmlFile = new File(filename) ;
        Document document = null;
        if (xmlFile.exists()){
            try{
                SAXReader saxReader = new SAXReader();
                document = saxReader.read(xmlFile);
            } catch (Exception e){
                e.printStackTrace();
            }
        }
        return document ;
    }

    /**
     * 遍历根节点
     */
    public static Document iteratorNode (String filename) {
        Document document = getDocument(filename) ;
        if (document != null) {
            Element root = document.getRootElement();
            Iterator iterator = root.elementIterator() ;
            while (iterator.hasNext()) {
                Element element = (Element) iterator.next();
                System.out.println(element.getName());
            }
        }
        return document ;
    }

    /**
     * 创建XML文档
     */
    public static void createXML (String filePath) throws Exception {
        // 创建 Document 对象
        Document document = DocumentHelper.createDocument();
        // 创建节点,首个节点默认为根节点
        Element rootElement = document.addElement("project");
        Element parentElement = rootElement.addElement("parent");
        parentElement.addComment("版本描述") ;
        Element groupIdElement = parentElement.addElement("groupId") ;
        Element artifactIdElement = parentElement.addElement("artifactId") ;
        Element versionElement = parentElement.addElement("version") ;
        groupIdElement.setText("SpringBoot2");
        artifactIdElement.setText("spring-boot-starters");
        versionElement.setText("2.1.3.RELEASE");
        //设置输出编码
        OutputFormat format = OutputFormat.createPrettyPrint();
        File xmlFile = new File(filePath);
        format.setEncoding("UTF-8");
        XMLWriter writer = new XMLWriter(new FileOutputStream(xmlFile),format);
        writer.write(document);
        writer.close();
    }

    /**
     * 更新节点
     */
    public static void updateXML (String filePath) throws Exception {
        Document document = getDocument (filePath) ;
        if (document != null){
            // 修改指定节点
            List elementList = document.selectNodes("/project/parent/groupId");
            Iterator iterator = elementList.iterator() ;
            while (iterator.hasNext()){
                Element element = (Element) iterator.next() ;
                element.setText("spring-boot-2");
            }
            //设置输出编码
            OutputFormat format = OutputFormat.createPrettyPrint();
            File xmlFile = new File(filePath);
            format.setEncoding("UTF-8");
            XMLWriter writer = new XMLWriter(new FileOutputStream(xmlFile),format);
            writer.write(document);
            writer.close();
        }
    }

    /**
     * 删除节点
     */
    public static void removeElement (String filePath) throws Exception {
        Document document = getDocument (filePath) ;
        if (document != null){
            // 修改指定节点
            List elementList = document.selectNodes("/project/parent");
            Iterator iterator = elementList.iterator() ;
            while (iterator.hasNext()){
                Element parentElement = (Element) iterator.next() ;
                Iterator parentIterator = parentElement.elementIterator() ;
                while (parentIterator.hasNext()){
                    Element childElement = (Element)parentIterator.next() ;
                    if (childElement.getName().equals("version")) {
                        parentElement.remove(childElement) ;
                    }
                }
            }
            //设置输出编码
            OutputFormat format = OutputFormat.createPrettyPrint();
            File xmlFile = new File(filePath);
            format.setEncoding("UTF-8");
            XMLWriter writer = new XMLWriter(new FileOutputStream(xmlFile),format);
            writer.write(document);
            writer.close();
        }
    }

    public static void main(String[] args) throws Exception {
        String filePath = "F:\\file-type\\project-cf.xml" ;
        // 1、创建文档
        Document document = getDocument(filePath) ;
        System.out.println(document.getRootElement().getName());
        // 2、根节点遍历
        iteratorNode(filePath);
        // 3、创建XML文件
        String newFile = "F:\\file-type\\project-cf-new.xml" ;
        createXML(newFile) ;
        // 4、更新XML文件
        updateXML(newFile) ;
        // 5、删除节点
        removeElement(newFile) ;
    }
}
```