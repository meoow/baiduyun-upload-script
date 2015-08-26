#BaiduYun Upload Script
**百度云上传脚本**

Upload files or direcotries form command line using shell script.
可以上传**文件**或**文件夹**到**百度云**的**shell脚本**

The goal of this script is to provide fast way to upload/backup files to baiduyun in linux/unix envronment when desktop is not available.(e.g. no X installed or using ssh)

##Preparation
First you need to retrieve the BDUSS from the cookie of your web browser in order "fool" baidu service that you have a login session, so you can connect to your baiduyun space without inputing your username and password everytime you want to upload files.  
首先，你需要获取浏览器的cookie里的BDUSS变量，以便“欺骗”百度服务让它以为你已经登录了，这样链接百毒云的时候就不用输入密码的。（而且因为登录帐号时需要符加码，这个在命令行不好实现）

The expiring time of BDUSS is very very long, you probably don't need to get update BDUSS ever again while using this script.
BDUSS的有效期非常长(7,8年)，所以只要提取BDUSS一次，几乎不需要再更新它。

###Getting BDUSS
Open your web browser, navigate to [www.baidu.com](http://www.baidu.com), and login with your baidu account.  
打开浏览器到www.baidu.com，登录帐号。

Due to the BDUSS has HttpOnly flag, you can not simply by using document.cookie from the web console of your browser to extract the content of BDUSS.  
因为BDUSS设置了HttpOnly标签，所以没法在浏览器的web conole里用javascript的docuemt.cookie直接查看。

Fortunately, both firefox's and chrome's web console have a network tab in their web console, which can capture the request and response connectivities while opening a web page. Select anyone of the requests, you will find BDUSS where in the cookie entry in the headers of that request.  
Firefox和Chrome浏览器的web console都支持在network标签下现实链接的请求，随便选取其中一个请求，在Headers标签下的Cookie项里，就能找到BDUSS。

Or a easier way:  install firebug.
或者用更简单的方法，安装Firebug扩展，可以直接在Cookie标签下找到BDUSS。

Copy the text and substitute for the content of BDUSS variable in the script.
把BDUSS的内容替换脚本里的同名变量。

##Requirement
bash    (needless to say)
curl    (for uploading files)
gzip    (if using compression)
find,sed,tr,xargs    (for uploading direcotries)


##Usage
```sh
# files are all uploaded to /upload folder
# 所有文件都上传到 /upload 下

# upload single file
# 上传单文件
./bdupload.sh filename

# compressing the file while uploading (saved with .gz suffix on server)
./bdupload.sh -z filename

# upload multiple files (pathes are not reserved)
# 上传多文件, 路径不保留，都传到/upload下
./bdupload.sh filename1 /path/to/filename2 filename3

# upload all files recursively in given direcotory
# 上传整个文件夹
./bdupload.sh folder

# compression is also supported (compress every single file, not the entire folder)
# 同样可以压缩（压缩每个文件，不是压缩整个文件夹。需要后者的可以先自行压缩）
./bdupload.sh -z folder
```