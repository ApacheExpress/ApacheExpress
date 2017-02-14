// Noze.io Simple Connect based TodoMVC implementation
// See: http://todomvc.com
// - to compile in Swift 3 invoke: swift build
// - to run result: .build/debug/todo-mvc
// - access backend via:
//     http://todobackend.com/client/index.html?http://localhost:8042/todomvc/
// - test:
//     http://todobackend.com/specs/index.html?http://localhost:8042/todomvc/

import ApacheExpress

// A global used in the model layer, yeah, lame. In a real app this wouldn't be
// part of the model.
let ourAPI = "http://localhost:8042/todomvc/"

func expressMain() {
  let app = apache.express()
  
  // MARK: - Middleware

  // app.use(logger("dev"))
  app.use(bodyParser.json())
  app.use(cors(allowOrigin: "*"))


  // MARK: - Hack Test, bug in spec tool

  app.get("/todomvc/*") { req, _, next in
    // The /specs/index.html sends:
    //   Content-Type: application/json
    //   Accept:       text/plain, */*; q=0.01
    //
    // The tool essentially has the misconception that the API always returns
    // JSON regardless of the Accept header.
    if let ctype = (req.getHeader("Content-Type") as? String) {
      if ctype.hasPrefix("application/json") {
        req.setHeader("Accept", "application/json")
      }
    }
    try next()
  }


  // MARK: - Storage

  let todos = VolatileStoreCollection<Todo>()

  // prefill hack
  todos.objects[42] = Todo(id: 42, title: "Buy Beer",     completed: true,
                           order: 1)
  todos.objects[43] = Todo(id: 43, title: "Buy Mo' Beer", completed: false,
                           order: 2)

  
  // MARK: - Routes & Handlers
  
  // hook up CalDAV support
  app.use(CalDAVExpress(prefix: "/todomvc", todos: todos))
  
  app.del("/todomvc/todos/:id") { req, res, _ in
    guard let id = req.params[int: "id"] else { return try res.sendStatus(400) }
    todos.delete(id: id)
    try res.sendStatus(200)
  }

  app.del("/todomvc") { req, res, _ in
    todos.deleteAll()
    try res.json([]) // everything deleted, respond with an empty array
  }

  app.patch("/todomvc/todos/:id") { req, res, _ in
    guard let id = req.params[int: "id"] else { return try res.sendStatus(404) }
    
    guard let json = req.body.json     else { return try res.sendStatus(400) }
    guard var todo = todos.get(id: id) else { return try res.sendStatus(404) }
    
    if let t = try? json.string("title")   { todo.title     = t }
    if let t = try? json.bool("completed") { todo.completed = t }
    if let t = try? json.int("order")      { todo.order     = t }
    todos.update(id: id, value: todo) // value type!
    
    try res.json(todo)
  }

  app.get("/todomvc/todos/:id") { req, res, _ in
    guard let id = req.params[int: "id"] else { return try res.sendStatus(404) }
    guard let todo = todos.get(id: id)   else { return try res.sendStatus(404) }
    try res.json(todo)
  }

  app.post("/todomvc/*") { req, res, _ in
    guard let json = req.body.json else { return try res.sendStatus(400) }
    
    guard let t = try? json.string("title")
     else { return try res.sendStatus(400) }
    
    let completed = try? json.bool("completed")
    let order     = try? json.int("order")
    
    let pkey = todos.nextKey()
    let newTodo = Todo(id: pkey, title: t,
                       completed: completed ?? false,
                       order:     order     ?? 0)
    todos.update(id: pkey, value: newTodo) // value type!
    try res.status(201).json(newTodo)
  }

  app.get("/todomvc/*") { req, res, _ in
    if req.accepts("json") != nil {
      try res.json(todos.getAll())
    }
    else {
      let clientURL = "http://todobackend.com/client/index.html?\(ourAPI)"
      
      try res.send(
        "<html><body><h3>Welcome to the ApacheExpress Todo MVC Backend</h3>" +
          "<ul>" +
          "<li><a href=\"\(clientURL)\">Client</a></li>" +
          "<ul>" +
        "</body></html>"
      )
    }
  }
}
