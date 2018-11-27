# distutils: extra_compile_args = -fopenmp
# distutils: extra_link_args = -fopenmp
# cython: nonecheck = False, wraparound = False, boundscheck = False, cdivision = True

from libc.string cimport strlen
from libc.stdlib cimport malloc, realloc
from libc.math cimport pow

from libc.stdio cimport printf
from cython.parallel cimport prange, parallel
cimport openmp

cdef class Generator:

    cdef char* charset
    cdef unsigned int charset_length
    cdef unsigned int i
    cdef unsigned int length
    cdef unsigned int using
    cdef char found

    def __init__(self, const char[] charset, int min_length = 1):
        self.charset = charset
        self.charset_length = strlen(charset)
        self.i = 0
        self.length = min_length
        self.using = 0
        self.found = 0

    cdef char* next(self, char* password) nogil:
        while self.using:
            pass
        self.using = 1
        cdef long j = self.i
        self.i += 1
        self.using = 0
        
        cdef unsigned int i = 0
        cdef unsigned int mod = self.charset_length

        if j == <unsigned int>pow(mod, self.length):
            self.length += 1
            password = <char*>realloc(password, self.length + 1)
        for i in reversed(range(self.length)):
            password[i] = self.charset[j % mod]
            j -= (j % mod) + mod
            j /= mod

        password[self.length] = '\0'

        return password

cdef struct hash_t:
    unsigned int h0, h1, h2, h3, h4

cdef unsigned int rol(unsigned int n, unsigned int b) nogil:
    return ((n << b) | (n >> (32 - b)))

cdef hash_t _sha1(const char[] data, unsigned int length) nogil:
    cdef unsigned int h0 = 0x67452301
    cdef unsigned int h1 = 0xEFCDAB89
    cdef unsigned int h2 = 0x98BADCFE
    cdef unsigned int h3 = 0x10325476
    cdef unsigned int h4 = 0xC3D2E1F0

    cdef unsigned int i

    cdef unsigned int[80] w

    for i in range(15):
        w[i] = 0

    for i in range(length):
        w[i / 4] |= data[i] << ((3 - (i % 4)) * 8)

    i += 1
    w[i / 4] |= 0x80 << ((3 - (i % 4)) * 8)

    w[15] = length * 8

    for i in range(16, 80):
        w[i] = rol(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1)

    cdef unsigned int a = h0
    cdef unsigned int b = h1
    cdef unsigned int c = h2
    cdef unsigned int d = h3
    cdef unsigned int e = h4
    cdef unsigned int f, k, temp

    for i in range(80):
        if 0 <= i <= 19:
            f = (b & c) | ((~b) & d)
            k = 0x5A827999
        elif 20 <= i <= 39:
            f = b ^ c ^ d
            k = 0x6ED9EBA1
        elif 40 <= i <= 59:
            f = (b & c) | (b & d) | (c & d)
            k = 0x8F1BBCDC
        elif 60 <= i <= 79:
            f = b ^ c ^ d
            k = 0xCA62C1D6

        temp = rol(a, 5) + f + e + k + w[i]
        e = d
        d = c
        c = rol(b, 30)
        b = a
        a = temp

    h0 = h0 + a
    h1 = h1 + b
    h2 = h2 + c
    h3 = h3 + d
    h4 = h4 + e

    cdef hash_t hash
    hash.h0 = h0
    hash.h1 = h1
    hash.h2 = h2
    hash.h3 = h3
    hash.h4 = h4
    return hash

cdef unsigned int hashes_equals(hash_t first, hash_t second) nogil:
    return first.h0 == second.h0 and first.h1 == second.h1 and first.h2 == second.h2 and first.h3 == second.h3 and first.h4 == second.h4

def sha1(const char[] data):
    cdef hash_t hash = _sha1(data, strlen(data))
    return (hash.h0, hash.h1, hash.h2, hash.h3, hash.h4)

cdef char* _brute_force(const char[] charset, hash_t target):
    cdef Generator generator = Generator(charset)
    cdef char* password

    with nogil, parallel(num_threads = 2):
        password = <char*>malloc(2)
        while True:
            password = generator.next(password)
            if hashes_equals(_sha1(password, generator.length), target):
                generator.found = 1
                printf("%d\n", generator.i)
                return password
            if generator.found:
                break

def brute_force(const char[] charset, unsigned int h0, unsigned int h1, unsigned int h2, unsigned int h3, unsigned int h4):    
    cdef hash_t target
    target.h0 = h0
    target.h1 = h1
    target.h2 = h2
    target.h3 = h3
    target.h4 = h4

    cdef char* password = _brute_force(charset, target)

    return password

def to_hex(h0, h1, h2, h3, h4):
    return '%08x%08x%08x%08x%08x' % (h0, h1, h2, h3, h4)

