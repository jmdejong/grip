extends Node


@export var tasks_per_frame: int = 4
var queues: Array[Array] = []
var tasks: Dictionary = {}

var next_id: int = 10

func queue_task(priority: int, task: Callable) -> int:
	var id := next_id
	next_id += 1
	while priority >= len(queues):
		queues.push_back([])
	queues[priority].push_back(id)
	tasks[id] = task
	return id

func cancel_task(id: int) -> void:
	tasks.erase(id)

func _process(_delta: float) -> void:
	var i: int = tasks_per_frame
	for queue in queues:
		while not queue.is_empty():
			var task_id = queue.pop_back()
			if task_id != null && tasks.has(task_id):
				tasks[task_id].call()
				tasks.erase(task_id)
				i -= 1
				if i <= 0:
					return
	assert(tasks.size() == 0)
