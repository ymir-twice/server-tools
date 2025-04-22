#!/bin/bash

# 定义要添加的条目
entry1="140.82.113.4 github.com"
entry2="140.82.114.4 github.com"

# 检查并添加第一条记录
if ! grep -Fxq "$entry1" /etc/hosts; then
    echo "" >> /etc/hosts
    echo "# connect to github" >> /etc/hosts
    echo "$entry1" >> /etc/hosts
    echo "已添加：$entry1"
else
    echo "已存在：$entry1"
fi

# 检查并添加第二条记录
if ! grep -Fxq "$entry2" /etc/hosts; then
    echo "# connect to github" >> /etc/hosts
    echo "$entry2" >> /etc/hosts
    echo "已添加：$entry2"
else
    echo "已存在：$entry2"
fi

