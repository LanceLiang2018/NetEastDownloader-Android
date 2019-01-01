require "import"
import "android.widget.*"
import "android.view.*"

path = ''
ori_path = ''

layout_select = {
  LinearLayout;
  orientation="vertical";
  {
    LinearLayout;
    layout_width="fill";
    {
      TextView;
      textSize="60px";
      text="Path:";
      id="text_path";
    };
  };
  {
    LinearLayout;
    gravity="center";
    layout_width="fill";
    {
      Button;
      text="上一级目录";
      id="btn_up";
    };
    {
      Button;
      text="选择此目录";
      id="btn_select";
    };
    {
      Button;
      text="取消";
      id="btn_exit";
    };
    {
      Button;
      text="根目录";
      id="btn_root";
    };
  };
  {
    LinearLayout;
    layout_height="fill";
    layout_width="fill";
    {
      ListView;
      id="list";
      layout_height="fill";
      layout_width="fill";
    };
  };
};

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


function set_path_text()
  text_path.setText("Path: " .. path)
end

function load_path()
  data = {}
  adp = LuaAdapter(activity, data, item)
  files = get_dir()
  --print(files[1])
  for i, v in ipairs(files) do
    name = tostring(v):match(path .. "(.+)")
    adp.add{text=name}
  end
  list.Adapter = adp
  list.onItemClick = function(l, v, p, i)
    str = tostring(v.Tag.text.Text)
    new_path = path .. str .. '/'
    --print(new_path)
    --activity.newActivity("select_dir", {new_path})
    path = new_path
    load_path()
    set_path_text()
  end
end

function main(data)
  path = tostring(data)
  --ori_path = path
  --print(ori_path)
  activity.setTheme(android.R.style.Theme_Material)
  activity.setTitle("选择下载目录")
  activity.setContentView(loadlayout(layout_select))

  load_path()
  set_path_text()
  btn_exit.onClick = function() activity.result{"Failed"} end
  btn_select.onClick = function() activity.result{path} end
  btn_up.onClick = function()
    if path == "/sdcard/" then return end
    new_path = path:match("(.+)/(.+)/") .. '/'
    path = new_path
    load_path()
    set_path_text()
    --print(new_path)
  end
  btn_root.onClick = function()
    path = '/sdcard/'
    load_path()
    set_path_text()
  end
end

function get_dir()
  import("java.io.File")
  li = luajava.astable(File(path).listFiles())
  res = {}
  res_last = 1
  for i, v in ipairs(li) do
    if File(tostring(v)).isDirectory() then
      res[res_last] = v
      res_last = res_last + 1
    end
  end
  table.sort(res, function(a,b)
    return (a.isDirectory()~=b.isDirectory() and a.isDirectory()) or ((a.isDirectory()==b.isDirectory()) and a.Name<b.Name)
  end)
  return res
end

function onResult(name, data)
  if name == 'select_dir' then
    activity.result{data}
  end
end

