#ifndef __CPU_H_
#define __CPU_H_

#include <bstrlib.h>

/* Configuration macros. */

/* Enable direct threading */
#if CONFIG_ENABLE_DT
#define DIRECT_THREADED 0
#else
#define DIRECT_THREADED 0
#endif

/* Whether or not to do runtime tracing support */
#define EXCESSIVE_TRACING state->excessive_tracing
// #define EXCESSIVE_TRACING 0

/* For profiling of code */
#define USE_GLOBAL_CACHING 1
#define USE_INLINE_CACHING 1

#define IP_TYPE uint32_t
#define BS_JUMP 2

#define CTX_FLAG_NO_LONG_RETURN (1<<0)

#define CPU_REGISTERS OBJECT sender; \
  OBJECT block; \
  OBJECT method; \
  OBJECT literals; \
  OBJECT locals; \
  unsigned short argcount; \
  OBJECT name; \
  OBJECT method_module; \
  void *opaque_data; \
  OBJECT self; \
  IP_TYPE *data; \
  unsigned char type; \
  unsigned char flags; \
  unsigned int ip; \
  unsigned int sp; \
  unsigned int fp;

struct fast_context {
  CPU_REGISTERS
};

#define FASTCTX(ctx) ((struct fast_context*)BYTES_OF(ctx))

/* 1Meg of stack */
#define InitialStackSize 262144

#define TASK_NO_STACK 1
#define TASK_FLAG_P(task, flag) ((task->flags & flag) == flag)
#define TASK_SET_FLAG(task, flag) (task->flags |= flag)
#define TASK_CLEAR_FLAG(task, flag) (task->flags ^= flag)

#define CPU_TASK_REGISTERS long int args; \
  unsigned long int stack_slave; \
  long int cache_index; \
  OBJECT *stack_top; \
  unsigned long int stack_size; \
  OBJECT outstanding; \
  OBJECT exception; \
  OBJECT enclosing_class; \
  OBJECT new_class_of; \
  OBJECT exceptions; \
  OBJECT active_context, home_context, main; \
  ptr_array paths; \
  unsigned int depth; \
  OBJECT context_cache; \
  IP_TYPE *ip_ptr; \
  OBJECT *sp_ptr; \
  int call_flags; \
  OBJECT debug_channel; \
  OBJECT control_channel; \
  unsigned long int flags; \
  unsigned int blockargs;
  
#define TASK_FIELDS 25

struct cpu_task {
  CPU_TASK_REGISTERS;
};

struct rubinius_cpu {
  /* Normal registers ande saved and restored per new method call . */
  OBJECT self, sender;
  OBJECT cache;
  IP_TYPE *data;
  unsigned short type;
  unsigned short argcount;
  unsigned int ip;
  unsigned int sp;
  unsigned int fp;
  
  // CPU_REGISTERS;
  
  OBJECT current_task, main_task;
  OBJECT current_thread, main_thread;
  
  /* Task registers are saved and restored when tasks are switched. */
  CPU_TASK_REGISTERS;
};

#define CPU_TASKS_LOCATION(cp) (((char*)cp) + offsetof(struct rubinius_cpu, args))

typedef struct rubinius_cpu *cpu;
typedef OBJECT (*cpu_sampler_collect_cb)(STATE, void*, OBJECT);
typedef OBJECT (*cpu_event_each_channel_cb)(STATE, void*, OBJECT);

#define cpu_stack_empty_p(state, cpu) (cpu->sp_ptr <= cpu->stack_top)
#define cpu_local_get(state, cpu, idx) (NTH_FIELD(cpu->locals, idx))
#define cpu_local_set(state, cpu, idx, obj) (SET_FIELD(cpu->locals, idx, obj))

#define stack_push(obj) cpu_stack_push(state, c, obj, FALSE)
#define stack_pop() ({cpu_stack_pop(state, c);})
#define stack_top() cpu_stack_top(state, c)

#define cpu_current_block(state, cpu) (FASTCTX(cpu->home_context)->block)
#define cpu_current_method(state, cpu) (FASTCTX(cpu->active_context)->method)
#define cpu_current_literals(state, cpu) (FASTCTX(cpu->active_context)->literals)
#define cpu_current_locals(state, cpu) (FASTCTX(cpu->home_context)->locals)
#define cpu_set_locals(state, cpu, obj) (FASTCTX(cpu->home_context)->locals = obj)
#define cpu_current_name(state, cpu) (FASTCTX(cpu->home_context)->name)
#define cpu_current_module(state, cpu) (FASTCTX(cpu->home_context)->method_module)
#define cpu_current_data(cpu) (FASTCTX(cpu->home_context)->data)
#define cpu_current_argcount(cpu) (cpu->argcount)
#define cpu_current_sender(cpu) (cpu->sender)

#define cpu_flush_ip(cpu) (cpu->ip = (cpu->ip_ptr - cpu->data))
#define cpu_flush_sp(cpu) (cpu->sp = (cpu->sp_ptr - cpu->stack_top))

#define cpu_cache_ip(cpu) (cpu->ip_ptr = (cpu->data + cpu->ip))
#define cpu_cache_sp(cpu) (cpu->sp_ptr = (cpu->stack_top + cpu->sp))

cpu cpu_new(STATE);
void cpu_initialize(STATE, cpu c);
void cpu_setup_top_scope(STATE, cpu c);
void cpu_initialize_context(STATE, cpu c);
void cpu_update_roots(STATE, cpu c, ptr_array roots, int start);
inline void cpu_activate_context(STATE, cpu c, OBJECT ctx, OBJECT home, int so);
inline int cpu_return_to_sender(STATE, cpu c, OBJECT val, int consider_block, int exception);
inline int cpu_simple_return(STATE, cpu c, OBJECT val);

OBJECT cpu_const_get_in_context(STATE, cpu c, OBJECT sym);
OBJECT cpu_const_get_from(STATE, cpu c, OBJECT sym, OBJECT under);

OBJECT cpu_const_get(STATE, cpu c, OBJECT sym, OBJECT under);
OBJECT cpu_const_set(STATE, cpu c, OBJECT sym, OBJECT val, OBJECT under);
void cpu_run(STATE, cpu c, int setup);
int cpu_dispatch(STATE, cpu c);
inline void cpu_compile_instructions(STATE, OBJECT ba);
OBJECT cpu_compile_method(STATE, OBJECT cm);

void cpu_set_encloser_path(STATE, cpu c, OBJECT cls);
void cpu_push_encloser(STATE, cpu c);
void cpu_add_method(STATE, cpu c, OBJECT target, OBJECT sym, OBJECT method);
void cpu_attach_method(STATE, cpu c, OBJECT target, OBJECT sym, OBJECT method);
void cpu_raise_exception(STATE, cpu c, OBJECT exc);
void cpu_raise_arg_error(STATE, cpu c, int args, int req);
void cpu_raise_arg_error_generic(STATE, cpu c, const char *msg);
void cpu_raise_from_errno(STATE, cpu c, const char *msg);
OBJECT cpu_new_exception(STATE, cpu c, OBJECT klass, const char *msg);
inline void cpu_perform_hook(STATE, cpu c, OBJECT recv, OBJECT meth, OBJECT arg);

inline void cpu_goto_method(STATE, cpu c, OBJECT recv, OBJECT meth,
                                     int count, OBJECT name, OBJECT block);

inline void cpu_unified_send(STATE, cpu c, OBJECT recv, OBJECT sym, int args, OBJECT block);
OBJECT cpu_locate_method_on(STATE, cpu c, OBJECT obj, OBJECT sym, OBJECT include_private);
inline void cpu_restore_context_with_home(STATE, cpu c, OBJECT ctx, OBJECT home, int ret, int is_block);

void cpu_run_script(STATE, cpu c, OBJECT meth);
inline void cpu_save_registers(STATE, cpu c, int stack_offset);

OBJECT exported_cpu_find_method(STATE, cpu c, OBJECT klass, OBJECT name, OBJECT *mod);

OBJECT cpu_unmarshal(STATE, uint8_t *str, int version);
OBJECT cpu_marshal(STATE, OBJECT obj, int version);
OBJECT cpu_unmarshal_file(STATE, const char *path, int version);
bstring cpu_marshal_to_bstring(STATE, OBJECT obj, int version);
OBJECT cpu_marshal_to_file(STATE, OBJECT obj, char *path, int version);

void cpu_bootstrap(STATE);
void cpu_add_roots(STATE, cpu c, ptr_array roots);
void cpu_update_roots(STATE, cpu c, ptr_array roots, int start);

/* Method cache functions */
void cpu_clear_cache(STATE, cpu c);
void cpu_clear_cache_for_method(STATE, cpu c, OBJECT meth, int full);
void cpu_clear_cache_for_class(STATE, cpu c, OBJECT klass);

OBJECT cpu_task_dup(STATE, cpu c, OBJECT cur);
int cpu_task_select(STATE, cpu c, OBJECT self);
OBJECT cpu_task_associate(STATE, OBJECT self, OBJECT be);
void cpu_task_set_debugging(STATE, OBJECT self, OBJECT dc, OBJECT cc);
OBJECT cpu_channel_new(STATE);
OBJECT cpu_channel_send(STATE, cpu c, OBJECT self, OBJECT obj);
void cpu_channel_receive(STATE, cpu c, OBJECT self, OBJECT cur_task);
OBJECT cpu_thread_new(STATE, cpu c);
void cpu_thread_switch(STATE, cpu c, OBJECT thr);
OBJECT cpu_thread_get_task(STATE, OBJECT self);
void cpu_thread_switch_best(STATE, cpu c);
void cpu_thread_schedule(STATE, OBJECT self);
void cpu_thread_run_best(STATE, cpu c);

void cpu_task_disable_preemption(STATE);
void cpu_task_configure_premption(STATE);

void cpu_sampler_collect(STATE, cpu_sampler_collect_cb, void *cb_data);

#define cpu_event_outstanding_p(state) (state->thread_infos != NULL)
#define cpu_event_update(state) if(cpu_event_outstanding_p(state)) cpu_event_runonce(state)
void cpu_event_runonce(STATE);
void cpu_event_init(STATE);
void cpu_event_run(STATE);
void cpu_event_wake_channel(STATE, cpu c, OBJECT channel, struct timeval *tv);
void cpu_event_each_channel(STATE, cpu_event_each_channel_cb, void *cb_data);
void cpu_event_wait_readable(STATE, cpu c, OBJECT channel, int fd, OBJECT buffer, int count);
void cpu_event_wait_writable(STATE, cpu c, OBJECT channel, int fd);
void cpu_event_wait_signal(STATE, cpu c, OBJECT channel, int sig);
void cpu_channel_register(STATE, cpu c, OBJECT self, OBJECT cur_thr);
void cpu_task_set_outstanding(STATE, OBJECT self, OBJECT ary);
void cpu_event_setup_children(STATE, cpu c);
void cpu_event_wait_child(STATE, cpu c, OBJECT channel, int pid);

#define channel_set_waiting(obj, val) SET_FIELD(obj, 1, val)
#define channel_get_waiting(obj) NTH_FIELD(obj, 1)
#define channel_set_value(obj, val) SET_FIELD(obj, 2, val)
#define channel_get_value(obj) NTH_FIELD(obj, 2)

void cpu_sampler_init(STATE, cpu c);
void cpu_sampler_activate(STATE, int hz);
OBJECT cpu_sampler_disable(STATE);

#if 1

#define cpu_stack_push(state, c, oop, check) ({ OBJECT _tmp = (oop); CHECK_PTR(_tmp); (c)->sp_ptr++; *((c)->sp_ptr) = _tmp; })
#define cpu_stack_pop(state, c) (*(c)->sp_ptr--)
#define cpu_stack_top(state, c) (*(c)->sp_ptr)
#define cpu_stack_set_top(state, c, oop) (*(c)->sp_ptr = oop)

#else 
static inline int cpu_stack_push(STATE, cpu c, OBJECT oop, int check) {
  c->sp += 1;
#if 0
  if(check) {
    if(NUM_FIELDS(c->stack) <= c->sp) {
      return FALSE;
    }
  }
#endif
  SET_FIELD(c->stack, c->sp, oop);
  return TRUE;
}

static inline OBJECT cpu_stack_pop(STATE, cpu c) {
  OBJECT obj;
  obj = NTH_FIELD(c->stack, c->sp);
  c->sp -= 1;
  return obj;
}

static inline OBJECT cpu_stack_top(STATE, cpu c) {
  return NTH_FIELD(c->stack, c->sp);
}

#endif

#define MAX_SYSTEM_PRIM 2048

#define FIRST_RUNTIME_PRIM 1024

int cpu_perform_system_primitive(STATE, cpu c, int prim, OBJECT mo, int num_args, OBJECT name, OBJECT mod);

int cpu_perform_runtime_primitive(STATE, cpu c, int prim, OBJECT mo, int num_args, OBJECT name, OBJECT mod);

static inline int cpu_perform_primitive(STATE, cpu c, int prim, OBJECT mo, int args, OBJECT name, OBJECT mod) {
  if(prim < FIRST_RUNTIME_PRIM) {
    return cpu_perform_system_primitive(state, c, prim, mo, args, name, mod);
  } else {
    return cpu_perform_runtime_primitive(state, c, prim, mo, args, name, mod);
  }
}



#endif /* __CPU_H_ */
