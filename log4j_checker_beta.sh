#!/bin/bash

# source https://github.com/rubo77/log4j_checker_beta
# modified by Thomas Dankert <thomas.dankert@stihl.de>

# needs locate to be installed, be sure to be up-to-date with
# sudo updatedb

# optionally scans the entire disk (using ionice)

RED="\033[0;31m"; GREEN="\033[32m"; YELLOW="\033[1;33m"; ENDCOLOR="\033[0m"
WARNING="[WARNING]"${ENDCOLOR}

# check using locate
echo -e ${YELLOW}"### locate files containing log4j ..."${ENDCOLOR1}
OUTPUT="$(locate -e log4j|grep -v log4js|grep -v log4j_checker_beta)"
if [ "$OUTPUT" ]; then
  echo -e ${RED}"[WARNING] maybe vulnerable, those files contain the name:"${ENDCOLOR}
  echo "$OUTPUT"
fi;

# check using yum (if installed)
if [ "$(command -v yum)" ]; then
  echo -e ${YELLOW}"### check installed yum packages ..."${ENDCOLOR1}
  OUTPUT="$(yum list installed|grep log4j|grep -v log4js)"
  if [ "$OUTPUT" ]; then
    echo -e ${RED}"[WARNING] maybe vulnerable, yum installed packages:"${ENDCOLOR}
    echo "$OUTPUT"
  fi;
fi;

# check using dpkg (if installed)
if [ "$(command -v dpkg)" ]; then
  echo -e ${YELLOW}"### check installed dpkg packages ..."${ENDCOLOR1}
  OUTPUT="$(dpkg -l|grep log4j|grep -v log4js)"
  if [ "$OUTPUT" ]; then
    echo -e ${RED}"[WARNING] maybe vulnerable, dpkg installed packages:"${ENDCOLOR}
    echo "$OUTPUT"
  fi;
fi;

# check for java
echo -e ${YELLOW}"### check if Java is installed ..."${ENDCOLOR1}
JAVA="$(command -v java)"
if [ "$JAVA" ]; then
  echo -e ${RED}"[WARNING] Java is installed"${ENDCOLOR}
  echo "Java applications often bundle their libraries inside jar/war/ear files, so there still could be log4j in such applications.";
else
  echo -e ${GREEN}"[OK]"${ENDCOLOR}" Java is not installed"
fi;

# ask for confirmation for filesystem scan
echo 
read -p "Do you want to scan the filesystem for log4j-core-*.jar and JdniLookup.class? [Y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  # perform best-effort (lowest priority) find call for log4j-core jar
  OUTPUT="$(ionice -c 2 -n 7 find / -name log4j-core-*.jar 2>/dev/null)"
  if [ "$OUTPUT" ]; then
    echo -e ${RED}"[WARNING] maybe vulnerable, those files contain the log4j jar:"${ENDCOLOR}
    echo "$OUTPUT"
  fi;

  # perform best-effort find call for all jars, and search for JndiLookup.class inside
  OUTPUT="$(ionice -c 2 -n 7 find / -name "*.jar" -exec sh -c 'unzip -l {}|grep -H --label {} JndiLookup.class' \; 2>/dev/null)"
    if [ "$OUTPUT" ]; then
    echo -e ${RED}"[WARNING] maybe vulnerable, those files contain the JndiLookup.class:"${ENDCOLOR}
    echo "$OUTPUT"
  fi;
fi;

echo -e ${YELLOW}"_________________________________________________"${ENDCOLOR}
echo "If you see no uncommented output above this line, you are safe. Otherwise check the listed files and packages.";
if [ "$JAVA" == "" ]; then
  echo "Some apps bundle the vulnerable library in their own compiled package, so 'java' might not be installed but one such apps could still be vulnerable."
fi
echo
echo "Note, this is not 100% proof you are not vulnerable, but a strong hint!"
