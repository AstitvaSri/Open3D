// ----------------------------------------------------------------------------
// -                        Open3D: www.open3d.org                            -
// ----------------------------------------------------------------------------
// The MIT License (MIT)
//
// Copyright (c) 2018-2021 www.open3d.org
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
// ----------------------------------------------------------------------------
#pragma once

#include "open3d/core/CUDAUtils.h"
#include "open3d/core/nns/BlockSelect.cuh"
#include "open3d/core/nns/Limits.cuh"

#define BLOCK_SELECT_DECL(TYPE, DIR, WARP_Q)                               \
    extern void runBlockSelect_##TYPE##_##DIR##_##WARP_Q##_(               \
            TYPE* in, TYPE* outK, int32_t* outV, bool dir, int k, int dim, \
            int num_points, cudaStream_t stream);                          \
                                                                           \
    extern void runBlockSelectPair_##TYPE##_##DIR##_##WARP_Q##_(           \
            TYPE* inK, int32_t* inV, TYPE* outK, int32_t* outV, bool dir,  \
            int k, int dim, int num_points, cudaStream_t stream);

#define BLOCK_SELECT_IMPL(TYPE, DIR, WARP_Q, THREAD_Q)                        \
    void runBlockSelect_##TYPE##_##DIR##_##WARP_Q##_(                         \
            TYPE* in, TYPE* outK, int32_t* outV, bool dir, int k, int dim,    \
            int num_points, cudaStream_t stream) {                            \
        auto grid = dim3(num_points);                                         \
                                                                              \
        constexpr int kBlockSelectNumThreads = (WARP_Q <= 1024) ? 128 : 64;   \
        auto block = dim3(kBlockSelectNumThreads);                            \
                                                                              \
        OPEN3D_ASSERT(k <= WARP_Q);                                           \
        OPEN3D_ASSERT(dir == DIR);                                            \
                                                                              \
        auto kInit = dir ? Limits<TYPE>::getMin() : Limits<TYPE>::getMax();   \
        auto vInit = -1;                                                      \
                                                                              \
        blockSelect<TYPE, int, DIR, WARP_Q, THREAD_Q, kBlockSelectNumThreads> \
                <<<grid, block, 0, stream>>>(in, outK, outV, kInit, vInit, k, \
                                             dim, num_points);                \
    }                                                                         \
                                                                              \
    void runBlockSelectPair_##TYPE##_##DIR##_##WARP_Q##_(                     \
            TYPE* inK, int32_t* inV, TYPE* outK, int32_t* outV, bool dir,     \
            int k, int dim, int num_points, cudaStream_t stream) {            \
        auto grid = dim3(num_points);                                         \
                                                                              \
        constexpr int kBlockSelectNumThreads = (WARP_Q <= 1024) ? 128 : 64;   \
        auto block = dim3(kBlockSelectNumThreads);                            \
                                                                              \
        OPEN3D_ASSERT(k <= WARP_Q);                                           \
        OPEN3D_ASSERT(dir == DIR);                                            \
                                                                              \
        auto kInit = dir ? Limits<TYPE>::getMin() : Limits<TYPE>::getMax();   \
        auto vInit = -1;                                                      \
                                                                              \
        blockSelectPair<TYPE, int, DIR, WARP_Q, THREAD_Q,                     \
                        kBlockSelectNumThreads><<<grid, block, 0, stream>>>(  \
                inK, inV, outK, outV, kInit, vInit, k, dim, num_points);      \
    }

#define BLOCK_SELECT_CALL(TYPE, DIR, WARP_Q)                                 \
    runBlockSelect_##TYPE##_##DIR##_##WARP_Q##_(in, outK, outV, dir, k, dim, \
                                                num_points, stream)

#define BLOCK_SELECT_PAIR_CALL(TYPE, DIR, WARP_Q)    \
    runBlockSelectPair_##TYPE##_##DIR##_##WARP_Q##_( \
            inK, inV, outK, outV, dir, k, dim, num_points, stream)
