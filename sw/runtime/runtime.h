#pragma once

// string methods
int     memcmp(const void*, const void*, unsigned);
void*   memmove(void*, const void*, unsigned);
void*   memset(void*, int, unsigned);
char*   safestrcpy(char*, const char*, int);
int     strlen(const char*);
int     strncmp(const char*, const char*, unsigned);
char*   strncpy(char*, const char*, int);