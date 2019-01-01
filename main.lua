require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "layout"
import "http"
--import "Http"
import "cjson"
import "java.io.File"
--activity.setTitle('AndroLua+')
activity.setTheme(android.R.style.Theme_Material)
activity.setContentView(loadlayout(layout))

item = {
  LinearLayout;
  layout_width="fill";
  layout_height="fill";
  gravity="center";
  {
    LinearLayout;
    gravity="left";
    layout_height="180px";
    orientation="horizontal";
    layout_width="-1";
    {
      ImageView;
      id="img";
      layout_gravity="center";
    };
    {
      TextView;
      textSize="50px";
      layout_marginLeft="20px";
      text="标题内容";
      layout_gravity="center";
      id="text";
      ellipsize="end";
    };
  };
};


urls = {
  search = "https://v1.hitokoto.cn/nm/search/";
  lrc = "https://v1.hitokoto.cn/nm/lyric/";
  download = "https://v1.hitokoto.cn/nm/url/";
};

--path = '/sdcard/'
path = io.open(activity.getLuaDir() .. '/path.txt', 'r'):read("*a")

function translate(data, list)
  res = ''
  start = true
  for i, v in ipairs(data) do
    if start ~= true then
      res = res .. '&'
    end
    res = res .. list[i] .. '=' .. tostring(data[i])
    start = false
  end
  return res
end

function wget(target, name, data, list)
  body, cookie, code, headers = http.get(
  target .. name .. '?' .. translate(data, list))
  return body
  --print(target .. name .. '?' .. translate(data, list))
end

function search(name, limit, offset)
  songs = cjson.decode(wget(urls.search, name, {limit, offset}, {"limit", "offset"})).result.songs
  --print(songs[1].id)
  --print(result.result((.songs[0].name)
  --print(result.code)
  return songs
end

function download(id)
  u = cjson.decode(wget(urls.download, ''..id, {}, {})).data[1].url
  return u
end

function init()
  data = {}
  adp = LuaAdapter(activity, data, item)
  list.Adapter = adp
  list.onItemClick = function(l,v,p,i)
    --print(l, v, p, i)
    local str = v.Tag.text.Text
    if string.find(str, "加载更多") ~= nil then
      offset = i - 1
      search_fun(l, offset)
      return
    end
    id = str:match("ID:(.+)")
    filename = str:match("(.-)ID:") .. '.mp3'
    --print(id, filename)
    url = download(id)
    --try_lisent(url)
    ori_filename = filename
    estr = {"/", "?", "\\", "\"", "\'"}
    for i, v in ipairs(estr) do 
      filename = (string.gsub(filename, v, '_'))
    end
    sys_download(url, filename)
    print("开始下载：" .. ori_filename)
  end
  list.onItemLongClick = function(l,v,p,i)
    --print(l, v, p, i)
    local str = v.Tag.text.Text
    if string.find(str, "加载更多") ~= nil then
      return
    end
    id = str:match("ID:(.+)")
    filename = str:match("(.-) ID:") .. '.mp3'
    --print(id, filename)
    url = download(id)
    try_lisent(url)
    print("试听：" .. filename)
  end
end

function main()
  --io.open("/sdcard/NetEaseDownloader", 'w'):close()
  File("/sdcard/NetEaseDownloader").mkdir()
  init()
  search_fun = function(obj, offset)
    name = tostring(text.getText())
    if name == '' then print("请输入") return end
    if offset == nil then offset = 0 end
    offset = tonumber(offset)
    --print(offset)
    songs = search(name, 30, offset)

    for i, v in ipairs(songs) do
      str = ''
      local start = true
      for j, k in ipairs(v.artists) do
        if start ~= true then str = str .. '、' end
        start = false
        str = str .. k.name
      end
      adp.add{img="icon.png", text=str .. ' - ' .. v.name .. " ID:" .. tostring(v.id):match('(.+).0')}
    end
    adp.add{img="down.png", text="加载更多"}
  end
  text.setOnEditorActionListener(function(obj)
    init()
    search_fun(obj, 0)
  end )
  btn.onClick = function(obj)
    init()
    search_fun(obj, 0)
  end
end

function onCreateOptionsMenu(menu)
  menu.add("设置下载目录")
  menu.add("使用方法")
  menu.add("关于")
end

function choose_file()
  import "android.content.Intent"
  import "android.net.Uri"
  import "java.net.URLDecoder"
  import "java.io.File"
  intent = Intent(Intent.ACTION_GET_CONTENT)
  intent.setType("*/*");
  intent.addCategory(Intent.CATEGORY_OPENABLE)
  activity.startActivityForResult(intent,1);
  function onActivityResult(requestCode,resultCode,data)
    if resultCode == Activity.RESULT_OK then
      local str = data.getData().toString()
      local decodeStr = URLDecoder.decode(str, "UTF-8")
      print(decodeStr)
      --print(data.getData())
      return decodeStr
    end
  end
end

function onOptionsItemSelected(item)
  str = item.Title
  if str == "设置下载目录" then
    --choose_file()
    activity.newActivity('select_dir', {path})
  end
  if str == "使用方法" then
    AlertDialog.Builder(activity)
    .setMessage(
[[点击歌曲下载，长按歌曲试听；
在右上角三个点设置下载目录。]])
    .setNegativeButton("了解", nil)
    .show()
  end
  if str == "关于" then
    AlertDialog.Builder(activity)
    .setMessage(
[[本应用经@LanceLiang2018开发。
由于开发者很懒所以不想写数相逢。
但是还是写了。

工具列表：
IDE: AndroLua+
API: hitokoto.cn

代码/反馈/提交BUG：
github: @LanceLiang2018
QQ: 1352040930
Email: LanceLiang2018@163.com
]])
    .setNegativeButton("确定", nil)
    .show()
  end
end

function onResult(name, data)
  if name == 'select_dir' then
    if data == "Failed" then return end
    path = data
    print("下载目录设置为 " .. path)
    io.open(activity.getLuaDir() .. '/path.txt', 'w'):write(path):close()
  end
end

function sys_download(url, filename)
  --导入包
  import "android.content.Context"
  import "android.net.Uri"

  downloadManager=activity.getSystemService(Context.DOWNLOAD_SERVICE);
  url=Uri.parse(url);
  request=DownloadManager.Request(url);
  request.setAllowedNetworkTypes(DownloadManager.Request.NETWORK_MOBILE|DownloadManager.Request.NETWORK_WIFI);
  request.setDestinationInExternalPublicDir(path, filename);
  request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
  downloadManager.enqueue(request);
end

function try_lisent(url)
  import "android.content.Intent"
  import "android.net.Uri"
  --url="http://www.androlua.cn"
  viewIntent = Intent("android.intent.action.VIEW",Uri.parse(url))
  activity.startActivity(viewIntent)
end

参数=0
function onKeyDown(code,event) 
  if string.find(tostring(event),"KEYCODE_BACK") ~= nil then 
    if 参数+2 > tonumber(os.time()) then 
      activity.finish()
    else
      print("再按一次退出程序")
      参数=tonumber(os.time()) 
    end
    return true
  end
end
