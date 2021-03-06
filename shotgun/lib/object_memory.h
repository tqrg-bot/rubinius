#include "shotgun.h"
#include "baker.h"
#include "marksweep.h"
#include <stdlib.h>

#ifndef __RUBINIUS_OM__
#define __RUBINIUS_OM__ 1

#define OMDefaultSize 4194304
/* A little over 1% of the total heap size. */
#define LargeObjectThreshold 2700
//#define OMDefaultSize 100000

#define OMCollectYoung  0x1
#define OMCollectMature 0x2

struct object_memory_struct {
  int collect_now;
  int enlarge_now;
  int tenure_now;
  int new_size;
  int last_object_id;
  baker_gc gc;
  mark_sweep_gc ms;
  int last_tenured;
  
  rheap contexts;
  /* The first not referenced stack context */
  OBJECT context_bottom;
  OBJECT context_top;
  OBJECT context_last;
};

typedef struct object_memory_struct *object_memory;

object_memory object_memory_new();
int object_memory_delete(object_memory om);
int object_memory_used(object_memory om);
int object_memory_collect(STATE, object_memory om, ptr_array roots);
void object_memory_check_memory(object_memory om);
OBJECT object_memory_new_object_normal(object_memory om, OBJECT cls, int fields);
static inline OBJECT _om_inline_new_object(object_memory om, OBJECT cls, int fields);

OBJECT object_memory_new_object_mature(object_memory om, OBJECT cls, int fields);
void object_memory_print_stats(object_memory om);
OBJECT object_memory_new_opaque();
OBJECT object_memory_tenure_object(void* data, OBJECT obj);
void object_memory_major_collect(STATE, object_memory om, ptr_array roots);
OBJECT object_memory_collect_references(STATE, object_memory om, OBJECT mark);
void object_memory_setup_become(STATE, object_memory om, OBJECT from, OBJECT to);
void object_memory_clear_become(STATE, object_memory om);
void object_memory_update_rs(object_memory om, OBJECT target, OBJECT val);

void object_memory_shift_contexts(STATE, object_memory om);
void object_memory_mark_contexts(STATE, object_memory om);
void object_memory_formalize_contexts(STATE, object_memory om);

#define FAST_NEW 1

#ifdef FAST_NEW
#define object_memory_new_object _om_inline_new_object_init
#else
#define object_memory_new_object object_memory_new_object_normal
#endif

#define object_memory_new_dirty_object _om_inline_new_object

#define CTX_SIZE SIZE_IN_BYTES_FIELDS(FASTCTX_FIELDS)
  
#define object_memory_new_context(om) ((OBJECT)heap_allocate_dirty(om->contexts, CTX_SIZE))

#define om_on_stack(om, ctx) heap_contains_p(om->contexts, ctx)
#define om_in_heap(om, ctx) heap_contains_p(om->gc->current, ctx)

#define object_memory_retire_context(om, ctx) \
if(om_on_stack(om, ctx) && (ctx >= om->context_bottom)) { \
  xassert(ctx == om->contexts->current - CTX_SIZE);\
  fast_memfill_s20((void*)ctx, 0); heap_putback(om->contexts, CTX_SIZE); \
}

#define object_memory_context_referenced(om, ctx) (void)({	      \
      OBJECT _nb = (OBJECT) ((uintptr_t)ctx + CTX_SIZE);	      \
      if(om_on_stack(om, ctx) &&				      \
	 (om->context_bottom < _nb)) { om->context_bottom = _nb; } })

#define om_context_referenced_p(om, ctx) ((ctx < om->context_bottom) && (ctx >= (OBJECT)om->contexts->address))

#define om_stack_context_p(om, ctx) (om_on_stack(om, ctx) && (ctx >= om->context_bottom))

#define om_stack_next_ctx(ctx) ((OBJECT)(ctx + CTX_SIZE))
#define om_stack_prev_ctx(ctx) ((OBJECT)(ctx - CTX_SIZE))
#define om_stack_sender(ctx) om_stack_prev_ctx(ctx)

#define om_valid_context_p(state, ctx) ( \
  (om_stack_context_p(state->om, ctx) && stack_context_p(ctx)) || \
  (om_context_referenced_p(state->om, ctx)) || \
  (om_in_heap(state->om, ctx) && (methctx_is_fast_p(state, ctx) ||  blokctx_s_block_context_p(state, ctx))) \
)

#define EACH_CTX(om, addr)		 \
  addr = (OBJECT) om->contexts->address; \
  while(addr < (OBJECT) om->contexts->current) {
    
#define DONE_EACH_CTX(addr) addr = (address)( (uintptr_t)addr + CTX_SIZE); }

#define EACH_REFD_CTX(om, addr)          \
  addr = (OBJECT) om->contexts->address; \
  while(addr < om->context_bottom) {
  
#define DONE_EACH_REFD_CTX(addr) addr = (address)( (uintptr_t)addr + CTX_SIZE); }

#define EACH_STACK_CTX(om, addr)       \
  addr = (OBJECT) om->context_bottom;  \
  while(addr < (OBJECT)om->contexts->current) {
    
#define DONE_EACH_STACK_CTX(addr) addr = (address)( (uintptr_t)addr + CTX_SIZE); }

#define om_no_referenced_ctxs_p(om) (om->context_bottom == (OBJECT)om->contexts->address)

/* These are the 4 scenarios detailed in doc/life_of_a_context.txt */

#define om_valid_sender_p(om, ctx, sender) ( \
  (NIL_P(sender) && om_on_stack(om, ctx)) || \
  (om_on_stack(om, ctx) && om_on_stack(om, sender) && (om_context_referenced_p(om, sender) || (sender == om_stack_sender(ctx)))) || \
  (om_in_heap(om, sender) && om_on_stack(om, ctx) && (om->context_bottom == ctx)) || \
  (om_in_heap(om, ctx) && (om_context_referenced_p(om, sender) || om_in_heap(om, sender))))

#endif

