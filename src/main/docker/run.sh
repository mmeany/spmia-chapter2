#!/bin/sh


echo "********************************************************"
echo "Starting License Server with Configuration Service :  $CONFIGSERVER_URI";
echo "********************************************************"
java -jar /usr/local/licensingservice/@project.build.finalName@.jar
