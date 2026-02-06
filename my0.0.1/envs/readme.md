# 当前环境说明

```note
一些 即要环境变量 又要路径的配置：
    变量：
        PYTHON_HOME
    路径：
        python
```

1. home 是 宿主机环境
   1. 宿主机目前只需要 python(静态)环境，能跑简单脚本即可；
   2. python 环境来自之前从虚拟机的conda中迁移的home;
   3. 不需要 pip, 不需要任何操作环境的脚本；
   4. 缺环境就从虚拟机中迁移；
   5. 保证宿主机的“绝对纯净”；
<br><br>
   
2. venv 是 虚拟机1号和虚拟机2号
   1. 做开发 需要环境：python node mysql;
   2. python 环境来自直接从官网下载的 python313
   3. node 环境是基于nvm构建的动态环境；
   4. mysql 环境是免安装的初始数据库；
<br><br>

3. work 是 公司电脑
   1. 做开发所需的环境：python node mysql redis git
   2. python 是基于 conda 的动态环境；
   3. node 是基于 nvm 的动态环境；
   4. mysql 和 redis 是静态的路径和变量；
   5. git 是顺手补充的；
<br><br>

4. hf 是 华峰电脑
   1. 仿 work 的环境，搭建日常开发的环境；
   2. ...

5. work2 是公司电脑 数据库备份机
   1. ...
