
# What did I change:
Below is a list of the changes I have made:

* src/main/docker/DockerFile
 * Switched to a fixed version of Alpine Linux
 * Changed the update semantics to match above
 * Replaced the hard-coded JAR filename with a token that Maven will replace
 * Not sure why netcat is baked into the image, but there are a lot of chapters still to come so I left it there and updated package name to the one used by Alpine Linux.

 ```Dockerfile
FROM openjdk:8-jdk-alpine
RUN apk update && apk upgrade && apk add netcat-openbsd
 ```

* src/main/docker/run.sh
 * Replaced the hard-coded JAR filename with a token that Maven will replace

 ```bash
java -jar /usr/local/licensingservice/@project.build.finalName@.jar
 ```

* pom.xml
 * Added maven-resources-plugin that copies DockerFile and run.sh into target directory at build time and replaces tokens (JAR filename)
 * Modified the docker-maven-plugin entry to use a later version
 * Modified the docker-maven-plugin to locate the filtered DockerFile and run.sh file from target folder

 ```xml
            <plugin>
                <artifactId>maven-resources-plugin</artifactId>
                <executions>
                    <execution>
                        <id>copy-resources</id>
                        <!-- here the phase you need -->
                        <phase>validate</phase>
                        <goals>
                            <goal>copy-resources</goal>
                        </goals>
                        <configuration>
                            <outputDirectory>${basedir}/target/dockerfile</outputDirectory>
                            <resources>
                                <resource>
                                    <directory>src/main/docker</directory>
                                    <filtering>true</filtering>
                                </resource>
                            </resources>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
            <plugin>
                <groupId>com.spotify</groupId>
                <artifactId>docker-maven-plugin</artifactId>
                <version>0.4.10</version>
                <configuration>
                    <imageName>${docker.image.name}:${docker.image.tag}</imageName>
                    <dockerDirectory>${basedir}/target/dockerfile</dockerDirectory>
                    <resources>
                        <resource>
                            <targetPath>/</targetPath>
                            <directory>${project.build.directory}</directory>
                            <include>${project.build.finalName}.jar</include>
                        </resource>
                    </resources>
                </configuration>
            </plugin>
 ```

# Why did I change it
Details are explained below, however what drove me to this is bad experiences in a production environment attributed to a lack of rigour. The issues encountered could happen on any project, but are easily avoidable and avoidance technique should be explained from the outset. 

## Switch to Alpine Linux version of JDK and fix the version of the base Docker image
Alpine Linux is an optimised image and is lots smaller than a Ubuntu equivalent. The less we install, the less we have to worry about.

Fixed Docker image to a specific version vs _latest_. Have been bitten by use of _latest_ in a production environment and suffered the hurt! A modified image was uploaded to DockerHub, it was incompatible with the previous version (easy to do, imagine a deprecated class that your code relies on being removed from a future release of the JDK). The next Docker image launched breaks the application. Versions are there for a reason, I always use them. I am working with clusters that scale up and down by time of day as well as by load triggers, using _latest_ is not an option.

Both of the above can be argued against by saying _development environment_ or similar, but we should always strive to adhere to best practices.

### Changed update semantics
No choice really, Alpine Linux uses _apk_ while Ubuntu uses _apt_, I had to change this as a result of choice above.

As I mentioned, I am not sure why _netcat_ is installed other than it is a really useful thing to have around. I would have removed it, but could see it may be brought into play later as the book is still a work in progress and also the package name changes as a result of switching to Alpine Linux. Best to present the solution than remove the utility.

## Replaced the hard coded JAR filename
This is a pet hate of mine. Why hard code something that is going to change over time - that's asking for a disaster and again a disaster I have been bitten by in a production environment.

Maven has a release plugin that will change the version number in the POM and all children. More recently there is an excellent GitFlow Maven plugin that also handles this. These can be used in a CI workflow to automate the change of the artifact version. They will not change the hard-coded version in the DockerFile or run.sh and this will result in a Docker image being built that does not contain the version of the software that was expected.

Again there are arguments along the lines of _the production CI will do x, y, z and this is development_ to which I repeat the mantra: we should always strive to adhere to best practices.

