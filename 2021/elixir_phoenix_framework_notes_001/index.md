# 初识 Phoenix Framework


Phoenix Framework 是一个 MVC web 框架，与 Ruby 的 Rails 和 Python 的 Django 类似，是整个 Elixir 社区的核心项目之一，推荐阅读 [Phoenix 文档](https://hexdocs.pm/phoenix/)


## 安装 {#安装}

我们使用 Phoenix (**v1.5.7**) 前，需要安装相关依赖与 mix

-   **Elixir** (&gt;= v1.6)
-   **Erlang** (&gt;= 20)
-   node.js [optional] (&gt;= 5.0.0)
-   Database [default=PostgreSQL]
-   **inotify-tools** [linux]

erlang 与 elixir 是运行时环境，数据库方面使用同为社区维护的 Ecto 来操作，Phoenix
使用 node.js 的原因是使用 webpack 编译静态资源，当然你可以只开发 API 不使用静态资源

Phoenix 提供了非常有用的实时重新加载功能，不过 Linux 用户需要安装 inotify-tools
才能使用


## 创建新项目 {#创建新项目}

我们使用 mix 来创建一个 Phoenix 项目

```shell
mix phx.new awesome
```

如果你没有 `phx.new` 这个命令，你需要先使用 mix 安装一下

```shell
mix archive.install hex phx_new
```

项目创建完成之后，我们可以看到终端中有提示，在 config/dev.exs 中配置程序并执行
`mix ecto.create`，配置文件中的 `Repo` 是数据库设置，`Endpoint` 配置的是网站相关的内容

这时 mix 会为我们创建一个 Phoenix 项目，默认的数据库是 PostgreSQL，如果应用不使用数据库则加上tag `--no-ecto` 即可，如果要使用其他数据库只需要加上 tag
`--database db`

webpack 用于管理静态资源，添加 tag `--no-webpack` 即可禁止使用 webpack，
`--no-html` 则会不生成HTML视图层，我们在完成 Rest API 程序时可以使用到这两个参数

配置完成之后，使用 `mix phx.server` 即可运行服务器了！

{{< figure src="/images/elixir-phoenix-framework-welcome.png" >}}

我们要写这个网站，首先要搞清楚目录关系，有关这个网站的所有的代码将在
`lib/awesome_web` 中实现，简单的做一个了解

-   `endpoint.ex` 是 **HTTP** 请求的入口
-   `router.ex` 是 **路由** 定义
-   `gettext.ex` 通过 Gettext 提供了国际化支持
-   `telemeter.ex` 是一个 Supervisor 相关的程序
-   `controllers` 是 **控制器** 实现，请求将通过路由分派到控制器上
-   `views` 是 **视图** 实现
-   `templates` 是 **模板** 实现

我们来看看路由情况，可以看到 `scope "/"` 这个空间下有一个 API，绑定的函数是
**PageController.index**，即浏览器发送请求 `GET /` 时将会执行绑定的函数。那看看控制器吧，就一句 `render(conn, "index.html")` 渲染页面，渲染的是哪里的 index.html，还得看视图层 `page_view.ex`，这会默认去找 `templates/page` 下的文件进行渲染，整个最简单的流程就是这样


### 仿照一个页面 {#仿照一个页面}

我们实现一个页面，通过请求 `GET /hello` 展示 **Hello, Phoenix!**

```elixir
# router.ex
get("/hello", HelloController, :index)

# controllers/hello_controller.ex
defmodule AwesomeWeb.HelloController do
  use AwesomeWeb, :controller
  def index(conn, _params), do: render(conn, "index.html")
end

# views/hello_view.ex
defmodule AwesomeWeb.HelloView do
  use AwesomeWeb, :view
end

# templates/hello/index.html.eex
<div class="phx-hero">
  <h2>Hello, Phoenix!</h2>
</div>
```

{{< figure src="/images/elixir-phoenix-framework-hello.png" >}}

效果还不错，不过太麻烦了，写页面岂不是要累死！好消息！Phoenix 提供了一些
`phx.gen.*` 的工具可以生成相关代码，减少重复的工作

我们先简单的生成一个 HTML 页面，然后按照提示添加路由并迁移数据库

```shell
mix phx.gen.html User User users username:string:unique email:string:unique password:string
```

之后访问 `/users` 就好，就完成了，简直暴力！！！最暴力的就是，后台开启的服务可以不需要关闭！！！你就能直接访问新加的页面了！！！

稍微说一说 `resources("/users", UserController)` 的作用，这其实是实现了一堆 CRUD
API，然后用一条命令路由所有 CRUD 方法，也可以将它等价替换为：

```elixir
get("/users", UserController, :index)
get("/users/:id/edit", UserController, :edit)
get("/users/new", UserController, :new)
get("/users/:id", UserController, :show)
post("/users", UserController, :create)
patch("/users/:id", UserController, :update)
put("/users/:id", UserController, :update)
delete("/users/:id", UserController, :delete)
```


### 限制字段 {#限制字段}

刚刚那个用户界面，我们只限制了所有字段必填，显然这种限制是不够的，我们应该清楚都需要哪些限制，如果添加这些限制，接下来我们以 username 为例

-   必填与唯一
-   英文字母、数字及下划线
-   长度 3 ~ 15
-   保留 `admin`, `administrator` 和 `root`

需求搞定了，我们知道这些需求第一个已经完成了，是 Phoenix 帮我们完成的，那看看源代码是怎么完成的吧。请打开 `lib/awesome/account/user.ex` 并查看源码，这是一个
Etco 所定义的模型，可以直接与数据库交互，而查文档的话也应该查 Ecto 的文档

```elixir
@doc false
def changeset(user, attrs) do
  user
  |> cast(attrs, [:username, :email, :password])
  |> validate_required([:username, :email, :password])
  |> unique_constraint(:username)
  |> unique_constraint(:email)
end
```

changeset/2 是 Ecto 的回调函数，一般对数据进行 **过滤**、**验证** 与 **约束** 操作，调用方式

```elixir
changeset = User.changeset(%User{}, %{username: "Example", email: "i@example.com"})
{:error, changeset} = Repo.insert(changeset)
changeset.errors #=> [password: {"can't be blank", []}]
```

OK，下来我们就开始仔细解读下这个函数，`validate_required` 是指明哪些字段必填，而 `unique_constraint` 则是约束字段唯一，那现在我们需要再添加一些代码来实现需求

```elixir
|> validate_exclusion(:username, ~w(admin administrator root)) # 保留用户名
|> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/) # 对格式进行要求
|> validate_length(:username, [min: 3, max: 15]) # 限制长度
```


## 基础 {#基础}


### Plug {#plug}

Plug 运行在 Phoenix 的 HTTP 层，所有链接都与 Plug 打交道，并且 Endpoint 、
Router 、 Controller 都属于 Plug


#### function plug {#function-plug}

一个符合 plug 的函数需要接受一个连接，和相关的选项作为参数，并且最终返回这个连接

```elixir
def put_headers(conn, kvs) do
  Enum.reduce(kvs, conn, fn ({k, v}, conn) -> Plug.Conn.put_resp_header(conn, k, v) end)
end
```

我们可以用 plug 将操作流式串联起来，将一个请求所需要的操作流水式的串联起来

```elixir
defmodule AwesomeWeb.HelloController do
  use AwesomeWeb, :controller

  plug :put_haeders, %{content_encoding: "gzip", cache_control: "max-age=3600"}
  plug :put_layout, "bare.html"

  # Other Operators
end
```


#### module plug {#module-plug}

Plug 的另一种类型是 module plug，它被定义在 module 中，可以将整个 module 当作一个 plug 放入处理流程中，因此这个 module 需要符合一定的规范

-   **init/1**：初始化传递给 call/2 的参数或选项
-   **call/2**：处理链接，与 function plug 差不多

我们可以试一试写一个模块 plug，功能是把 `:locale` 键值对放到连接流里，以便让后面的其他 plugs 控制器和页面等也能使用

```elixir
defmodule HelloPhoenixWeb.Plugs.Locale do
  import Plug.Conn
  @locales ["en", "fr", "de"]
  def init(default), do: default
  def call(%Plug.Conn{params: %{"locale" => loc}} = conn, _default) when loc in @locales do
    assign(conn, :locale, loc)
  end
  def call(conn, default), do: assign(conn, :locale, default)
end
```

我们将 Locale Plug 串入 router 中即可

```elixir
defmodule HelloPhoenixWeb.Router do
  use HelloPhoenixWeb, :router
  pipeline :browser do
    ...
    plug HelloPhoenixWeb.Plugs.Locale "en"
  end
  ...
end
```


### 路由 {#路由}

路由是 Phoenix 应用的重要组成部分，可以将对应的 HTTP 请求映射到
controller/action, 处理实时 channel，还为路由之前的中间件定义了一系列的转换功能

**pipeline** 可以定义一种类型的操作，这种操作可以定义一系列 plug 为以后定义的 API
使用。**scope** 操作可以定义一组 API 的作用域，并且可以指定 pipe 类型来获取 plug
操作

```elixir
pipeline :browser do
  plug :accepts, ["html"]
  plug :fetch_session
  plug :fetch_flash
  plug :protect_from_forgery
  plug :put_secure_browser_headers
end
scope "/", HelloPhoenixWeb do
  pipe_through :browser
  get("/", PageController, :index)
end
```

Phoenix 可以使用命令 `mix phx.routes` 查看所有已定义的 API

```text
 page_path  GET     /         HelloPhoenixWeb.PageController :index
hello_path  GET     /hello    HelloPhoenixWeb.HelloController :index
```

Path helpers 是 Router.Helpers 模块动态产生的函数，命名规则根据 Controller 生成，我们可以执行命令 `iex -S mix` 运行项目并中查看 Helps

```elixir
HelloPhoenixWeb.Router.Helpers.page_path(HelloPhoenixWeb.Endpoint, :index) # "/"
HelloPhoenixWeb.Router.Helpers.hello_path(HelloPhoenixWeb.Endpoint, :index) # "/hello"
```

Helps 也可以用在 eex 中，示例 `page_path(@conn, :index)` 的输出即为 `"/"`

```elixir
<a href="<%= page_path(@conn, :index) %>">To the Welcome Page!</a>
```

我们添加一系列 `/` 与 `/admin` 下的 API，phx.routes 查看 API，可以发现 uri、
Controller、function 都是没问题的，但是 helps 都是 **review_path**，这会引起
helps 函数调用错误

```text
review_path  GET     /reviews HelloPhoenixWeb.ReviewController :index
review_path  GET     /reviews/:id/edit HelloPhoenixWeb.ReviewController :edit
review_path  GET     /reviews/new HelloPhoenixWeb.ReviewController :new
review_path  GET     /reviews/:id HelloPhoenixWeb.ReviewController :show
review_path  POST    /reviews HelloPhoenixWeb.ReviewController :create
review_path  PATCH   /reviews/:id HelloPhoenixWeb.ReviewController :update
             PUT     /reviews/:id HelloPhoenixWeb.ReviewController :update
review_path  DELETE  /reviews/:id HelloPhoenixWeb.ReviewController :delete
review_path  GET     /admin/reviews HelloPhoenixWeb.Admin.ReviewController :index
review_path  GET     /admin/reviews/:id/edit HelloPhoenixWeb.Admin.ReviewController :edit
review_path  GET     /admin/reviews/new HelloPhoenixWeb.Admin.ReviewController :new
review_path  GET     /admin/reviews/:id HelloPhoenixWeb.Admin.ReviewController :show
review_path  POST    /admin/reviews HelloPhoenixWeb.Admin.ReviewController :create
review_path  PATCH   /admin/reviews/:id HelloPhoenixWeb.Admin.ReviewController :update
             PUT     /admin/reviews/:id HelloPhoenixWeb.Admin.ReviewController :update
review_path  DELETE  /admin/reviews/:id HelloPhoenixWeb.Admin.ReviewController :delete
```

我们需要添加 `as: :admin` 来解决 helps 冲突

```elixir
scope "/", HelloPhoenixWeb do
  pipe_through :browser
  resources "/reviews", ReviewController
end

scope "/admin", HelloPhoenixWeb.Admin, as: :admin do
  resources "/reviews", ReviewController
end
```


### 控制器 {#控制器}

Phoenix 控制器是一个类似中间人的角色，里面的函数称为 atcion，它响应路由的 HTTP
请求。action 可以命名为任意名称，但我们一般遵循一些约定

-   **index**：按照给定的数据渲染一组条目
-   **show**：渲染一个给定的 id 的独立条目
-   **new**：渲染一个创建新条目所需的表单
-   **create**：接收创建的新条并将其存储
-   **edit**：接收给定 id 的条目，并将其显示在 form 中用以编辑
-   **update**：接收修改过的 item 并存储
-   **delete**：接收给定 id 的条目并将其删除

控制器有一些方法渲染内容，最简单的一种是使用 Phoenix 提供的 `text/2` 方法渲染纯文本，当然也可以有一些其他方法来渲染 `json/2` 或 `html/2`

```elixir
def show(conn, %{"id" => id}) do
  text(conn, "Showing id ${id}") # text: Showing id 15
  json(conn, %{id, id}) # json: {"id": "15"}
  html(conn, """
  <html>
      <head>
	  <title>Passing an Id</title>
      </head>
      <body>
	  <p>You sent in id #{id}</p>
      </body>
  </html>
  """)
end
```

`render/3` 是 Phoenix 提供的渲染 View 的方法，View 与 Controller 需要使用相同的名称，且在 Templates 下有对应的模板目录，目录下对应着 Elixir 模板 HTML 文件

```elixir
defmodule HelloPhoenixWeb.HelloConttoller do
  use HelloPhoenixWeb, :controller
  def show(conn, %{"messenger" => messenger}), do: render(conn, "show.html", messenger: messenger)
end
```

控制器还可以直接返回响应状态

```elixir
def index(conn, _params), do: conn |> send_resp(201, "")
```
