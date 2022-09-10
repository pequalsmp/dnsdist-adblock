/*
 * Copyright (c) 2022 enilfodne
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */

#include "libdagg.h"

int init(uint64_t *set, size_t set_size, binary_fuse16_t filter) {
  if (!binary_fuse16_allocate(set_size, &filter)) {
    // you may have run out of memory
    return ENOMEM;
  }

  if (!binary_fuse16_populate(set, set_size, &filter)) {
    // it should not fail in practice unless you have
    // many duplicated hash values
    return EINVAL;
  }

  return 0;
}

binary_fuse16_t initialize(uint64_t *set, size_t set_size) {
  binary_fuse16_t filter;

  // printf("[I] initialize - allocate\n");

  if (!binary_fuse16_allocate(set_size, &filter)) {
    // you may have run out of memory
    printf("[E] out of memory");
    // return ENOMEM;
  }

  // printf("[I] initialize - populate\n");

  if (!binary_fuse16_populate(set, set_size, &filter)) {
    // it should not fail in practice unless you have
    // many duplicated hash values
    printf("[E] invalid args");
    // return EINVAL;
  }

  return filter;
}

void deinit(binary_fuse16_t filter) {
  // printf("[I] free\n");
  binary_fuse16_free(&filter);
}

bool contains(const char *value, binary_fuse16_t filter) {
  uint64_t hash = xxhash(value);
  // printf("[%s] - %lx\n", value, hash);
  // printf("al: %d", filter.ArrayLength);
  return binary_fuse16_contain(hash, &filter);
}

uint64_t xxhash(const char *str) {
  return (uint64_t)XXH64(str, strlen(str), 0x00000000);
}
