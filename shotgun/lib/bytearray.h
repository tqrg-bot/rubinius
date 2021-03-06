OBJECT bytearray_new(STATE, int sz);
void *bytearray_byte_address(STATE, OBJECT self);
int bytearray_bytes(STATE, OBJECT self);
char *bytearray_as_string(STATE, OBJECT self);
OBJECT bytearray_dup(STATE, OBJECT self);

OBJECT bytearray_new_dirty(STATE, int size);

#define BYTEARRAY_ADDRESS(self) ((void*)BYTES_OF(self))
#define BYTEARRAY_SIZE(self) SIZE_OF_BODY(self)

#define bytearray_byte_address(st, self) BYTEARRAY_ADDRESS(self)
#define bytearray_bytes(st, self) BYTEARRAY_SIZE(self)

OBJECT iseq_new(STATE, int fields);
void iseq_flip(STATE, OBJECT self);
