- [SonarQube中Maven项目的测试覆盖率报告](https://mp.weixin.qq.com/s/aXGKZ7oHeGNpge2s3RukWw)

SonarQube将所有测试报告合并为一份涵盖整体的测试报告。因此，如果您在Maven项目中将单元测试（由Maven Surefire Plugin运行）和集成测试（由Maven Failsafe Plugin运行）分开进行测试，那么如何配置 JaCoCo Maven Plugin。

在以下各节中，提出了满足以下条件的解决方案：

- 使用Maven作为构建工具。
- 该项目可以是多模块项目（微服务）。
- 单元测试和集成测试是每个模块的一部分。
- 测试覆盖率是通过 JaCoCo Maven Plugin来衡量的。

下面显示了Maven项目结构，用于单元测试和集成测试的分离。然后显示了Maven项目配置，其中包含单独的单元测试运行和集成测试运行。之后，我们来看看Maven项目配置以生成涵盖单元测试和集成测试的测试报告。最后，SonarQube的仪表板中显示了SonarQube的配置，用于测试报告的可视化。

#### Maven项目结构

首先，我们看一下单个模块项目的默认Maven项目结构。

```
my-app
├── pom.xml
├── src
│   ├── main
│   │   └── java
│   └── test
│       └── java
```

目录src/main/java包含生产项目的源代码，目录src/test/java包含测试源代码。我们可以将单元测试和集成测试放到这个目录中。但是我们需要将这两种类型的测试放在单独的目录中。因此，我们添加了一个名为src/it/java的新目录。然后将单元测试放在src/test java目录中，并将集成测试放在src/it/java目录中，因此新的项目结构如下图所示。

```
my-app
├── pom.xml
├── src
│   ├── it
│   │   └── java
│   ├── main
│   │   └── java
│   └── test
│       └── java
```

#### 单元和集成测试运行

幸运的是，单元测试运行配置是Maven默认项目配置的一部分。如果满足以下条件，Maven将自动运行这些测试：

- 目录src/test/java存在测试用例
- 测试类名称以Test开头或以Test或TestCase结尾。

Maven在Maven的构建生命周期阶段中的测试期间来运行这些测试。

集成测试运行配置必须手动完成。它存在可以提供帮助的Maven插件。我们希望满足以下条件：

- 集成测试存储在目录src/it/java
- 集成测试类名称要么以IT开头，要么以IT或ITCase结尾，
- 集成测试在Maven的构建生命周期阶段进行 集成测试。

首先，Maven必须知道它必须在其测试类路径中包含目录src/it/java。在这里，Build Helper Maven插件可以提供帮助。它将目录src/it/java添加到测试类路径。

```
<plugin>
    <groupId>org.codehaus.mojo</groupId>
    <artifactId>build-helper-maven-plugin</artifactId>
    <version>3.1.0</version>
    <executions>
        <execution>
            <goals>
                <goal>add-test-source</goal>
                <goal>add-test-resource</goal>
            </goals>
            <configuration>
                <sources>
                    <source>src/it/java</source>
                </sources>
                <resources>
                    <resource>
                        <directory>src/it/resources</directory>
                    </resource>
                </resources>
            </configuration>
        </execution>
    </executions>
</plugin>
```

上面的代码段必须插入到 项目根pom中的<project> <build> <plugins>部分。

Maven的构建生命周期包含一个称为集成测试的阶段。在此阶段，我们要运行集成测试。幸运的是，当在POM中设置Maven故障安全插件的目标集成测试时，它会自动绑定到此阶段。如果您希望在集成测试失败时构建失败，那么还必须将目标验证添加到POM中

```
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-failsafe-plugin</artifactId>
    <version>3.0.0-M4</version>
    <configuration>
        <encoding>${project.build.sourceEncoding}</encoding>
    </configuration>
    <executions>
        <execution>
            <goals>
                <goal>integration-test</goal>
                <goal>verify</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

同样，上述代码段也必须插入到 项目根pom中的<project> <build> <plugins>部分。然后，当Maven故障保护插件的类名称以IT开头或以IT 或ITCase结尾时，它们会自动运行集成测试。

#### 测试报告生成

我们想使用JaCoCo Maven插件生成测试报告。它应该为单元测试和集成测试生成测试报告。因此，该插件必须要准备两个单独的代理。然后他们在测试运行期间生成报告。Maven的构建生命周期包含自己的阶段，可以在测试阶段之前进行准备（测试和集成测试）。测试阶段的准备阶段称为过程测试类，集成测试阶段的准备阶段称为pre-integration-test。当JaCoCo的目标prepare-agent和在POM中设置了prepare-agent-integration。但这还不够。JaCoCo还必须创建一个报告，以便SonarQube可以读取报告以进行可视化。因此，我们必须在POM中添加目标报告和报告集成：

```
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.5</version>
    <executions>    
        <execution>
            <goals>  
                <goal>prepare-agent</goal>
                <goal>prepare-agent-integration</goal>
                <goal>report</goal>
                <goal>report-integration</goal>
            </goals>  
        </execution>
    </executions>  
</plugin>
```

同样，它是*<project> <build> <plugins>*部分的一部分。

现在，我们可以运行目标*mvn验证，*并且我们的项目已构建为包含单元和集成测试，并生成两个测试报告。

#### SonarQube测试报告可视化

现在，我们想在SonarQube中可视化我们的测试报告。因此，在成功构建之后，我们必须在我们的项目中运行Sonar Maven 3插件（命令*mvn sonar:sonar*）。因此，Sonar Maven插件知道将报告上传到哪里，我们必须在*〜/ .m2 / setting.xml中*配置SonarQube实例*：*

```
<profile>
  <id>sonar</id>
  <activation>
    <activeByDefault>true</activeByDefault>
  </activation>
  <properties>
    <!-- Optional URL to server. Default value is http://localhost:9000 -->
    <sonar.host.url>http://localhost:9000</sonar.host.url>
  </properties>
</profile>
```

在SonarQube仪表板中打开项目时，我们会看到总体测试覆盖率报告。

#### 附：参考pom.xml

```
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.github.sparsick.sonarqube</groupId>
    <artifactId>sonarqube-test-report-with-maven</artifactId>
    <version>1.0.0-SNAPSHOT</version>

    <name>sonarqube-test-report-with-maven</name>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <java.version>11</java.version>
    </properties>
  
    <build>
        <pluginManagement>
            <plugins>
                <plugin>
                    <groupId>org.sonarsource.scanner.maven</groupId>
                    <artifactId>sonar-maven-plugin</artifactId>
                    <version>3.7.0.1746</version>
                </plugin>
            </plugins>
        </pluginManagement>
        
        <plugins>
            <plugin>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.8.1</version>
                <configuration>
                    <source>${java.version}</source>
                    <target>${java.version}</target>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.codehaus.mojo</groupId>
                <artifactId>build-helper-maven-plugin</artifactId>
                <version>3.1.0</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>add-test-source</goal>
                            <goal>add-test-resource</goal>
                        </goals>
                        <configuration>
                            <sources>
                                <source>src/it/java</source>
                            </sources>
                            <resources>
                                <resource>
                                    <directory>src/it/resources</directory>
                                </resource>
                            </resources>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>3.0.0-M4</version>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-failsafe-plugin</artifactId>
                <version>3.0.0-M4</version>
                <configuration>
                    <encoding>${project.build.sourceEncoding}</encoding>
                </configuration>
                <executions>
                    <execution>
                        <goals>
                            <goal>integration-test</goal>
                            <goal>verify</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
            <plugin>
                <groupId>org.jacoco</groupId>
                <artifactId>jacoco-maven-plugin</artifactId>
                <version>0.8.5</version>
                <executions>    
                    <execution>
                        <goals>  
                            <goal>prepare-agent</goal>
                            <goal>prepare-agent-integration</goal>
                            <goal>report</goal>
                            <goal>report-integration</goal>
                        </goals>  
                    </execution>
                </executions>  
            </plugin>
        </plugins>
    </build>
  

    <dependencies>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter</artifactId>
            <version>5.6.2</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>
```