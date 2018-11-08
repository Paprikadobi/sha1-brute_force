from libc.string cimport strlen

cdef unsigned int rol(unsigned int n, unsigned int b) nogil:
    return ((n << b) | (n >> (32 - b)))

cdef unsigned int bytes_to_int(unsigned char *c) nogil:
    return c[0] << 24 | c[1] << 16 | c[2] << 8 | c[3]

def sha1(const char* data):
    cdef unsigned int h0 = 0x67452301
    cdef unsigned int h1 = 0xEFCDAB89
    cdef unsigned int h2 = 0x98BADCFE
    cdef unsigned int h3 = 0x10325476
    cdef unsigned int h4 = 0xC3D2E1F0

    cdef Py_ssize_t i = 0

    cdef unsigned char[8] chr = data
    cdef unsigned int[16] bytes
    bytes[0] = bytes_to_int(chr)
    bytes[1] = bytes_to_int(&(chr[4])) | (1 << (63 - strlen(data) * 8))

    for i in range(2, 15):
        bytes[i] = 0

    bytes[15] = strlen(data) * 8;

    cdef unsigned int[80] w = [0]*80
    for i in range(0, 16):
        w[i] = bytes[i]
    for i in range(16, 80):
        w[i] = rol(w[i-3] ^ w[i-8] ^ w[i-14] ^ w[i-16], 1)

    cdef int n = 30
    cdef int sum = 0

    for i in range(n):
        sum += i


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

    return (h0, h1, h2, h3, h4)

def to_hex(h0, h1, h2, h3, h4):
    return '%08x%08x%08x%08x%08x' % (h0, h1, h2, h3, h4)
